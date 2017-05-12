package Data::Dumper::Concise::Aligned;

use 5.010000;
use strict;
use warnings;
use Scalar::Util qw/reftype/;
use Text::Wrap qw/wrap/;

our $VERSION = '0.25';
our @ISA;

require Exporter;
require Data::Dumper;

BEGIN { @ISA = qw/Exporter/ }
our @EXPORT = qw/DumperA/;

sub DumperObjectA {
  my $dd = Data::Dumper->new( [] );
  $dd->Terse(1)->Indent(0)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1);
}

sub DumperA {
  my $str_buf;
  my $prefix = '';
  for my $o (@_) {
    if ( defined reftype $o) {
      $str_buf .=
        wrap( $prefix, $prefix, DumperObjectA->Values( [$o] )->Dump ) . "\n";
    } else {
      $prefix = $o;
      $prefix .= ' ' unless $prefix =~ m/\s$/;
    }
  }
  return $str_buf;
}

1;
__END__

=head1 NAME

Data::Dumper::Concise::Aligned - even less indentation plus string prefix

=head1 SYNOPSIS

  use Data::Dumper::Concise::Aligned;
  warn DumperA S => \@input, D => \@output;

=head1 DESCRIPTION

Like L<Data::Dumper::Concise> except with even less indentation, and string
prefixing of the wrapped-as-necessary output. Used in particular to look at
data that needs to be shown in as compact a manner as possible for easy
vertical comparison (hypothetically, musical pitch numbers), for example:

  S [[2,2,1,2,2,2,1],[1,2,2,2,1,2,2]]
  D [[2,1,2,2,2,2,1],[2,2,1,2,2,1,2]]

This could possibly be done via C<DumperF> of L<Data::Dumper::Concise>, but
that's more typing, and not exactly the string prefix handling I wanted.

=head2 Not Safe for Emacs Users

In C<vi> type editors, an C<ab> editor configuration along the lines of the
following can expand out to include the desired Dumper routine:

  ab PUDD use Data::Dumper; warn Dumper
  ab PUCC use Data::Dumper::Concise::Aligned; warn DumperA

=head1 FUNCTIONS

=head2 DumperA

Dumper, aligned, concise. Should be called with key value pairs, where the key
is presumably some short label used to prefix the concisely dumped subsequent
reference to some data structure. This function is exported by default.

=head2 DumperObjectA 

A mostly internal function used by B<DumperA>. Returns the L<Data::Dumper>
object with formatting options as used by this module set. Not exported by
default since version 0.25.

=head1 SEE ALSO

L<Data::Dump>, L<Data::Dumper::Concise>, L<Data::Dumper>, or so forth and so on
from CPAN, one of which will hopefully meet your needs. If not, well, you can
always write your own. Another good debugging tip is the C<%vd> C<printf>
format, for seeing what the data really contains, but then you'll probably want
to also know about L<ascii(7)>:

  printf "%vd\n", "hi\r\tthere";

L<Text::Wrap> is used to wrap text that strays beyond the usual punchcard
inherited limits.

L<ascii(7)>, L<vi(1)>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013,2015 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
