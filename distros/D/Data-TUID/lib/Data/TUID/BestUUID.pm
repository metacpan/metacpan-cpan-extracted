package Data::TUID::BestUUID;

use strict;
use warnings;

our ( %loaded, %skip );

BEGIN {
    eval {
        $loaded{LibUUID} = require Data::UUID::LibUUID;
        1;
    } unless $skip{LibUUID};

    eval {
        $loaded{DataUUID} = require Data::UUID;
        1;
    } unless $skip{DataUUID};
}

sub new_uuid {
    my $self = shift;

    return &Data::UUID::LibUUID::new_uuid_string if $loaded{LibUUID};
    return Data::UUID->new->create_str if $loaded{DataUUID};

    die "No UUID package loaded";
}

sub uuid_to_canonical {
    my $self = shift;
    my ( $uuid ) = @_;

    die "Missing/invalid uuid" unless $uuid;

    my $result;

    if ( $loaded{LibUUID} ) {
        $result = &Data::UUID::LibUUID::uuid_to_binary( $uuid );
        $result = &Data::UUID::LibUUID::uuid_to_string( $result ) if $result;
    }
    elsif ( $loaded{DataUUID} ) {
        eval {
            while ( 1 ) {
                $result =
                    eval { Data::UUID->new->from_string( $uuid ) } ||
                    eval { Data::UUID->new->from_hexstring( $uuid ) } ||
                    eval { Data::UUID->new->from_b64string( $uuid ) };
                last if $result;
                $result = $uuid; # Assume already binary
            }
            $result = Data::UUID->new->to_string( $result ) if $result;
        };
        undef $result if $@;
    };

    $result = lc $result;

    die "Invalid uuid ($uuid): Unable to convert"
        unless $result =~ m/^
            (?:[a-f0-9]{8}) -
            (?:[a-f0-9]{4}) -
            (?:[a-f0-9]{4}) -
            (?:[a-f0-9]{4}) -
            (?:[a-f0-9]{12})
        $/x;

    return $result;
}

1;

__END__
=pod

=head1 NAME

Data::TUID::BestUUID

=head1 VERSION

version 0.0122

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

