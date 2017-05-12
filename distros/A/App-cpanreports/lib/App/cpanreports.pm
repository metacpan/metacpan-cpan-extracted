package App::cpanreports;

# Created on: 2015-03-01 11:33:26
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use FindBin qw/$Bin/;
use YAML::XS qw/Load LoadFile/;
use HTML::Entities;
use WWW::Mechanize;
use Path::Tiny;

our $VERSION = 0.004;
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
    version  => meta()->{version},
    distname => meta()->{name},
    dir      => 't/report',
    verbose  => 0,
    man      => 0,
    help     => 0,
    VERSION  => 0,
);


sub run {
    my ($self) = @_;

    Getopt::Long::Configure('bundling');
    GetOptions(
        \%option,
        'version|v=s',
        'distiname|d=s',
        'dir|D=s',
        'state|s=s',
        'verbose|V+',
        'man',
        'help',
        'VERSION!',
    ) or pod2usage(2);

    if ( $option{'VERSION'} ) {
        print "$name Version = $VERSION\n";
        exit 1;
    }
    elsif ( $option{'man'} ) {
        pod2usage( -verbose => 2 );
    }
    elsif ( $option{'help'} ) {
        pod2usage( -verbose => 1 );
    }
    elsif ( !$option{version} || !$option{distname} ) {
        warn <<'HELP';
The arguments --version and --distname must be specified if you are not
running from this script from the distribution's directory.

HELP
        pod2usage( -verbose => 1 );
    }

    # do stuff here
    my $mech = WWW::Mechanize->new;
    my $dir  = "$option{dir}/$option{version}";
    my $test_reports = $self->get_report_summary($mech, $dir, $option{distname}, $option{version});

    for my $report (@$test_reports) {
        next if $report->{version} ne $option{version};
        next if $option{state} && $report->{state} eq $option{state};

        my $guid = $report->{guid};
        next if glob "$dir/*.$guid";

        my $file_name = "$dir/log.test-$report->{osname}.$report->{osvers}-$report->{perl}";
        $mech->get("http://www.cpantesters.org/cpan/report/$guid");
        my $text = $mech->content;

        if ($text =~ /ccflags[^\n]+ -DDEBUGGING.+?\n/sm) {
            $file_name .= 'd';
        }
        if ($report->{platform} !~ /thread/) {
            $file_name .= "-nt";
        }

        # add the GUID to the file to make determining if the report has been
        # previously downloaded easy.
        $file_name .= ".$guid";

        $text =~ s/^.*<pre>\nFrom:/From/sm;
        $text =~ s{<hr class="clear-contentunit" />.*$}{}s;
        decode_entities($text);

        path($file_name)->spew_utf8($text);
    }

    return;
}

my $meta;
sub meta {
    return $meta if $meta;
    my $file
        = -f 'MYMETA.yml'               ? path('MYMETA.yml')
        : -f '.build/latest/MYMETA.yml' ? path('.build/latest/MYMETA.yml')
        :                                 path('META.yml');

    $meta = eval { LoadFile $file } || {};
    return $meta;
}

sub get_report_summary {
    my ($self, $mech, $dir, $distname, $version) = @_;
    my $cache = path("$dir/$distname.yml");
    $cache->parent->mkpath;
    if (-f $cache) {
        return Load scalar $cache->slurp_utf8;
    }

    my $initial = substr $distname, 0, 1;
    my $url = "http://www.cpantesters.org/distro/$initial/$distname.yml";
    $mech->get($url);
    $cache->spew_utf8($mech->content);

    my $yaml = Load $mech->content;
    return $yaml;
}


1;

__END__

=head1 NAME

App::cpanreports - Download test reports for a CPAN distribution from CPAN Testers

=head1 VERSION

This documentation refers to App::cpanreports version 0.004

=head1 SYNOPSIS

   cpan-reports [option]

 OPTIONS:
  -v --version[=]version
                The version of the distributions who's reports you want. If not
                specified it is attempted to be determined from the by assuming
                that you are in the current directory of that distribution.
                Looks for the meta file in the following way:
                 - MYMETA.yml
                 - .build/latest/MYMETA.yml (for dzil)
                 - META.yml
  -d --distiname[=]distribution
                The name of the distribution who's reports you want. If not
                specified it is attempted to be found via the name attribute
                of the meta file (see --version for details)
  -D --dir[=]report-dir
                The base directory to stort the reports int (Default is t/reports)
  -s --state[=](pass|fail|invalid|na|unknown)
                Only download tests in this state

  -V --verbose  Show more detailed option
     --VERSION  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for cpan-reports

=head1 DESCRIPTION

This script downloads test reports from CPAN Testers for a specific CPAN
distribution of a specific version.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Runs the actual code

=head2 C<get_report_summary ($mech, $dir, $distname, $version)>

Downloads tests to C<$dir> for C<$distname> C<$version> using C<$mech>

=head2 C<meta ()>

Reads the MYMETA.json file to discover details about the current project.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
