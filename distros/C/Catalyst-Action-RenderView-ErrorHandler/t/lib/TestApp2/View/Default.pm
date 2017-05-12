package TestApp2::View::Default;

use base qw( Catalyst::View::TT );

sub process {
    my( $self, $c ) = @_;
    $self->maybe::next::method($c);
}

1;
