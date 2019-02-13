#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use App::AVR::Fuses;

sub capture(&)
{
   my $code = shift;

   open my $fh, ">", \my $output;
   my $was_outfh = select;
   select $fh;

   $code->();

   select $was_outfh;

   return $output;
}

# ATtiny84 default
is( capture {
      App::AVR::Fuses->run(qw( -p ATtiny84 -v ));
   },
   <<'EOF',
using SELFPRGEN=1
using RSTDISBL=1
using DWEN=1
using SPIEN=0
using WDTON=1
using EESAVE=1
using BODLEVEL=DISABLED - Brown-out detection disabled
using CKDIV8=0
using CKOUT=1
using SUT_CKSEL=INTRCOSC_8MHZ_6CK_14CK_64MS_DEFAULT - Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms; default value
-U efuse:w:0xFF:m -U hfuse:w:0xDF:m -U lfuse:w:0x62:m
EOF
   'ATtiny84 defaults'
);

# ATmega328 default
is( capture {
      App::AVR::Fuses->run(qw( -p ATmega328 -v ));
   },
   <<'EOF',
using BODLEVEL=DISABLED - Brown-out detection disabled
using RSTDISBL=1
using DWEN=1
using SPIEN=0
using WDTON=1
using EESAVE=1
using BOOTSZ=2048W_3800 - Boot Flash size=2048 words start address=$3800
using BOOTRST=1
using CKDIV8=0
using CKOUT=1
using SUT_CKSEL=INTRCOSC_8MHZ_6CK_14CK_65MS - Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 65 ms
-U efuse:w:0xFF:m -U hfuse:w:0xD9:m -U lfuse:w:0x62:m
EOF
   'ATmega328 defaults'
);

# ATmega328 list BODLEVEL
is( capture {
      App::AVR::Fuses->run(qw( -p ATmega328 BODLEVEL=? ));
   },
   <<'EOF',
Possible values for BODLEVEL are:
  4V3 - Brown-out detection at VCC=4.3 V
  2V7 - Brown-out detection at VCC=2.7 V
  1V8 - Brown-out detection at VCC=1.8 V
  DISABLED - Brown-out detection disabled
EOF
   'ATmega328 list BODLEVEL'
);

done_testing;
