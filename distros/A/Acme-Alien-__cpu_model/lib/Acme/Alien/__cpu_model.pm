use strict;
use warnings;
package Acme::Alien::__cpu_model;

# ABSTRACT: Provides the __cpu_mode symbol
our $VERSION = '0.001'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Acme::Alien::__cpu_model - Provides the __cpu_model symbol


=head1 SYNOPSIS

    use ExtUtils::MakeMaker;
    WriteMakefile(
        # ...

        LIBS => Acme::Alien::__cpu_model->libs,
    );


=head1 DESCRIPTION

Older GCCs, and some recent Clangs, like my Apple LLVM 8.0.0 (clang-800.0.42.1), lack the C<__cpu_model> builtin, which some libraries like GLFW depend on.

This package provides a useless definition, that allows packages using GLFW on such a system to link. As long you don't use any function, that depends on the exact value of C<__cpu_model>, all should be well.

=head1 IMPLEMENTATION

    const struct __processor_model {
      unsigned int __cpu_vendor;
      unsigned int __cpu_type;
      unsigned int __cpu_subtype;
      unsigned int __cpu_features[1];
    } __cpu_model;

An archive is created with a single (non-COMMON) __cpu_model symbol


=cut

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-__cpu_model>

=head1 SEE ALSO

L<Graphics::Raylib::XS> for a package that depends on it to build correctly on some systems.

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
