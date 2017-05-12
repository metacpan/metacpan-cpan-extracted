use strict;
use warnings;
use Cwd;
use App::Implode;
use Test::More;

my $script = 'bin/implode';
plan skip_all => "Cannot test without $script" unless -x $script;

$script = do $script or die "do $script: $@";
is $script, 'App::implode::cli', 'implode loaded';
$script = bless {verbose => $ENV{HARNESS_IS_VERBOSE}}, $script;

eval { $script->run; };
like $@, qr{Usage:}, 'usage';

eval { $script->run('foo'); };
like $@, qr{Cannot read}, 'invalid script';

ok !$script->dir_is_empty('t'), 'not empty: t';
ok $script->dir_is_empty('/nakjdsnlkjad8123nlkjansdad'), 'empty: /nakjdsnlkjad8123nlkjansdad';
mkdir 'exists-but-is-empty';
ok $script->dir_is_empty('exists-but-is-empty'), 'empty: exists-but-is-empty';
rmdir 'exists-but-is-empty';

my $guard = $script->chdir('t');
ok !-e $0, 'chdir';
undef $guard;
ok -e $0, 'chdir DESTROY';

like $script->code('exploder'), qr{^sub exploder.*IO::Uncompress::Bunzip2.*PERL5LIB}s, 'got exploder';

$script->{tmpdir} = getcwd;
my $tar = $script->tarball;
my %files;
isa_ok($tar, 'Archive::Tar');
$files{$_} = 1 for $tar->list_files;
ok $files{'bin/implode'},              'tar with bin/implode';
ok $files{'lib/App/Implode.pm'},       'tar with lib/App/Implode.pm';
ok $files{'lib/perl5/App/Implode.pm'}, 'tar with lib/perl5/App/Implode.pm';
is length($tar->get_content('lib/App/Implode.pm')), -s $INC{'App/Implode.pm'}, "Implode.pm size @{[-s _]}";
is $tar->get_content('lib/perl5/App/Implode.pm'), $tar->get_content('lib/App/Implode.pm'), 'Implode.pm content';

done_testing;
