#!/usr/bin/perl -w
# vim: set ts=4 sw=4 tw=78 et si:
#
use strict;

use Algorithm::CheckDigits;
use Getopt::Long;
use Pod::Usage;

use version; our $VERSION = qv('v1.3.6');

my %opt;

GetOptions(\%opt, 'algorithm=s', 'help', 'man');

pod2usage(-exitstatus => 0, -input => \*DATA)                if $opt{help};
pod2usage(-exitstatus => 0, -verbose => 2, -input => \*DATA) if $opt{man};

my $cmd = shift || 'check';

pod2usage(0) unless $cmd;

if ($cmd =~ /^list(_alg(orithms)?)?$/i) {
    my %descr = Algorithm::CheckDigits::method_descriptions();
    for my $method (Algorithm::CheckDigits->method_list()) {
        print $method, ': ', $descr{$method}, "\n";
    }
    exit 0;
}
if ($cmd =~ /^descr(ibe)?$/i) {
    while (my $method = shift @ARGV) {
        print join(': ',Algorithm::CheckDigits->method_descriptions($method))
            , "\n";
    }
    exit 0;
}

my $algorithm = determine_algorithm(\%opt);

my $cd = CheckDigits($algorithm);

my $complete   = sub { $cd->complete($_[0]); };
my $check      = sub { $cd->is_valid($_[0]) ? "valid" : "not valid"; };
my $checkdigit = sub { $cd->checkdigit($_[0]); };

my %cmdtable = (
    complete   => $complete,
    check      => $check,
    checkdigit => $checkdigit,
);

if (my $action = $cmdtable{$cmd}) {
    if (0 < scalar @ARGV) {
        while (my $number = shift) {
            printf "%s\n", $action->($number);
        }
    }
    else {
        print STDERR "Reading numbers from STDIN\n";
        while (my $number = <>) {
            $number =~ s/\s+$//;
            printf "%s\n", $action->($number);
        }
    }
}
else {
    pod2usage(1);
}

#----- only functions following -----
sub determine_algorithm {
    my $opt = shift;

    return $opt->{algorithm} if $opt->{algorithm};

    if ($0 =~ /^checkdigit(?:s)?-?(.*)$/i) {
        return $1 ? $1 : undef;
    }
    return $0;
} # determine algorithm()

__END__

=head1 NAME

checkdigits - check or generate check digits

=head1 VERSION

This document describes checkdigits v1.3.3

=head1 SYNOPSIS

  checkdigits [Options] command [[number] ...]

  options:

   -algorithm alg - use this algorithm

  commands:

   check           - check validity of number containing checkdigit
   checkdigit      - return checkdigit belonging to number
   complete        - return number completed with checkdigit
   list_algorithms - list all known algorithms
   describe        - describe the given algorithms

=head1 DESCRIPTION

This is a command line program that may be used to compute any checkdigit
known by the perl module Algorithm::CheckDigits.

=head1 OPTIONS AND COMMANDS

=head2 Options

=head3 -algorithm alg

Compute checkdigits according to algorithm I<alg>. Instead of providing the
algorithm with this option, you may choose to rename the program to the name
of the algorithm or to C<< checkdigits- >> followed by the name of the algorithm.

You must provide the algorithm with any of these means or the program will not
compute any checkdigit.

=head2 Commands

=head3 check

=head3 checkdigit

=head3 complete

When called with this command, the program will take the number compute the
appropriate checkdigits and return the complete number with checkdigits.

=head3 describe

Called with this command, the program will list the algorithm handles given on
the command line with a short description or the word "unknown" for any
unknown algorithm. See command I<list_algorithms> for a list of known
algorithms.

=head3 list_algorithms

Called with this command, the program will list all known algorithms together
with a short description and then exit.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

At the moment the program doesn't recognise any environment variables.

The algorithm to use may be predefined by renaming the program to the name of
the algorithm or to C<checkdigits-> followed by the name of the algorithm.

=head1 AUTHOR

Mathias Weidner C<< mamawe@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010-2020, Mathias Weidner C<< mamawe@cpan.org >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

