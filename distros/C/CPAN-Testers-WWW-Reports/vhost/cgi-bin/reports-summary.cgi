#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '3.59';

#----------------------------------------------------------------------------

=head1 NAME

reports-summary.cgi - program to return graphical status of a CPAN distribution

=head1 SYNOPSIS

  perl reports-summary.cgi

=head1 DESCRIPTION

Called in a CGI context, returns the current reporting statistics for a CPAN
distribution, depending upon the POST parameters provided.

Primary Query String parameters are

=over 4

item * dist

The distribution to provide a summary for. An error will be returned if no
distribution name is provided.

item * author

Filter based on a specific author who released the distribution. Defaults to authors.

=back

At least one of these parameters needs to be supplied, otherwise an error will
be returned.

Secondary optional Query String parameters available are

item * version

Filter based on a specific distribution version. Defaults to the latest 
version.

item * grade

Filter based on report grade, i.e. 'pass','fail','na' or 'unknown'.

item * oncpan

Filter based on whether the distribution is available on CPAN or only BACKPAN.
Values are:

=over 4

=item * 0 = CPAN and BACKPAN
=item * 1 = CPAN only
=item * 2 = BACKPAN only

=back

item * distmat

Filter based on whether the distribution is a developer release or a 
stable release.

=over 4

=item * 0 = all releases
=item * 1 = stable releases only
=item * 2 = development releases only

=back

item * perlmat

Filter based on perl maturity, i.e. whether a development version (5.21.3) or
a stable version (5.20.1). Values are:

=over 4

=item * 0 = all reports
=item * 1 = stable versions only
=item * 2 = development versions only

=back

item * patches

Filter based on whether the perl version is a patch. Values are:

=over 4

=item * 0 = all reports
=item * 1 = patches only
=item * 2 = exclude patches

=back

Defaults to all reports.

item * perlver

Filter based on Perl version, e.g. 5.20.1. Defaults to all versions.

item * osname (optional)

Filter based on Operating System name, e.g. MSWin32. Defaults to all Operating 
Systems.

item * format

Available formats are: 'csv', 'txt', 'html' and 'xml'. Defaults to 'html'.
'txt' is provided for backwards compatibility, but is mapped to 'csv'.

=back

=cut

# -------------------------------------
# Library Modules

use CGI;
use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use Data::Dumper;
use Getopt::Long;
use IO::File;
use OpenThought();
use Template;

# -------------------------------------
# Variables

my $DEBUG = $ENV{DEBUG} || 0;
my $LONG_ALLOWED = 0;

my $VHOST = '/var/www/reports/';
my (%options,%cgiparams,%output,$OT,$cgi,$tt);

my %rules = (
    dist    => qr/^([-\w.]+)$/i,
    author  => qr/^([a-z0-9]+)$/i,
    version => qr/^([-\w.]+)$/i,
    grade   => qr/^([0-4])$/i,
    oncpan  => qr/^([0-2])$/i,
    distmat => qr/^([0-2])$/i,
    perlmat => qr/^([0-2])$/i,
    patches => qr/^([0-2])$/i,
    perlver => qr/^([\w.]+)$/i,
    osname  => qr/^([\w.]+)$/i
);

my $EXCEPTIONS;
my %SYMLINKS;
my %MERGED;

# -------------------------------------
# Program

init_options();
process_dist()      if($cgiparams{dist});
process_author()    if($cgiparams{author});
writer();

local $SIG{__DIE__} = sub {
    audit( "Dying: $_[0]" );
    die @_;
};

# -------------------------------------
# Subroutines

sub init_options {
    GetOptions( 
        \%options,
        'config=s',
        'dist=s',
        'author=s',
        'version=s',
        'grade=s',
        'oncpan=s',
        'distmat=s',
        'perlmat=s',
        'patches=s',
        'perlver=s',
        'osname=s',
        'format=s'
    );

    $options{config} ||= $VHOST . 'cgi-bin/config/settings.ini';

    error("Must specific the configuration file\n")             unless($options{config});
    error("Configuration file [$options{config}] not found\n")  unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure upload DB
    for my $db (qw(CPANSTATS)) {
        my %opts = map {$_ => scalar $cfg->val($db,lc $db . '_' . $_);} qw(driver database dbfile dbhost dbport dbuser dbpass);
        $opts{ errsub } = sub { audit( "DB ERROR: " . Dumper( \@_ ) ) };
        $options{$db} = CPAN::Testers::Common::DBUtils->new(%opts);
        error("Cannot configure '$options{database}' database\n")   unless($options{$db});
    }

    $cgi = CGI->new;

    $options{format} ||= $cgi->param('format') || 'html';
    $options{format} = 'html' unless($options{format} =~ /html|txt|xml|csv|json/);
    $options{format} = 'csv'  if($options{format} =~ /txt/);

    audit("DEBUG: configuration done");

    for my $key (keys %rules) {
        my $val = $options{$key} || $cgi->param("${key}_pref") || $cgi->param($key);
        $cgiparams{$key} = $1   if($val =~ $rules{$key});
    }

    audit('DEBUG: cgiparams=',Dumper(\%cgiparams));

    # set up API to Template Toolkit
    $tt = Template->new(
        {
            #    POST_CHOMP => 1,
            #    PRE_CHOMP => 1,
            #    TRIM => 1,
            EVAL_PERL    => 1,
            INCLUDE_PATH => [ 'templates' ],
        }
    );

    my $config = $VHOST . 'cgi-bin/config/cpan-config.ini';
    error("Must specific the configuration file\n")             unless($config);
    error("Configuration file [$config] not found\n")           unless(-f $config);

    $cfg = Config::IniFiles->new( -file => $config );

    if($cfg->SectionExists('EXCEPTIONS')) {
        my @values = $cfg->val('EXCEPTIONS','LIST');
        $EXCEPTIONS = join('|',@values);
    }

    if($cfg->SectionExists('SYMLINKS')) {
        $SYMLINKS{$_} = $cfg->val('SYMLINKS',$_)  for($cfg->Parameters('SYMLINKS'));
        push @{$MERGED{$SYMLINKS{$_}}}, $_              for(keys %SYMLINKS);
        push @{$MERGED{$SYMLINKS{$_}}}, $SYMLINKS{$_}   for(keys %SYMLINKS);
    }

    #audit('DEBUG: SYMLINKS=',Dumper(\%SYMLINKS));
    #audit('DEBUG: MERGED=',Dumper(\%MERGED));

    #$cgiparams{dist} = 'App-Maisha';
    #$cgiparams{author} = 'BARBIE';
}

sub process_dist {
    $cgiparams{dist} = $SYMLINKS{$cgiparams{dist}}  if(defined $SYMLINKS{$cgiparams{dist}});

    if( $LONG_ALLOWED && 
        ( ($cgiparams{osname}  && $cgiparams{osname}  =~ /ALL/i) ||
          ($cgiparams{perlver} && $cgiparams{perlver} =~ /ALL/i) ) ) {
        process_dist_long();
    } else {
        process_dist_short();
    }
}

sub process_dist_short {
    audit("DEBUG: start process dist (short): $cgiparams{dist}");

    %output = (
        template  => 'dist_summary',
    );

    my @where;
    push @where, "patched=$cgiparams{patches}"      if($cgiparams{patches});
    push @where, "distmat=$cgiparams{distmat}"      if($cgiparams{distmat});
    push @where, "perlmat=$cgiparams{perlmat}"      if($cgiparams{perlmat});
    push @where, "oncpan=$cgiparams{oncpan}"        if($cgiparams{oncpan});
    push @where, "version='$cgiparams{version}'"    if($cgiparams{version});
    my $where = @where ? ' AND ' . join(' AND ',@where) : '';

    my $dist = "'$cgiparams{dist}'";
    $dist = "'" . join("','",@{$MERGED{$cgiparams{dist}}}) . "'"    if(defined $MERGED{$cgiparams{dist}});
    my $sql = "SELECT version,sum(pass) as pass, sum(fail) as fail, sum(na) as na, sum(unknown) as unknown FROM release_summary" .
    	" WHERE dist IN ($dist) $where GROUP BY version ORDER BY version";

    audit("DEBUG: sql=$sql");

    my $next;
    eval { $next = $options{CPANSTATS}->iterator('hash', $sql ) };
    if ( $@ ) { audit( "SQL failed: $@" ); return; }

    audit( "DEBUG: SQL ran successfully" );

    my ( $summary );
    while ( my $row = $next->() ) {
        next unless $row->{version};

        $summary->{ $row->{version} }->{ PASS }    = $row->{pass};
        $summary->{ $row->{version} }->{ FAIL }    = $row->{fail};
        $summary->{ $row->{version} }->{ NA }      = $row->{na};
        $summary->{ $row->{version} }->{ UNKNOWN } = $row->{unknown};
        $summary->{ $row->{version} }->{ ALL }     = $row->{pass} + $row->{fail} + $row->{na} + $row->{unknown};
    }

    if (!keys %$summary) {
	audit( "DEBUG: nothing to process for dist $dist" );
	return;
    }

    audit("DEBUG: summary=".Dumper($summary));

    my $oncpan = q!'cpan','upload','backpan'!;
    $oncpan = q!'cpan','upload'!    if($cgiparams{oncpan} && $cgiparams{oncpan} == 1);
    $oncpan = q!'backpan'!          if($cgiparams{oncpan} && $cgiparams{oncpan} == 2);

    my @versions;
    if($cgiparams{version}) {
        @versions = ($cgiparams{version});
    } else {
        # ensure we cover all known versions
        my @rows = $options{CPANSTATS}->get_query(
                        'array',
                        "SELECT DISTINCT(version) FROM uploads WHERE dist IN ($dist) AND type IN ($oncpan) ORDER BY released DESC" );
        for(@rows) {
            next    if($cgiparams{distmat} && $cgiparams{distmat} == 1     && $_->[0]  =~ /_/i);
            next    if($cgiparams{distmat} && $cgiparams{distmat} == 2     && $_->[0]  !~ /_/i);
            push @versions, $_->[0];
        }
    }

    my %versions = map {my $v = $_; $v =~ s/[^\w\.\-]/X/g; $_ => $v} @versions;

    audit("DEBUG: versions=".Dumper(\%versions));

    %output = (
        template  => 'dist_summary',
        variables => {
            versions        => \@versions,
            versions_tag    => \%versions,
            summary         => $summary,
            distro          => $cgiparams{dist}
        }
    );
}

sub process_dist_long {
    audit("DEBUG: start process dist (long): $cgiparams{dist}");

    %output = (
        template  => 'dist_summary',
    );

    my @where;
    push @where, "perl NOT LIKE '%patch%'"          if($cgiparams{patches} && $cgiparams{patches} == 1);
    push @where, "perl LIKE '%patch%'"              if($cgiparams{patches} && $cgiparams{patches} == 2);
    push @where, "version NOT LIKE '%\\_%'"         if($cgiparams{distmat} && $cgiparams{distmat} == 1);
    push @where, "version LIKE '%\\_%'"             if($cgiparams{distmat} && $cgiparams{distmat} == 2);
    push @where, "version='$cgiparams{version}'"    if($cgiparams{version});
    my $where = @where ? ' AND ' . join(' AND ',@where) : '';

    my $dist = "'$cgiparams{dist}'";
    $dist = "'" . join("','",@{$MERGED{$cgiparams{dist}}}) . "'"    if(defined $MERGED{$cgiparams{dist}});
    my $sql = "SELECT id, state, version, perl, osname, FROM cpanstats WHERE dist IN ($dist) AND state != 'cpan' $where ORDER BY version, id";

    audit("DEBUG: sql=$sql");

    my $next = $options{CPANSTATS}->iterator('hash', $sql );

    my ( $summary );
    while ( my $row = $next->() ) {
        next unless $row->{version};
        $row->{perl} = "5.004_05" if $row->{perl} eq "5.4.4"; # RT 15162
        #next    if($cgiparams{patches} && $cgiparams{patches} == 1     && $row->{perl}     =~ /patch/i);
        #next    if($cgiparams{patches} && $cgiparams{patches} == 2     && $row->{perl}     !~ /patch/i);
        #next    if($cgiparams{distmat} && $cgiparams{distmat} == 1     && $row->{version}  =~ /_/i);
        #next    if($cgiparams{distmat} && $cgiparams{distmat} == 2     && $row->{version}  !~ /_/i);
        next    if($cgiparams{perlmat} && $cgiparams{perlmat} == 1     && $row->{perl}     =~ /^5.(7|9|[1-9][13579])/);
        next    if($cgiparams{perlmat} && $cgiparams{perlmat} == 2     && $row->{perl}     !~ /^5.(7|9|[1-9][13579])/);
        next    if($cgiparams{perlver} && $cgiparams{perlver} ne 'ALL' && $row->{perl}     !~ /$cgiparams{perlver}/i);
        next    if($cgiparams{osname}  && $cgiparams{osname}  ne 'ALL' && $row->{osname}   !~ /$cgiparams{osname}/i);

        $summary->{ $row->{version} }->{ uc $row->{state} }++;
        $summary->{ $row->{version} }->{ 'ALL' }++;
    }

    return  unless(keys %$summary);

    audit("DEBUG: summary=".Dumper($summary));

    my $oncpan = q!'cpan','upload','backpan'!;
    $oncpan = q!'cpan','upload'!    if($cgiparams{oncpan} && $cgiparams{oncpan} == 1);
    $oncpan = q!'backpan'!          if($cgiparams{oncpan} && $cgiparams{oncpan} == 2);

    # ensure we cover all known versions
    my @rows = $options{CPANSTATS}->get_query(
                    'array',
                    "SELECT DISTINCT(version) FROM uploads WHERE dist IN ($dist) AND type IN ($oncpan) ORDER BY released DESC" );
    my @versions;
    for(@rows) {
        next    if($cgiparams{distmat} && $cgiparams{distmat} == 1     && $_->[0]  =~ /_/i);
        next    if($cgiparams{distmat} && $cgiparams{distmat} == 2     && $_->[0]  !~ /_/i);
        push @versions, $_->[0];
    }
    my %versions = map {my $v = $_; $v =~ s/[^\w\.\-]/X/g; $_ => $v} @versions;

    audit("DEBUG: versions=".Dumper(\%versions));

    %output = (
        template  => 'dist_summary',
        variables => {
            versions        => \@versions,
            versions_tag    => \%versions,
            summary         => $summary,
            distro          => $cgiparams{dist}
        }
    );
}

sub process_author {
    if( $LONG_ALLOWED && 
        ( ($cgiparams{osname}  && $cgiparams{osname}  =~ /ALL/i) ||
          ($cgiparams{perlver} && $cgiparams{perlver} =~ /ALL/i) ) ) {
        process_author_long();
    } else {
        process_author_short();
    }
}

sub process_author_short {
    audit("DEBUG: start process author (short): $cgiparams{author}");
    my (@dists,%summary);

    %output = (
        template  => 'author_summary',
    );

    my @where;
    push @where, "s.patched=$cgiparams{patches}"      if($cgiparams{patches});
    push @where, "s.distmat=$cgiparams{distmat}"      if($cgiparams{distmat});
    push @where, "s.perlmat=$cgiparams{perlmat}"      if($cgiparams{perlmat});
    push @where, "s.oncpan=$cgiparams{oncpan}"        if($cgiparams{oncpan});
    my $where = @where ? ' AND ' . join(' AND ',@where) : '';

    my $sql =   q{SELECT x.dist FROM ixlatest AS x WHERE x.author=? AND x.version IS NOT NULL AND x.version!=''};
    my @rows = $options{CPANSTATS}->get_query('hash', $sql, $cgiparams{author} );

    return  unless(@rows);

    for my $row (@rows) {
        $summary{ $row->{dist} }->{ PASS }    = 0;
        $summary{ $row->{dist} }->{ FAIL }    = 0;
        $summary{ $row->{dist} }->{ NA }      = 0;
        $summary{ $row->{dist} }->{ UNKNOWN } = 0;
        $summary{ $row->{dist} }->{ ALL }     = 0;
    }

    $sql =  'SELECT x.dist,x.version,sum(s.pass) as pass,sum(s.fail) as fail,sum(s.na) as na,sum(s.unknown) as unknown ' .
            'FROM ixlatest AS x ' .
            'LEFT JOIN release_summary AS s ON x.dist=s.dist AND x.version=s.version ' .
            "WHERE x.author=? AND s.version IS NOT NULL AND s.version!='' $where " .
            'GROUP BY x.dist';

    audit("DEBUG: sql=$sql");

    #my $next = $options{CPANSTATS}->iterator('hash', $sql, $cgiparams{author} );
    my @rows = $options{CPANSTATS}->get_query('hash', $sql, $cgiparams{author} );
    audit("DEBUG: rows=".(scalar(@rows)));

    #while ( my $row = $next->() ) {
    for my $row (@rows) {
        audit("DEBUG: processing: $row->{dist} [$row->{type}]");

        next    unless($row->{dist} =~ /^[A-Za-z0-9][A-Za-z0-9\-_]*$/
                    || $row->{dist} =~ /$EXCEPTIONS/);

        $summary{ $row->{dist} }->{ version }  = $row->{version};
        $summary{ $row->{dist} }->{ PASS }    += $row->{pass};
        $summary{ $row->{dist} }->{ FAIL }    += $row->{fail};
        $summary{ $row->{dist} }->{ NA }      += $row->{na};
        $summary{ $row->{dist} }->{ UNKNOWN } += $row->{unknown};
        $summary{ $row->{dist} }->{ ALL }     += $row->{pass} + $row->{fail} + $row->{na} + $row->{unknown};
    }

    my @dists = map {
            {
                distribution => $_,
                summary      => $summary{$_},
            }
        } sort keys %summary;

    audit("DEBUG: summary data retrieved");
    audit("DEBUG: dists=".Dumper(\@dists));

    %output = (
        template  => 'author_summary',
        variables => {
            distributions   => \@dists,
        }
    );
}

sub process_author_long {
    audit("DEBUG: start process author: $cgiparams{author}");
    my (@dists,%summary);

    %output = (
        template  => 'author_summary',
    );

    my @where;
    push @where, "u.type != 'backpan'"              if($cgiparams{oncpan}  && $cgiparams{oncpan}  == 1);
    push @where, "u.type = 'backpan'"               if($cgiparams{oncpan}  && $cgiparams{oncpan}  == 2);
    push @where, "c.perl NOT LIKE '%patch%'"        if($cgiparams{patches} && $cgiparams{patches} == 1);
    push @where, "c.perl LIKE '%patch%'"            if($cgiparams{patches} && $cgiparams{patches} == 2);
    push @where, "c.version NOT LIKE '%\\_%'"       if($cgiparams{distmat} && $cgiparams{distmat} == 1);
    push @where, "c.version LIKE '%\\_%'"           if($cgiparams{distmat} && $cgiparams{distmat} == 2);
    my $where = @where ? ' AND ' . join(' AND ',@where) : '';

    my $sql =   'SELECT c.dist,c.state,c.perl,c.osname,c.version FROM cpanstats AS c ' .
                'INNER JOIN ixlatest AS x ON x.dist=c.dist AND x.version=c.version ' .
                'INNER JOIN uploads AS u ON u.dist=x.dist AND u.version=x.version ' .
                "WHERE x.author=? $where ORDER BY id";

    audit("DEBUG: sql=$sql");

    #my $next = $options{CPANSTATS}->iterator('hash', $sql, $cgiparams{author} );
    my @rows = $options{CPANSTATS}->get_query('hash', $sql, $cgiparams{author} );
    audit("DEBUG: rows=".(scalar(@rows)));

    return  unless(@rows);

    my $inx = 0;
    my $max = 0;#scalar(@rows);
    #while ( my $row = $next->() ) {
    for my $row (@rows) {
        $inx++;
        audit("DEBUG: processing $inx/$max: $row->{dist} [$row->{type}]");

        next    unless($row->{dist} =~ /^[A-Za-z0-9][A-Za-z0-9\-_]*$/
                    || $row->{dist} =~ /$EXCEPTIONS/);

        $row->{perl} = "5.004_05" if $row->{perl} eq "5.4.4"; # RT 15162
        next    if($cgiparams{perlmat} && $cgiparams{perlmat} == 1     && $row->{perl}     =~ /^5.(7|9|[1-9][13579])/);
        next    if($cgiparams{perlmat} && $cgiparams{perlmat} == 2     && $row->{perl}     !~ /^5.(7|9|[1-9][13579])/);
        next    if($cgiparams{perlver} && $cgiparams{perlver} ne 'ALL' && $row->{perl}     !~ /$cgiparams{perlver}/i);
        next    if($cgiparams{osname}  && $cgiparams{osname}  ne 'ALL' && $row->{osname}   !~ /$cgiparams{osname}/i);

        $summary{$row->{dist}}->{ version } = $row->{version};
        $summary{$row->{dist}}->{ uc $row->{state} }++;
        $summary{$row->{dist}}->{ 'ALL' }++;
    }

    my @dists = map {
            {
                distribution => $_,
                summary      => $summary{$_},
            }
        } sort keys %summary;

    audit("DEBUG: summary data retrieved");
    audit("DEBUG: dists=".Dumper(\@dists));

    %output = (
        template  => 'author_summary',
        variables => {
            distributions   => \@dists,
        }
    );
}

sub writer {
    my $result;

    audit("DEBUG: output=" . Dumper(\%output));
    audit("DEBUG: options=" . Dumper(\%options));

    my $template = $output{template} . '.' . $options{format};
    unless(-f "templates/$template") {
        print $cgi->header('text/text','404 Page Not Found');
        print "Invalid data request\n";
        return;
    }

    $tt->process( $template, $output{variables}, \$result )
            || error( $tt->error );

    $result =~ s/\s{2,}/ /g;

    audit("DEBUG: result=$result");

    if($options{format} eq 'xml') {
        print $cgi->header('text/xml') . $result . "\n";
    } elsif($options{format} eq 'csv') {
        print $cgi->header(-type => 'text/csv', -attachment => "report-summary.csv") . $result . "\n";
    } elsif($options{format} eq 'json') {
        print $cgi->header('application/json') . $result . "\n";
    } else {
        $OT = OpenThought->new();

        my $html;
        $html->{'reportsummary'} = $result;
        $OT->param( $html );

        audit("DEBUG: response=" . $OT->response());

        print $cgi->header;
        print $OT->response();
    }
}

sub error {
    audit('ERROR:',@_);
    print STDERR @_;
    print $cgi->header('text/plain'), "Error retrieving data\n";
    exit;
}

sub audit {
    return  unless($DEBUG);

    my @date = localtime(time);
    my $date = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $date[5]+1900, $date[4]+1, $date[3], $date[2], $date[1], $date[0];

    my $fh = IO::File->new($VHOST . 'cgi-bin/cache/summary-audit.log','a+') or return;
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

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2017 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
