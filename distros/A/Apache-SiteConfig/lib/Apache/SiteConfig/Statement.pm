package Apache::SiteConfig::Statement;
use Moose;

has parent => ( is => 'rw' );

sub get_level {
    my ($self) = @_;
    my $cnt = 0;
    my $p = $self->parent;
    $cnt++ if $p;
    while( $p && $p->parent ) {
        $p = $p->parent;
        $cnt++;
    }

    return $cnt;
}

1;
