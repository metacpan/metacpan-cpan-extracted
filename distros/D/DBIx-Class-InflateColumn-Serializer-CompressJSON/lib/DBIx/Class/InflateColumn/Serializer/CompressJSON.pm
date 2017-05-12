#
# This file is part of DBIx-Class-InflateColumn-Serializer-CompressJSON
#
# This software is copyright (c) 2012 by Weborama.  No
# license is granted to other entities.
#
package DBIx::Class::InflateColumn::Serializer::CompressJSON;
{
  $DBIx::Class::InflateColumn::Serializer::CompressJSON::VERSION = '0.004';
}

# ABSTRACT: DBIx::Class::InflateColumn::Serializer::CompressJSON - JSON compressed Inflator

use strict;
use warnings;
use JSON qw//;
use Compress::Zlib qw/compress uncompress/;
use Carp;

sub get_freezer {
    my ( $class, $column, $info, $args ) = @_;

    my $size = $info->{'size'};
    my $compress_method = $info->{compress_method} || 'zlib';

    return sub {
        my $b;

        if ( $compress_method eq 'zlib' ) {
            $b = compress( JSON::to_json(shift) );
        }
        elsif ( $compress_method eq 'mysql' ) {
            my $json = JSON::to_json(shift);
            $b = pack( 'L', length($json) ) . compress($json);
        }
        else {
            croak "Unknown compress method: '$compress_method'";
        }

        # check for known errors
        croak "could not get a compressed binary" unless defined $b;
        croak "serialization too big"
          if defined $size && ( length($b) > $size );
        return $b;
    };
}

sub get_unfreezer {
    my ( $class, $column, $info, $args ) = @_;

    my $compress_method = $info->{compress_method} || 'zlib';

    return sub {
        my $j;
    
        if ($compress_method eq 'zlib') {
            $j = uncompress(shift);
        }
        elsif ( $compress_method eq 'mysql' ) {
            $j = uncompress(substr(shift,4));
        }
        else {
            croak "Unknown compress method: '$compress_method'";
        }
        
        croak "could not get an uncompressed scalar" unless defined( $j );
        return JSON::from_json($j);
    };
}


1;


=pod

=head1 NAME

DBIx::Class::InflateColumn::Serializer::CompressJSON - DBIx::Class::InflateColumn::Serializer::CompressJSON - JSON compressed Inflator

=head1 VERSION

version 0.001

=head1 NAME

DBIx::Class::InflateColumn::Serializer::JSON - CompressJSON Inflator
=head1 SYNOPSIS

  package MySchema::Table;
    use base 'DBIx::Class';

    __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
    __PACKAGE__->add_columns(
        'data_column' => {
            'data_type' => 'VARCHAR',
            'size'      => 255,
            'serializer_class'   => 'CompressJSON'
        }
     );

     Then in your code...

     my $struct = { 'I' => { 'am' => 'a struct' };
     $obj->data_column($struct);
     $obj->update;

     And you can recover your data structure with:

     my $obj = ...->find(...);
     my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database in JSON format.

=over 4

=item get_freezer

Called by DBIx::Class::InflateColumn::Serializer to get the routine that serializes
the data passed to it. Returns a coderef.

=item get_unfreezer

Called by DBIx::Class::InflateColumn::Serializer to get the routine that deserializes
the data stored in the column. Returns a coderef.

=back

=head1 AUTHOR

Baptiste FOSSÉ <baptiste@weborama.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Weborama.  No
license is granted to other entities.

=cut


__END__



