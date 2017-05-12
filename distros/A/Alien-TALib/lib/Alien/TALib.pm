package Alien::TALib;
use strict;
use warnings;
use Alien::TALib::ConfigData;

our $VERSION = '0.08';
$VERSION = eval $VERSION;

sub new {
    my $class = shift || __PACKAGE__;
    my %args = @_;
    my $cflags = Alien::TALib::ConfigData->config('cflags');
    my $libs = Alien::TALib::ConfigData->config('libs');
    $args{cflags} = $cflags unless defined $args{cflags};
    $args{libs} = $libs unless defined $args{libs};
    $args{installed} = Alien::TALib::ConfigData->config('installed') unless defined $args{installed};
    $args{ta_lib_config} = Alien::TALib::ConfigData->config('ta_lib_config') unless defined $args{ta_lib_config};
    return bless({%args}, $class);
}

sub cflags { return shift->{cflags}; }
sub libs { return shift->{libs}; }
sub is_installed { return shift->{installed}; }
sub ta_lib_config { return shift->{ta_lib_config}; }

1;

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.

=head1 NAME

Alien::TALib - Perl extension to install TA-lib

=head1 SYNOPSIS

Alien::TALib is a perl module that enables the installation of the technical
analysis library TA-lib from "L<http://ta-lib.org>" on the system and easy
access by other perl modules in the methodology cited by Alien::Base.

You can use it in the C<Build.PL> file if you're using Module::Build or
C<Makefile.PL> file if you're using ExtUtils::MakeMaker.

            my $talib = Alien::TALib->new;
            die "ta-lib is not installed" unless $talib->is_installed;

            my $build = Module::Build->new(
                ...
                extra_compiler_flags => $talib->cflags(),
                extra_linker_flags => $talib->libs(),
                ...
            );


=head1 VERSION

0.07

=head1 DESCRIPTION

Installing ta-lib on various platforms can be a hassle for the end-user. Hence
the modules like L<Finance::Talib> and L<PDL::Finance::Talib> may choose to use
L<Alien::TALib> for automatically checking and verifying that there are already
existing installs of ta-lib on the system and if not, installing the ta-lib
libraries on the system.

=head1 METHODS

=over

=item B<new>

This method finds an already installed ta-lib or can install it if not found or
if the install is forced by setting the $Alien::TALib::FORCE variable to 1.
The user can set TALIB_CFLAGS at runtime to override the B<cflags> output of the
object created with this function.
The user can also set TALIB_LIBS at runtime to override the B<libs> output of
the object created with this function.

=item B<cflags>

This method provides the compiler flags needed to use the library on the system.

=item B<libs>

This method provides the linker flags needed to use the library on the system.

=item B<ta_lib_config>

This method returns the path of the ta-lib-config executable if it has been
installed.

=item B<is_installed>

This method returns a boolean saying whether ta-lib has been installed or not.

=item B<config>

This method provides the access to configuration information for the library on
the system. More information can be seen in the module
L<Alien::TALib::ConfigData>.

=back

=head1 SPECIAL BUILD TIME VARIABLES

=over

=item $ENV{TALIB_FORCE}

Setting this value to 1 before running Build.PL will force the download and
re-install of the B<ta-lib> library.

=item $ENV{TALIB_CFLAGS} and $ENV{TALIB_LIBS}

Setting these environment variables before running Build.PL will force these
values to be used to provide the output of B<cflags()> and B<libs()> functions.
In this case B<is_installed()> will always return 1 and B<ta_lib_config()> will
always return undefined.

=item $ENV{PREFIX}

Setting this environment variable before running Build.PL will configure
Alien::TALib::ConfigData to use this value as the install prefix of B<ta-lib> if
it is built and installed.

=back

=head1 SEE ALSO

=over

=item C<Alien::TALib::ConfigData>

=item C<PDL::Finance::Talib>

=item C<Finance::Talib>

=back

=head1 AUTHORS

Vikas N Kumar <vikas@cpan.org>

=head1 REPOSITORY

L<https://github.com/vikasnkumar/Alien-TALib.git>

=head1 COPYRIGHT

Copyright (C) 2013-2014. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. YOu can redistribute it or modify it under the terms of
Perl itself.
