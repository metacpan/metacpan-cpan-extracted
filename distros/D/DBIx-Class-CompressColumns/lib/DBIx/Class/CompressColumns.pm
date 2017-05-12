package DBIx::Class::CompressColumns;

use strict;
use warnings;

use vars qw($VERSION);
use base qw/DBIx::Class/;
use Compress::Zlib qw/compress uncompress/;

__PACKAGE__->mk_classdata( 'compress_auto_columns' => [] );
__PACKAGE__->mk_classdata( 'compress_auto' => 1 );
__PACKAGE__->mk_classdata( 'compress_maker' );

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too

$VERSION = '0.01001';

=head1 NAME

DBIx::Class::CompressColumns - Automatic Compression/Decompression of columns

=head1 SYNOPSIS

In your L<DBIx::Class> table class:

  __PACKAGE__->load_components(qw/CompressColumns ... Core/);

  __PACKAGE__->compresscolumns(
      columns   => [qw/ column_foo /],
      auto      => 1,
  );

B<Note:> The component needs to be loaded I<before> Core.

Alternatively you could call each method individually  

  __PACKAGE__->compress_columns(qw/ column_foo /);
  __PACKAGE__->compress_auto(1);



=head1 DESCRIPTION

This L<DBIx::Class> component can be used to automatically compress and decompress
data in selected columns.

=head1 METHODS

=head2 compresscolumns

  __PACKAGE__->compresscolumns(
      columns   => [qw/ column_foo /],
      auto      => 1,
  );

Calls L</compress_columns>  and L</compress_auto> if the
corresponding argument is defined.

=cut

sub compresscolumns {
    my $self = shift;
    my %args = @_;
    $self->compress_columns( @{$args{columns}} ) if exists $args{columns};
    $self->compress_auto( $args{auto} ) if exists $args{auto};
}

=head2 compress_columns

Takes a list of columns to be compressed/decompressed during insert or retrieval.

  __PACKAGE__->compress_columns(qw/ column_foo /);

=cut

sub compress_columns {
    my $self = shift;
    for (@_) {
        $self->throw_exception("column $_ doesn't exist") unless $self->has_column($_);
    }
    $self->compress_auto_columns(\@_);
}

=head2 _get_compressed_binary $value

Handles the actual compression of column values into binary objects.
When given a C<$value> it will return the compressed binary for
that value.

=cut

sub _get_compressed_binary {
    my ($self, $value) = @_;
	
	my $compressed_binary = compress($value,9);
    
    $self->throw_exception("could not get a compressed binary$@") 
	unless defined( $compressed_binary );

    return $compressed_binary;
}

=head2 _get_uncompressed_scalar $value

Handles the actual decompression of column values into scalar strings.
When given a C<$value> it will return the uncompressed scalar for
that compressed binary value.

=cut

sub _get_uncompressed_scalar {
    my ($self, $value) = @_;
	
	my $uncompressed_scalar = uncompress($value);
    
    $self->throw_exception("could not get an uncompressed scalar:$@") 
	unless defined( $uncompressed_scalar );

    return $uncompressed_scalar;
}

=head2 _compress_column_values

Go through the columns and compress the values that need it.

This method is called by insert and update when automatic compression
is turned on.

=cut

sub _compress_column_values{
    my $self = shift;

    for my $col (@{$self->compress_auto_columns}) {
		warn "in compress_column_values. col: $col";
	
		#don't compress null columns
		my $col_v = $self->get_column( $col );

		#update column value with encoded value if needed
		$self->set_column( $col, $self->_get_compressed_binary( $col_v ) );
    }    
}

=head2 compress_auto

  __PACKAGE__->compress_auto(1);

Turns on and off automatic compression/decompression of columns.  When on, this feature makes all
UPDATEs and INSERTs automatically insert a compressed binary into selected columns. SELECTS will
retrieve the decompressed scalar from selected columns.

The default is for compress_auto is to be on.

=head1 EXTENDED METHODS

The following L<DBIx::Class::Row> methods are extended by this module:-

=over 4

=item insert

=cut

sub insert {
    my $self = shift;
    $self->_compress_column_values if $self->compress_auto;
    $self->next::method(@_);
}

=item update

=cut

sub update {
    my ( $self, $upd, @rest ) = @_;
    if ( ref $upd ) {
        for my $col ( @{$self->compress_auto_columns} ) {
			$upd->{$col} = compress($upd->{$col},9) if ( exists $upd->{$col} );
        }
    }
    $self->next::method($upd, @rest);
}

=back

=head2 get_column

=cut

sub get_column {
    my ( $self, $column ) = @_;
    my $value = $self->next::method($column);

    if( defined $value ) {
		for my $col ( @{$self->compress_auto_columns} ) {
			if ( $column eq $col ) {
        		$value = $self->compress_auto ? uncompress( $value ) : $value;
			}
		}
    }

    return $value;
}

=head2 get_columns

=cut

sub get_columns {
    my $self = shift;
    my %data = $self->next::method(@_);

    foreach my $col (keys %data) {
        if(defined(my $value = $data{$col}) ) {
			for my $col2 ( @{$self->compress_auto_columns} ) {
				if ($col eq $col2) {
            		$value = $self->compress_auto ? uncompress( $value ) : $value;
            		$data{$col} = $value;
				}
			}
        }
    }

    return %data;
}

1;
__END__

=head1 SEE ALSO

L<DBIx::Class>,
L<Compress::Zlib>

=head1 AUTHOR

Jesse Stay (jessestay) <jesse@staynalive.com>

A Product of SocialToo.com

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
