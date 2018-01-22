use strict;
use warnings;
use utf8;
use Test::More;
use Test::Command;
use File::Spec;

my($perl_dir, $perl_name) = ($^X =~ m{ (.*) / ([^/]+) $ }x);

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/optex');
my $home = File::Spec->rel2abs('t/home');

$ENV{HOME} = $home;
my $optex_root = $ENV{OPTEX_ROOT} = "$home/_optex.d";
my $bindir = "${optex_root}/bin";
$ENV{PATH} = "${bindir}:/bin:/usr/bin";
$ENV{PATH} .= ":${perl_dir}" if $perl_dir;

my $echo = command('echo', '-M');
is( $echo->stdout_value, "-M\n", 'no-module' );

my $echo_n = command('echo-n', 'yes');
is( $echo_n->stdout_value, 'yes', 'alias' );

my $hello = command('hello');
is( $hello->stdout_value, "hello  world", 'alias string' );

system "mkdir -p $bindir" unless -d $bindir;
for my $command (qw(echo echo-n)) {
    my $file = "${bindir}/${command}";
    unless (-l $file) {
    	symlink $bin, $file;
    }
}

stdout_is_eq( [ 'echo', '-M' ], "-M\n", 'symlink, no-module' );

stdout_is_eq( [ 'echo-n', 'yes' ], "yes", 'symlink, alias' );

done_testing;

sub command {
    Test::Command->new( cmd => [ $^X, "-I$lib", $bin, @_ ]);
}
