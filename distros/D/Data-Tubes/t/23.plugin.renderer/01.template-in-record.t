use strict;

# vim: ts=3 sts=3 sw=3 et ai ft=perl :

use Test::More;
use Data::Dumper;
use Test::Exception;

use Data::Tubes qw< summon >;

summon('Renderer::with_template_perlish');
ok __PACKAGE__->can('with_template_perlish'),
  "summoned with_template_perlish";

my $structured = {
   what   => 'ever',
   you    => 'like',
   please => 'do',
};
my $target_string = "Have you ever felt like you have to do something?\n";

{
   my $template = <<'END';
Have you [% what %] felt [% you %] you have to [% please %] something?
END
   my $rend = with_template_perlish(
      template       => 'BOOOOH!',
      template_input => 'template'
   );
   my $record = $rend->(
      {
         structured => $structured,
         template   => $template
      }
   );
   is ref($record), 'HASH', 'default stuff, record is a hash';
   is_deeply $record,
     {
      structured => $structured,
      rendered   => $target_string,
      template   => $template
     },
     'template passed in record';

   $record = $rend->({structured => $structured});
   is ref($record), 'HASH', 'default stuff, record is a hash';
   is_deeply $record,
     {
      structured => $structured,
      rendered   => 'BOOOOH!',
     },
     'template missing in record, fallback';
}

{
   my $template = <<'END';
Have you [% what %] felt [% you %] you have to [% please %] something?
END
   my $rend = with_template_perlish(template_input => 'template');
   my $record = $rend->(
      {
         structured => $structured,
         template   => $template
      }
   );
   is ref($record), 'HASH', 'default stuff, record is a hash';
   is_deeply $record,
     {
      structured => $structured,
      rendered   => $target_string,
      template   => $template
     },
     'template passed in record, only allowed alternative';

   dies_ok { $rend->({structured => $structured}); }
   'complains if no template at all';
   is ref($@), 'HASH', 'dies with a hash';
   is $@->{message}, 'undefined template', 'thrown message';
}

done_testing();

