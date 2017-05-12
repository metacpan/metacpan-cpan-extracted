package builder::MyBuilder;
use strict;
use warnings FATAL => 'all';
use 5.008008;
use base 'Module::Build::XSUtil';

sub new {
    my ( $self, %args ) = @_;
    $self->SUPER::new(
        %args,
        allow_pureperl => 1,
        c_source       => 'xs',
        xs_files       => { './xs/hyperloglog.xs' => './lib/Algorithm/HyperLogLog.xs', },
        add_to_cleanup => [
            'Algorithm-HyperLogLog-*', 'MANIFEST.bak', 'lib/Algorithm/*.o', 'lib/Algorithm/*.h',
            'lib/Algorithm/*.c',       'lib/Algorithm/*.xs',
        ],
        meta_add          => { keywords => [qw/HyperLogLog cardinality/], },
        generate_ppport_h => 'lib/Algorithm/ppport.h',
    );
}

1;
__END__
