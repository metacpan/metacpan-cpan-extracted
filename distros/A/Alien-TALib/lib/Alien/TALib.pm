package Alien::TALib;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.14';
$VERSION = eval $VERSION;

1;

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### DATE: 26th Dec 2022
#### LICENSE: Refer LICENSE file.

=head1 NAME

Alien::TALib

=head1 SYNOPSIS

Alien::TALib is a perl module that enables the installation of the technical
analysis library TA-lib from "L<http://ta-lib.org>" on the system and easy
access by other perl modules in the methodology cited by C<Alien::Base>.

You can use it in the C<Build.PL> file if you're using C<Module::Build> or
C<Makefile.PL> file if you're using ExtUtils::MakeMaker.

            my $talib = Alien::TALib->new;

            my $build = Module::Build->new(
                ...
                extra_compiler_flags => $talib->cflags(),
                extra_linker_flags => $talib->libs(),
                ...
            );


=head1 VERSION

0.14

=head1 WARNING

This module is not supported on Windows unless running under Cygwin or MSYS.

We are working to fix this soon.

=head1 METHODS

=over

=item B<cflags>

This method provides the compiler flags needed to use the library on the system.

=item B<libs>

This method provides the linker flags needed to use the library on the system.

=back

=head1 SEE ALSO

=over

=item C<Alien::Base>

=item C<Alien::Build>

=item C<PDL::Finance::TA>

=back

=head1 AUTHORS

Vikas N Kumar <vikas@cpan.org>

=head1 REPOSITORY

L<https://github.com/vikasnkumar/Alien-TALib.git>

=head1 COPYRIGHT

Copyright (C) 2013-2022. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. YOu can redistribute it or modify it under the terms of
Perl itself.
