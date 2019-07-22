package Astro::App::Satpass2::ParseTime::Date::Manip;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::ParseTime };

use Astro::App::Satpass2::Utils qw{
    load_package
    __date_manip_backend
    @CARP_NOT
};

our $VERSION = '0.040';

sub __class_name {
    return __PACKAGE__;
}

sub delegate {
    my $back_end;
    defined ( $back_end = __date_manip_backend() )
	or return $back_end;
    return __PACKAGE__ . "::v$back_end";
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::ParseTime::Date::Manip - Parse time for Astro::App::Satpass2 using Date::Manip

=head1 SYNOPSIS

 my $delegate = Astro::App::Satpass2::ParseTime::Date::Manip->delegate();

=head1 DETAILS

This class is simply a trampoline for
L<< Astro::App::Satpass2::ParseTime->new()|Astro::App::Satpass2::ParseTime/new >> to
determine which Date::Manip class to use.

=head1 METHODS

This class supports the following public methods:

=head2 delegate

 my $delegate = Astro::App::Satpass2::ParseTime::Date::Manip->delegate();

This static method returns the class that should be used based on which
version of L<Date::Manip|Date::Manip> could be loaded. If
C<< Date::Manip->VERSION() >> returns a number less than 6,
'L<Astro::App::Satpass2::ParseTime::Date::Manip::v5|Astro::App::Satpass2::ParseTime::Date::Manip::v5>'
is returned. If it returns 6 or greater,
'L<Astro::App::Satpass2::ParseTime::Date::Manip::v6|Astro::App::Satpass2::ParseTime::Date::Manip::v6>'
is returned. If L<Date::Manip|Date::Manip> can not be loaded, C<undef>
is returned.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
