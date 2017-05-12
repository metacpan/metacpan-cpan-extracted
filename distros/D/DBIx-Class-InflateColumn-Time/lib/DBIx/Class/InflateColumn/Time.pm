package DBIx::Class::InflateColumn::Time;

use strict;
use warnings;

use base qw/DBIx::Class/;

use DateTime::Duration;
use namespace::autoclean;

our $VERSION = '0.0.1'; # VERSION
# ABSTRACT: Automagically inflates time columns into DateTime::Duration objects

=pod

=encoding utf8

=head1 NAME

DBIx::Class::InflateColumn::Time - Inflate and Deflate "time" columns into DateTime::Duration Objects

=head1 SYNOPSIS

    package HorseTrack::Database::Schema::Result::Race;
    use base 'DBIx::Class::Core';

    use strict;
    use warnings;

    __PACKAGE__->load_components("InflateColumn::Time");

    __PACKAGE__->add_columns(
        race_number => { data_type => 'integer'},
        duration    => { data_type => 'time'},
    );

=head1 DESCRIPTION

This module can be used to automagically inflate database columns of data type "time" into
DateTime::Duration objects.  It is used similiar to other InflateColumn DBIx modules.

Once your Result is properly defined you can now pass DateTime::Duration objects into columns
of data_type time and retrieve DateTime::Duration objects from these columns as well

=head2 Inflation

Inflation occurs whenever the data is being taken FROM the database.  In this case the database
is storing the value with data_type of time, upon inflation a DateTime::Duration object is returned
from the resultset.

    package HorseTrack::Race;

    use strict;
    use warnings;

    use Moose;
    use namespace::autoclean;

    use DateTime::Duration;

    has 'race_number' => ( is => 'rw', isa => 'Int' );
    has 'duration'    => ( is => 'rw', isa => 'DateTime::Duration' );

    sub retrieve {
        my $self = shift;

        my $result = $schema->resultset('...')->search({ race_number => 1 })->single;

        my $race = $self->new({
            race_number => $result->race_number,
            duration    => $result->duration,
        });

        return $race;
    }

    __PACKAGE__->meta->make_immutable();
    1;

=head2 Deflation

Deflation occurs whenever the data is being taken TO the database.  In this case an object
of type DateTime::Duration is being stored into the a database columns with a data_type of "time".
Using the same object from the Inflation example:

    $schema->resultset('...')->create({
        race_number => $self->race_number,
        duration    => $self->duration,
    });


=head1 METHODS

Strictly speaking, you don't actually call any of these methods yourself.  DBIx handles the magic
provided you have included the InflateColumn::Time component in your Result.

Therefore, there are no public methods to be consumed.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);

    return unless $info->{data_type} eq 'time';

    $self->inflate_column(
        $column => {
            inflate => \&_inflate,
            deflate => \&_deflate,
        }
    );
}

sub _inflate {
    my $value = shift;

    my ($sign, $hours, $minutes, $seconds) = $value =~ m/(-?)0?(\d+):0?(\d+):0?(\d+)/g;

    ### Sign: (defined $sign ? "-" : "+")
    ### Hours: $hours
    ### Minutes: $minutes
    ### Seconds: $seconds

    my $duration = DateTime::Duration->new({
        hours   => $hours,
        minutes => $minutes,
        seconds => $seconds,
    });

    if($sign) {
        return $duration->inverse;
    }

    return $duration;
}

sub _deflate {
    my $value = shift;

    # For time purposes we'll always assume that a day is 24 hours.
    my $hours = $value->hours + ($value->days * 24);

    my $time = ($value->is_negative ? '-' : '')
               . sprintf( $hours >= 100 ? "%03d" : "%02d" , $hours)   . ':'
               . sprintf( "%02d", $value->minutes) . ':'
               . sprintf( "%02d", $value->seconds);

    return $time;
}

1;

__END__

=pod

=head1 AUTHORS

Robert Stone C<< <drzigman AT cpan DOT org > >>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Robert Stone

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU Lesser General Public License as published by the Free Software Foundation; or any compatible license.

See http://dev.perl.org/licenses/ for more information.

=cut
