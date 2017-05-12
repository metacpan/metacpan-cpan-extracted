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
   is $warned_string,qq{[\n  "warn",\n  "friend"\n]\n}, 'Dwarn warns lists';

   ok eq_array($foo, ['warn','friend']), 'Dwarn passes lists through correctly';
}

DWARNF: {
   my @foo = DwarnF { "arr: $_[0] str: $_[1]" } [qw(wut HALP)], "gnarl";

   is($warned_string, qq{arr: [\n  "wut",\n  "HALP"\n]\n str: "gnarl"\n}, 'DumperF works!');
   ok eq_array($foo[0], ['wut','HALP']) && $foo[1] eq 'gnarl', 'DwarnF passes lists through correctly';
}

DWARNN: {
   my $loaded = eval { require Devel::ArgNames; 1 };
   if ($loaded) {
      my $x = [1];
      my $foo = DwarnN $x;
      is $warned_string, qq{\$x => [\n  1\n]\n}, 'DwarnN warns';

      ok eq_array($foo, [1]), 'DwarnN passes through correctly';

      DwarnN [1];
      is $warned_string, qq{(anon) => [\n  1\n]\n}, 'DwarnN warns';
   }
}

DDIE: {
   eval {
      DdieS [ 'k', 'bar' ];
   };
   is $@, qq{[\n  "k",\n  "bar"\n]\n}, 'DwarnD dies output correctly';
}

