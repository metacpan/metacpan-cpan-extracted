package Catalyst::Plugin::Session::Manager::Storage;
use strict;
use warnings;

use Storable;

sub new { bless { config => $_[1] || {} }, $_[0] }
sub set { }
sub get { }

sub deserialize {
    my ( $self, $data ) = @_;
    Storable::thaw($data);
}

sub serialize {
    my ( $self, $data ) = @_;
    Storable::freeze($data);
}

1;
__END__

