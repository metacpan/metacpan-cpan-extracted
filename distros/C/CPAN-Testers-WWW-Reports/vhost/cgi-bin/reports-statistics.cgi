#!/usr/bin/perl
use strict;
$|++;

my $VERSION = '3.60';

#----------------------------------------------------------------------------

=head1 NAME

reports-statistics.cgi - retrieves the statistics table for the respective distribution page

=head1 SYNOPSIS

  perl reports-statistics.cgi

=head1 DESCRIPTION

Called in a CGI context, returns the current statistics table for a CPAN
distribution.

Primary Query String parameters are

=over 4

item * dist (mandatory)

The distribution to provide a summary for. An error will be returned if no
distribution name is provided.

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
use version;

# -------------------------------------
# Variables

my $DEBUG = $ENV{DEBUG} || 0;
my $LONG_ALLOWED = 0;

my $VHOST = '/var/www/reports/';
my (%options,%cgiparams,%output,$OT,$cgi,$tt);

my %rules = (
    dist    => qr/^([-\w.]+)$/i,
);

my $EXCEPTIONS;
my %SYMLINKS;
my %MERGED;

# -------------------------------------
# Program

init_options();
process_stats();
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
    );

    $options{config} ||= $VHOST . 'cgi-bin/config/settings.ini';

    error("Must specify the configuration file\n")             unless($options{config});
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

    #audit("DEBUG: options" . Dumper(\%options));

    $cgi = CGI->new;

    audit("DEBUG: configuration done");

    for my $key (keys %rules) {
        my $val = $options{$key} || $cgi->param("${key}_pref") || $cgi->param($key);
        $cgiparams{$key} = $1   if($val =~ $rules{$key});
    }

    audit('DEBUG: cgiparams=',Dumper(\%cgiparams));
    error("Must supply the distribution name\n") unless($cgiparams{dist});

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

    #$cgiparams{dist} = 'App-Maisha';
}

sub process_stats {
    # retrieve perl/os stats
    my ($stats,$oses);
    my @rows = $options{CPANSTATS}->get_query('hash','SELECT * FROM cpanstats.stats_store WHERE dist=?',$cgiparams{dist});
    for(@rows) {
        $stats->{$_->{perl}}{$_->{osname}}{version} = $_->{version};
        $stats->{$_->{perl}}{$_->{osname}}{count}   = $_->{counter};
        $oses->{$_->{osname}} = $_->{osname};
    }

    my @stats_oses = sort keys %$oses;
    my @stats_perl = sort {_versioncmp($b,$a)} keys %$stats;
    my @stats_poff = grep {!/patch/} sort {_versioncmp($b,$a)} keys %$stats;

    %output = (
        template  => 'cpan/distro-stats-table',
        variables => {
            stats      => $stats,
            stats_code => $oses,
            stats_oses => \@stats_oses,
            stats_perl => \@stats_perl,
            stats_poff => \@stats_poff
        }
    );
}


sub writer {
    my $result;

    audit("DEBUG: output=" . Dumper(\%output));
    audit("DEBUG: options=" . Dumper(\%options));

    my $template = $output{template} . '.html';
    unless(-f "templates/$template") {
        print $cgi->header('text/text','404 Page Not Found');
        print "Invalid data request\n";
        return;
    }

    $tt->process( $template, $output{variables}, \$result )
            || error( $tt->error );

    $result =~ s/\s{2,}/ /g;

    audit("DEBUG: result=$result");

    $OT = OpenThought->new();

    my $html;
    $html->{'statstable'} = $result;
    $OT->param( $html );

    audit("DEBUG: response=" . $OT->response());

    print $cgi->header;
    print $OT->response();
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

    my $fh = IO::File->new($VHOST . 'cgi-bin/cache/reports-statistics-audit.log','a+') or return;
    print $fh "$date " . join(' ',@_ ). "\n";
    $fh->close;
}

sub _versioncmp {
    my ($v1,$v2) = @_;
    my ($vn1,$vn2);

    $v1 =~ s/\s.*$//    if($v1);
    $v2 =~ s/\s.*$//    if($v2);

    return -1   if(!$v1 &&  $v2);
    return  0   if(!$v1 && !$v2);
    return  1   if( $v1 && !$v2);

    eval { $vn1 = version->parse($v1); };
    if($@) { return $v1 cmp $v2 }
    eval { $vn2 = version->parse($v2); };
    if($@) { return $v1 cmp $v2 }

    return $vn1 cmp $vn2;
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
