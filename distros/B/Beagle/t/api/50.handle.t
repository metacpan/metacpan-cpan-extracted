use Test::More;
use Beagle::Handle;
use Beagle::Test;
use Beagle::Util;

my ($root) = Beagle::Test->init;

my $bh = Beagle::Handle->new();
is( $bh->root, $root, 'root' );
my $name = $root;
$name =~ s!:!_!g if is_windows();
is( $bh->name, $name, 'name' );
is( $bh->type, 'fs',  'type' );
isa_ok( $bh->backend, 'Beagle::Backend::fs' );

for $method (
    qw/cache info comments map comments_map entries
    attachments_map updated sites list articles barks reviews tasks
    /
  )
{
    can_ok( $bh, $method );
}

done_testing();
