package Astro::App::Satpass2::FormatValue::Formatter;

use 5.008;

use strict;
use warnings;

use Astro::App::Satpass2::FormatValue;
use Astro::App::Satpass2::Utils qw{ has_method @CARP_NOT };

our $VERSION = '0.040';

sub new {
    my ( $class, $info ) = @_;

    return bless {
	info	=> $info,
	code	=> Astro::App::Satpass2::FormatValue
	    ->__make_formatter_code( $info ),
    }, $class;

}

sub code {
    my ( $self ) = @_;
    return $self->{code};
}

sub name {
    my ( $self ) = @_;
    return $self->{info}{name};
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::FormatValue::Formatter - Implement a formatter

=head1 SYNOPSIS

 No user-servicable parts inside.

=head1 DESCRIPTION

This Perl class should be considered private to the
F<Astro-App-Satpass2> package, and this documentation is for the benefit
of the author. The author reserves the right to modify or retract this
class without notice.

This Perl class encapsulates the construction of individual formatter
routines for the use of the
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
object. It is called to construct that class' built-in formatters, and
by that class'
L<add_formatter_method()|Astro::App::Satpass2::FormatValue/add_formatter_method>
method to add user-defined formatter methods. It is not instantiated by
the user.

=head1 METHODS

This class supports the following methods:

=head2 new

This static method instantiates the object. Besides the invocant, its
argument is a reference to a hash that describes the formatter.

=head2 code

This method returns the code that implements the formatter.

=head2 name

This method returns the name of the formatter.

=head1 SEE ALSO

L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
