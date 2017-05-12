use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;
use Path::Tiny;

use Data::Tubes qw< summon >;

my @functions = qw<
  render_with_template_perlish
>;
summon(['Renderer', @functions]);
ok __PACKAGE__->can($_), "summoned $_" for @functions;

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
   my $rend = render_with_template_perlish(template => $template);
   my $record = $rend->({structured => $structured});
   is ref($record), 'HASH', 'default stuff, record is a hash';
   is_deeply $record,
     {structured => $structured, rendered => $target_string},
     'default stuff, rendering of the string';
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you have to {{ please }} {{ new }}?
END
   my $rend = render_with_template_perlish(
      template  => $template,
      input     => 'foo',
      output    => 'bar',
      start     => '{{',
      stop      => '}}',
      variables => {
         what => 'XXXX',         # overridden by data in record
         new  => 'something',    # preserved
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH', 'custom stuff, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'custom stuff, rendering of the string';
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you have to {{ please }} {{ new }}?
END
   my $rend = render_with_template_perlish(
      template  => [\$template],    # as "filename"
      input     => 'foo',
      output    => 'bar',
      start     => '{{',
      stop      => '}}',
      variables => {
         what => 'XXXX',            # overridden by data in record
         new  => 'something',       # preserved
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH',
     'custom & in-memory filename, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'custom & in-memory filename, rendering of the string';
}

{
   my $me = path(__FILE__);
   my $tf = $me->sibling($me->basename() . '.tmp');
   $tf->remove() if $tf->exists();
   $tf->spew_raw(<<'END');
Have you {{ what }} felt {{ you }} you have to {{ please }} {{ new }}?
END

   my $rend = render_with_template_perlish(
      template  => [$tf->stringify()],    # as "filename"
      input     => 'foo',
      output    => 'bar',
      start     => '{{',
      stop      => '}}',
      variables => {
         what => 'XXXX',                  # overridden by data in record
         new  => 'something',             # preserved
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH', 'custom & real filename, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'custom & real filename, rendering of the string';

   $tf->remove();
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you have to {{ please }} {{ new }}?
END
   my $rend = render_with_template_perlish(
      $template,
      input     => 'foo',
      output    => 'bar',
      start     => '{{',
      stop      => '}}',
      variables => {
         what => 'XXXX',         # overridden by data in record
         new  => 'something',    # preserved
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH', 'implicit custom stuff, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'implicit custom stuff, rendering of the string';
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you have to {{ please }} {{ new }}?
END
   my $rend = render_with_template_perlish(
      [\$template],    # as "filename"
      input     => 'foo',
      output    => 'bar',
      start     => '{{',
      stop      => '}}',
      variables => {
         what => 'XXXX',         # overridden by data in record
         new  => 'something',    # preserved
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH',
     'implicit custom & in-memory filename, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'implicit custom & in-memory filename, rendering of the string';
}

{
   my $me = path(__FILE__);
   my $tf = $me->sibling($me->basename() . '.tmp');
   $tf->remove() if $tf->exists();
   $tf->spew_raw(<<'END');
Have you {{ what }} felt {{ you }} you have to {{ please }} {{ new }}?
END

   my $rend = render_with_template_perlish(
      [$tf->stringify()],    # as "filename"
      input     => 'foo',
      output    => 'bar',
      start     => '{{',
      stop      => '}}',
      variables => {
         what => 'XXXX',         # overridden by data in record
         new  => 'something',    # preserved
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH',
     'implicit custom & real filename, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'implicit custom & real filename, rendering of the string';

   $tf->remove();
}

require Template::Perlish;
my $tp = Template::Perlish->new(
   start     => '{{',
   stop      => '}}',
   variables => {
      what => 'XXXX',         # overridden by data in record
      new  => 'something',    # preserved
   },
);
$target_string = "Have you ever felt like you [[have]] to do something?\n";

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you [[have]] to {{ please }} {{ new }}?
END

   my $rend = render_with_template_perlish(
      template         => $template,
      input            => 'foo',
      output           => 'bar',
      template_perlish => $tp,
      start            => '[[',        # ignored
      stop             => ']]',        # ignored
      variables        => {            # ignored
         have => 'boooo',
         what => 'XXXX',
         new  => 'whatever',
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH', 'custom template_perlish, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'custom template_perlish, rendering of the string';
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you [[have]] to {{ please }} {{ new }}?
END
   $template = $tp->compile($template);

   my $rend = render_with_template_perlish(
      template         => $template,
      input            => 'foo',
      output           => 'bar',
      template_perlish => $tp,
      start            => '[[',        # ignored
      stop             => ']]',        # ignored
      variables        => {            # ignored
         have => 'boooo',
         what => 'XXXX',
         new  => 'whatever',
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH',
     'pre-compiled, custom template_perlish, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'pre-compiled, custom template_perlish, rendering of the string';
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you [[have]] to {{ please }} {{ new }}?
END
   $template = $tp->compile($template);

   my $rend = render_with_template_perlish(
      template  => $template,
      input     => 'foo',
      output    => 'bar',
      start     => '[[',        # ignored
      stop      => ']]',        # ignored
      variables => {            # ignored
         have => 'boooo',
         what => 'XXXX',
         new  => 'whatever',
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH',
     'pre-compiled, no custom template_perlish, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'pre-compiled, no custom template_perlish, rendering of the string';
}

{
   my $template = <<'END';
Have you {{ what }} felt {{ you }} you [[have]] to {{ please }} {{ new }}?
END
   $template = $tp->compile($template, no_check => 1);
   my $target_string =
     "Have you ever felt like you [[have]] to do whatever?\n";

   my $rend = render_with_template_perlish(
      template  => $template,
      input     => 'foo',
      output    => 'bar',
      start     => '[[',        # ignored
      stop      => ']]',        # ignored
      variables => {            # considered!!!
         have => 'boooo',
         what => 'XXXX',
         new  => 'whatever',    # this wins
      },
   );
   my $record = $rend->({foo => $structured});
   is ref($record), 'HASH',
     'pre-compiled, no custom template_perlish, record is a hash';
   is_deeply $record,
     {foo => $structured, bar => $target_string},
     'pre-compiled, no custom template_perlish, rendering of the string';
}

done_testing();
