use strict;
use warnings;
use Test::More;
BEGIN {
  eval 'use Test::CheckManifest 0.09; 1'
    or plan skip_all => 'Test::CheckManifest 0.09 not installed';
}

ok_manifest({
  exclude => ['/t/var', '/cover_db'],
  filter  => [qr/\.(svn|git)/, qr/cover/, qr/Build(.(PL|bat))?/, qr/_build/, qr/\.DS_Store/],
  bool    => 'or'
});
