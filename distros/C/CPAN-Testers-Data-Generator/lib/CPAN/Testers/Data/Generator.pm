package CPAN::Testers::Data::Generator;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.21';

#----------------------------------------------------------------------------
# Library Modules

use Config::IniFiles;
use CPAN::Testers::Common::Article;
use CPAN::Testers::Common::DBUtils;
#use Data::Dumper;
use Data::FlexSerializer;
use DateTime;
use DateTime::Duration;
use File::Basename;
use File::Path;
use File::Slurp;
use HTML::Entities;
use IO::File;
use JSON;
use Time::Local;

use Metabase    0.004;
use Metabase::Fact;
use Metabase::Resource;
use CPAN::Testers::Fact::LegacyReport;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Metabase::AWS;
use CPAN::Testers::Report;

#----------------------------------------------------------------------------
# Variables

my $DIFF = 30;          # max difference allowed in seconds
my $MINS = 15;          # split time in minutes

my %testers;

my $FROM    = 'CPAN Tester Report Server <do_not_reply@cpantesters.org>';
my $HOW     = '/usr/sbin/sendmail -bm';
my $HEAD    = 'To: EMAIL
From: FROM
Date: DATE
Subject: CPAN Testers Generator Error Report

';

my $BODY    = '
The following reports failed to parse into the cpanstats database:

INVALID

Thanks,
CPAN Testers Server.
';

my @admins = (
    'barbie@missbarbell.co.uk',
    #'david@dagolden.com'
);

my ($OSNAMES,%MAPPINGS);

#----------------------------------------------------------------------------
# The Application Programming Interface

sub new {
    my $class = shift;
    my %hash  = @_;

    my $self = {
        meta_count  => 0,
        stat_count  => 0,
        last        => '',
    };
    bless $self, $class;

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $hash{config} );

    # configure databases
    for my $db (qw(CPANSTATS METABASE)) {
        die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
        my %opts = map {$_ => ($cfg->val($db,$_)||undef);} qw(driver database dbfile dbhost dbport dbuser dbpass);
        $opts{AutoCommit} = 0;
        $self->{$db} = CPAN::Testers::Common::DBUtils->new(%opts);
        die "Cannot configure $db database\n" unless($self->{$db});
        $self->{$db}->{'mysql_enable_utf8'}    = 1 if($opts{driver} =~ /mysql/i);
        $self->{$db}->{'mysql_auto_reconnect'} = 1 if($opts{driver} =~ /mysql/i);
    }

    if($cfg->SectionExists('ADMINISTRATION')) {
        my @admins = $cfg->val('ADMINISTRATION','admins');
        $self->{admins} = \@admins;
    }

    # command line swtiches override configuration settings
    for my $key (qw(logfile poll_limit stopfile offset aws_bucket aws_namespace)) {
        $self->{$key} = $hash{$key} || $cfg->val('MAIN',$key);
    }

    $self->{offset}     ||= 1;
    $self->{poll_limit} ||= 1000;

    my @rows = $self->{METABASE}->get_query('hash','SELECT * FROM testers_email');
    for my $row (@rows) {
        $testers{$row->{resource}} = $row->{email};
    }

    # build OS names map
    @rows = $self->{CPANSTATS}->get_query('array','SELECT osname,ostitle FROM osname');
    for my $row (@rows) {
        $self->{OSNAMES}{lc $row->[0]} ||= $row->[1];
    }
    $OSNAMES = join('|',keys %{$self->{OSNAMES}})   if(keys %{$self->{OSNAMES}});

    $self->load_uploads();
    $self->load_authors();
    $self->load_perl_versions();

    if($cfg->SectionExists('DISABLE')) {
        my @values = $cfg->val('DISABLE','LIST');
        $self->{DISABLE}{$_} = 1    for(@values);
    }

    if($cfg->SectionExists('OSNAMES')) {
        for my $param ($cfg->Parameters('OSNAMES')) {
            $self->{OSNAMES}{lc $param} ||= lc $cfg->val('OSNAMES',$param);
        }
    }

    if($cfg->SectionExists('MAPPINGS')) {
        for my $param ($cfg->Parameters('MAPPINGS')) {
            $MAPPINGS{$param} = [ split(',', $cfg->val('MAPPINGS',$param), 2) ];
        }
    }

    eval {
        $self->{metabase} = CPAN::Testers::Metabase::AWS->new(
            bucket      => $self->{aws_bucket},
            namespace   => $self->{aws_namespace},
        );
        $self->{librarian} = $self->{metabase}->public_librarian;
    };

    # if we require remote access, we need the librarian
    unless($hash{localonly}) {
        return  unless($self->{metabase} && $self->{librarian});
    }

    # reports are now stored in a compressed format
    $self->{serializer} = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_json         => 1,
        output_format       => 'json'
    );
    $self->{serializer2} = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_sereal       => 1,
        output_format       => 'sereal'
    );

    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->save_perl_versions();
}

#----------------------------------------------------------------------------
# Public Methods

sub generate {
    my $self    = shift;
    my $nonstop = shift || 0;
    my $maxdate = shift;
    my ($to,@reports);

    $self->{reparse} = 0;

$self->_log("START GENERATE nonstop=$nonstop\n");

    do {
        my $start = localtime(time);
        ($self->{processed},$self->{stored},$self->{cached}) = (0,0,0);

        if($maxdate) {
            $to = $maxdate;
        } else {
            $to = sprintf "%sT%sZ", DateTime->now->ymd, DateTime->now->hms;
        }

$self->_log("DATES maxdate=$maxdate, to=$to \n");

        my $data = $self->get_next_dates($to);
    
        $self->_consume_reports( $to, $data );

        $nonstop = 0	if($self->{processed} == 0);
        $nonstop = 0	if($self->{stopfile} && -f $self->{stopfile});
        $nonstop = 0	if($maxdate && $maxdate le $to);

        $self->load_uploads()	if($nonstop);
        $self->load_authors()	if($nonstop);

$self->_log("CHECK nonstop=$nonstop\n");
    } while($nonstop);
$self->_log("STOP GENERATE nonstop=$nonstop\n");
}

sub regenerate {
    my ($self,$hash) = @_;

    $self->{reparse} = 0;

    my $maxdate = sprintf "%sT%sZ", DateTime->now->ymd, DateTime->now->hms;

    $self->_log("START REGENERATE\n");

    my @data;
    if($hash->{file}) {
        my $fh = IO::File->new($hash->{file},'r') or die "Cannot open file [$hash->{file}]: $!\n";
        while(<$fh>) {
            s/\s+$//;
            my ($fval,$tval) = split(/,/,$_,2);
            my %data;
            $data{gstart} = $fval   if($fval =~ /^\w+-\w+-\w+-\w+-\w+$/);
            $data{dstart} = $fval   if($fval =~ /^\d+-\d+-\d+T\d+:\d+:\d+Z$/);
            $data{gend}   = $tval   if($tval =~ /^\w+-\w+-\w+-\w+-\w+$/);
            $data{dend}   = $tval   if($tval =~ /^\d+-\d+-\d+T\d+:\d+:\d+Z$/);
            push @data, \%data;
        }
        $fh->close;
    } else {
        push @data, {   gstart => $hash->{gstart}, gend => $hash->{gend},
                        dstart => $hash->{dstart}, dend => $hash->{dend} };
    }

    $self->_consume_reports( $maxdate, \@data );

    $self->_log("STOP REGENERATE\n");
}

sub rebuild {
    my ($self,$hash) = @_;
$self->_log("START REBUILD\n");

    my $start = localtime(time);
    ($self->{processed},$self->{stored},$self->{cached}) = (0,0,0);

    $self->{reparse}   = 1;
    $self->{localonly} = $hash->{localonly} ? 1 : 0;
    $self->{check}     = $hash->{check}     ? 1 : 0;


    # selection choices:
    # 1) from guid [to guid]
    # 2) from date [to date]

    $hash->{dstart} = $self->_get_createdate( $hash->{gstart}, $hash->{dstart} );
    $hash->{dend}   = $self->_get_createdate( $hash->{gend},   $hash->{dend} );

    my @where;
    push @where, "updated >= '$hash->{dstart}'"  if($hash->{dstart});
    push @where, "updated <= '$hash->{dend}'"    if($hash->{dend});
    
    my $sql =   'SELECT * FROM metabase' . 
                (@where ? ' WHERE ' . join(' AND ',@where) : '') .
                ' ORDER BY updated ASC';

$self->_log("START sql=[$sql]\n");

#    $self->{CPANSTATS}->do_query("DELETE FROM cpanstats WHERE id >= $start AND id <= $end");

    my $iterator = $self->{METABASE}->iterator('hash',$sql);
    while(my $row = $iterator->()) {
        $self->_log("GUID [$row->{guid}]");
        $self->{processed}++;

        my $report = $self->load_fact(undef,0,$row);

        unless($report) {
            $self->_log(" ... no report\n");
            warn "No report returned [$row->{id},$row->{guid}]\n";
            next;
        }

        $self->{report}{id}       = $row->{id};
        $self->{report}{guid}     = $row->{guid};
        $self->{report}{metabase} = $self->{facts};

        # corrupt cached report?
        if($self->reparse_report()) { # true if invalid report
            $self->_log(".. cannot parse metabase cache report\n");
            warn "Cannot parse cached report [$row->{id},$row->{guid}]\n";
            next;
        }

        if($self->store_report())   { $self->_log(".. cpanstats stored\n") }
        else                        { $self->_log(".. cpanstats not stored\n") }
        if($self->cache_update())   { $self->_log(".. metabase stored\n") }
        else                        { $self->_log(".. bad metabase cache data\n") }

        $self->{stored}++;
        $self->{cached}++;
    }

    my $invalid = $self->{invalid} ? scalar(@{$self->{invalid}}) : 0;
    my $stop = localtime(time);
    $self->_log("MARKER: processed=$self->{processed}, stored=$self->{stored}, cached=$self->{cached}, invalid=$invalid, start=$start, stop=$stop\n");

    $self->commit();
$self->_log("STOP REBUILD\n");
}

sub parse {
    my ($self,$hash) = @_;
$self->_log("START PARSE\n");

    my @guids = $self->_get_guid_list($hash->{guid},$hash->{file});
    return  unless(@guids);

    $self->{force} ||= 0;

    for my $guid (@guids) {
        $self->_log("GUID [$guid]");

        my ($report,$stored);
        unless($hash->{force}) {
            $report = $self->load_fact($guid,1);
            $stored = $self->retrieve_report($guid);
        }

        if($report && $stored) {
            $self->_log(".. report already stored and cached\n");
            next;
        }

        $report = $self->get_fact($guid);

        unless($report) {
            $self->_log(".. report not found [$guid]\n");
            next;
        }
            
        $self->{report}{guid} = $guid;
        $hash->{report} = $report;
        if($self->parse_report(%$hash)) {	# true if invalid report
            $self->_log(".. cannot parse report [$guid]\n");
            next;
        }

	    if($self->store_report()) { $self->_log(".. stored"); }
	    else                      { $self->_log(".. already stored"); }

       	if($self->cache_report()) { $self->_log(".. cached\n"); }
       	else                      { $self->_log(".. FAIL: bad cache data\n"); }
	}

    $self->commit();
$self->_log("STOP PARSE\n");
    return 1;
}

sub reparse {
    my ($self,$hash) = @_;
$self->_log("START REPARSE\n");

    my @guids = $self->_get_guid_list($hash->{guid},$hash->{file});
    return  unless(@guids);

    $self->{reparse}   = $self->{force}     ? 0 : 1;
    $self->{localonly} = $hash->{localonly} ? 1 : 0;
    $self->{check}     = $hash->{check}     ? 1 : 0;

    for my $guid (@guids) {
        $self->_log("GUID [$guid]");

        my $report;
        $report = $self->load_fact($guid)    unless($hash->{force});

        if($report) {
            $self->{report}{metabase} = $report;
            $self->{report}{guid} = $guid;
            $hash->{report} = $report;
            if($self->reparse_report(%$hash)) {	# true if invalid report
                $self->_log(".. cannot parse report [$guid]\n");
                return 0;
            }
        } else {
            $report = $self->get_fact($guid)    unless($report || $hash->{localonly});

            unless($report) {
                if($self->{localonly}) {
                    $self->_log(".. report not available locally [$guid]\n");
                    return 0;
                }
                $self->_log(".. report not found [$guid]\n");
                return 0;
            }
            
            $self->{report}{guid} = $guid;
            $hash->{report} = $report;
            if($self->parse_report(%$hash)) {	# true if invalid report
                $self->_log(".. cannot parse report [$guid]\n");
                return 0;
            }
        }

	    if($self->store_report()) { $self->_log(".. stored"); }
	    else                      {
	        if($self->{time} gt $self->{report}{updated}) {
	            $self->_log(".. FAIL: older than requested [$self->{time}]\n");
	            return 0;
            }
            
           	$self->_log(".. already stored");
       	}
       	if($self->cache_report()) { $self->_log(".. cached\n"); }
       	else                      { $self->_log(".. FAIL: bad cache data\n"); }
	}

    $self->commit();
$self->_log("STOP REPARSE\n");
    return 1;
}

sub tail {
    my ($self,$hash) = @_;
    return unless($hash->{file});

$self->_log("START TAIL\n");

    my $guids = $self->get_tail_guids();
    my $fh = IO::File->new($hash->{file},'a+') or die "Cannot read file [$hash->{file}]: $!";
    print $fh "$_\n"    for(@$guids);
    $fh->close;

$self->_log("STOP TAIL\n");
}

#----------------------------------------------------------------------------
# Internal Methods

sub commit {
    my $self = shift;
    for(qw(CPANSTATS)) {
        next    unless($self->{$_});
        $self->{$_}->do_commit;
    }
}

sub get_tail_guids {
    my $self = shift;
    my $guids;

    eval {
#        $guids = $self->{librarian}->search(
#        	'core.type'         => 'CPAN-Testers-Report',
#        	'core.update_time'  => { ">", 0 },
#        	'-desc'             => 'core.update_time',
#        	'-limit'            => $self->{poll_limit},
#    	);
        $guids = $self->{librarian}->search(
            '-where'  => [
                '-and' =>
                    [ '-eq' => 'core.type'         => 'CPAN-Testers-Report' ],
                    [ '-ge' => 'core.update_time'  => 0 ]
            ],
            '-order'  => [ '-desc' => 'core.update_time' ],
            '-limit'  => $self->{poll_limit},
        );
    };

    $self->_log(" ... Metabase Tail Failed [$@]\n") if($@);
    $self->_log("Retrieved ".($guids ? scalar(@$guids) : 0)." guids\n");

    return $guids;
}

sub get_next_dates {
    my ($self,$to) = @_;
    my (@data,$from);

    my $time = sprintf "%sT%sZ", DateTime->now->ymd, DateTime->now->hms;

$self->_log("DATES to=$to, time=$time\n");

    # note that because Amazon's SimpleDB can return odd entries out of sync, we have to look at previous entries
    # to ensure we are starting from the right point. Also ignore date/times in the future.
    my @rows = $self->{METABASE}->get_query('array','SELECT updated FROM metabase WHERE updated <= ? ORDER BY updated DESC LIMIT 10',$time);
    for my $row (@rows) {
        if($from) {
            my $diff = abs( _date_diff($from,$row->[0]) ); # just interested in the difference
            $self->_log("get_next_dates from=[$from], updated=[$row->[0]], diff=$diff, DIFF=$DIFF\n");
            next if($diff < $DIFF);
        }

        $from = $row->[0];
    }

    $from ||= '1999-01-01T00:00:00Z';
    if($from gt $to) {
        my $xx = $from;
        $from  = $to;
        $to    = $xx;
    }

    $self->_log("NEXT from=[$from], to=[$to]\n");

    while($from lt $to) {
        my @from = $from =~ /(\d+)\-(\d+)\-(\d+)T(\d+):(\d+):(\d+)/;
        my $dt = DateTime->new(
            year => $from[0], month => $from[1], day => $from[2],
            hour => $from[3], minute => $from[4], second => $from[5],
        );
        $dt->add( DateTime::Duration->new( minutes => $MINS ) );
        my $split = sprintf "%sT%sZ", $dt->ymd, $dt->hms;
        if($split lt $to) {
            push @data, { dstart => $from, dend => $split };
        } else {
            push @data, { dstart => $from, dend => $to };
        }

        $from = $split;
    }

    return \@data;
}

sub get_next_guids {
    my ($self,$start,$end) = @_;
    my ($guids);

    $self->{time} ||= 0;
    $self->{last} ||= 0;
    $start ||= 0;

    $self->_log("PRE time=[$self->{time}], last=[$self->{last}], start=[".($start||'')."], end=[".($end||'')."]\n");

    if($start) {
        $self->{time}       = $start;
        $self->{time_to}    = $end || '';
    } else {
        my $time = sprintf "%sT%sZ", DateTime->now->ymd, DateTime->now->hms;

        # note that because Amazon's SimpleDB can return odd entries out of sync, we have to look at previous entries
        # to ensure we are starting from the right point. Also ignore date/times in the future.
        my @rows = $self->{METABASE}->get_query('array','SELECT updated FROM metabase WHERE updated <= ? ORDER BY updated DESC LIMIT 10',$time);
        for my $row (@rows) {
            if($self->{time}) {
                my $diff = abs( _date_diff($self->{time},$row->[0]) ); # just interested in the difference
                next if($diff < $DIFF);
            }

            $self->{time} = $row->[0];
        }

        $self->{time} ||= '1999-01-01T00:00:00Z';
        if($self->{last} ge $self->{time}) {
            my @ts = $self->{last} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/;
            $ts[1]--;
            my $ts = timelocal(reverse @ts);
            @ts = localtime($ts + $self->{offset}); # increment the offset for next time
            $self->{time} = sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ", $ts[5]+1900,$ts[4]+1,$ts[3], $ts[2],$ts[1],$ts[0];
        }
    }

    $self->_log("START time=[$self->{time}], last=[$self->{last}]\n");
    $self->{last} = $self->{time};

    eval {
#        if($self->{time_to}) {
#            $guids = $self->{librarian}->search(
#                'core.type'         => 'CPAN-Testers-Report',
#                'core.update_time'  => { -and => { ">=" => $self->{time}, "<=" => $self->{time_to} } },
#                '-asc'              => 'core.update_time',
#                '-limit'            => $self->{poll_limit},
#            );
#        } else {
            $guids = $self->{librarian}->search(
                '-where'  => [ 
                    '-and' => 
                        [ '-eq' => 'core.type'         => 'CPAN-Testers-Report' ],
                        [ '-ge' => 'core.update_time'  => $self->{time} ]
                ],
                '-order'  => [ '-asc' => 'core.update_time' ],
                '-limit'  => $self->{poll_limit},
            );
#        }
    };

    $self->_log(" ... Metabase Search Failed [$@]\n") if($@);
    $self->_log("Retrieved ".($guids ? scalar(@$guids) : 0)." guids\n");
    return $guids;
}

sub retrieve_reports {
    my ($self,$guids,$start) = @_;

    if($guids) {
        for my $guid (@$guids) {
            $self->_log("GUID [$guid]");
            $self->{processed}++;
            $self->{msg} = '';

            if(my $report = $self->get_fact($guid)) {
                $self->{report}{guid}   = $guid;
                next    if($self->parse_report(report => $report)); # true if invalid report

                if($self->store_report()) { 
                    $self->{msg} .= ".. stored";
                    $self->{stored}++; 

                } else {
                    if($self->{time} gt $self->{report}{updated}) {
                        $self->_log(".. FAIL: older than requested [$self->{time}]\n");
                        next;
                    }
                    $self->{msg} .= ".. already stored";
                }
                if($self->cache_report()) { $self->_log(".. cached\n"); $self->{cached}++; }
                else                      { $self->_log(".. bad cache data\n"); }
            } else {
                $self->_log(".. FAIL\n");
            }
        }
    }

    $self->commit();
    my $invalid = $self->{invalid} ? scalar(@{$self->{invalid}}) : 0;
    my $stop = localtime(time);
    $self->_log("MARKER: processed=$self->{processed}, stored=$self->{stored}, cached=$self->{cached}, invalid=$invalid, start=$start, stop=$stop\n");

    # only email invalid reports during the generate process
    $self->_send_email()    if($self->{invalid});
}

sub already_saved {
    my ($self,$guid) = @_;
    my @rows = $self->{METABASE}->get_query('array','SELECT updated FROM metabase WHERE guid=?',$guid);
    return $rows[0]->[0]	if(@rows);
    return 0;
}

sub load_fact {
    my ($self,$guid,$check,$row) = @_;

    if(!$row && $guid) {
        my @rows = $self->{METABASE}->get_query('hash','SELECT report,fact FROM metabase WHERE guid=?',$guid);
        $row = $rows[0]  if(@rows);
    }

    if($row) {
        if($row->{fact}) {
            $self->{fact} = $self->{serializer2}->deserialize($row->{fact});
            $self->{facts} = $self->dereference_report($self->{fact});
            return $self->{facts};
        }
        
        if($row->{report}) {
            $self->{facts} = $self->{serializer}->deserialize($row->{report});
            return $self->{facts};
        }
    }

    $self->_log(" ... no report [guid=$guid]\n")    unless($check);
    return;
}

sub get_fact {
    my ($self,$guid) = @_;
    my $fact;
    #print STDERR "guid=$guid\n";
    eval { $fact = $self->{librarian}->extract( $guid ) };

    if($fact) {
        $self->{fact} = $fact;
        return $fact;
    }

    $self->_log(" ... no report [guid=$guid] [$@]\n");
    return;
}

sub dereference_report {
    my ($self,$report) = @_;
    my %facts;

    my @facts = $report->facts();
    for my $fact (@facts) {
        my $name = ref $fact;
        $facts{$name} = $fact->as_struct;
        $facts{$name}{content} = decode_json($facts{$name}{content});
    }

    return \%facts;
}

sub parse_report {
    my ($self,%hash) = @_;
    my $options = $hash{options};
    my $report  = $hash{report};
    my $guid    = $self->{report}{guid};
    my $invalid;

    $self->{report}{created} = $report->{metadata}{core}{creation_time};
    $self->{report}{updated} = $report->{metadata}{core}{update_time};

    unless(ref($report) eq 'CPAN::Testers::Report') {
        $self->{msg} .= ".. ref [" . ref($report) . "]";
        return 1;
    }

    my @facts = $report->facts();
    for my $fact (@facts) {
        if(ref $fact eq 'CPAN::Testers::Fact::TestSummary') {
            $self->{report}{metabase}{'CPAN::Testers::Fact::TestSummary'} = $fact->as_struct;
            $self->{report}{metabase}{'CPAN::Testers::Fact::TestSummary'}{content} = decode_json($self->{report}{metabase}{'CPAN::Testers::Fact::TestSummary'}{content});

            $self->{report}{state}      = lc $fact->{content}{grade};
            $self->{report}{platform}   = $fact->{content}{archname};
            $self->{report}{osname}     = $self->_osname($fact->{content}{osname});
            $self->{report}{osvers}     = $fact->{content}{osversion};
            $self->{report}{perl}       = $fact->{content}{perl_version};
            #$self->{report}{created}    = $fact->{metadata}{core}{creation_time};
            #$self->{report}{updated}    = $fact->{metadata}{core}{update_time};

            my $dist                    = Metabase::Resource->new( $fact->resource );
            $self->{report}{dist}       = $dist->metadata->{dist_name};
            $self->{report}{version}    = $dist->metadata->{dist_version};
            $self->{report}{resource}   = $dist->metadata->{resource};

            # some distros are a pain!
	    	if($self->{report}{version} eq '' && $MAPPINGS{$self->{report}{dist}}) {
                $self->{report}{version}    = $MAPPINGS{$self->{report}{dist}}->[1];
                $self->{report}{dist}       = $MAPPINGS{$self->{report}{dist}}->[0];
            } elsif($self->{report}{version} eq '') {
                $self->{report}{version}    = 0;
            }

            $self->{report}{from}       = $self->_get_tester( $fact->creator->resource );

            # alternative API
            #my $profile                 = $fact->creator->user;                                                                                                                                                                          
            #$self->{report}{from}       = $profile->{email};
            #$self->{report}{from}       =~ s/'/''/g; #'
            #$self->{report}{dist}       = $fact->resource->dist_name;                                                                                                                                                                 
            #$self->{report}{version}    = $fact->resource->dist_version;          

        } elsif(ref $fact eq 'CPAN::Testers::Fact::LegacyReport') {
            $self->{report}{metabase}{'CPAN::Testers::Fact::LegacyReport'} = $fact->as_struct;
            $self->{report}{metabase}{'CPAN::Testers::Fact::LegacyReport'}{content} = decode_json($self->{report}{metabase}{'CPAN::Testers::Fact::LegacyReport'}{content});
            $invalid = 'missing textreport' if(length $fact->{content}{textreport} < 10);   # what is the smallest report?

            $self->{report}{perl}       = $fact->{content}{perl_version};
        }
    }

    if($invalid) {
        push @{$self->{invalid}}, {msg => $invalid, guid => $guid};
        return 1;
    }

    # fixes from metabase formatting
    $self->{report}{perl} =~ s/^v//;    # no leading 'v'
    $self->_check_arch_os();

    if($self->{report}{created}) {
        my @created = $self->{report}{created} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/; # 2010-02-23T20:33:52Z
        $self->{report}{postdate}   = sprintf "%04d%02d", $created[0], $created[1];
        $self->{report}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[0], $created[1], $created[2], $created[3], $created[4];
    } else {
        my @created = localtime(time);
        $self->{report}{postdate}   = sprintf "%04d%02d", $created[5]+1900, $created[4]+1;
        $self->{report}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[5]+1900, $created[4]+1, $created[3], $created[2], $created[1];
    }

    $self->{msg} .= ".. time [$self->{report}{created}][$self->{report}{updated}]";

    $self->{report}{type}       = 2;
    if($self->{DISABLE} && $self->{DISABLE}{$self->{report}{from}}) {
        $self->{report}{state} .= ':invalid';
        $self->{report}{type}   = 3;
    } elsif($self->{report}{response} && $self->{report}{response} =~ m!/perl6/!) {
#        $self->{report}{type}   = 6;
        return 1;
    }

    #print STDERR "\n====\nreport=".Dumper($self->{report});

    return 1  unless($self->_valid_field($guid, 'dist'     => $self->{report}{dist})     || ($options && $options->{exclude}{dist}));
    return 1  unless($self->_valid_field($guid, 'version'  => $self->{report}{version})  || ($options && $options->{exclude}{version}));
    return 1  unless($self->_valid_field($guid, 'from'     => $self->{report}{from})     || ($options && $options->{exclude}{from}));
    return 1  unless($self->_valid_field($guid, 'perl'     => $self->{report}{perl})     || ($options && $options->{exclude}{perl}));
    return 1  unless($self->_valid_field($guid, 'platform' => $self->{report}{platform}) || ($options && $options->{exclude}{platform}));
    return 1  unless($self->_valid_field($guid, 'osname'   => $self->{report}{osname})   || ($options && $options->{exclude}{osname}));
    return 1  unless($self->_valid_field($guid, 'osvers'   => $self->{report}{osvers})   || ($options && $options->{exclude}{osname}));

    return 0
}

sub reparse_report {
    my ($self,%hash) = @_;
    my $fact = 'CPAN::Testers::Fact::TestSummary';
    my $options = $hash{options};

    $self->{report}{metabase}{$fact}{content} = encode_json($self->{report}{metabase}{$fact}{content});
    my $report  = CPAN::Testers::Fact::TestSummary->from_struct( $self->{report}{metabase}{$fact} );
    my $guid    = $self->{report}{guid};

    $self->{report}{state}      = lc $report->{content}{grade};
    $self->{report}{platform}   = $report->{content}{archname};
    $self->{report}{osname}     = $self->_osname($report->{content}{osname});
    $self->{report}{osvers}     = $report->{content}{osversion};
    $self->{report}{perl}       = $report->{content}{perl_version};
    $self->{report}{created}    = $report->{metadata}{core}{creation_time};

    my $dist                    = Metabase::Resource->new( $report->{metadata}{core}{resource} );
    $self->{report}{dist}       = $dist->metadata->{dist_name};
    $self->{report}{version}    = $dist->metadata->{dist_version};
    $self->{report}{resource}   = $dist->metadata->{resource};

    $self->{report}{from}       = $self->_get_tester( $report->{metadata}{core}{creator}{resource} );

    if($self->{report}{created}) {
        my @created = $self->{report}{created} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/; # 2010-02-23T20:33:52Z
        $self->{report}{postdate}   = sprintf "%04d%02d", $created[0], $created[1];
        $self->{report}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[0], $created[1], $created[2], $created[3], $created[4];
    } else {
        my @created = localtime(time);
        $self->{report}{postdate}   = sprintf "%04d%02d", $created[5]+1900, $created[4]+1;
        $self->{report}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[5]+1900, $created[4]+1, $created[3], $created[2], $created[1];
    }

    $self->{report}{type}       = 2;
    if($self->{DISABLE} && $self->{DISABLE}{$self->{report}{from}}) {
        $self->{report}{state} .= ':invalid';
        $self->{report}{type}   = 3;
    } elsif($self->{report}{response} && $self->{report}{response} =~ m!/perl6/!) {
#        $self->{report}{type}   = 6;
        return 1;
    }

    return 1  unless($self->_valid_field($guid, 'dist'     => $self->{report}{dist})     || ($options && $options->{exclude}{dist}));
    return 1  unless($self->_valid_field($guid, 'version'  => $self->{report}{version})  || ($options && $options->{exclude}{version}));
    return 1  unless($self->_valid_field($guid, 'from'     => $self->{report}{from})     || ($options && $options->{exclude}{from}));
    return 1  unless($self->_valid_field($guid, 'perl'     => $self->{report}{perl})     || ($options && $options->{exclude}{perl}));
    return 1  unless($self->_valid_field($guid, 'platform' => $self->{report}{platform}) || ($options && $options->{exclude}{platform}));
    return 1  unless($self->_valid_field($guid, 'osname'   => $self->{report}{osname})   || ($options && $options->{exclude}{osname}));
    return 1  unless($self->_valid_field($guid, 'osvers'   => $self->{report}{osvers})   || ($options && $options->{exclude}{osname}));

    return 0;
}

sub retrieve_report {
    my $self = shift;
    my $guid = shift or return;

    my @rows = $self->{CPANSTATS}->get_query('hash','SELECT * FROM cpanstats WHERE guid=?',$guid);
    return $rows[0] if(@rows);
    return;
}

sub store_report {
    my $self    = shift;
    my @fields  = qw(guid state postdate from dist version platform perl osname osvers fulldate type uploadid);

    my %fields = map {$_ => $self->{report}{$_}} @fields;
    $fields{$_} ||= 0   for(qw(type uploadid));
    $fields{$_} ||= '0' for(qw(perl));
    $fields{$_} ||= ''  for(@fields);
    $fields{uploadid} ||= $self->{upload}{$fields{dist}}{$fields{version}};

    my @values = map {$fields{$_}} @fields;

    my %SQL = (
        'SELECT' => {
            CPANSTATS => 'SELECT id FROM cpanstats WHERE guid=?',
            RELEASE   => 'SELECT id FROM release_data WHERE guid=?',
        },
        'INSERT' => {
            CPANSTATS => 'INSERT INTO cpanstats (guid,state,postdate,tester,dist,version,platform,perl,osname,osvers,fulldate,type,uploadid) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
            RELEASE   => 'INSERT INTO release_data (id,guid,dist,version,oncpan,distmat,perlmat,patched,pass,fail,na,unknown,uploadid) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
            PASSES    => 'INSERT IGNORE passreports SET platform=?, osname=?, perl=?, dist=?, postdate=?',
        },
        'UPDATE' => {
            CPANSTATS => 'UPDATE cpanstats SET state=?,postdate=?,tester=?,dist=?,version=?,platform=?,perl=?,osname=?,osvers=?,fulldate=?,type=?,uploadid=? WHERE guid=?',
            RELEASE   => 'UPDATE release_data SET id=?,dist=?,version=?,oncpan=?,distmat=?,perlmat=?,patched=?,pass=?,fail=?,na=?,unknown=?,uploadid=? WHERE guid=?',
        },
    );

    # update the mysql database
    my @rows = $self->{CPANSTATS}->get_query('array',$SQL{SELECT}{CPANSTATS},$values[0]);
    if(@rows) {
        if($self->{reparse}) {
            my ($guid,@update) = @values;
            if($self->{check}) {
                $self->_log( "CHECK: $SQL{UPDATE}{CPANSTATS},[" . join(',',@update,$guid) . "]\n" );
            } else {
                $self->{CPANSTATS}->do_query($SQL{UPDATE}{CPANSTATS},@update,$guid);
            }
        } else {
            $self->{report}{id} = $rows[0]->[0];
            return 0;
        }
    } else {
        if($self->{check}) {
            $self->_log( "CHECK: $SQL{INSERT}{CPANSTATS},[" . join(',',@values) . "]\n" );
        } else {
            $self->{report}{id} = $self->{CPANSTATS}->id_query($SQL{INSERT}{CPANSTATS},@values);
        }
    }

    # in check mode, assume the rest happens
    return 1 if($self->{check});

    # perl version components
    my ($perl,$patch,$devel) = $self->_get_perl_version($fields{perl});

    # only valid perl5 reports
    if($self->{report}{type} == 2) {
        $fields{id} =  $self->{report}{id};

        # push page requests
        # - note we only update the author if this is the *latest* version of the distribution
        my $author = $self->{report}{pauseid} || $self->_get_author($fields{uploadid},$fields{dist},$fields{version});
        $self->{CPANSTATS}->do_query("INSERT INTO page_requests (type,name,weight,id) VALUES ('author',?,1,?)",$author,$fields{id})  if($author);
        $self->{CPANSTATS}->do_query("INSERT INTO page_requests (type,name,weight,id) VALUES ('distro',?,1,?)",$fields{dist},$fields{id});

        my @rows = $self->{CPANSTATS}->get_query('array',$SQL{SELECT}{RELEASE},$fields{guid});
        #print STDERR "# select release $SQL{SELECT}{RELEASE},$fields{guid}\n";
        if(@rows) {
            if($self->{reparse}) {
                $self->{CPANSTATS}->do_query($SQL{UPDATE}{RELEASE},
                    $fields{id},                        # id,
                    $fields{dist},$fields{version},     # dist, version

                    $self->_oncpan($fields{uploadid},$fields{dist},$fields{version}) ? 1 : 2,

                    $fields{version} =~ /_/     ? 2 : 1,
                    $devel                      ? 2 : 1,
                    $patch                      ? 2 : 1,

                    $fields{state} eq 'pass'    ? 1 : 0,
                    $fields{state} eq 'fail'    ? 1 : 0,
                    $fields{state} eq 'na'      ? 1 : 0,
                    $fields{state} eq 'unknown' ? 1 : 0,

                    $fields{uploadid},

                    $fields{guid});             # guid
            }
        } else {
        #print STDERR "# insert release $SQL{INSERT}{RELEASE},$fields[0],$fields[1]\n";
            $self->{CPANSTATS}->do_query($SQL{INSERT}{RELEASE},
                $fields{id},$fields{guid},          # id, guid
                $fields{dist},$fields{version},     # dist, version

                $self->_oncpan($fields{uploadid},$fields{dist},$fields{version}) ? 1 : 2,

                $fields{version} =~ /_/     ? 2 : 1,
                $devel                      ? 2 : 1,
                $patch                      ? 2 : 1,

                $fields{state} eq 'pass'    ? 1 : 0,
                $fields{state} eq 'fail'    ? 1 : 0,
                $fields{state} eq 'na'      ? 1 : 0,
                $fields{state} eq 'unknown' ? 1 : 0,

                $fields{uploadid});
        }
    }

    if($fields{state} eq 'pass') {
        $fields{perl} =~ s/\s.*//;  # only need to know the main release
        $self->{CPANSTATS}->do_query($SQL{INSERT}{PASSES},
            $fields{platform},
            $fields{osname},
            $fields{perl},
            $fields{dist},
            $fields{postdate});
    }

    if((++$self->{stat_count} % 500) == 0) {
        $self->commit;
    }

    return 1;
}

sub cache_report {
    my $self = shift;
    return 0 unless($self->{report}{guid} && $self->{report}{metabase});

    # in check mode, assume the rest happens
    return 1 if($self->{check});
    return 1 if($self->{localonly});

    my ($json,$data,$fact);

    eval { $json = encode_json($self->{report}{metabase}); };
    eval { $data = $self->{serializer}->serialize("$json"); };
    eval { $data = $self->{serializer}->serialize( $self->{report}{metabase} ); }   if($@);
    eval { $fact = $self->{serializer2}->serialize($self->{fact}); };

    $data ||= '';
    $fact ||= '';

    $self->{METABASE}->do_query('INSERT IGNORE INTO metabase (guid,id,updated,report,fact) VALUES (?,?,?,?,?)',
        $self->{report}{guid},$self->{report}{id},$self->{report}{updated},$data,$fact);

    if((++$self->{meta_count} % 500) == 0) {
        $self->{METABASE}->do_commit;
    }

    return 1;
}

sub cache_update {
    my $self = shift;
    return 0 unless($self->{report}{guid} && $self->{report}{id});

    # in check mode, assume the rest happens
    return 1 if($self->{check});
    return 1 if($self->{localonly});

    $self->{METABASE}->do_query('UPDATE metabase SET id=? WHERE guid=?',$self->{report}{id},$self->{report}{guid});

    if((++$self->{meta_count} % 500) == 0) {
        $self->{METABASE}->do_commit;
    }

    return 1;
}

#----------------------------------------------------------------------------
# Internal Cache Methods

sub load_uploads {
    my $self = shift;

    my @rows = $self->{CPANSTATS}->get_query('hash','SELECT uploadid,dist,version,type FROM uploads');
    for my $row (@rows) {
        $self->{oncpan}{$row->{uploadid}} = $row->{type};
        $self->{upload}{$row->{dist}}{$row->{version}} = $row->{uploadid};
    }
}

sub load_authors {
    my $self = shift;

    my @rows = $self->{CPANSTATS}->get_query('hash','SELECT author,dist,version,uploadid FROM ixlatest');
    for my $row (@rows) {
        $self->{author}{$row->{dist}}{$row->{version}} = $row->{author};
        $self->{author2}{$row->{uploadid}} = $row->{author};
    }
}

sub load_perl_versions {
    my $self = shift;

    my @rows = $self->{CPANSTATS}->get_query('hash','SELECT * FROM perl_version');
    for my $row (@rows) {
        $self->{perls}{$row->{version}} = {
                perl  => $row->{perl},
		patch => $row->{patch},
		devel => $row->{devel},
		saved => 1
        };
    }
}

sub save_perl_versions {
    my $self = shift;

    for my $vers (keys %{ $self->{perls} }) {
        next    if($self->{perls}{$vers}{saved});
        $self->{CPANSTATS}->do_query("INSERT INTO perl_version (version,perl,patch,devel) VALUES (?,?,?,?)",
		$vers, $self->{perls}{$vers}{perl}, $self->{perls}{$vers}{patch}, $self->{perls}{$vers}{devel});
    }
}

#----------------------------------------------------------------------------
# Private Methods

sub _consume_reports {
    my ($self,$maxdate,$dataset) = @_;

    for my $data (@$dataset) {
        my $start = $self->_get_createdate( $data->{gstart}, $data->{dstart} );
        my $end   = $self->_get_createdate( $data->{gend},   $data->{dend} );

        unless($start && $end) {
            $start ||= '';
            $end   ||= '';
            $self->_log("BAD DATES: start=$start, end=$end [missing dates]\n");
            next;
        }
        if($start ge $end) {
            $self->_log("BAD DATES: start=$start, end=$end [end before start]\n");
            next;
        }
#        if($end gt $maxdate) {
#            $self->_log("BAD DATES: start=$start, end=$end [exceeds $maxdate]\n");
#            next;
#        }

        $self->_log("LOOP: start=$start, end=$end\n");

        ($self->{processed},$self->{stored},$self->{cached}) = (0,0,0);

        # what guids do we already have?
        my $sql =   'SELECT guid FROM metabase WHERE updated >= ? AND updated <= ? ORDER BY updated asc';
        my @guids = $self->{METABASE}->get_query('hash',$sql,$data->{dstart},$data->{dend});
        my %guids = map {$_->{guid} => 1} @guids;

        # note that because Amazon's SimpleDB can return odd entries out of 
        # sync, we have to look at previous entries to ensure we are starting
        # from the right point
        my ($update,$prev,$last) = ($start,$start,$start);
        my @times = ();

        my $prior = [ 0, 0 ];
        my $saved = 0;
        while($update lt $end) {
            $self->_log("UPDATE: update=$update, end=$end, saved=$saved, guids=".(scalar(@guids))."\n");

            # get list of guids from last update date
            my $guids = $self->get_next_guids($update,$end);
            last    unless($guids);

            @guids = grep { !$guids{$_} } @$guids;
            last    unless(@guids);
            last    if($prior->[0] eq $guids[0] && $prior->[1] eq $guids[-1]);  # prevent an endless loop
            $prior = [ $guids[0], $guids[-1] ];

            $self->_log("UPDATE: todo guids=".(scalar(@guids))."\n");

            my $current = $update;
            for my $guid (@guids) {
                # don't process too far
                shift @times    if(@times > 9);                         # one off
                push @times, [ $current, (_date_diff($end,$current) <= 0 ? 0 : 1) ];    # one on ... max 10

                my $times = 0;
                $times += $_->[1]    for(@times);
                last    if($times == 10);                           # stop if all greater than end

                # okay process
                $self->_log("GUID [$guid]");

                $self->{processed}++;

                if(my $time = $self->already_saved($guid)) {
                    $self->_log(".. already saved [$time]\n");
                    $current = $time;
                    $saved++;
                    next;
                }

                if(my $report = $self->get_fact($guid)) {
                    $current = $report->{metadata}{core}{update_time};
                    $self->{report}{guid}   = $guid;
                    next    if($self->parse_report(report => $report)); # true if invalid report

                    if($self->store_report()) { $self->_log(".. stored"); $self->{stored}++;    }
                    else                      { $self->_log(".. already stored");       }
                    if($self->cache_report()) { $self->_log(".. cached\n"); $self->{cached}++;  }
                    else                      { $self->_log(".. bad cache data\n");     }
                } else {
                    $self->_log(".. FAIL\n");
                }
            }

            $update = $times[0]->[0];

            $self->commit();
        }

        $self->commit();
        my $invalid = $self->{invalid} ? scalar(@{$self->{invalid}}) : 0;
        my $stop = localtime(time);
        $self->_log("MARKER: processed=$self->{processed}, stored=$self->{stored}, cached=$self->{cached}, invalid=$invalid, start=$start, stop=$stop\n");
    }

    # only email invalid reports during the generate process
    $self->_send_email()    if($self->{invalid});
}

sub _get_perl_version {
    my $self = shift;
    my $vers = shift;

    unless($self->{perls}{$vers}) {
        my $patch  = $vers =~ /^5.(7|9|[1-9][13579])/   ? 1 : 0,    # odd numbers now mark development releases
        my $devel  = $vers =~ /(RC\d+|patch)/           ? 1 : 0,
        my ($perl) = $vers =~ /(5\.\d+(?:\.\d+)?)/;

        $self->{perls}{$vers} = {
                perl  => $perl,
		patch => $patch,
		devel => $devel,
		saved => 0
        };
    }

    return $self->{perls}{$vers}{perl}, $self->{perls}{$vers}{patch}, $self->{perls}{$vers}{devel};
}

sub _get_guid_list {
    my ($self,$guid,$file) = @_;
    my (@ids,@guids);

    # we're only parsing one id
    if($guid) {
        if($guid =~ /^\d+$/)    { push @ids,   $guid }
        else                    { push @guids, $guid }
    } elsif($file) {
        my $fh = IO::File->new($file,'r')       or die "Cannot read file [$file]: $!";
        while(<$fh>) {
            chomp;
            my ($num) = (m/^([\da-z-]+)/i);
            if($num =~ /^\d+$/) { push @ids,   $num }
            else                { push @guids, $num }
        }
        $fh->close;
    } else {
        return;
    }

    # turn ids into guids
    if(@ids) {
        my @rows = $self->{CPANSTATS}->get_query('array','SELECT guid FROM cpanstats WHERE id IN ('.join(',',@ids).')');
        push @guids, $_->[0] for(@rows);
    }

    my %guids = map {$_ => 1} @guids;
    my @list  = keys %guids;
    return @list;
}

sub _get_createdate {
    my ($self,$guid,$date) = @_;

    return  unless($guid || $date);
    if($guid) {
        my @rows = $self->{METABASE}->get_query('hash','SELECT updated FROM metabase WHERE guid=?',$guid);
        $date = $rows[0]->{updated}  if(@rows);
    }

    return          unless($date && $date =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
    return $date;        
}

sub _get_tester {
    my ($self,$creator) = @_;
    return $testers{$creator}   if($testers{$creator});

    my $profile  = Metabase::Resource->new( $creator );
    return $creator unless($profile);

    my $user;
    eval { $user = $self->{librarian}->extract( $profile->guid ) };
    return $creator unless($user);

    my ($name,@emails);
    for my $fact ($user->facts()) {
        if(ref $fact eq 'Metabase::User::EmailAddress') {
            push @emails, $fact->{content};
        } elsif(ref $fact eq 'Metabase::User::FullName') {
            $name = encode_entities($fact->{content});
        }
    }

    $name ||= 'NONAME'; # shouldn't happen, but allows for checks later

    for my $em (@emails) {
        $self->{METABASE}->do_query('INSERT INTO testers_email (resource,fullname,email) VALUES (?,?,?)',$creator,$name,$em);
    }

    $testers{$creator} = @emails ? $emails[0] : $creator;
    $testers{$creator} =~ s/\'/''/g if($testers{$creator});
    return $testers{$creator};
}

sub _get_author {
    my ($self,$upid,$dist,$vers) = @_;

    my $author = $self->{author2}{$upid} || '';
    $author ||= $self->{author}{$dist}{$vers} || '';

    return $author;
}

sub _valid_field {
    my ($self,$id,$name,$value) = @_;
    return 1    if(defined $value);
    $self->_log(" . [$id] ... missing field: $name\n");
    return 0;
}

sub _get_lastid {
    my $self = shift;

    my @rows = $self->{METABASE}->get_query('array',"SELECT MAX(id) FROM metabase");
    return 0    unless(@rows);
    return $rows[0]->[0] || 0;
}

sub _oncpan {
    my ($self,$upid,$dist,$vers) = @_;
    
    $upid ||= $self->{upload}{$dist}{$vers};
    my $type = $self->{oncpan}{$upid};

    return 1    unless($type);          # assume it's a new release
    return 0    if($type eq 'backpan'); # on backpan only
    return 1;                           # on cpan or new upload
}

sub _osname {
    my $self = shift;
    my $name = shift || return '';

    my $lname = lc $name;
    my $uname = uc $name;
    $self->{OSNAMES}{$lname} ||= do {
        $self->{CPANSTATS}->do_query(qq{INSERT INTO osname (osname,ostitle) VALUES ('$name','$uname')});
        $uname;
    };

    return $self->{OSNAMES}{$lname};
}

sub _check_arch_os {
    my $self = shift;

    my $text = $self->_platform_to_osname($self->{report}{platform});
#print STDERR "_check: text=$text\n";
#print STDERR "_check: platform=$self->{report}{platform}\n";
#print STDERR "_check: osname=$self->{report}{osname}\n";
    return	if($text && $self->{report}{osname} && lc $text eq lc $self->{report}{osname});

#print STDERR "_check: metabase=".Dumper($self->{report}{metabase})."\n";
    my $textreport = $self->{report}{metabase}{'CPAN::Testers::Fact::LegacyReport'}{content}{textreport};
    $textreport =~ s/\\n/\n/g; # newlines may be escaped

    # create a fake mail, as CTC::Article parses a mail like text block
    my $mail = <<EMAIL;
From: fake\@example.com
To: fake\@example.com
Subject: PASS Fake-0.01
Date: 01-01-2010 01:01:01 Z

$textreport
EMAIL
    my $object = CPAN::Testers::Common::Article->new( $mail ) or return;
    $object->parse_report();

    $self->{report}{osname}   = $object->osname;
    $self->{report}{platform} = $object->archname;
}

sub _platform_to_osname {
    my $self = shift;
    my $arch = shift || return '';

    $OSNAMES = join('|',keys %{$self->{OSNAMES}})   if(keys %{$self->{OSNAMES}});

    return $1	if($arch =~ /($OSNAMES)/i);

    for my $rx (keys %{ $self->{OSNAMES} }) {
        return $self->{OSNAMES}{$rx} if($arch =~ /$rx/i);
    }

    return '';
}

sub _send_email {
    my $self = shift;
    my $t = localtime;
    my $DATE = $t->strftime("%a, %d %b %Y %H:%M:%S +0000");
    $DATE =~ s/\s+$//;
    my $INVALID = join("\n",@{$self->{invalid}});
    $self->_log("INVALID:\n$INVALID\n");

    for my $admin (@{$self->{admins}}) {
        my $cmd = qq!| $HOW $admin!;

        my $body = $HEAD . $BODY;
        $body =~ s/FROM/$FROM/g;
        $body =~ s/EMAIL/$admin/g;
        $body =~ s/DATE/$DATE/g;
        $body =~ s/INVALID/$INVALID/g;

        if(my $fh = IO::File->new($cmd)) {
            print $fh $body;
            $fh->close;
            $self->_log(".. MAIL SEND - SUCCESS - $admin\n");
        } else {
            $self->_log(".. MAIL SEND - FAILED - $admin\n");
        }
    }
}

sub _date_diff {
    my ($date1,$date2) = @_;

    my (@dt1) = $date1 =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/;
    my (@dt2) = $date2 =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/;

    return -1 unless(@dt1 && @dt2);

    my $dt1 = DateTime->new( year => $dt1[0], month => $dt1[1], day => $dt1[2], hour => $dt1[3], minute => $dt1[4], second => $dt1[5], time_zone => 'UTC' )->epoch;
    my $dt2 = DateTime->new( year => $dt2[0], month => $dt2[1], day => $dt2[2], hour => $dt2[3], minute => $dt2[4], second => $dt2[5], time_zone => 'UTC' )->epoch;

    return $dt2 - $dt1;
}

sub _log {
    my $self = shift;
    my $log = $self->{logfile} or return;
    mkpath(dirname($log))   unless(-f $log);
    my $fh = IO::File->new($log,'a+') or die "Cannot append to log file [$log]: $!\n";
    print $fh $self->{msg}	if($self->{msg});
    print $fh @_;
    $fh->close;
    $self->{msg} = '';
}

1;

__END__

=head1 NAME

CPAN::Testers::Data::Generator - Download and summarize CPAN Testers data

=head1 SYNOPSIS

  % cpanstats
  # ... wait patiently, very patiently
  # ... then use the cpanstats MySQL database

=head1 DESCRIPTION

This distribution was originally written by Leon Brocard to download and
summarize CPAN Testers data. However, all of the original code has been
rewritten to use the CPAN Testers Statistics database generation code. This
now means that all the CPAN Testers sites including the Reports site, the
Statistics site and the CPAN Dependencies site, can use the same database.

This module retrieves and parses reports from the Metabase, generating or
updating entries in the cpanstats database, which extracts specific metadata
from the reports. The information in the cpanstats database is then presented
via CPAN::Testers::WWW::Reports on the CPAN Testers Reports website.

A good example query from the cpanstats database for Acme-Colour would be:

  SELECT version, status, count(*) FROM cpanstats WHERE
  dist = "Acme-Colour" group by version, state;

To create a database from scratch can take several days, as there are now over
24 million submitted reports. As such updating from a known copy of the
database is much more advisable. If you don't want to generate the database
yourself, you can obtain a feed using CPAN::Testers::WWW::Report::Query::Reports.

With over 24 million reports in the database, if you do plan to run this
software to generate the databases it is recommended you utilise a high-end
processor machine. Even with a reasonable processor it can take over a week!

=head1 DATABASE SCHEMA

The cpanstats database schema is very straightforward, one main table with
several index tables to speed up searches. The main table is as below:

  CREATE TABLE `cpanstats` (

    `id`          int(10) unsigned    NOT NULL AUTO_INCREMENT,
    `guid`        char(36)            NOT NULL DEFAULT '',
    `state`       varchar(32)         DEFAULT NULL,
    `postdate`    varchar(8)          DEFAULT NULL,
    `tester`      varchar(255)        DEFAULT NULL,
    `dist`        varchar(255)        DEFAULT NULL,
    `version`     varchar(255)        DEFAULT NULL,
    `platform`    varchar(255)        DEFAULT NULL,
    `perl`        varchar(255)        DEFAULT NULL,
    `osname`      varchar(255)        DEFAULT NULL,
    `osvers`      varchar(255)        DEFAULT NULL,
    `fulldate`    varchar(32)         DEFAULT NULL,
    `type`        int(2)              DEFAULT '0',
      
    PRIMARY KEY       (`id`),
    KEY `guid`        (`guid`),
    KEY `distvers`    (`dist`,`version`),
    KEY `tester`      (`tester`),
    KEY `state`       (`state`),
    KEY `postdate`    (`postdate`)
  
  )

It should be noted that 'postdate' refers to the YYYYMM formatted date, whereas
the 'fulldate' field refers to the YYYYMMDDhhmm formatted date and time.

The metabase database schema is again very straightforward, and consists of one
main table, as below:

  CREATE TABLE `metabase` (
  
    `guid`      char(36)            NOT NULL,
    `id`        int(10) unsigned    NOT NULL,
    `updated`   varchar(32)         DEFAULT NULL,
    `report`    longblob            NOT NULL,
    `fact`      longblob            NOT NULL,
  
    PRIMARY KEY     (`guid`),
    KEY `id`        (`id`),
    KEY `updated`   (`updated`)
  
  )

The id field is a reference to the cpanstats.id field.

The report field is JSON encoded, and is a cached version of the facts of a 
report, while the fact field is the full report fact, and associated child 
facts, Sereal encoded. Both are extracted from the returned fact from
Metabase::Librarian.

See F<examples/cpanstats-createdb> for the full list of tables used.

=head1 SIGNIFICANT CHANGES

=head2 v0.31 CHANGES

With the release of v0.31, a number of changes to the codebase were made as
a further move towards CPAN Testers 2.0. The first change is the name for this
distribution. Now titled 'CPAN-Testers-Data-Generator', this now fits more
appropriately within the CPAN-Testers namespace on CPAN.

The second significant change is to now reference a MySQL cpanstats database.
The SQLite version is still updated as before, as a number of other websites
and toolsets still rely on that database file format. However, in order to make
the CPAN Testers Reports website more dynamic, an SQLite database is not really
appropriate for a high demand website.

The database creation code is now available as a standalone program, in the
examples directory, and all the database communication is now handled by the
new distribution CPAN-Testers-Common-DBUtils.

=head2 v0.41 CHANGES

In the next stage of development of CPAN Testers 2.0, the id field used within
the database schema above for the cpanstats table no longer matches the NNTP
ID value, although the id in the articles does still reference the NNTP ID, at
least for the reports submitted prior to the switch to the Metabase in 2010.

In order to correctly reference the id in the articles table, you will need to
use the function guid_to_nntp() with CPAN::Testers::Common::Utils, using the
new guid field in the cpanstats table.

As of this release the cpanstats id field is a unique auto incrementing field.

The next release of this distribution will be focused on generation of stats
using the Metabase storage API.

=head2 v1.00 CHANGES

Moved to Metabase API. The change to a definite major version number hopefully
indicates that this is a major interface change. All previous NNTP access has
been dropped and is no longer relavent. All report updates are now fed from
the Metabase API.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::Testers::Data::Generator. Accepts a hash containing
values to prepare the object. These are described as:

  my $obj = CPAN::Testers::Data::Generator->new(
                logfile => './here/logfile',
                config  => './here/config.ini'
  );

Where 'logfile' is the location to write log messages. Log messages are only
written if a logfile entry is specified, and will always append to any existing
file. The 'config' should contain the path to the configuration file, used
to define the database access and general operation settings.

=back

=head2 Public Methods

=over

=item * generate

Starting from the last cached report, retrieves all the more recent reports
from the Metabase Report Submission server, parsing each and recording each
report in both the cpanstats database and the metabase cache database.

=item * regenerate

For a given date range, retrieves all the reports from the Metabase Report 
Submission server, parsing each and recording each report in both the cpanstats
database and the metabase cache database.

Note that as only 2500 can be returned at any one time due to Amazon SimpleDB
restrictions, this method will only process the guids returned from a given
start data, up to a maxiumu of 2500 guids.

This method will return the guid of the last report processed.

=item * rebuild

In the event that the cpanstats database needs regenerating, either in part or
for the whole database, this method allow you to do so. You may supply
parameters as to the 'start' and 'end' values (inclusive), where all records
are assumed by default. Records are rebuilt using the local metabase cache
database.

=item * reparse

Rather than a complete rebuild the option to selective reparse selected entries
is useful if there are reports which were previously unable to correctly supply
a particular field, which now has supporting parsing code within the codebase.

In addition there is the option to exclude fields from parsing checks, where
they may be corrupted, and can be later amended using the 'cpanstats-update'
tool.

=item * parse

Unlike reparse, parse is used to parse just missing reports. As such if a
report has already been stored and cached, it won't be processed again, unless
the 'force' option is used.

In addition, as per reparse, there is the option to exclude fields from parsing
checks, where they may be corrupted, and can be later amended using the 
'cpanstats-update' tool.

=item * tail

Write to a file, the list of GUIDs returned from a tail request.

=back

=head2 Private Methods

=over

=item * commit

To speed up the transaction process, a commit is performed every 500 inserts.
This method is used as part of the clean up process to ensure all transactions
are completed.

=item * get_tail_guids

Get the list of GUIDs as would be seen for a tail log.

=item * get_next_dates

Get the list of dates to use in the next cycle of report retrieval.

=item * get_next_guids

Get the list of GUIDs for the reports that have been submitted since the last
cached report.

=item * retrieve_reports

Abstracted loop of requesting GUIDs, then parsing, storing and caching each 
report as appropriate.

=item * already_saved

Given a guid, determines whether it has already been saved in the local
metabase cache.

=item * load_fact

Get a specific report fact for a given GUID, from the local database.

=item * get_fact

Get a specific report fact for a given GUID, from the Metabase.

=item * dereference_report

When you retrieve the parent report fact from the database, you'll need to 
dereference it to ensure the child elements contain the child facts in the
correct format for processing.

=item * parse_report

Parses a report extracting the metadata required for the cpanstats database.

=item * reparse_report

Parses a report (from a local metabase cache) extracting the metadata required
for the stats database.

=item * retrieve_report

Given a guid will attempt to return the report metadata from the cpanstats 
database.

=item * store_report

Inserts the components of a parsed report into the cpanstats database.

=item * cache_report

Inserts a serialised report into a local metabase cache database.

=item * cache_update

For the current report will update the local metabase cache with the id used
within the cpanstats database.

=back

=head2 Very Private methods

The following modules load information enmasse to avoid DB connection hogging 
and IO blocking. Thus improving performance.

=over 4

=item * load_uploads

Loads the upload information.

=item * load_authors

Loads information regarding each author's distribution.

=item * load_perl_versions

Loads all the known Perl versions.

=item * save_perl_versions

Saves any new Perl versions

=back

=head1 HISTORY

The CPAN Testers was conceived back in May 1998 by Graham Barr and Chris
Nandor as a way to provide multi-platform testing for modules. Today there
are over 40 million tester reports and more than 100 testers each month
giving valuable feedback for users and authors alike.

=head1 BECOME A TESTER

Whether you have a common platform or a very unusual one, you can help by
testing modules you install and submitting reports. There are plenty of
module authors who could use test reports and helpful feedback on their
modules and distributions.

If you'd like to get involved, please take a look at the CPAN Testers Wiki,
where you can learn how to install and configure one of the recommended
smoke tools.

For further help and advice, please subscribe to the the CPAN Testers
discussion mailing list.

  CPAN Testers Wiki
    - http://wiki.cpantesters.org
  CPAN Testers Discuss mailing list
    - http://lists.cpan.org/showlist.cgi?name=cpan-testers-discuss

=head1 BUCKETS

  beta6 - 2014-01-21
  beta7 - 2014-11-12

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Data-Generator

=head1 SEE ALSO

L<CPAN::Testers::Report>,
L<Metabase>,
L<Metabase::Fact>,
L<CPAN::Testers::Fact::LegacyReport>,
L<CPAN::Testers::Fact::TestSummary>,
L<CPAN::Testers::Metabase::AWS>

L<CPAN::Testers::WWW::Statistics>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

It should be noted that the original code for this distribution began life
under another name. The original distribution generated data for the original
CPAN Testers website. However, in 2008 the code was reworked to generate data
in the format for the statistics data analysis, which in turn was reworked to
drive the redesign of the all the CPAN Testers websites. To reflect the code
changes, a new name was given to the distribution.

=head2 CPAN-WWW-Testers-Generator

  Original author:    Leon Brocard <acme@astray.com>   (C) 2002-2008
  Current maintainer: Barbie       <barbie@cpan.org>   (C) 2008-2010

=head2 CPAN-Testers-Data-Generator

  Original author:    Barbie       <barbie@cpan.org>   (C) 2008-2015

=head1 LICENSE

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.
