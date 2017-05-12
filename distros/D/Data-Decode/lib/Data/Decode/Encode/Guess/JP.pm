# $Id: /mirror/perl/Data-Decode/trunk/lib/Data/Decode/Encode/Guess/JP.pm 4834 2007-11-03T09:22:42.139028Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Decode::Encode::Guess::JP;
use strict;
use warnings;
use base qw(Data::Decode::Encode::Guess);

sub new
{
    my $class = shift;
    $class->SUPER::new(encodings => [ qw(shiftjis euc-jp 7bit-jis utf8) ], @_);
}

1;

__END__

=head1 NAME

Data::Decode::Encode::Guess::JP - Generic Encode::Guess For Japanese Encodings

=head1 SYNOPSIS

  Data::Decode->new(
    strategy => Data::Decode::Encode::Guess::JP->new()
  );

=head1 METHODS

=head2 new

=cut