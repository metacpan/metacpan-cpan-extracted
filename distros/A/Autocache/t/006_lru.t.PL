use Module::Build;
my $filename = shift;

my $mb = Module::Build->current();

if( $mb->feature( 'memory_lru' ) )
{
    qx/link $filename.X $filename/;
}
