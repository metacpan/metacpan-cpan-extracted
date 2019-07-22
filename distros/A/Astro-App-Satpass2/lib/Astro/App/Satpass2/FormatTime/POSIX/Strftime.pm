package Astro::App::Satpass2::FormatTime::POSIX::Strftime;

use 5.008;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::FormatTime };

use Astro::App::Satpass2::FormatTime::Strftime;
use Astro::App::Satpass2::Utils qw{ ARRAY_REF @CARP_NOT };
use POSIX ();

our $VERSION = '0.040';

sub format_datetime {
    my ( $self, $tplt, $time, $gmt ) = @_;
    $time = $self->__round_time_value( $time );
    defined $gmt or $gmt = $self->gmt();
    my @parts;
    if ( ARRAY_REF eq ref $time ) {
	@parts = @{ $time };
    } elsif ( $gmt ) {
	@parts = gmtime $time;
    } else {
	my $tz = $self->tz();
	defined $tz
	    and $tz ne ''
	    and local $ENV{TZ} = $tz;
	@parts = localtime $time;
    }
    return POSIX::strftime( $tplt, @parts );
}

{
    my %adjuster = (
	year	=> sub { $_[0][5] = $_[1] - 1900; return },
	month	=> sub { $_[0][4] = $_[1] - 1; return },
	day	=> sub { $_[0][3] = $_[1]; return },
	hour	=> sub { $_[0][2] = $_[1]; return },
	minute	=> sub { $_[0][1] = $_[1]; return },
	second	=> sub { $_[0][0] = $_[1]; return },
    );

    sub __format_datetime_width_adjust_object {
	my ( undef, $obj, $name, $val ) = @_;	# Invocant unused
	$obj or $obj = [ 0, 0, 0, 1, 0, 200 ];
	$adjuster{$name}->( $obj, $val );
	return $obj;
    }

}

1;

__END__

=head1 NAME

Astro::App::Satpass2::FormatTime::POSIX::Strftime - Format time using POSIX::strftime

=head1 SYNOPSIS

 use Astro::App::Satpass2::FormatTime::POSIX::Strftime;
 my $tf = Astro::App::Satpass2::FormatTime::POSIX::Strftime->new();
 print 'It is now ',
     $tf->format_datetime( '%H:%M:%S', time, 1 ),
     " GMT\n";

=head1 NOTICE

This class and its subclasses are private to the
L<Astro::App::Satpass2|Astro::App::Satpass2> package. The author
reserves the right to add, change, or retract functionality without
notice.

=head1 DETAILS

This subclass of
L<Astro::App::Satpass2::FormatTime|Astro::App::Satpass2::FormatTime>
formats times using C<POSIX::strftime>. Time zones other than the
default local zone are handled by setting C<$ENV{TZ}> from the
L<tz|Astro::App::Satpass2::FormatTime/tz>
attribute before calling C<localtime()>, but this is unsupported by the
C<localtime()> built-in. It may work, but if it does not there is
nothing I can do about it.

=head1 METHODS

This class provides no public methods over and above those provided by
L<Astro::App::Satpass2::FormatTime|Astro::App::Satpass2::FormatTime> and
L<Astro::App::Satpass2::FormatTime::Strftime|Astro::App::Satpass2::FormatTime::Strftime>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
