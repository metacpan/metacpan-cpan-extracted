package Beagle::Role::Date;
use Any::Moose 'Role';
use Date::Format;

has 'timezone' => (
    isa     => 'Str',
    is      => 'rw',
    default => 'UTC',
);


has 'created' => (
    isa     => 'Int',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return time;
    },
);

has 'updated' => (
    isa     => 'Int',
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->created },
);

sub format_date {
    my $self   = shift;
    my $format = shift;
    my $value  = shift;
    local $ENV{TZ} = $self->timezone;
    my @lt = localtime($value);
    return strftime( $format, @lt );
}

sub created_string {
    my $self = shift;
    return $self->format_date( '%Y-%m-%d %T %z', $self->created );
}

sub created_year {
    my $self = shift;
    return $self->format_date( '%Y', $self->created );
}

sub created_month {
    my $self = shift;
    return $self->format_date( '%m', $self->created );
}

sub created_day {
    my $self = shift;
    return $self->format_date( '%d', $self->created );
}

sub updated_string {
    my $self = shift;
    return $self->format_date( '%Y-%m-%d %T %z', $self->updated );
}

sub updated_year {
    my $self = shift;
    return $self->format_date( '%Y', $self->updated );
}

sub updated_month {
    my $self = shift;
    return $self->format_date( '%m', $self->updated );
}

sub updated_day {
    my $self = shift;
    return $self->format_date( '%d', $self->updated );
}

no Any::Moose 'Role';
1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

