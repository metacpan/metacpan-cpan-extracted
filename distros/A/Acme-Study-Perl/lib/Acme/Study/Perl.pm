package Acme::Study::Perl;

use warnings;
use strict;
require Data::Dumper;
use Test::Builder;
use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(studyperl);

=encoding utf-8

=head1 NAME

Acme::Study::Perl - empirical studies about how perl behaves

=cut

use version; our $VERSION = qv('0.0.2');

=head1 SYNOPSIS

    use Acme::Study::Perl qw(studyperl);
    studyperl("your expression goes here", "optional comment");

=head1 DESCRIPTION

This module provides nothing that you cannot do yourself. Its focus
is the test suite. If cpantesters deliver what they promise, this
module's test suite can be used to study the behaviour of perl on
multiple platforms.

The single function C<studyperl> only does some trivial formatting
which will help deciphering the output of the testsuite.

=head1 EXAMPLE

My first descriptive table overview after I first released
Acme::Study::Perl was generated with the following command:

  ctgetreports --q meta:perl -q conf:use64bitint -q conf:use64bitall --q qr:"(native big math float/int.*)" Acme-Study-Perl

The result showed me six perls that have a bug in their conversion of
strings to numbers and 28 perls that did it right. To find out more
about the parameters that might have an influence, I called
ctgetreports with --solve and --ycb (example in the ctgetreports
manpage).

The calculation provided a hint that conf:ivtype is a candidate.
Looking closer helped confirm the finding that all perls with ivtype
C<long long> have this bug. And only one architecture with ivtype
C<long>, namely C<alpha-netbsd>. All others either provided the
correct result, C<-1> because they were native 64 bit processors or
the expected wrong-by-rounding result C<0>.

=head1 EXPORT

=head1 FUNCTIONS

=head2 (void) studyperl ($expr, $comment)

Evals the expression and sends with the diag() command from Test::More
a terse Data::Dumper representation for STDERR.

So far we have defined four characters as hash keys per study:

  # comment
  < input
  > output
  @ error ($@)

We have configured Data::Dumpe to write one line and sort the keys

=cut

sub studyperl {
    my($expr, $comment) = @_;
    my $out = eval $expr;
    my $err = $@;
    my @err = $err ? ('@' => $err) : ();
    my @comment = $comment ? ("#" => $comment) : ();
    our $Test;
    $Test ||= Test::Builder->new;
    $Test->diag(Data::Dumper->new([{"<"=>$expr, ">"=>$out, @comment, @err}])
                ->Sortkeys(1)->Indent(0)->Useqq(1)->Terse(1)->Dump);
    return;
}

=head1 AUTHOR

Andreas König, C<< <andreas.koenig.7os6VVqR at franz.ak.mind.de> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Study-Perl>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Study::Perl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Study-Perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Study-Perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Study-Perl>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Study-Perl>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to RJBS for Module::Starter.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Andreas König.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Acme::Study::Perl
