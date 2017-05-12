use Test::More;
use Beagle::Backend;

my $backend = Beagle::Backend->new( root => 'fake' );

for my $sub (qw/type root encoded_root create read update delete/) {
    can_ok( $backend, $sub );
}

isa_ok( $backend, 'Beagle::Backend::fs', 'default backend is git' );
is( $backend->type, 'fs',  'no .git, type is fs' );
is( $backend->root, 'fake', 'root is set' );

$backend = Beagle::Backend->new( type => 'fs', root => 'fake' );
isa_ok( $backend, 'Beagle::Backend::fs', 'backend is set to fs' );
is( $backend->type, 'fs', 'type is set to git' );

$backend = Beagle::Backend->new( type => 'git', root => 'fake' );
isa_ok( $backend, 'Beagle::Backend::git', 'backend is set to git' );
is( $backend->type, 'git', 'type is set to git' );

done_testing();
