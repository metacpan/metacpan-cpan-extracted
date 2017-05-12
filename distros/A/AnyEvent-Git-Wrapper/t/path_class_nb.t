use strict;
use warnings;
BEGIN { $^O eq 'MSWin32' ? eval q{ use Event; 1 } || q{ use EV } : eval q{ use EV } }
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

my $version = $git->version(AE::cv)->recv;
if ( versioncmp( $git->version(AE::cv)->recv , '1.5.0') eq -1 ) {
  plan skip_all =>
    "Git prior to v1.5.0 doesn't support 'config' subcmd which we need for this test."
}

$git->init(AE::cv)->recv; # 'git init' also added in v1.5.0 so we're safe

$git->config( 'user.name'  , 'Test User'        , AE::cv)->recv;
$git->config( 'user.email' , 'test@example.com' , AE::cv)->recv;

# make sure git isn't munging our content so we have consistent hashes
$git->config( 'core.autocrlf' , 'false' , AE::cv)->recv;
$git->config( 'core.safecrlf' , 'false' , AE::cv)->recv;

my $foo = $dir->subdir('foo');
$foo->mkpath;

$foo->file('bar')->spew(iomode => '>:raw', "hello\n");

$git->ls_files({o => 1 }, sub {
  my $out = shift->recv;
  
  is_deeply(
    $out,
    [ 'foo/bar' ],
    'git ls-files -o',
  );

})->recv;

$git->add(Path::Class::dir('.'), AE::cv)->recv;
$git->ls_files(sub {
  my $out = shift->recv;
  is_deeply(
    $out,
    [ 'foo/bar' ],
    'git ls-files',
  );
})->recv;

$git->commit({ message => "FIRST\n\n\tBODY\n" }, AE::cv)->recv;

my $baz = $dir->file('baz');

$baz->spew("world\n");

$git->add($baz, AE::cv)->recv;

ok(1);

done_testing;
