package MockApp;

use Test::More tests => 10;
use Cwd;

# Remove all relevant env variables to avoid accidental fail
foreach my $name ( grep { m{^(CATALYST)} } keys %ENV ) {
    delete $ENV{ $name };
}

$ENV{ CATALYST_HOME } = cwd . '/t/mockapp';

use_ok( 'Catalyst', qw( ConfigLoader ) );

__PACKAGE__->config->{ 'Plugin::ConfigLoader' }->{ substitutions } = {
    foo => sub { shift; join( '-', @_ ); }
};

__PACKAGE__->setup;

ok( __PACKAGE__->config );
is( __PACKAGE__->config->{ 'Controller::Foo' }->{ foo }, 'bar' );
is( __PACKAGE__->config->{ 'Controller::Foo' }->{ new }, 'key' );
is( __PACKAGE__->config->{ 'Model::Baz' }->{ qux },      'xyzzy' );
is( __PACKAGE__->config->{ 'Model::Baz' }->{ another },  'new key' );
is( __PACKAGE__->config->{ 'view' },                     'View::TT::New' );
is( __PACKAGE__->config->{ 'foo_sub' },                  'x-y' );
is( __PACKAGE__->config->{ 'literal_macro' },            '__DATA__' );
is( __PACKAGE__->config->{ 'Plugin::Zot' }->{ zoot },    'zooot');
