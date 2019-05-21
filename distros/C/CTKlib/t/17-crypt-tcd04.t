#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 17-crypt-tcd04.t 238 2019-05-06 18:17:51Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('CTK::Crypt::TCD04') };

my $tcd04 = new_ok( 'CTK::Crypt::TCD04' );

# One char
my $code = $tcd04->tcd04c('u');   # 1 char
my $decode = $tcd04->tcd04d($code); # 1 word
is($decode, "u", "One char encrypt and decrypt");

# Text
is($tcd04->decrypt( $tcd04->encrypt( 'Hello, World!' ) ), 'Hello, World!', 'Hello, World!');

1;

__END__
