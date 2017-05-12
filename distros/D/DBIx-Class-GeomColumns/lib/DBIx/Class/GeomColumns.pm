package DBIx::Class::GeomColumns;
use strict;
use warnings;
use Carp;
use Geo::Converter::WKT2KML;

use version; our $VERSION = qv('0.0.2');
use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata( '_geom_columns' );
__PACKAGE__->mk_classdata( '_kml_columns' );

=head1 NAME

DBIx::Class::GeomColumns - Filter of geometry columns to access with WKT

=head1 SYNOPSIS

    package POI;
    __PACKAGE__->load_components(qw/GeomColumns Core/);
    __PACKAGE__->utf8_columns('wgs84_col',{'tokyo_col' => 4301});
    __PACKAGE__->kml_columns('kml_col');
    
    # Then belows return the result of 'AsText(wgs84_col)'
    $poi->wgs84_col;

    # You can also create or update 'GeomFromText($data,$srid)';
    # below example is insert 'GeomFromText('POINT(135 35)',4301)'
    $poi->tokyo_col('POINT(135 35)');
    $poi->update;

    # Access by KML geometry fragment 
    $poi->kml_col; 
    $poi->kml_col('<LineString><coordinates>135,35 136,36</coordinates></LineString>');
    $poi->update;

=head1 DESCRIPTION

This module allows you to access geometry columns by WKT or KML format.

=head1 METHODS

=head2 geom_columns

=cut

sub geom_columns { shift->set_geom_columns( 'geom', @_ ) }

=head2 kml_columns

=cut

sub kml_columns  { shift->set_geom_columns( 'kml',  @_ ) }

=head1 INTERNAL METHODS

=head2 set_geom_column

=cut

sub set_geom_columns {
    my $self    = shift;
    my $type    = shift;
    my $property = "_${type}_columns"; 

    if (@_) {
        my %args;
        foreach my $elm (@_) {
            my $ref = ref($elm) ? $elm : { $elm => 4326 };
            foreach my $col ( keys %$ref ) {
                $self->throw_exception("column $col doesn't exist")
                    unless $self->has_column($col);
            }
            %args = ( %args, %$ref );
        }        
        my @keys = keys %args;

        $self->resultset_attributes(
            {
                '+select' => [ map { { 'AsText' => "me.$_" } } @keys ], 
                '+as'     => \@keys,
            }
        );

        return $self->$property({ map { $_ => $args{$_} } @keys });
    } else {
        return $self->$property;
    }
}

=head2 get_column

=cut

sub get_column {
    my ( $self, $column ) = @_;
    my $value = $self->next::method($column);

    my $kcols = $self->_kml_columns || {};
    my $cols  = { %{ $self->_geom_columns || {} }, %{ $kcols } };

    if ( $cols and defined $value and ref($value) and ref($value) eq 'SCALAR' and $cols->{$column} ) {
        $value = ${$value} . "";
        $value =~ s/GeomFromText\('(.+)',\d+\)/$1/;
    }

    if ( $kcols and defined $value and $kcols->{$column} ) {
        $value = wkt2kml($value);
    }

    $value;
}

=head2 get_columns

=cut

sub get_columns {
    my $self = shift;
    my %data = $self->next::method(@_);

    my $kcols = $self->_kml_columns || {};
    my $cols  = { %{ $self->_geom_columns || {} }, %{ $kcols } };

    unless ( (caller(1))[3] eq 'DBIx::Class::Row::insert' ) {
        foreach my $col (grep { defined $data{$_} } keys %{ $cols }) {
            my $value = $data{$col};

            if ( ref($value) and ref($value) eq 'SCALAR' ) {
                $value = ${$value};
                $value =~ s/GeomFromText\('(.+)',\d+\)/$1/;
            }

            $value = wkt2kml($value) if ( $kcols->{$col} );

            $data{$col} = $value;
        }
    }

    %data;
}

=head2 store_column

=cut

sub store_column {
    my ( $self, $column, $value ) = @_;

    my $kcols = $self->_kml_columns || {};
    my $cols  = { %{ $self->_geom_columns || {} }, %{ $kcols } };

    if ( $cols and defined $value ) {
        $value = kml2wkt($value) if ( $kcols->{$column} );

        if ( my $srid = $cols->{$column} ) {
            $value = \"GeomFromText('$value',$srid)";
        }
    }

    $self->next::method( $column, $value );
}

=head1 DEPENDENCIES

L<Geo::Converter::WKT2KML>.

L<DBIx::Class>.

=head1 AUTHOR

OHTSUKA Ko-hei <nene@kokogiko.net>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

