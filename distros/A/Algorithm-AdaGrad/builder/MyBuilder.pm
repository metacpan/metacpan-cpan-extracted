package builder::MyBuilder;
use strict;
use warnings FATAL => 'all';
use 5.008008;
use base 'Module::Build::XSUtil';

sub new {
    my ( $self, %args ) = @_;
    $self->SUPER::new(
        %args,
        add_to_cleanup => [
            'Algorithm-AdaGrad-*', 'MANIFEST.bak', 'lib/Algorithm/*.o',
        ],
        meta_add          => { keywords => [qw/AdaGrad/], },
        needs_compiler_cpp => 11,
        extra_compiler_flags => [qw/-Wno-format-security -Wno-duplicate-decl-specifier -Wno-reserved-user-defined-literal/],
    );
}

1;
__END__
