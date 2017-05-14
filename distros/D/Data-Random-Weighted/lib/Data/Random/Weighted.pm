package Data::Random::Weighted;


# ABSTRACT: get weighted random data


use strict;
use warnings;

sub new {
    my $class = shift;
    my $args  = shift || {};
    my $self  = bless {}, $class;
    $self->{'roller'} = $self->randomizer($args);
    return $self;
}

sub randomizer {
    my ( $self, $args ) = @_;
    my ( $weight, $total );
    my $count = 0;
    for my $key( keys %$args ) {
        my $set = $args->{$key};
        $total += $set;
        for ( 1 .. $set ) {
            $weight->{$count++} = $key;
        }
    }
    return sub {
        my $rand = int(rand($total));
        return $weight->{$rand};
    }
}

sub roll { &{ shift->{'roller'} }() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Random::Weighted - get weighted random data

=head1 VERSION

version 1.000

=head1 Data::Random::Weighted

Used to return random results from a weighted set.

=head1 Usage

my $rand = Data::Random::Weighter->new({
    'Result' => 5,
    42       => 1,
 });

print $rand->roll;

=head1 AUTHOR

Russel Fisher <geistberg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Russel Fisher.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
