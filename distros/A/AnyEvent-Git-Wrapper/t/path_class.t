use strict;
use warnings;
use Test::More;

use File::Temp qw(tempdir);
use AnyEvent::Git::Wrapper;
use POSIX qw(strftime);
use Sort::Versions;
use Test::Deep;
use Test::Exception;

eval "use Path::Class 0.19; 1" or plan skip_all =>
    "Path::Class 0.19 is required for this test.";

my $tempdir = tempdir(CLEANUP => 1);

my $dir = Path::Class::dir($tempdir);

my $git = AnyEvent::Git::Wrapper->new($dir);

my $version = $git->version;
if ( versioncmp( $git->version , '1.5.0') eq -1 ) {
  plan skip_all =>
    "Git prior to v1.5.0 doesn't support 'config' subcmd which we need for this test."
}

$git->init; # 'git init' also added in v1.5.0 so we're safe

$git->config( 'user.name'  , 'Test User'        );
$git->config( 'user.email' , 'test@example.com' );

# make sure git isn't munging our content so we have consistent hashes
$git->config( 'core.autocrlf' , 'false' );
$git->config( 'core.safecrlf' , 'false' );

my $foo = $dir->subdir('foo');
$foo->mkpath;

$foo->file('bar')->spew(iomode => '>:raw', "hello\n");

is_deeply(
  [ $git->ls_files({ o => 1 }) ],
  [ 'foo/bar' ],
);

$git->add(Path::Class::dir('.'));
is_deeply(
  [ $git->ls_files ],
  [ 'foo/bar' ],
);

$git->commit({ message => "FIRST\n\n\tBODY\n" });

my $baz = $dir->file('baz');

$baz->spew("world\n");

$git->add($baz);

ok(1);

done_testing();
