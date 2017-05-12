#!/usr/bin/env perl

use strict;
use warnings;

use FindBin::libs;
use Pod::Usage;
use Getopt::Long;

use App::HistHub;

GetOptions(
    \my %option,
    qw/help histfile=s server=s/,
);
pod2usage(0) if $option{help};
pod2usage(1) unless $option{histfile} and $option{server};


my $hh = App::HistHub->new(
    hist_file    => $option{histfile},
    api_endpoint => $option{server},
);
$hh->run;

=head1 NAME

histhubd.pl - histhub history update script

=head1 SYNOPSIS

    histhubd.pl --histfile=~/.zhistory --server=http://localhost:3000

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

