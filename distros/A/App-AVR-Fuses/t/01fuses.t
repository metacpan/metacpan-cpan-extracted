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
      App::AVR::Fuses->run(qw( -p ATtiny84 ));
   },
   "-U efuse:w:0xFF:m -U hfuse:w:0xDF:m -U lfuse:w:0x62:m\n",
   'ATtiny84 defaults'
);

# ATtiny84 default by short name
is( capture {
      App::AVR::Fuses->run(qw( -p t84 ));
   },
   "-U efuse:w:0xFF:m -U hfuse:w:0xDF:m -U lfuse:w:0x62:m\n",
   'ATtiny84 defaults'
);

# ATmega328 default
is( capture {
      App::AVR::Fuses->run(qw( -p ATmega328 ));
   },
   "-U efuse:w:0xFF:m -U hfuse:w:0xD9:m -U lfuse:w:0x62:m\n",
   'ATmega328 defaults'
);

# setting boolean fuse
is( capture {
      App::AVR::Fuses->run(qw( -p ATmega328 CKDIV8=1 ));
   },
   "-U efuse:w:0xFF:m -U hfuse:w:0xD9:m -U lfuse:w:0xE2:m\n",
   'ATmega328 CKDIV8=1'
);

# setting enumerated fuse
is( capture {
      App::AVR::Fuses->run(qw( -p ATmega328 BODLEVEL=2V7 ));
   },
   "-U efuse:w:0xFD:m -U hfuse:w:0xD9:m -U lfuse:w:0x62:m\n",
   'ATmega328 BODLEVEL=2V7'
);

# overriding fuse value
is( capture {
      App::AVR::Fuses->run(qw( -p ATmega328 -f lfuse=0x6D ));
   },
   "-U efuse:w:0xFF:m -U hfuse:w:0xD9:m -U lfuse:w:0x6D:m\n",
   'ATmega328 -f lfuse=0x6D'
);

done_testing;
