use 5.10.1;
use strict;
use warnings;

package DBIx::Class::InflateColumn::Geo;

# ABSTRACT: Inflate geometric columns to data structures
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0100';

use Carp qw/confess/;

sub register_column {
    my($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);

    return if !(defined $info->{'data_type'});

    $self->_handle_point($column, $info, @rest) if lc $info->{'data_type'} eq 'point';
}

sub _handle_point {
    my($self, $column, $info, @rest) = @_;

    my $srid = exists $info->{'geo_srid'} ? $info->{'geo_srid'} : 4326;
    my $xname = $info->{'geo_xname'} || 'x';
    my $yname = $info->{'geo_yname'} || 'y';
    my $with_astext = exists $info->{'geo_with_astext'} ? $info->{'geo_with_astext'} : 0;

    $self->inflate_column(
        $column => {
            inflate => sub {
                my($value, $object) = @_;

                my($astext) = $object->result_source->schema->storage->dbh->selectrow_array("SELECT ASTEXT(?)", {}, $value);

                if($astext =~ m{^POINT\(([^\s]+) ([^\s]+)\)$}i) {
                    my $result = {
                        $xname => $1,
                        $yname => $2,
                    };
                    if($with_astext) {
                        $result->{'astext'} = $astext;
                    }
                    return $result;
                }
                return;
            },
            deflate => sub {
                my($value, $object) = @_;

                my $stringified = ref $value eq 'HASH'  ? sprintf ('%s %s', $value->{ $xname }, $value->{ $yname })
                                : ref $value eq 'ARRAY' ? "$value->[0] $value->[1]"
                                :                         $value
                                ;

                if($stringified =~ m/[^-+\d\s\.]/) {
                    confess "The submitted value for column <$column> stringifies to <$stringified>, which is not suitable for POINT";
                }

                return $srid ? \"ST_PointFromText('POINT($stringified)', $srid)"
                             : \"ST_PointFromText('POINT($stringified)')"
                             ;
            },
        }
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::Geo - Inflate geometric columns to data structures



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10.1+-blue.svg" alt="Requires Perl 5.10.1+" />
<a href="https://travis-ci.org/Csson/p5-DBIx-Class-InflateColumn-Geo"><img src="https://api.travis-ci.org/Csson/p5-DBIx-Class-InflateColumn-Geo.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/DBIx-Class-InflateColumn-Geo-0.0100"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/DBIx-Class-InflateColumn-Geo/0.0100" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=DBIx-Class-InflateColumn-Geo%200.0100"><img src="http://badgedepot.code301.com/badge/cpantesters/DBIx-Class-InflateColumn-Geo/0.0100" alt="CPAN Testers result" /></a>
</p>

=end html

=head1 VERSION

Version 0.0100, released 2018-10-27.

=head1 SYNOPSIS

    package TheSchema::Result::Park;
    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components(qw/InflateColumn::Geo/);
    __PACKAGE__->add_columns({
        location => {
            data_type => 'point'
        },
        secondary_location => {
            data_type => 'point',
            geo_srid => 4326,
            geo_xname => 'longitude',
            geo_yname => 'latitude',
            geo_with_astext => 1,
        },
    });

Later:
    my $park = $schema->resultset('Park')->create({
        location => { x => 15.43, y => 54.32 },
        secondary_location => { longitude => 12.32, latitude => 45.9843 },
    });
    say $park->location->{'x'};                  # 15.43
    say $park->secondary_location->{'latitude'}; # 45.9843
    say $park->secondary_location->{'astext'};   # POINT(12.32 45.9843)

    # Values can also be given as an array ref or as a space-separated string, both in x/longitude, y/latitude order:
    my $same_park = $schema->resultset('Park')->create({
        location => [15.43, 54.32],
        secondary_location => '12.32 45.9843',
    });

=head1 DESCRIPTION

DBIx::Class::InflateColumn::Geo inflates geometry columns (so far, only C<POINT> is supported) to more accessible data structures.

=head1 COLUMN SPECIFICATION OPTIONS

Usage shown in the synopsis.

=head2 geo_srid

The spacial reference identifier you wish to use.

Default: C<4326> (aka L<WGS 84|http://spatialreference.org/ref/epsg/wgs-84/>)

Set it to C<undef> if you want to use your database's default.

=head2 geo_xname

The name you wish to use for the C<X> (or C<longitude>) value.

Default: C<x>

=head2 geo_yname

The name you wish to use for the C<Y> (or C<latitude>) value.

Default: C<y>

=head2 geo_with_astext

A boolean determining whether the L<Well-known text|https://en.wikipedia.org/wiki/Well-known_text> of the column is included in the inflated hash. It is not used during deflation.

Default: C<0>

=head1 COMPATIBILITY

I have only tested this on MariaDB 10.*.

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::GeomColumns>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-InflateColumn-Geo>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-InflateColumn-Geo>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
