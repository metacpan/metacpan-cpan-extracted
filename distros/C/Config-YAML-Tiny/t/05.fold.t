use Test::More tests => 2;
use Config::YAML::Tiny;

@config{ "attrib1", "attrib2" } = qw(37 foo);

my $c = Config::YAML::Tiny->new( config => 't/test.yaml' );
$c->fold( \%config );
ok( $c->{attrib1} == 37 );
ok( $c->{attrib2} eq 'foo', "Folding from hash works." );
