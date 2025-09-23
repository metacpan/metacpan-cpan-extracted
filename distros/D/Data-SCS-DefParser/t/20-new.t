#!perl

use lib 'lib';
use Test2::V0 -target => 'Data::SCS::DefParser';

use Archive::SCS::GameDir;
use List::Util 1.33 qw( any );
use Path::Tiny qw( path );

my $parser;

# mount / parse, arity

$parser = CLASS->new(
  mount => [qw( t/fixtures/new-bar )],
  parse => 'foo1.sii',
);
is $parser->raw_data->{foobar}{foo}, 'bar', 'mount one, parse string';

$parser = CLASS->new(
  mount => [qw( t/fixtures/new-bar )],
  parse => [qw( foo1.sii foo2.sii )],
);
is $parser->raw_data->{foobar}{foo}, 'bar', 'mount one, parse array';

$parser = CLASS->new(
  mount => [qw( t/fixtures/new-bar t/fixtures/new-baz )],
  parse => 'foo2.sii',
);
is $parser->raw_data->{foobar}{foo}, undef, 'mount two, parse string: no foo1';
is $parser->raw_data->{foobaz}{foo}, 'baz', 'mount two, parse string: foo2';

$parser = CLASS->new(
  mount => [qw( t/fixtures/new-bar t/fixtures/new-baz )],
  parse => [qw( foo1.sii foo2.sii )],
);
is $parser->raw_data->{foobar}{foo}, 'bar', 'mount two, parse array: foo1';
is $parser->raw_data->{foobaz}{foo}, 'baz', 'mount two, parse array: foo2';

# mount / parse, zero arity

ok dies { CLASS->new( parse => [] ) }, 'parse empty dies';
ok dies { CLASS->new( mount => [] ) }, 'mount empty dies';

ok dies { CLASS->new( mount => undef ) }, 'mount undef dies';
ok dies { CLASS->new }, 'mount unset dies';

# The implication of an empty array would be that the parser can't actually
# parse anything. That doesn't make sense; it's almost certainly a usage error.
# There is no default value for mount, but an explicit empty string will
# auto-detect the installed game using Archive::SCS::GameDir (see below).

# mount: archive

my $archive = Archive::SCS->new;
$archive->mount('t/fixtures/new-baz');
$parser = CLASS->new( mount => $archive, parse => 'foo2.sii' );
is [$parser->mounts], [], 'mount archive: mounts list empty';
is $parser->raw_data->{foobaz}{foo}, 'baz', 'mount archive: foo2';

{ my $todo = todo 'Archive::SCS offers no list of mounts';
$archive->mount('t/fixtures/dlc-suffix/dlc_az');
$parser = CLASS->new( mount => $archive, parse => 'def/city.sii' );
is [keys $parser->raw_data->{city}->%*], ['ehrenberg'], 'mount archive: dlc suffix';
}

# mount: source path

$parser = CLASS->new( mount => 't/fixtures/new-bar' );
is [$parser->mounts], [], 'mount source path, no def/dlc mounts';

$parser = CLASS->new( mount => 't/fixtures/class-company' );
is [$parser->mounts], ['t/fixtures/class-company'], 'mount source path, single legacy def mount';

$parser = CLASS->new( mount => 't/fixtures/dlc-suffix' );
is [$parser->mounts], [qw(
  t/fixtures/dlc-suffix/def
  t/fixtures/dlc-suffix/dlc_az
)], 'mount source path, multiple regular def/dlc mounts';

###### note for docs: if you explicitly give a scalar string which is a valid path to a dir, it must be the path to a dir that contains the archives to be mounted (e.g. game dir or legacy sii dir); GameDir will NOT be used; to specifically mount a single directory, you need to use [] (or pass a Archive::SCS instance)

ok dies { CLASS->new( mount => 't' ) }, 'mount source path no slash dies';
ok lives { CLASS->new( mount => 't/' ) }, 'mount source path with slash';
ok lives { CLASS->new( mount => path 't' ) }, 'mount source Path::Tiny';

# mount: abstract

ok dies { CLASS->new( mount => 'doesnt/exist' ) }, 'mount game dir, not found dies';

SKIP: {
  skip 'no Steam library install found', 1 unless Archive::SCS::GameDir->new->path;

  $parser = CLASS->new( mount => '' );
  is +( any { m|/def\.scs$| } $parser->mounts ), T(), 'mount empty string, found install';
}

done_testing;
