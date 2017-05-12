use Test::More tests => 19;
use Test::Output;

my $class = 'ConfigReader::Simple';

use_ok( $class );

my @Directives = qw( Test1 Test2 Test3 Test4 );
my $config = $class->new( "t/example.config", \@Directives );
isa_ok( $config, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# set things that do exist
foreach my $pair (
	[ qw(Test1 Foo)] , [ qw(Pagagena Papageno) ], [ qw(Tamino Pamina) ] )
	{
	my $key   = $pair->[0];
	my $value = $pair->[1];

	$config->set( $key, $value );

	is( $config->get( $key ), $value,
		"$key has the right value with get" );
	is( $config->$key, $value,
		"$key has the right value with autoload" );
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setting things to references should fail: With $Die set
{
no warnings 'once';
local $ConfigReader::Simple::Die = 1;

my $config = $class->new;
isa_ok( $config, $class );

my $rc = eval { $class->set( 'Cat', \ 'Buster' ) };
my $at = $@;
ok( length $at, '$@ is set while trying to set with a scalar reference' );
like( $at, qr/must be a simple scalar/ );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setting things to references should fail: With $Die not set, $Warn set
{
no warnings 'once';
local $ConfigReader::Simple::Die  = undef;
local $ConfigReader::Simple::Warn = 1;
local $SIG{__WARN__} = sub { print STDERR @_ };

my $config = $class->new;
isa_ok( $config, $class );

stderr_like
	{ $class->set( 'Cat', \ 'Buster' ) }
	qr/must be a simple scalar/,
	'set complains when $Warn is set and given a reference';

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setting things to references should fail: With $Die not set, $Warn not set
{
no warnings 'once';
local $ConfigReader::Simple::Die  = undef;
local $ConfigReader::Simple::Warn = undef;
local $SIG{__WARN__} = sub { print STDERR @_ };

my $config = $class->new;
isa_ok( $config, $class );

stderr_like
	{ $class->set( 'Cat', \ 'Buster' ) }
	qr/^$/,
	'set silent when $Warn, $Die are unset and given a reference';

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# unset things that do exist
{
my $directive = 'Test2';

ok( $config->unset( $directive ), "Unset thing that exists [$directive]" );

my $not_defined = not defined $config->$directive;

ok( $not_defined, "Unset thing [$directive] still has value" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# unset things that do not exist
{
my $directive = 'Tenor';

my $value = not $config->unset( $directive );
ok( $value, 'Unset thing that does not exist [$directive]' );

$value = not $config->exists( $directive );
ok( $value, 'Unset thing that did not exist [$directive] exists' );
}
