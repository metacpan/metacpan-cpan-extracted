# $Id: /mirror/perl/Data-Decode/trunk/lib/Data/Decode/Chain.pm 4834 2007-11-03T09:22:42.139028Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode::Chain;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Data::Decode::Exception;

__PACKAGE__->mk_accessors($_) for qw(decoders);

sub new
{
    my $class = shift;
    my %args  = @_;
    $args{decoders} ||= [];
    if (ref $args{decoders} ne 'ARRAY') {
        $args{decoders} = [ $args{decoders} ];
    }

    return $class->SUPER::new({ decoders => $args{decoders} });
}

sub decode
{
    my ($self, $decoder, $string, $hints) = @_;

    my $ret;
    foreach my $decoder (@{ $self->decoders }) {
        $ret = eval {
            $decoder->decode($decoder, $string, $hints);
        };
        my $e;
        if ($e = Data::Decode::Exception::Deferred->caught() ) {
            # Decoding was deffered, we don't do anything about this
            # error, and simply let the next decoder attempt to handle
            # this particular set of inputs.
            next;
        } elsif ( $e = Exception::Class->caught() ) {
            # This is a generic error, just propagate it
            eval { $e->isa('Data::Decode::Exception') } ?
                $e->rethrow : die $e;
        }
        last;
    }

    return $ret;
}

1;

__END__

=head1 NAME

Data::Decode::Chain - Chain Multiple Decoders

=head1 SYNOPSIS

  Data::Decode->new(
    strategy => Data::Decode::Chain->new(
      decoders => [
        Data::Decode::Whatever->new,
        Data::Decode::SomethingElse->new
      ]
    )
  );

=head1 METHODS

=head2 new

=head2 decode

=cut