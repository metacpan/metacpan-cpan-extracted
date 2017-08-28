package BioX::Workflow::Command::run::Rules::Directives::Types::Hash;

use Moose::Role;

sub create_HASH_attr {
    my $self = shift;
    my $meta = shift;
    my $k    = shift;

    $meta->add_attribute(
        $k => (
            traits  => ['Hash'],
            isa     => 'HashRef',
            is      => 'rw',
            clearer => "clear_$k",
            default => sub { {} },
            handles => {
                "get_$k"        => 'get',
                "has_no_$k"     => 'is_empty',
                "num_$k"        => 'count',
                "$k" . "_pairs" => 'kv',
            },
        )
    );
}

1;
