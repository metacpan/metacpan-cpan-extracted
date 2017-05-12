# $Id$
#
# Copyright (c) 2007 Daisuke Maki daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode::Util;
use strict;
use warnings;
use Encode ();
use Exporter 'import';
our @EXPORT_OK = qw(try_decode pick_encoding);

sub try_decode
{
    my ($encoding, $data) = @_;
    return () unless $encoding;
    my $decoded = eval { Encode::decode($encoding, $data, Encode::FB_CROAK()) };
    return $decoded;
}

sub pick_encoding
{
    for my $e (@_) {
        next unless defined $e;
        next unless Encode::find_encoding($e);
        return $e;
    }
    return ();
}

1;

__END__

=head1 NAME

Data::Decode::Util - Utilities 

=head1 SYNOPSIS

  use Data::Decode::Util qw(try_decode pick_encoding);

=head1 METHODS

=head2 try_decode

=head2 pick_encoding

=cut
