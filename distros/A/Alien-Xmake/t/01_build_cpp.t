use v5.40;
use blib;
use Test2::V0 -no_srand => 1;
use File::Temp    qw[tempdir];
use Capture::Tiny qw[capture];
my $dir = tempdir();
#
use Alien::Xmake;
#
my $xmake = Alien::Xmake->new;
{
    chdir $dir;
    my ( $stdout, $stderr, $exit ) = capture { system $xmake->exe, qw[create --quiet --project=test_cpp --language=c++ --template=console] };
    ok( ( -d 'test_cpp' ), 'project created' );

    #~ ok !$exit, 'project created';
    diag $stdout if $exit && length $stdout;
    diag $stderr if $exit && length $stderr;
    chdir 'test_cpp';
    subtest compile => sub {
        my $todo = todo 'Require a working compiler';    # outside the scope of Alien::Xmake
        diag 'Building project..';
        ( $stdout, $stderr, $exit ) = capture { system $xmake->exe, '--quiet' };
        ok !$exit, 'project built';
        diag $stdout if $exit && length $stdout;
        diag $stderr if $exit && length $stderr;
        ( $stdout, $stderr, $exit ) = capture { system $xmake->exe, 'run' };
        ok $stdout =~ /hello world!/, 'project says hello';
        diag $stdout if $exit && length $stdout;
        diag $stderr if $exit && length $stderr;
    }
}
#
done_testing;
