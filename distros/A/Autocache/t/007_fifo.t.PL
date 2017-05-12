use Module::Build;
my $filename = shift;

my $mb = Module::Build->current();

if( $mb->feature( 'eviction_fifo' ) )
{
    qx/link $filename.X $filename/;
}
