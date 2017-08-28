package BioX::Workflow::Command::run::Rules::Directives::Types::Array;

use Moose::Role;

sub create_ARRAY_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    $meta->add_attribute(
        $k => (
            traits  => ['Array'],
            isa     => 'ArrayRef',
            is      => 'rw',
            clearer => "clear_$k",
            default => sub { [] },
            handles => {
                "all_$k" . "s" => 'elements',
                "count_$k"     => 'count',
                "has_$k"       => 'count',
                "has_no_$k"    => 'is_empty',
            },
        )
    );
}

1;
