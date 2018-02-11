use strict;
use warnings;
use utf8;
use Test::More;
use Test::Command;
use File::Spec;
use File::Path qw(make_path remove_tree);
use IO::File;

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/optex');
my $home = File::Spec->rel2abs('t/home');

sub command {
    Test::Command->new( cmd => [ $^X, "-I$lib", $bin, @_ ]);
}

$ENV{HOME} = $home;
my $optex_root = $ENV{OPTEX_ROOT} = "${home}/.optex.d";
my $bindir = "${optex_root}/bin";
$ENV{PATH} = "${bindir}:/bin:/usr/bin";

my $config_data = <<'END';
############################################################

no-module = [
	"echo",
]

[alias]
	double = "expr 2 *"
	hello = "echo 'hello  world'"

############################################################
END

## make root directory
unless (-d $optex_root) {
    make_path $optex_root or die "${optex_root}: make_path error\n";
}

my $config_file = "${optex_root}/config.toml";
my $fh = IO::File->new("> $config_file")
    or do { warn "${config_file}: $!"; goto FINISH };

print $fh $config_data;
$fh->close();

my $expr = command('echo', '-M');
is( $expr->stdout_value, "-M\n", 'no-module' );

my $double = command('double', '1');
is( $double->stdout_value, "2\n", 'alias' );

my $hello = command('hello');
is( $hello->stdout_value, "hello  world\n", 'alias string' );


## make bin directory
unless (-d $bindir) {
    make_path $bindir
	or do { warn "mkdir: $!"; goto FINISH };
}

## symlink to perl for '/usr/bin/env perl' to work.
symlink $^X, "${bindir}/perl"
    or do { warn "symlink $^X: $!"; goto FINISH };

## command links
for my $command (qw(echo double hello)) {
    my $file = "${bindir}/${command}";
    symlink $bin, $file
	or do { warn "symlink $file: $!"; goto FINISH };
}

stdout_is_eq( [ 'echo', '-M' ], "-M\n", 'symlink, no-module' );

stdout_is_eq( [ 'double',  '2' ], "4\n", 'symlink, alias' );

stdout_is_eq( [ 'hello' ], "hello  world\n", 'symlink, alias string' );

done_testing;

FINISH:

## remove entire root directory
File::Path::remove_tree $home or warn "${home}: $!";
