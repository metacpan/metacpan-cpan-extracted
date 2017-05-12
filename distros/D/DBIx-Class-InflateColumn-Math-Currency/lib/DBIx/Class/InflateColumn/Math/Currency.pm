package DBIx::Class::InflateColumn::Math::Currency;

use strict;
use warnings;

use base qw/DBIx::Class/;

use Math::Currency;
use Scalar::Util qw(looks_like_number);
use Carp;

use namespace::autoclean;

our $VERSION = '0.2.0'; # VERSION
# ABSTRACT: Automagically inflates decimal columns into Math::Currency objects

=pod

=encoding utf8

=head1 NAME

DBIx::Class::InflateColumn::Math::Currency - Inflate and Deflate "decimal" columns into Math::Currency Objects

=head1 SYNOPSIS

    package HorseTrack::Database::Schema::Result::Bet;
    use base 'DBIx::Class::Core';

    use strict;
    use warnings;

    __PACKAGE__->load_components("InflateColumn::Math::Currency");

    __PACKAGE__->add_columns(
      id         => { data_type => 'integer' },
      gambler_id => { data_type => 'integer' },
      amount     => { data_type => 'decimal', size => [9,2], is_currency => 1 },
    );

=head1 DESCRIPTION

This module can be used to automagically inflate database columns of data type "decimal" that are flagged with "is_currency" into Math::Currency objects.  It is used similiar to other InflateColumn DBIx modules.

Once your Result is properly defined you can now pass Math::Currency objects (and regular integers and floats for that matter, they need not be Math::Currency objects) into columns of data_type decimal and retrieve Math::Currency objects from these columns as well.

In the event anything other than a Math::Currency object, an integer, or a float, is provided this module will croak, stating as such.

=head2 Inflation

Inflation occurs whenever the data is being taken FROM the database.  In this case the database is storing the value with data_type of decimal, upon inflation a Math::Currency object is returned from the resultset.

    package HorseTrack::Bet;

    use strict;
    use warnings;

    use Moose;
    use namespace::autoclean;

    use Math::Currency;

    has 'id'       => ( is => 'rw', isa => 'Int' );
    has 'gamber_id => ( is => 'rw', isa => 'Int' );
    has 'amount'   => ( is => 'rw', isa => 'Math::Currency', is_currency => 1 );

    sub retrieve {
        my $self = shift;
        my $result = $schema->resultset('...')->search({ id => 1 })->single;

        my $bet = $self->new({
            id        => $result->id,
            gamber_id => $result->gamber_id,
            amount    => $result->amount,
        });

        return $bet;
    }

    __PACKAGE__->meta->make_immutable();
    1;

=head2 Deflation

Deflation occurs whenever the data is being taken TO the database.  In this case an object of type Math::Currency is being stored into the a database columns with a data_type of "decimal". Using the same object from the Inflation example:

    $schema->resultset('...')->create({
        id        => $self->id,
        gamber_id => $self->gambler_id,
        amount    => $self->amount,
    });

=head1 METHODS

Strictly speaking, you don't actually call any of these methods yourself.  DBIx handles the magic provided you have included the InflateColumn::Math::Currency component in your Result.

Therefore, there are no public methods to be consumed.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);

    if( $info->{data_type} eq 'decimal' && $info->{is_currency } ) {
        $self->inflate_column(
            $column => {
                inflate => \&_inflate,
                deflate => \&_deflate,
            }
        );
    }

    return;
}

sub _inflate {
    my $value = shift;

    if(ref $value eq "Math::Currency") {
        return $value;
    }
    elsif(looks_like_number($value)) {
        return Math::Currency->new($value);
    }
    else {
        croak "Failed to inflate " . $value
            . ".  This value is not a Math::Currency object nor does it look like a number";
    }
}

sub _deflate {
    my $value = shift;

    if(ref $value eq "Math::Currency") {
        return $value->as_float;
    }
    elsif(looks_like_number($value)) {
        return $value;
    }
    else {
        croak "Failed to deflate " . $value
            . ".  This value is not a Math::Currency object nor does it look like a number";
    }
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
