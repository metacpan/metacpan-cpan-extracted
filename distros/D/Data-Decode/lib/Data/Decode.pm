# $Id: /mirror/perl/Data-Decode/trunk/lib/Data/Decode.pm 8881 2007-11-09T10:28:54.182349Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp ();
use Data::Decode::Exception;

__PACKAGE__->mk_accessors($_) for qw(_decoder);

our $VERSION = '0.00006';

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless {}, $class;
    $self->decoder($args{strategy});

    return $self;
}

sub decoder
{
    my $self = shift;

    my $ret;
    if (! @_) {
        $ret = $self->_decoder();
    } else {
        $ret = $self->_decoder($_[0] || Carp::croak("No strategy specified") );
        if (! eval { $_[0]->can('decode') }) {
            Carp::croak("$_[0] does not implement a 'decode' method");
        }
    }
    return $ret;
}

sub decode
{
    my ($self, $data, $hints) = @_;

    return () unless defined $data;
    $hints ||= {};

    my $ret = eval {
        $self->decoder->decode($self, $data, $hints);
    };
    my $e;
    if ($e = Data::Decode::Exception::Deferred->caught() ) {
        # Just deferred. return ()
        return ();
    } elsif ( $e = Exception::Class->caught() ) {
        # Oh, this we re-throw
        eval { $e->isa('Data::Decode::Exception') } ?
            $e->rethrow : die $e;
    }
    return $ret;
}

1;

__END__

=head1 NAME

Data::Decode - Pluggable Data Decoder

=head1 SYNOPSIS

  use Data::Decode;

  my $decoder = Data::Decode->new(
    strategy => Data::Decode::Encode::Guess->new()
  );
  my $decoded = $decoder->decode($data);

=head1 DESCRIPTION

WARNING: Alpha grade software.

Data::Decode implements a pluggable "decoder". The main aim is to provide
a uniform interface to decode a given data while allowing the actual
algorithm being used to be changed depending on your needs..

For now this is aimed at decoding miscellaneous text to perl's internal 
unicode encoding.

=head1 DECODING TO UNICODE

Japanese, which is the language that I mainly deal with, has an annoying
property, in that it can come in at least 4 different flavors (utf-8,
shift-jis, euc-jp and iso-2022-jp).
Even worse, vendors may have more vendor-specific symbols, such as the
pictograms in mobile phones.

Ways to decode these strings into unicode varies between each environment 
and application.

Many modules require that the strings be normalized to unicode, but they
all handle this normalization process differently, which is, well, not exactly
an optimal solution.

Data::Decode provides a uniform interface to this problem, and a few common
ways decoding is handled. The actual decoding strategies are separated out
from the surface interface, so other users who find a particular strategy to
decode strings can then upload their way to CPAN, and everyone can benefit
from it.

=head1 DEFAULT STRATEGIES

By default, this module comes with a few default strategies. These are just
basic strategies -- they probably work in most cases, but you are strongly
encouraged not to overtrust these algorithms.

=head1 CHAINING

Data::Decode comes with a simple chaining functionality. You can take as many
decoders as you want, and you can stack them on top of each other.

=head1 METHODS

=head2 new

Instantiates a new Data::Decode object.

=over 4

=item strategy

Required. Takes in the object that encapsulates the actual decoding logic.
The object must have a method named "decode", which takes in a reference
to the Data::Decode object and a string to be decoded. An optional third
parameter may be provided to specify any hints that could be used to figure
out what to do. 

  sub decode {
    my ($self, $decoder, $string, $hints) = @_;
    # $decoder = Data::Decode object
    # $string  = a scalar to be decoded
    # $hints   = a hashref of hints
  }

=back

=head2 decode

Decodes a string. Takes in a string, and a hashref of hints to be used
for decoding. The meaning or the usage of the hints may differ between 
the actual underlying decoders.

=head2 decoder

Get/set the underlying decoder object.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut