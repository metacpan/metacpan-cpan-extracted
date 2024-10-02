################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Config;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 69 }

eval {
  $s = Convert::Binary::C::native('IntSize');
};
ok($@, '');
ok($s > 0);

eval {
  $s = Convert::Binary::C::native('foobar');
};
ok($@, qr/^Invalid property 'foobar'/);

eval {
  $s = Convert::Binary::C::native('EnumType');
};
ok($@, qr/^Invalid property 'EnumType'/);

$c = Convert::Binary::C->new;
eval {
  $s2 = $c->native('IntSize');
};
ok($@, '');
ok($s2 > 0);
ok($s == $s2);

$warn_utf8 = 0;

for my $prop (qw( PointerSize IntSize CharSize ShortSize LongSize LongLongSize
                  FloatSize DoubleSize LongDoubleSize Alignment CompoundAlignment )) {
  my $nat = $c->native($prop);
  ok($nat, Convert::Binary::C::native($prop));
  print "# native($prop) = $nat\n";
  my $cfgvar = lc $prop;
  if (exists $Config{$cfgvar}) {
    print "#   found \$Config{$cfgvar}\n";
    my $val = $Config{$cfgvar};
    if ($val =~ /^\d+$/) {
      ok($val, $c->native($prop));
      next;
    }
    warn " *** Your perl seems to have broken UTF-8 support ***\n"
        if $ENV{LANG} =~ /utf/i and not $warn_utf8++;
    $val =~ s/\n/\\n/g;
    $val =~ s/\r/\\r/g;
    print "#   \$Config{$cfgvar} looks broken: [$val]\n";
  }
  ok($c->native($prop), qr/^(?:1|2|4|8|12|16)$/);
}

ok($c->native('EnumSize'), qr/^(?:-1|0|1|2|4|8)$/);

ok($c->native('ByteOrder'), qr/^(?:Big|Little)Endian$/);
ok($c->native('ByteOrder'), byte_order());

ok($c->native('UnsignedChars'), qr/^(?:0|1)$/);
ok($c->native('UnsignedBitfields'), qr/^(?:0|1)$/);

$nh1 = $c->native;
$nh2 = Convert::Binary::C::native();

ok(join(':', sort keys %$nh1), join(':', sort keys %$nh2));

for (keys %$nh1) {
  ok($nh1->{$_}, $nh2->{$_});
  ok($nh1->{$_}, $c->native($_));
}

sub byte_order
{
  my $byteorder = $Config{byteorder} || unpack( "a*", pack "L", 0x34333231 );
  $byteorder eq '4321' || $byteorder eq '87654321' ? 'BigEndian' : 'LittleEndian';
}
