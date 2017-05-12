package Data::BitStream::BLVec;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::BLVec::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::BLVec::VERSION   = '0.08';
}

use Moo;
use MooX::Types::MooseLike::Base qw/InstanceOf/;

with 'Data::BitStream::Base',
     'Data::BitStream::Code::Gamma',
     'Data::BitStream::Code::Delta',
     'Data::BitStream::Code::Omega', 
     'Data::BitStream::Code::Levenstein',
     'Data::BitStream::Code::EvenRodeh',
     'Data::BitStream::Code::Fibonacci',
     'Data::BitStream::Code::Golomb',
     'Data::BitStream::Code::Rice',
     'Data::BitStream::Code::GammaGolomb',
     'Data::BitStream::Code::ExponentialGolomb',
     'Data::BitStream::Code::Baer',
     'Data::BitStream::Code::BoldiVigna',
     'Data::BitStream::Code::ARice',
     'Data::BitStream::Code::Additive',
     'Data::BitStream::Code::Comma',
     'Data::BitStream::Code::Taboo',
     'Data::BitStream::Code::BER',
     'Data::BitStream::Code::Varint',
     'Data::BitStream::Code::StartStop';

use Data::BitStream::XS 0.04;

has '_vec' => (is => 'rw',
               isa => InstanceOf['Data::BitStream::XS'],
               default => sub { return Data::BitStream::XS->new });

# Force our pos and len sets to also set the XS object
has '+pos' => (trigger => sub { shift->_vec->_set_pos(shift) });
has '+len' => (trigger => sub { shift->_vec->_set_len(shift) });

after 'rewind'      => sub { shift->_vec->rewind;      1; };
after 'erase'       => sub { shift->_vec->erase;       1; };
after 'read_open'   => sub { shift->_vec->read_open;   1; };
after 'write_open'  => sub { shift->_vec->write_open;  1; };
after 'write_close' => sub { shift->_vec->write_close; 1; };

sub read {
  my $self = shift;
  my $vref = $self->_vec;

  my $val = $vref->read(@_);
  $self->_setpos( $vref->pos );
  $val;
}
sub write {
  my $self = shift;
  my $vref = $self->_vec;

  $vref->write(@_);

  $self->_setlen( $vref->len );
  1;
}

# This is a bit ugly, but my other alternatives:
#
#   1) hand-write each sub.
#      Error prone, and lots of duplication.
#
#   2) make a _generic_put and then:
#      sub put_unary { _generic_put( sub { shift->put_unary(shift) }, @_) }
#      Very nice, but adds time for every value
#
#   3) _generic_put with a for loop inside the sub argument.
#      Solves performance, but now unwieldy and not generic.
#
#   3) Use *{$fn} = sub { ... }; instead of eval.
#      100ns slower, which is 0.5-2x the total function cost
#

sub _generate_generic_put {
  my $param = shift;
  my $fn   = shift;
  my $blfn = shift || $fn;

  my $st = "sub $fn {\n " .
'  my $self = shift;
   __PARAM__
   my $vref = $self->_vec;
   $vref->__CALLFUNC__;
   $self->_setlen( $vref->len );
   1;
 }';

  $st =~ s/__PARAM__/$param/;
  $st =~ s/__CALLFUNC__/$blfn(\@_)/g;

  { no warnings 'redefine';  eval $st; }  ## no critic
  warn $@ if $@;
}
sub _generate_generic_get {
  my $param = shift;
  my $fn   = shift;
  my $blfn = shift || $fn;

  my $st = "sub $fn {\n " .
'  my $self = shift;
   __PARAM__
   my $vref = $self->_vec;
   if (wantarray) {
     my @vals = $vref->__CALLFUNC__;
     $self->_setpos( $vref->pos );
     return @vals;
   } else {
     my $val = $vref->__CALLFUNC__;
     $self->_setpos( $vref->pos );
     return $val;
   }
 }';

  $st =~ s/__PARAM__/$param/;
  $st =~ s/__CALLFUNC__/$blfn(\@_)/g;

  { no warnings 'redefine';  eval $st; }  ## no critic
  warn $@ if $@;
}

sub _generate_generic_getput {
  my $param = shift;
  my $code = shift;
  my $blcode = shift || $code;
  _generate_generic_put($param, 'put_'.$code, 'put_'.$blcode );
  _generate_generic_get($param, 'get_'.$code, 'get_'.$blcode );
}

_generate_generic_getput('', 'unary');
_generate_generic_getput('', 'unary1');
_generate_generic_getput('', 'gamma');
_generate_generic_getput('', 'delta');
_generate_generic_getput('', 'omega');
_generate_generic_getput('', 'fib');
_generate_generic_getput('', 'fibgen');
_generate_generic_getput('', 'levenstein');
_generate_generic_getput('', 'evenrodeh');
_generate_generic_getput('', 'gammagolomb');
_generate_generic_getput('', 'expgolomb');
_generate_generic_getput('', 'baer');
_generate_generic_getput('', 'boldivigna');
_generate_generic_getput('', 'comma');
_generate_generic_getput('', 'blocktaboo');
_generate_generic_getput('', 'goldbach_g1');
_generate_generic_getput('', 'goldbach_g2');
_generate_generic_getput('', 'binword');

# The XS module understands subs, so we can map these directly
_generate_generic_getput('', 'golomb');
_generate_generic_getput('', 'rice');
_generate_generic_getput('', 'arice');

_generate_generic_getput('', 'startstepstop');
_generate_generic_getput('', 'startstop');

#_generate_generic_get('', 'get_levenstein');
#_generate_generic_get(
#   'die "invalid parameters" unless $p > 0 && $p <= 15',
#   'get_boldivigna');
#_generate_generic_getput(
#   'die "invalid parameters" unless $p >= 0 && $p <= $self->maxbits',
#   'expgolomb', 'gamma_rice');

sub put_string {
  my $self = shift;
  my $vref = $self->_vec;

  $vref->put_string(@_);

  $self->_setlen( $vref->len );
  1;
}

sub read_string { shift->_vec->read_string(@_); }

sub to_raw {
  my $self = shift;
  $self->write_close;
  my $vref = $self->_vec;
  return $vref->to_raw;
}
sub put_raw {
  my $self = shift;
  my $vref = $self->_vec;
  $vref->put_raw(@_);
  $self->_setlen( $vref->len );
  1;
}
sub from_raw {
  my $self = $_[0];
  # data comes in 2nd argument
  my $bits = $_[2] || 8*length($_[1]);

  $self->write_open;
  my $vref = $self->_vec;
  $vref->from_raw($_[1], $bits);

  $self->_setlen( $bits );
  $self->rewind_for_read;
}

sub put_stream {
  my $self = shift;
  my $source = shift;
  my $vref = $self->_vec;

  if (ref $source eq __PACKAGE__) {
    $vref->put_stream($source->_vec);
  } else {
    $vref->put_stream($source);
  }

  $self->_setlen( $vref->len );
  1;
}

# default everything else

__PACKAGE__->meta->make_immutable;
no Moo;
1;

# ABSTRACT: An XS-wrapper implementation of Data::BitStream

=pod

=head1 NAME

Data::BitStream::BLVec - An XS-wrapper implementation of Data::BitStream

=head1 SYNOPSIS

  use Data::BitStream::BLVec;
  my $stream = Data::BitStream::BLVec->new;
  $stream->put_gamma($_) for (1 .. 20);
  $stream->rewind_for_read;
  my @values = $stream->get_gamma(-1);



=head1 DESCRIPTION

An implementation of L<Data::BitStream>.  See the documentation for that
module for many more examples, and L<Data::BitStream::Base> for the API.
This document only describes the unique features of this implementation,
which is of limited value to people purely using L<Data::BitStream>.

This implementation points everything to the implementations in
Data::BitStream::XS where possible.  This gives the majority of the performance
benefit of the XS module, while (1) transparently applying the speedup through
the Data::BitStream package, and (2) allowing all the Moo/Mouse/Moose extensions
and extra roles to be used while still retaining high performance at the core.

This is the default L<Data::BitStream> implementation if Data::BitStream::XS
is installed.



=head2 DATA

=over 4

=item B< _vec >

A private Data::BitStream::XS object.

=back



=head2 CLASS METHODS

=over 4

=item I<after> B< erase >

=item I<after> B< rewind >

=item I<after> B< read_open >

=item I<after> B< write_open >

=item I<after> B< write_close >

Applies the appropriate behavior to the XS object.


=item B< read >

=item B< write >

=item B< put_string >

=item B< read_string >

=item B< to_raw >

=item B< put_raw >

=item B< from_raw >

=item B< put_stream >

These methods have custom implementations.

The following codes have C<get_> and C<put_> methods:

  unary
  unary1
  gamma
  delta
  omega
  fib
  fibgen
  levenstein
  evenrodeh
  gammagolomb
  expgolomb
  baer
  boldivigna
  comma
  blocktaboo
  goldbach_g1
  goldbach_g2
  binword
  golomb
  rice
  arice
  startstepstop
  startstop

=back


=head2 ROLES

The following roles are included.

=over 4

=item L<Data::BitStream::Code::Base>

=item L<Data::BitStream::Code::Gamma>

=item L<Data::BitStream::Code::Delta>

=item L<Data::BitStream::Code::Omega>

=item L<Data::BitStream::Code::Levenstein>

=item L<Data::BitStream::Code::EvenRodeh>

=item L<Data::BitStream::Code::Fibonacci>

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::Rice>

=item L<Data::BitStream::Code::GammaGolomb>

=item L<Data::BitStream::Code::ExponentialGolomb>

=item L<Data::BitStream::Code::Baer>

=item L<Data::BitStream::Code::BoldiVigna>

=item L<Data::BitStream::Code::ARice>

=item L<Data::BitStream::Code::Additive>

=item L<Data::BitStream::Code::Comma>

=item L<Data::BitStream::Code::Taboo>

=item L<Data::BitStream::Code::StartStop>

=back




=head1 SEE ALSO

=over 4

=item L<Data::BitStream>

=item L<Data::BitStream::XS>

=item L<Data::BitStream::Base>

=item L<Data::BitStream::WordVec>

=back



=head1 AUTHORS

Dana Jacobsen E<lt>dana@acm.orgE<gt>



=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
