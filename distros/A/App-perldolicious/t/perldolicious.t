use strict;
use warnings;

use Test::More;
use Test::Mojo;

use FindBin ();
use File::Spec;
use File::Which ();

my $script = "$FindBin::Bin/../bin/perldolicious";
require $script;

pass;

plan skip_all => 'cpandoc is not installed'
  unless File::Which::which('cpandoc');

plan skip_all => "don't have cache file"
  unless (
    -f File::Spec->catfile($ENV{HOME}, '.perldolicious', 'modules.storable'));

my $ua = Test::Mojo->new;

$ua->get_ok('/')->status_is(200)->content_like(qr/Search modules/);

$ua->post_ok('/results', form => {pattern => '^Mojolicious$'})
  ->status_is(200)
  ->content_like(qr{Found 1 matches for <code>\^Mojolicious\$</code>});

$ua->post_ok('/results', form => {pattern => 'GGGGGGgggggxxxxsss'})
  ->status_is(500)->content_like(qr/Could not find/);

$ua->post_ok('/results', form => {pattern => '[pattern'})->status_is(500)
  ->content_like(qr/Invalid regular expression/);

$ua->get_ok('/doc/Mojolicious')->status_is(200)
  ->content_like(qr/Mojolicious - Real-time web framework/);

$ua->get_ok('/doc/Mojolicious/source')->status_is(200)
  ->content_like(qr/Fry: Shut up and take my money!/);

done_testing;
