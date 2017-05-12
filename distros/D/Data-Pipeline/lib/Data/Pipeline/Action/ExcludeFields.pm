package Data::Pipeline::Action::ExcludeFields;

use Moose;
with 'Data::Pipeline::Action';

has fields => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [ ] },
    predicate => 'has_fields',
);

sub map_item {
    my($self, $item) = @_;

    delete @{$item}{@{$self -> fields}};
    $item;
}

1;

__END__
