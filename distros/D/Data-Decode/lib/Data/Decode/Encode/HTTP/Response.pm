# $Id: /mirror/perl/Data-Decode/trunk/lib/Data/Decode/Encode/HTTP/Response.pm 8763 2007-11-06T09:42:32.814221Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode::Encode::HTTP::Response;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Data::Decode::Exception;
use Encode();
use Data::Decode::Util qw(try_decode pick_encoding);
use HTTP::Response::Encoding;

__PACKAGE__->mk_accessors($_) for qw(_parser);

sub decode
{
    my ($self, $decoder, $string, $hints) = @_;

    if (! $hints->{response} || ! eval { $hints->{response}->isa('HTTP::Response') }) {
        Data::Decode::Exception::Deferred->throw;
    }
    my $res = $hints->{response};

    my $decoded;
    { # Attempt to decode from header information
        my $encoding = pick_encoding(
            $res->encoding, 
            ( ($res->header('Content-Type') || '') =~ /charset=([\w\-]+)/g),
        );
        $decoded = try_decode($encoding, $string);
        return $decoded if $decoded;
    }

    { # Attempt to decode from meta information
        my $p = $self->parser();
        my $encoding = pick_encoding(
            $p->extract_encodings( $res->content )
        );

        $decoded = try_decode($encoding, $string);
        return $decoded if $decoded;
    }

    Data::Decode::Exception::Deferred->throw;
}

sub parser
{
    my $self = shift;
    my $parser = $self->_parser();
    if (! $parser) {
        require Data::Decode::Encode::HTTP::Response::Parser;
        $parser = Data::Decode::Encode::HTTP::Response::Parser->new();
        $self->_parser($parser);
    }
    return $parser;
}

1;

__END__

=head1 NAME

Data::Decode::Encode::HTTP::Response - Get Encoding Hints From HTTP::Response

=head1 METHODS

=head2 new

=head2 decode

=head2 parser

=cut