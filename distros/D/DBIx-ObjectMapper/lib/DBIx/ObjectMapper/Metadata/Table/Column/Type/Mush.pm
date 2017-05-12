package DBIx::ObjectMapper::Metadata::Table::Column::Type::Mush;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type::Text);

use Storable ();
use MIME::Base64 ();

sub from_storage {
    my ( $self, $val ) = @_;
    return $val if !defined $val or ref $val;
    return Storable::thaw(MIME::Base64::decode($val));
}

sub to_storage {
    my ( $self, $val ) = @_;
    return $val unless defined $val and ref($val);
    $val = $$val if ref $val eq 'REF';
    return MIME::Base64::encode(Storable::nfreeze($val));
}

1;
