use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw/tempdir/;
use lib 't/lib';
use TestConfig;

my $config_dirname = tempdir( CLEANUP => !$ENV{CONFIG_GITLIKE_DEBUG} );
my $config_filename = File::Spec->catfile( $config_dirname, 'config' );

diag "config file is: $config_filename" if $ENV{TEST_VERBOSE};

my $config
    = TestConfig->new( confname => 'config', tmpdir => $config_dirname );
$config->load;

# Test add_comment.
$config->add_comment(
    filename => $config_filename,
    comment  => 'yo dawg',
);
my $expect = "# yo dawg\n";
is( $config->slurp, $expect, 'comment' );

# Make sure leading whitespace is maintained.
$config->add_comment(
    filename => $config_filename,
    comment  => '   for you.'
);

$expect .= "#    for you.\n";
is( $config->slurp, $expect, 'comment with ws' );

# Make sure it interacts well with configuration.
$config->set(
    key      => 'core.penguin',
    value    => 'little blue',
    filename => $config_filename
);

$config->add_comment(
    filename => $config_filename,
    comment  => "this is\n  for you\n  \n  you know",
    indented => 1,
);

$expect = <<'EOF'
# yo dawg
#    for you.
[core]
	penguin = little blue
# this is
  # for you
  # 
  # you know
EOF
    ;
is( $config->slurp, $expect, 'indented comment with newlines and config' );

$config->add_comment(
    filename  => $config_filename,
    comment   => '  gimme a semicolon',
    semicolon => 1,
);
$expect .= ";   gimme a semicolon\n";
is( $config->slurp, $expect, 'comment with semicolon' );

done_testing;
