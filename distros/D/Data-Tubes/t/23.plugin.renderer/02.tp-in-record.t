use strict;

# vim: ts=3 sts=3 sw=3 et ai ft=perl :

use Test::More;
use Data::Dumper;
use Test::Exception;

use Data::Tubes qw< summon >;
use Template::Perlish;

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
Have you {{ what }} felt {{ you }} you have to {{ please }} something?
END
   my $tp = Template::Perlish->new(start => '{{', stop => '}}');
   my $rend = with_template_perlish(
      template               => $template,
      template_perlish_input => 'template_perlish',
   );
   my $record = $rend->(
      {
         structured       => $structured,
         template_perlish => $tp,
      }
   );
   is ref($record), 'HASH', 'default stuff, record is a hash';
   is_deeply $record,
     {
      structured       => $structured,
      rendered         => $target_string,
      template_perlish => $tp,
     },
     'default stuff, rendering of the string';
}

{
   my $template = <<'END';
Have you [% what %] felt [% you %] you have to [% please %] something?
END
   my $rend = with_template_perlish(
      template               => $template,
      template_perlish_input => 'template_perlish',
   );
   my $record = $rend->(
      {
         structured => $structured,
      }
   );
   is ref($record), 'HASH', 'default stuff, record is a hash';
   is_deeply $record,
     {
      structured => $structured,
      rendered   => $target_string,
     },
     'default stuff, rendering of the string';
}

{
   throws_ok {
      with_template_perlish(template_perlish_input => 'template_perlish');
   }
   qr{undefined template}, 'complains with missing template';
}

done_testing();

