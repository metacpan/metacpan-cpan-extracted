package Data::ClearSilver::HDF;

use strict;
use warnings;

use ClearSilver;
use Data::Structure::Util qw(unbless has_circular_ref circular_off);
use File::Slurp qw(slurp);
use File::Temp;

=head1 NAME

Data::ClearSilver::HDF - Convert from Perl Data Structure to ClearSilver HDF

=head1 VERSION

version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use Data::ClearSilver::HDF;

  my $data = {
    foo => {
      bar => 1,
      baz => [0 .. 5]
    },
    obj => bless { foo => "xxx", bar => "yyy" }
  };

  my $hdf = Data::ClearSilver::HDF->hdf($data);

  print $hdf->getValue("obj.foo", undef); # xxx

=head1 PROPERTIES

=head2 $USE_SORT

Sorting each keys hieralcally. default false;

=cut

our $USE_SORT = 0;

=head1 METHODS

=head2 hdf($data)

The argument $data must be reference.
In the data, all of value excluded ARRAY, HASH, blessed reference will be ignored.

Blessed reference will be unblessed by L<Data::Structure::Util>'s unbless functon.

=cut

sub hdf {
    my ( $class, $data ) = @_;

    unbless($data);
    circular_off($data) if ( has_circular_ref($data) );

    my $hdf       = ClearSilver::HDF->new;
    my $data_type = ref $data;

    unless ( $data_type && ( $data_type eq "ARRAY" || $data_type eq "HASH" ) ) {
        return $hdf;
    }
    else {
        my $method = "hdf_" . lc($data_type);
        $class->$method( $hdf, undef, $data );
        _hdf_walk($hdf) if ($USE_SORT);
        return $hdf;
    }
}

=head2 hdf_dump($hdf)

Dump as string from ClearSilver::HDF object.
This method will create temporary file.

=cut

sub hdf_dump {
    my ( $class, $hdf ) = @_;

    my $fh = File::Temp->new;
    $hdf->writeFile( $fh->filename );

    return slurp( $fh->filename );
}

=head2 hdf_scalar($hdf, $keys, $data)

Translate scalar data to hdf.
Please don't call directory.

=cut

sub hdf_scalar {
    my ( $class, $hdf, $keys, $data ) = @_;

    $hdf->setValue( join( ".", @$keys ), $data );
}

=head2 hdf_array($hdf, $keys, $data)

Translate array reference data to hdf.
Please don't call directory.

=cut

sub hdf_array {
    my ( $class, $hdf, $keys, $data ) = @_;

    $keys ||= [];
    my $idx = 0;

    for my $value (@$data) {
        my @keys      = @$keys;
        my $value_ref = ref $value;

        push( @keys, $idx );

        unless ( defined $value && $value_ref ) {
            $class->hdf_scalar( $hdf, \@keys, $value );
        }
        elsif ( $value_ref eq "ARRAY" ) {
            $class->hdf_array( $hdf, \@keys, $value );
        }
        elsif ( $value_ref eq "HASH" ) {
            $class->hdf_hash( $hdf, \@keys, $value );
        }
        else {
            next;
        }

        $idx++;
    }
}

=head2 hdf_hash($hdf, $keys, $data)

Translate hash reference data to hdf.
Please don't call directory.

=cut

sub hdf_hash {
    my ( $class, $hdf, $keys, $data ) = @_;

    $keys ||= [];

    while ( my ( $key, $value ) = each %$data ) {
        my @keys      = @$keys;
        my $value_ref = ref $value;

        push( @keys, $key );

        unless ( defined $value && $value_ref ) {
            $class->hdf_scalar( $hdf, \@keys, $value );
        }
        elsif ( $value_ref eq "ARRAY" ) {
            $class->hdf_array( $hdf, \@keys, $value );
        }
        elsif ( $value_ref eq "HASH" ) {
            $class->hdf_hash( $hdf, \@keys, $value );
        }
        else {
            next;
        }
    }
}

### private method

sub _hdf_walk {
    my $hdf = shift;
    $hdf->sortObj("_hdf_sort");
    my $child = $hdf->objChild;
    _hdf_walk($child) if ($child);
    my $next = $hdf->objNext;
    _hdf_walk($next) if ($next);
}

sub _hdf_sort {
    my ( $a, $b ) = @_;

    return $a->objName cmp $b->objName;
}

=head1 SEE ALSO

=over 4

=item http://www.clearsilver.net/

This module requires ClearSilver and ClearSilver's perl binding.

=item http://www.clearsilver.net/docs/perl/

ClearSilver perl binding documentation.

=item L<Data::Structure::Util>

=item L<File::Slurp>

=item L<File::Temp>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-clearsilver-hdf@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Data::ClearSilver::HDF
