use strict;
use warnings;
use utf8;
use Test::More;
use Test::Command;
use File::Spec;
use File::Path qw(make_path remove_tree);

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/optex');
my $home = File::Spec->rel2abs('t/home');

$ENV{HOME} = $home;
my $optex_root = $ENV{OPTEX_ROOT} = "$home/_optex.d";
my $bindir = "${optex_root}/bin";
$ENV{PATH} = "${bindir}:/bin:/usr/bin";

my $echo = command('echo', '-M');
is( $echo->stdout_value, "-M\n", 'no-module' );

my $echo_n = command('echo-n', 'yes');
is( $echo_n->stdout_value, 'yes', 'alias' );

my $hello = command('hello');
is( $hello->stdout_value, "hello  world", 'alias string' );


## make bin directory
make_path $bindir or die "mkdir: $!";

## symlink to perl for '/usr/bin/env perl' to work.
symlink $^X, "${bindir}/perl" or die "symlink $^X: $!";

## command links
for my $command (qw(echo echo-n)) {
    my $file = "${bindir}/${command}";
    symlink $bin, $file or die "symlink $file: $!";
}

stdout_is_eq( [ 'echo', '-M' ], "-M\n", 'symlink, no-module' );

stdout_is_eq( [ 'echo-n',  'yes' ], "yes", 'symlink, alias' );

## remove entire bin directory
File::Path::remove_tree $bindir or warn "$bindir: $!";

done_testing;

sub command {
    Test::Command->new( cmd => [ $^X, "-I$lib", $bin, @_ ]);
}
