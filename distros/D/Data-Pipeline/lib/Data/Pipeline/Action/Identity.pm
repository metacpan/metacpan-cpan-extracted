package Data::Pipeline::Action::Identity;

use Moose;
with 'Data::Pipeline::Action';

sub map_item {
    my($self, $item) = @_;

    return $item;
}

1;

__END__

