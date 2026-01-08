use v5.40;
use blib;
use Test2::V0 -no_srand => 1;
use Alien::Xmake;
use File::Temp qw[tempdir];
#
my $xmake = Alien::Xmake->new;
diag 'Install type:  ' . $xmake->install_type;
diag 'Xmake version: ' . $xmake->version;
use Capture::Tiny qw[capture];
#
subtest xmake => sub {
    my $exe = $xmake->exe;
    diag 'Path to exe:  ' . $exe;
    my ( $stdout, $stderr, $exit ) = capture { system $exe, '--version' };
    is $exit, 0, $exe . ' --version';
    diag $stdout if length $stdout;
    diag $stderr if length $stderr;
};
#
subtest xrepo => sub {
    my $exe = $xmake->xrepo;
    diag 'Path to exe:  ' . $exe;
    my ( $stdout, $stderr, $exit ) = capture { system $exe, '--version' };
    is $exit, 0, $exe . ' --version';
    diag $stdout if length $stdout;
    diag $stderr if length $stderr;
};
#
done_testing;
