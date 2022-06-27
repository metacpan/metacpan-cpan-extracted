package App::GHPT::Wrapper::OurMooseX::Role::Parameterized::Meta::Trait::Parameterizable::Strict;

use App::GHPT::Wrapper::OurMoose::Role;

our $VERSION = '2.000000';

with 'MooseX::Role::Parameterized::Meta::Trait::Parameterizable';

around construct_parameters => sub ( $orig, $self, %params ) {
    my %attrs = (
        -alias    => 1,
        -excludes => 1,
        (
            map      { $_ => 1 }
                grep {defined}
                map  { $_->init_arg }
                $self->parameters_metaclass->get_all_attributes
        ),
    );

    if ( my @bad = sort grep { !exists $attrs{$_} } keys %params ) {
        die 'Found unknown parameter(s) passed to role: ' . join ', ',
            @bad;
    }

    return $self->$orig(%params);
};

1;
