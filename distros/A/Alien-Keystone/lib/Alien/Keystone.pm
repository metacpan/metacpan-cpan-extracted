package Alien::Keystone;
use parent 'Alien::Base';

our $VERSION = '0.03';

1;

__END__
#### COPYRIGHT: Selective Intellect LLC.
#### AUTHOR: Vikas N Kumar
#### DATE: 13 September 2016

=head1 NAME

Alien::Keystone - Perl extension to install Keystone-Engine from
L<www.keystone-engine.org>

=head1 SYNOPSIS

Alien::Keystone is a perl module that enables the installation of the open
source disassembly library Keystone-Engine from
L<http://www.keystone-engine.org> on the system or locate the existing
installation if any. It is currently setup to look for the Github master.

You can use it in the C<Build.PL> file if you're using Module::Build or
C<Makefile.PL> file if you're using ExtUtils::MakeMaker.


            use Alien::Keystone;
            # ...
            my $keystone= Alien::Keystone->new;
            my $build = Module::Build->new(
                ...
                extra_compiler_flags => $keystone->cflags(),
                extra_linker_flags => $keystone->libs(),
                ...
            );


=head1 VERSION

0.03

=head1 METHODS

=over

=item B<new>

Creates the object. Refer C<Alien::Base> for more information.

=item B<cflags>

This method provides the compiler flags needed to use the library on the system.

=item B<libs>

This method provides the linker flags needed to use the library on the system.

=back

=head1 SEE ALSO

=over

=item C<Alien::Base>

=back

=head1 AUTHORS

Vikas N Kumar <vikas@cpan.org>

=head1 REPOSITORY

L<https://github.com/selectiveintellect/p5-alien-keystone.git>

=head1 COPYRIGHT

Copyright (C) 2016. Selective Intellect LLC <github@selectiveintellect.com>. All Rights Reserved.

=head1 LICENSE

This is free software under the MIT license.
