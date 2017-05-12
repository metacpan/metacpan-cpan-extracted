#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '3.57';

#----------------------------------------------------------------------------

=head1 NAME

view-report.cgi - program to display a individual CPAN Testers report.

=head1 SYNOPSIS

  perl view-report.cgi

=head1 DESCRIPTION

Called in a CGI context, returns the specified CPAN Testers report.

=cut

# -------------------------------------
# Library Modules

use lib qw(lib plugins);

use Labyrinth;
use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Globals  qw(:all);
use Labyrinth::MLUtils;
use Labyrinth::Variables;
use Labyrinth::Writer;

use Labyrinth::Plugin::CPAN;

#use CGI::Carp			qw(fatalsToBrowser);

use CGI;
use Config::IniFiles;
use Data::Dumper;
use Data::FlexSerializer;
use IO::File;
use JSON;
use MIME::QuotedPrint;
use Template;
use Text::Demoroniser qw(demoroniser);

use CPAN::Testers::Common::Article;
use CPAN::Testers::Common::Utils qw(nntp_to_guid guid_to_nntp);
use CPAN::Testers::Fact::LegacyReport;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Report;

use Metabase    0.004;
use Metabase::Fact;
use Metabase::Resource;
use Metabase::Resource::cpan::distfile;
use Metabase::Resource::metabase::user;

# -------------------------------------
# Variables

my $AUDIT = 0;
my $LONG_ALLOWED = 0;

my $VHOST = '/var/www/reports/';
my (%options,$serializer,$logfile);

my $EXCEPTIONS;
my %SYMLINKS;
my %MERGED;

# -------------------------------------
# Program

init_options();
process_report();

# -------------------------------------
# Subroutines

sub init_options {
    audit("AUDIT[$$]: start init_options");

    $options{config} = $VHOST . 'cgi-bin/config/settings.ini';

    error("Must specific the configuration file\n")             unless($options{config});
    error("Configuration file [$options{config}] not found\n")  unless(-f $options{config});

    $serializer = Data::FlexSerializer->new(
        detect_compression  => 1,
        detect_sereal       => 1,
        detect_json         => 1,
    );

    # load configuration
    Labyrinth::Variables::init();   # initial standard variable values
    LoadSettings($options{config});            # Load All Global Settings

    $logfile = $settings{'logfile'} . '.reports';

    SetLogFile( FILE   => $logfile,
                USER   => 'labyrinth',
                LEVEL  => ($settings{'loglevel'} || 0),
                CLEAR  => 1,
                CALLER => 1);

    ParseParams();
    DBConnect();

    ## defaults in the event of errors
    my $LAYOUT = 'public/layout.html';
    $tvars{layout} = $LAYOUT;
    $tvars{content} = '';

    LogDebug("DEBUG: configuration done");

#    for my $key (keys %rules) {
#        my $val = $cgi->param("${key}_pref");
#        $cgiparams{$key} = $1   if($val =~ $rules{$key});
#    }

    LogDebug('DEBUG: cgiparams=',Dumper(\%cgiparams));
    audit("AUDIT[$$]: stop init_options");
}

sub process_report {
    audit("AUDIT[$$]: start retrieve_report - $cgiparams{id}");
    retrieve_report();
    audit("AUDIT[$$]: stop retrieve_report");
    audit("AUDIT[$$]: start print_report");
    print_report();
    audit("AUDIT[$$]: stop print_report");
}

sub retrieve_report {
    $tvars{body}{result} = '""';

    if($cgiparams{id} =~ /^\d+$/) {
        my @rows = $dbi->GetQuery('hash','GetStatReport',$cgiparams{id});

        if(@rows) {
            if($rows[0]->{guid} =~ /^[0-9]+\-[-\w]+$/) {
                my $id = guid_to_nntp($rows[0]->{guid});
                _parse_nntp_report($id);
            } else {
                $cgiparams{id} = $rows[0]->{guid};
                _parse_guid_report();
            }
        } else {
            #$tvars{errcode} = 'NEXT';
            #$tvars{command} = 'cpan-distunk';
        }
   } elsif($cgiparams{id} =~ /^[\w-]+$/) {
        my $id = guid_to_nntp($cgiparams{id});
        if($id) {
            _parse_nntp_report($id);
        } else {
            _parse_guid_report();
        }
    } else {
        $cgiparams{id} =~ s/[\w-]+//g;
    }

    unless($tvars{article}{article}) {
        if($cgiparams{id} =~ /^\d+$/) {
            $tvars{article}{id} = $cgiparams{id};
        } else {
            $tvars{article}{guid} = $cgiparams{id};
        }
    }

    if($cgiparams{json}) {
        $tvars{body}{success} = $tvars{body}{result} && $tvars{body}{result} ne '""' ? 1 : 0;
        $tvars{layout}  = 'public/layout.json';
    } elsif($cgiparams{raw}) {
        $tvars{article}{raw} = $cgiparams{raw};
        $tvars{layout} = 'public/popup.html'
    } else {
        $tvars{layout} = 'public/layout-wide.html'
    }
}

sub print_report {
    $tvars{content}     = 'cpan/report-view.html';
    $tvars{siteversion} = $VERSION;
    $tvars{labversion}  = $Labyrinth::VERSION;
    Publish();
}

#----------------------------------------------------------------------------
# Private Interface Functions

sub _parse_nntp_report {
    my $nntpid = shift;
    my @rows;

    unless($nntpid) {
       @rows = $dbi->GetQuery('hash','GetStatReport',$cgiparams{id});
       return  unless(@rows);
       $nntpid = guid_to_nntp($rows[0]->{guid});
    }

    @rows = $dbi->GetQuery('hash','GetArticle',$nntpid);
       return  unless(@rows);

    if($rows[0]->{article} =~ /Content-Transfer-Encoding: quoted-printable/is) {
        my ($head,$body) = split(/\n\n/,$rows[0]->{article},2);
        $body = decode_qp($body);
        $rows[0]->{article} = $head . "\n\n" . $body;
    }

    $rows[0]->{article} = demoroniser($rows[0]->{article});
    $rows[0]->{article} = SafeHTML($rows[0]->{article});
    $tvars{article} = $rows[0];
    ($tvars{article}{head},$tvars{article}{body}) = split(/\n\n/,$rows[0]->{article},2);

    my $object = CPAN::Testers::Common::Article->new($rows[0]->{article});
    return  unless($object);

    $tvars{article}{nntp}    = 1;
    $tvars{article}{id}      = $cgiparams{id};
    $tvars{article}{body}    = $object->body;
    $tvars{article}{subject} = $object->subject;
    $tvars{article}{from}    = $object->from;
    $tvars{article}{from}    =~ s/\@.*//;
    $tvars{article}{post}    = $object->postdate;

    my @date = $object->date =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})/;
    $tvars{article}{date}    = sprintf "%04d-%02d-%02dT%02d:%02d:00Z", @date;

    return      if($tvars{article}{subject} =~ /Re:/i);
    return      unless($tvars{article}{subject} =~ /(CPAN|FAIL|PASS|NA|UNKNOWN)\s+/i);

    my $state = lc $1;

    if($state eq 'cpan') {
        if($object->parse_upload()) {
            $tvars{article}{dist}    = $object->distribution;
            $tvars{article}{version} = $object->version;
            $tvars{article}{author}  = $object->author;
            $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
        }
    } else {
        if($object->parse_report()) {
            $tvars{article}{dist}    = $object->distribution;
            $tvars{article}{version} = $object->version;
            $tvars{article}{author}  = $object->from;
            $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);
        }
    }
}

sub _parse_guid_report {
    my $cpan = Labyrinth::Plugin::CPAN->new();
    $cpan->Configure();

    my @rows = $dbi->GetQuery('hash','GetMetabaseByGUID',$cgiparams{id});
    return unless(@rows);

    my $row = $rows[0];

    my ($report,$data);
    if($row->{fact}) {
        eval { $report = $serializer->deserialize($row->{fact}); };
        return if($@);

        $data = dereference_report($report);
    } else {
        $data = $serializer->deserialize($row->{report});
        $report = { metadata => { core => { guid => $row->{guid}, type => 'CPAN-Testers-Report' } } };
        for my $name (keys %$data) {
            push @{$report->{content}}, $data->{$name};
        }
    }

    my $fact;
    eval { 
        $data->{'CPAN::Testers::Fact::LegacyReport'}{content} = encode_json($data->{'CPAN::Testers::Fact::LegacyReport'}{content})
            if(ref $data->{'CPAN::Testers::Fact::LegacyReport'}{content} eq 'HASH');
        $fact = CPAN::Testers::Fact::LegacyReport->from_struct( $data->{'CPAN::Testers::Fact::LegacyReport'} ) 
    };
    if($@ && !$fact) {
        error('LegacyReport',$@);
        return;
    }

    $tvars{article}{article}    = SafeHTML($fact->{content}{textreport});
    $tvars{article}{guid}       = $row->{guid};

    eval { 
        $data->{'CPAN::Testers::Fact::TestSummary'}{content} = encode_json($data->{'CPAN::Testers::Fact::TestSummary'}{content})
            if(ref $data->{'CPAN::Testers::Fact::TestSummary'}{content} eq 'HASH');
        $fact = CPAN::Testers::Fact::TestSummary->from_struct( $data->{'CPAN::Testers::Fact::TestSummary'} ) 
    };
    if($@ && !$fact) {
        error('TestSummary',$@);
        return;
    }

    if($row->{fact}) {
        $report->{metadata}{core}{$_} = $fact->{metadata}{core}{$_}
            for(qw(resource schema_version creation_time valid creator update_time));
    } else {
        $report->{metadata}{core}{$_} = $data->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}{$_}
            for(qw(resource schema_version creation_time valid creator update_time));
    }

    my ($osname);
    eval { ($osname) = $cpan->OSName($fact->{content}{osname}); };
    return  if($@);

    $tvars{article}{state}      = lc $fact->{content}{grade};
    $tvars{article}{platform}   = $fact->{content}{archname};
    $tvars{article}{osname}     = $osname;
    $tvars{article}{osvers}     = $fact->{content}{osversion};
    $tvars{article}{perl}       = $fact->{content}{perl_version};
    $tvars{article}{created}    = $fact->{metadata}{core}{creation_time};

    my $dist                    = Metabase::Resource->new( $fact->{metadata}{core}{resource} );
    $tvars{article}{dist}       = $dist->metadata->{dist_name};
    $tvars{article}{version}    = $dist->metadata->{dist_version};

    ($tvars{article}{author},$tvars{article}{from}) = get_tester( $fact->creator );
    $tvars{article}{author} =~ s/\@/ [at] /g;
    $tvars{article}{from}   =~ s/\@/ [at] /g;
    $tvars{article}{from}   =~ s/\./ [dot] /g;

    if($tvars{article}{created}) {
        my @created = $tvars{article}{created} =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/; # 2010-02-23T20:33:52Z
        $tvars{article}{postdate}   = sprintf "%04d%02d", $created[0], $created[1];
        $tvars{article}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[0], $created[1], $created[2], $created[3], $created[4];
    } else {
        my @created = localtime(time);
        $tvars{article}{postdate}   = sprintf "%04d%02d", $created[5]+1900, $created[4]+1;
        $tvars{article}{fulldate}   = sprintf "%04d%02d%02d%02d%02d", $created[5]+1900, $created[4]+1, $created[3], $created[2], $created[1];
    }

    $tvars{article}{letter}  = substr($tvars{article}{dist},0,1);

    $tvars{article}{subject} = sprintf "%s %s-%s %s %s", 
        uc $tvars{article}{state}, $tvars{article}{dist}, $tvars{article}{version}, $tvars{article}{perl}, $tvars{article}{osname};

    $tvars{body}{result} = decode_report($report);
    LogDebug('DEBUG: report=' . Dumper($report));
    LogDebug('DEBUG: result=' . Dumper($tvars{body}{result}));
}

sub decode_report {
    my $report = shift;
    my $hash;

    # do we have an encoded report object?
    if(ref $report eq 'CPAN::Testers::Report') {
        $hash = $report->as_struct;
        $hash->{content} = decode_json($hash->{content});
        for my $content (@{ $hash->{content} }) {
            $content->{content} = decode_json($content->{content});
        }
        
        return encode_json($hash);
    }

    # we have a manufactured hash, with a collection of fact objects

    eval {
        for my $fact (@{ $report->{content} }) {
            $fact->{content} = decode_json($fact->{content});
        }
    };

    return  if($@);

    return encode_json($report);

#    my $hash = { 'CPAN::Testers::Report' => { metadata => $report->{metadata}, content => {} } };

    my @facts = $report->facts();
    for my $fact (@facts) {
        my $name = ref $fact;
        $hash->{'CPAN::Testers::Report'}->{content}{$name} = $fact->as_struct();
    }
    return $hash;
}

sub dereference_report {
    my ($report) = @_;
    my %facts;

    eval {
        my @facts = $report->facts();
        for my $fact (@facts) {
            my $name = ref $fact;
            $facts{$name} = $fact->as_struct;
            $facts{$name}{content} = decode_json($facts{$name}{content});
        }
    };

    return  if($@);

    return \%facts;
}

sub get_tester {
    my $creator = shift;

    #$dbi->{'mysql_enable_utf8'} = 1;
    my @rows = $dbi->GetQuery('hash','GetTesterFact',$creator);
    return ($creator,$creator)  unless(@rows);

    #$rows[0]->{fullname} = encode_entities($rows[0]->{fullname});
    my $name = $rows[0]->{fullname};
    $name = join(' ',$rows[0]->{name},$rows[0]->{pause})    if($rows[0]->{name});

    my $email = $rows[0]->{contact} || $rows[0]->{email} || $creator;
    $email =~ s/\'/''/g if($email);
    return ($name,$email);
}

sub error {
    LogError('ERROR:',@_);
    print STDERR @_;
    print $cgi->header('text/plain'), "Error retrieving data\n";
    exit;
}

sub audit {
    return  unless($AUDIT);

    my @date = localtime(time);
    my $date = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $date[5]+1900, $date[4]+1, $date[3], $date[2], $date[1], $date[0];

    my $fh = IO::File->new($VHOST . 'cgi-bin/cache/view-report-audit.log','a+') or return;
    print $fh "$date " . join(' ',@_ ). "\n";
    $fh->close;
}

1;

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers=WWW-Reports

=head1 SEE ALSO

L<CPAN::Testers::WWW::Statistics>,
L<CPAN::Testers::WWW::Wiki>,
L<CPAN::Testers::WWW::Blog>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie       <barbie@cpan.org>   2008-present

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2015 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
