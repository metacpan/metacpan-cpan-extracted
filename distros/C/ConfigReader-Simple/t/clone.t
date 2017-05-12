use Test::More tests => 17;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class = 'ConfigReader::Simple';
use_ok( $class );
can_ok( $class, qw(clone new_from_prototype) );

my @Directives = qw( Test1 Test2 Test3 Test4 );

my $config = $class->new( "t/example.config", \@Directives );
isa_ok( $config, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# can we clone the object?
# this should be a deep copy
my $clone = $config->clone;
isa_ok( $clone, $class );

my $proto = $config->new_from_prototype;
isa_ok( $proto, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# can we change the clone without affecting the original?
{
my $Test1_value = 'Kundry';
$clone->set( 'Test1', $Test1_value );
is( $clone->Test1, $Test1_value,
	'Cloned object has right value after change' );
isnt( $config->Test1, $Test1_value,
	'Original object has right value after clone change' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# can we change the original without affecting the clone?
{
my $Test2_value = 'Second Squire';
$config->set( 'Test2', $Test2_value );
is( $config->Test2, $Test2_value,
	'Original object has right value after change' );
isnt( $clone->Test2, $Test2_value,
	'Clone object has right value after original change' );

my @files       = $config->files;
my @clone_files = $clone->files;

is( scalar @files, 1, "Original object has 1 associated file" );
is( scalar @clone_files, 1, "Clone object has 1 associated file" );
is( $files[-1], "t/example.config", "Original object returns right file" );
is( $clone_files[-1], "t/example.config", "Clone object returns right file" );

$config->add_config_file( 't/clone.config' );

@files       = $config->files;
@clone_files = $clone->files;

is( scalar @files, 2, "Original object has 1 associated file" );
is( scalar @clone_files, 1, "Clone object has 1 associated file" );
is( $files[-1], "t/clone.config", "Original object returns right file" );
is( $clone_files[-1], "t/example.config", "Clone object returns right file" );
}
