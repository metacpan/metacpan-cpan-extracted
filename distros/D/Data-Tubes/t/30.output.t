use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;
use Path::Tiny;

use Data::Tubes::Util::Output;

{
   my $buffer = '';
   {
      my $output = Data::Tubes::Util::Output->new(
         output => \$buffer,
         header => "---\n",
         interlude => "~~~\n",
         footer => "...\n",
      );
      $output->print("whatever\n");
      $output->print("what\n", "ever\n");
   }
   my $expected = <<'END';
---
whatever
~~~
what
~~~
ever
...
END
   is $buffer, $expected, 'header, interlude, footer, auto-close';
}

{
   my @buffers;
   {
      my $output = Data::Tubes::Util::Output->new(
         output => sub {
            push @buffers, '';
            return \$buffers[-1];
         },
         header => "---\n",
         interlude => "~~~\n",
         footer => "...\n",
         policy => {
            records_threshold => 2,
         },
      );
      $output->print("whatever\n");
      $output->print("what\n", "ever\n");
   }

   my @expected;
   push @expected, <<'END';
---
whatever
~~~
what
...
END
   push @expected, <<'END';
---
ever
...
END
   is_deeply \@buffers, \@expected,
     'header, interlude, footer, policy, auto-close';
}

done_testing();
