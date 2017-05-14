use strict;
use warnings;
use Data::Dumper::Concise::Sugar;

use Data::Dumper::Concise ();

use Test::More qw(no_plan);

my $warned_string;

BEGIN {
   $SIG{'__WARN__'} = sub {
      $warned_string = $_[0]
   }
}

DWARNL: {
   my @foo = DwarnL 'warn', 'friend';
   is $warned_string,qq{"warn"\n"friend"\n}, 'DwarnL warns';

   ok eq_array(\@foo, ['warn','friend']), 'DwarnL passes through correctly';
}

DWARNS: {
   my $bar = DwarnS 'robot',2,3;
   is $warned_string,qq{"robot"\n}, 'DwarnS warns';
   is $bar, 'robot', 'DwarnS passes through correctly';
}

DWARN: {
   my @foo = Dwarn 'warn', 'friend';
   is $warned_string,qq{"warn"\n"friend"\n}, 'Dwarn warns lists';

   ok eq_array(\@foo, ['warn','friend']), 'Dwarn passes lists through correctly';

   my $bar = Dwarn 'robot',2,3;
   is $warned_string,qq{"robot"\n2\n3\n}, 'Dwarn warns scalars correctly';
   is $bar, 'robot', 'Dwarn passes scalars through correctly';
}

DWARN_CODEREF: {
   my $foo = ['warn', 'friend']->$Dwarn;
   like $warned_string,qr{^\[\n  "warn",\n  "friend",?\n\]\n\z}, 'Dwarn warns lists';

   ok eq_array($foo, ['warn','friend']), 'Dwarn passes lists through correctly';
}

DWARNF: {
   my @foo = DwarnF { "arr: $_[0] str: $_[1]" } [qw(wut HALP)], "gnarl";

   like($warned_string, qr{^arr: \[\n  "wut",\n  "HALP",?\n\]\n str: "gnarl"\n\z}, 'DumperF works!');
   ok eq_array($foo[0], ['wut','HALP']) && $foo[1] eq 'gnarl', 'DwarnF passes lists through correctly';
}

DWARNN: {
   my $loaded = eval { require Devel::ArgNames; 1 };
   if ($loaded) {
      my $x = [1];
      my $foo = DwarnN $x;
      like $warned_string, qr{^\$x => \[\n  1,?\n\]\n\z}, 'DwarnN warns';

      ok eq_array($foo, [1]), 'DwarnN passes through correctly';

      DwarnN [1];
      like $warned_string, qr{^\(anon\) => \[\n  1,?\n\]\n\z}, 'DwarnN warns';
   }
}

DDIE: {
   eval {
      DdieS [ 'k', 'bar' ];
   };
   like $@, qr{^\[\n  "k",\n  "bar",?\n\]\n\z}, 'DwarnD dies output correctly';
}

