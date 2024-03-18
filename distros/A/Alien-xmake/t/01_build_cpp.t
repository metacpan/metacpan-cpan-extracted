use strict;
use warnings;
use lib 'lib', '../blib/lib', '../lib';
use Test2::V0;
use File::Temp qw[tempdir];
use Env        qw[@PATH];
#
use Alien::xmake;
#
{
    my $dir = tempdir();
    chdir $dir;
    unshift @PATH, Alien::xmake->bin_dir;
    my $exe = Alien::xmake->exe;
    note $exe;
    system $exe, qw[create --quiet --project=test_cpp --language=c++ --template=console];
    ok( ( -d 'test_cpp' ), 'project created' );
    chdir 'test_cpp';
    subtest compile => sub {
        my $todo = todo 'Require a working compiler';    # outside the scope of Alien::xmake
        diag 'Building project..';
        ok !system( $exe, '--quiet' ), 'project built';
        my $greeting = `$exe run`;
        ok $greeting =~ /hello world!/, 'project says hello';
    }
}
#
done_testing;
