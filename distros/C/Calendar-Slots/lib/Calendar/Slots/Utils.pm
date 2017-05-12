package Calendar::Slots::Utils;
{
  $Calendar::Slots::Utils::VERSION = '0.15';
}
use strict;
use warnings;
use DateTime::Format::Strptime;
use Carp;

use vars qw(@ISA @EXPORT);
require Exporter;

@ISA=qw(Exporter);
@EXPORT = qw/format_args check_date check_weekday check_time parse_dt/; 

sub format_args {
    my %args = @_;
    $args{$_} =~ s{[\-|\:|\s]}{}g for grep !/name|data/, keys %args;
    return %args;
}

sub check_time {
    my $time = shift;
    confess 'Invalid time. Must be in the range 00:00 to 24:00'
      unless defined $time and $time >= 0 and $time <= 2400;
}

sub check_weekday {
    my $weekday = shift;
    confess 'Invalid weekday. Must be from 1 (Monday) to 7 (Sunday)'
      unless $weekday >= 1 and $weekday <= 7;
}

sub check_date {
    my $date = shift;
    confess 'Invalid date. Date format must be YYYY-MM-DD'
      unless length($date) == 8;
}

sub parse_dt {
    my ( $format, $date ) = @_;
    use DateTime::Format::Strptime;
    my $parser = DateTime::Format::Strptime->new( pattern => $format );
    return $parser->parse_datetime( $date );
}


1;
__END__

=pod

=head1 NAME

Calendar::Slots::Utils - Calendar::Slots internal machinery

=head1 VERSION

version 0.15

=head1 SYNOPSIS

Nothing here to look at. You may want to take a look at L<Calendar::Slot>.

=head1 METHODS

=head2 check_date

=head2 check_weekday

=head2 check_time

=head2 format_args

=head1 AUTHOR

Rodrigo de Oliveira C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
