package Alien::ggml;

use 5.008003;
use strict;
use warnings;
use parent 'Alien::Base';

=head1 NAME

Alien::ggml - Find or build the ggml tensor library

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Alien::ggml;
    use ExtUtils::MakeMaker;
    
    WriteMakefile(
        NAME         => 'MyXSModule',
        VERSION_FROM => 'lib/MyXSModule.pm',
        CONFIGURE_REQUIRES => {
            'Alien::ggml' => 0,
        },
        LIBS => [ Alien::ggml->libs ],
        INC  => Alien::ggml->cflags,
    );

Or with Alien::Base::Wrapper:

    use Alien::Base::Wrapper qw( Alien::ggml !export );
    use ExtUtils::MakeMaker;
    
    WriteMakefile(
        NAME         => 'MyXSModule',
        Alien::Base::Wrapper->mm_args,
    );

=head1 DESCRIPTION

Alien::ggml finds or builds the ggml tensor library, which is the
foundation of llama.cpp and other LLM inference engines. ggml provides
efficient tensor operations with support for various backends:

=over 4

=item * CPU with SIMD optimizations (SSE, AVX, NEON)

=item * Apple Metal (macOS/iOS GPU)

=item * NVIDIA CUDA

=item * Vulkan

=item * OpenCL

=back

This Alien module will first check if ggml is installed on your system.
If not found, it will download and build ggml from source.

=head1 METHODS

All methods are inherited from L<Alien::Base>.

=head2 cflags

    my $cflags = Alien::ggml->cflags;

Returns the compiler flags needed to compile against ggml.
Typically includes C<-I/path/to/ggml/include>.

=head2 libs

    my $libs = Alien::ggml->libs;

Returns the linker flags needed to link against ggml.
Typically includes C<-L/path/to/lib -lggml -lggml-base -lggml-cpu>.

=head2 dynamic_libs

    my @libs = Alien::ggml->dynamic_libs;

Returns a list of dynamic library paths for ggml.

=head2 install_type

    my $type = Alien::ggml->install_type;

Returns either C<system> if using a system-installed ggml, or
C<share> if ggml was built from source.

=head1 BUILDING FROM SOURCE

When no system ggml is found, Alien::ggml will download and build
ggml from source. This requires:

=over 4

=item * C compiler (gcc, clang)

=item * CMake 3.14+

=item * Make or Ninja

=back

Platform-specific optimizations are enabled automatically:

=over 4

=item * B<macOS>: Metal GPU support, Accelerate BLAS

=item * B<Linux>: OpenBLAS (if available)

=back

=head1 ENVIRONMENT VARIABLES

=head2 ALIEN_GGML_SHARE

Force building from source even if system ggml is found:

    ALIEN_GGML_SHARE=1 cpanm Alien::ggml

=head1 SEE ALSO

L<Alien::Base> - Base class for Alien modules

L<Lugh> - LLM inference engine using ggml

L<https://github.com/ggerganov/ggml> - ggml source code

L<https://github.com/ggerganov/llama.cpp> - llama.cpp (uses ggml)

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-ggml at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-ggml>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION E<lt>email@lnation.orgE<gt>.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut

1;
