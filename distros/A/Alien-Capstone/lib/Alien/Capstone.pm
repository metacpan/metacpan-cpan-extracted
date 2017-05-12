package Alien::Capstone;
use parent 'Alien::Base';
use Alien::Capstone::ConfigData;

our $VERSION = '0.07';

sub is_installed {
    return Alien::Capstone::ConfigData->config('finished_installing');
}

1;

__END__
#### COPYRIGHT: Selective Intellect LLC.
#### AUTHOR: Vikas N Kumar
#### DATE: 13 September 2016

=head1 NAME

Alien::Capstone - Perl extension to install Capstone-Engine from L<www.capstone.org>

=head1 SYNOPSIS

Alien::Capstone is a perl module that enables the installation of the open
source disassembly library Capstone-Engine from
L<http://www.capstone-engine.org> on the system or locate the existing
installation if any. It is currently setup to look for version 3.0.4.

You can use it in the C<Build.PL> file if you're using Module::Build or
C<Makefile.PL> file if you're using ExtUtils::MakeMaker.

            use Alien::Capstone;
            # ...
            die "Alien::Capstone isn't installed" unless &Alien::Capstone::is_installed();
            # ...
            my $capstone= Alien::Capstone->new;
            my $build = Module::Build->new(
                ...
                extra_compiler_flags => $capstone->cflags(),
                extra_linker_flags => $capstone->libs(),
                ...
            );


=head1 VERSION

0.07

=head1 METHODS

=over

=item B<new>

Creates the object. Refer C<Alien::Base> for more information.

=item B<cflags>

This method provides the compiler flags needed to use the library on the system.

=item B<libs>

This method provides the linker flags needed to use the library on the system.

=item B<is_installed>

This method checks to see if Capstone has been installed correctly.

=back

=head1 SEE ALSO

=over

=item C<Alien::Base>

=back

=head1 AUTHORS

Vikas N Kumar <vikas@cpan.org>

=head1 REPOSITORY

L<https://github.com/selectiveintellect/p5-alien-capstone.git>

=head1 COPYRIGHT

Copyright (C) 2016. Selective Intellect LLC <github@selectiveintellect.com>. All Rights Reserved.

=head1 LICENSE

This is free software under the MIT license.
