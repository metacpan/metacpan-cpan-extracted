package Alien::onnxruntime;
# ABSTRACT: Discover or download and install onnxruntime (ONNX Runtime is a cross-platform inference and training machine-learning accelerator.)
use strict;
use warnings;

use base 'Alien::Base';

1;

__END__

=head1 NAME

Alien::onnxruntime

=head1 SYNOPSIS

    my $alien = Alien::onnxruntime->new;
    my $cflags = $alien->cflags;
    my $libs = $alien->libs;
    my $path = $alien->dist_dir;

The above methods are inherited from L<Alien::Base>.

Otherwise it will download a latest from L<onnxruntime|https://github.com/microsoft/onnxruntime>.

=head1 DESCRIPTION

Discover or download and install L<onnxruntime|https://github.com/microsoft/onnxruntime>

=head1 AUTHOR

Yegor Korablev <egor@cpan.org>

=head1 LICENSE

The default license of onnxruntime is MIT.

=cut
