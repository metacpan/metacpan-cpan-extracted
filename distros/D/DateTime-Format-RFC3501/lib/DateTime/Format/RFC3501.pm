use strict;
use warnings;

package DateTime::Format::RFC3501;
BEGIN {
  $DateTime::Format::RFC3501::VERSION = '0.02';
}
# ABSTRACT: Parse and format RFC3501 datetime strings


use Carp;
use DateTime();

# http://tools.ietf.org/html/rfc3501#section-9 (date-month)
my @date_month = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

my %month_by_name;
@month_by_name{@date_month} = 1 .. @date_month;


sub new {
    my $class = shift;
    my %opts  = @_;

    return bless \%opts, $class;
}



sub parse_datetime {
    my $self = shift;
    my ($str) = @_;

    $self = $self->new()
        if !ref($self);

    my ( $D, $M, $Y ) = $str =~ s/^([ ]\d|\d{2})-([A-Z][a-z]{2})-(\d{4})// && (0+$1,$2,0+$3)
        or croak("Incorrectly formatted date");

    $str =~ s/^ //
        or croak("Incorrectly formatted datetime");

    my ( $h, $m, $s ) = $str =~ s/^(\d{2}):(\d{2}):(\d{2})// && (0+$1,0+$2,0+$3)
        or croak("Incorrectly formatted time");

    $str =~ s/^ //
        or croak("Incorrectly formatted datetime");

    my $tz;
    if ( $str =~ s/^([+-])(\d{4})// ) {
        $tz = "$1$2";
    }
    else {
        croak("Missing time zone");
    }

    $str =~ /^\z/ or croak("Incorrectly formatted datetime");

    return DateTime->new(
        year       => $Y,
        month      => $month_by_name{$M},
        day        => $D,
        hour       => $h,
        minute     => $m,
        second     => $s,
        time_zone  => $tz,
        formatter  => $self,
    );
}


sub format_datetime {
    my ($self, $dt) = @_;
    my $tz;

    if ( $dt->time_zone->is_utc() ) {
        $tz = '+0000';
    } else {
        my $secs  = $dt->offset;
        my $sign  = $secs < 0 ? '-' : '+';  $secs = abs($secs);
        my $mins  = int( $secs / 60 );      $secs %= 60;
        my $hours = int( $mins / 60 );      $mins %= 60;
        if ($secs) {
            ( $dt = $dt->clone() )
            ->set_time_zone('UTC');
            $tz = '+0000';
        }
        else {
            $tz = sprintf( '%s%02d%02d', $sign, $hours, $mins );
        }
    }

    return $dt->strftime('%e-%b-%Y %H:%M:%S ').$tz;
}

1;


__END__
=pod

=head1 NAME

DateTime::Format::RFC3501 - Parse and format RFC3501 datetime strings

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use DateTime::Format::RFC3501;
    
    my $f = DateTime::Format::RFC3501->new();
    my $dt = $f->parse_datetime( ' 1-Jul-2002 13:50:05 +0200' );
    
    # 1-Jul-2002 13:50:05 +0200
    print $f->format_datetime($dt);

=head1 DESCRIPTION

This module understands the RFC3501 date-time format, defined
at http://tools.ietf.org/html/rfc3501.

It can be used to parse this format in order to create the
appropriate objects.

=head1 METHODS

=head2 new()

Returns a new RFC3501 parser object.

=head2 parse_datetime($string)

Given a RFC3501 date-time string, this method will return a new
L<DateTime> object.

If given an improperly formatted string, this method will croak.

For a more flexible parser, see L<DateTime::Format::Strptime>.

=head2 format_datetime($datetime)

Given a L<DateTime> object, this methods returns a RFC3501 date-time string.

=head1 CREDITS

This module was heavily inspired by L<DateTime::Format::RFC3339>.

=head1 SEE ALSO

=over 4

=item *

L<DateTime>

=item *

L<DateTime::Format::RFC3339>

=item *

L<DateTime::Format::Strptime>

=item *

L<http://tools.ietf.org/html/rfc3501>, "Internet Message Access Protocol - version 4rev1"

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-datetime-format-rfc3501 at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Format-RFC3501>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::RFC3501

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Format-RFC3501>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Format-RFC3501>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Format-RFC3501>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Format-RFC3501>

=back

=head1 AUTHOR

Alex Muntada <alexm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alex Muntada.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

