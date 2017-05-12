use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Path::Tiny;
use Data::Dumper;
use Encode qw< encode decode >;

use Data::Tubes qw< summon >;

summon('Util::read_file');
ok __PACKAGE__->can('read_file'), "summoned read_file";

my $me = path(__FILE__);
my $td = $me->sibling($me->basename() . '.tmp');
$td->remove_tree() if $td->is_dir();
$td->remove()      if $td->is_file();
$td->mkpath();
END { $td->remove_tree() }

my $content_chars = "whatever \N{U+263A}";
my $content_octets =
  encode('UTF-8', $content_chars, Encode::FB_CROAK | Encode::LEAVE_SRC);

my $file = $td->child('smiley.txt');
$file->spew_raw($content_octets);

{
   my $got;
   lives_ok { $got = read_file($file->stringify()) }
   'single argument file name, lives';
   is $got, $content_chars, 'read was successful (UTF-8 auto-decode)';
}

{
   my $got;
   lives_ok { $got = read_file($file->stringify(), binmode => ':raw') }
   'standalone filename and additional key/value pair';
   is $got, $content_octets, 'read was successful (raw)';
}

{
   my $got;
   lives_ok {
      $got = read_file(filename => $file->stringify(), binmode => ':raw');
   }
   'key/value pairs';
   is $got, $content_octets, 'read was successful (raw)';
}

throws_ok { read_file(); } qr{undefined}, 'undefined filename complains';

throws_ok { read_file(''); } qr{read_file\(\) for <>},
  'empty filename complains';

throws_ok {
   local *STDERR;    # silence warning
   open STDERR, '>', \my $buffer;
   read_file($file->stringify(), binmode => 'whateeevah!');
}
qr{binmode\(\)}, 'bad binmode complains';

done_testing();
