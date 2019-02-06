package Alt::FFI::libffi;

use strict;
use warnings;

# ABSTRACT: Perl Foreign Function interface based on libffi
our $VERSION = '0.09'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alt::FFI::libffi - Perl Foreign Function interface based on libffi

=head1 VERSION

version 0.09

=head1 DESCRIPTION

This distribution provides an alternative implementation of L<FFI> that uses L<FFI::Platypus> which
in turn uses C<libffi> as the underlying implementation instead of C<ffcall>.  This may be useful,
as the underlying implementation of the original L<FFI> is C<ffcall> and is no longer supported and
is not actively developed.

=head1 ABSTRACT

 env PERL_ALT_INSTALL=OVERWRITE cpanm Alt::FFI::libffi

=head1 CAVEATS

The connecting code is all pure perl, and not especially fast.  You will likely get
better performance porting your code to L<FFI::Platypus>.  When using the C<attach> feature
of L<FFI::Platypus>, it will likely be faster than the original L<FFI> implementation.

=head1 SEE ALSO

=over 4

=item L<Alt>

=item L<FFI>

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
