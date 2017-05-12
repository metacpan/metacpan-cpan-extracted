package Install;

use Moose;


sub install {
    my ($self, $module, $mi ) = @_;
    $module->{installed} = 1;
}

sub uninstall {
    my ($self, $module, $mi ) = @_;
    $module->{installed} = 0;
}
1;
