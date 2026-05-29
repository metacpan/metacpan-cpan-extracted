package DateTime::Format::Natural::Calendar;

use strict;
use warnings;

use DateTime ();

our $VERSION = '0.02';

sub _init
{
    my ($class) = @_;

    my $type = _type($class);

    return "DateTime::Format::Natural::Calendar::${type}"->_new(calendar_class => $class, type => $type);
}

sub _type
{
    my ($class) = @_;

    if (defined $class) {
        return 'julian' if $class eq 'DateTime::Calendar::Julian';
    }
    else {
        return 'gregorian';
    }
}

sub _can_convert
{
    my $self = shift;

    return $self->can('_to_gregorian');
}

sub _new
{
    my $class = shift;

    return bless { @_ }, $class;
}

1;

package DateTime::Format::Natural::Calendar::gregorian;

use base 'DateTime::Format::Natural::Calendar';

1;

package DateTime::Format::Natural::Calendar::julian;

use base 'DateTime::Format::Natural::Calendar';

sub _to_gregorian
{
    my $self = shift;
    my ($year, $month, $day, $opts, $code) = @_;

    $code->(\$year, \$month, \$day, $opts);

    my $dt = DateTime->from_object(object => $self->{calendar_class}->new(year => $year, month => $month, day => $day));

    return map $dt->$_, qw(year month day);
}

1;
__END__

=head1 NAME

DateTime::Format::Natural::Calendar - Convert between calendar systems

=head1 SYNOPSIS

 Please see the DateTime::Format::Natural documentation.

=head1 DESCRIPTION

C<DateTime::Format::Natural::Calendar> converts between calendar systems.

=head1 SEE ALSO

L<DateTime::Format::Natural>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
