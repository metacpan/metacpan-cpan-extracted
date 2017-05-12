# -*- Perl -*-
#
# c[ad]+r list-operation support for Perl, based on (car) and (cdr) and
# so forth of lisp fame, though with a limit of 704 as to the maximum
# length any such shenanigans.
#
# Run perldoc(1) on this file for additional documentation.

package Acme::List::CarCdr;

use 5.010000;
use strict;
use warnings;

use Carp qw(croak);
use Moo;

our $VERSION = '0.01';

##############################################################################
#
# METHODS

sub AUTOLOAD {
  my $method = our $AUTOLOAD;
  if ( $method =~ m/::c([ad]{1,704})r$/ ) {
    my $ops   = reverse $1;
    my $self  = shift;
    my $ref   = \@_;
    my $start = 0;
    my $end;
    my $delve = 0;
    while ( $ops =~ m/\G([ad])(\1*)/cg ) {
      my $op = $1;
      my $len = length $2 || 0;
      if ( $op eq 'a' ) {
        if ( $len > 0 ) {
          for my $i ( 1 .. $len ) {
            if ( ref $ref->[$start] ne 'ARRAY' ) {
              croak "$method: " . $ref->[$start] . " is not a list";
            }
            $ref   = $ref->[$start];
            $start = 0;
          }
        }
        $end   = $start;
        $delve = 1;
      } else {    # $op eq 'd'
        if ($delve) {
          if ( ref $ref->[$start] ne 'ARRAY' ) {
            croak "$AUTOLOAD: " . $ref->[$start] . " is not a list";
          }
          $ref   = $ref->[$start];
          $start = 0;
        }
        $start += $len + 1;
        $end = $#$ref;
      }
    }
    return if $start > $end;
    return @{ $ref->[$start] }
      if ( $start == $end and ref $ref->[$start] eq 'ARRAY' );
    return @$ref[ $start .. $end ];
  } else {
    croak "no such method $method";
  }
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Acme::List::CarCdr - car cdr cdaadadrdrr

=head1 SYNOPSIS

  use Acme::List::CarCdr;
  my $can = Acme::List::CarCdr->new;

  $can->car(qw/cat dog fish/);  # "cat"
  $can->cdr(qw/cat dog fish/);  # "dog", "fish"
  $can->cddr(qw/cat dog fish/); # "fish"
  $can->c...r(...);             # ...

See also the C<t/> directory of the distribution of this module for
example code.

=head1 DESCRIPTION

C<car> or C<cdr> or C<caar> or C<cadadr> or so forth support for Perl.

=head1 METHODS

Many. Any combination of C<a> and C<d> may be used, up to the
historically appropriate limit of 704 characters, to form a means of
operating on a list, or list of lists of lists of some hopefully
appropriate depth. Should an invalid method name be specified (for
example, C<cat>) or if the method name is too long (704 characters,
again, being the maximum combination of C<a> or C<d> allowed, or 706
with the requisite prefix and suffix characters of C<c> and C<r>) or
should the supplied arguments be not deep enough for the number of C<a>
somewhere in the method name, this module will throw an exception.

For those not intimately familiar with lisp (or the IBM 704 hardware
instructions abducted by the said), moving from right to left, an C<a>
gets the first element of a supplied list (C<cat> of the list C<cat dog
fish>), and C<d> gets the remainder of the list (C<dog fish>). Repeated
C<a> descend deeper into an again hopefully suitable data structure,
while repeated C<d> reduce how much of the given list is returned
(C<cddr> on the list C<cat dog fish> will return just C<fish>). Should
too many C<d> run off the end of the supplied list, a bare C<return>
call is made.

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-acme-list-carcdr at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-List-CarCdr>.

Patches might best be applied towards:

L<https://github.com/thrig/Acme-List-CarCdr>

=head2 Known Issues

Things have not been tested exhaustively for correctedness.

=head1 SEE ALSO

L<perllol>, and any number of a few documents on Lisp (or
possibly Scheme).

=head1 INSTIGATOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
