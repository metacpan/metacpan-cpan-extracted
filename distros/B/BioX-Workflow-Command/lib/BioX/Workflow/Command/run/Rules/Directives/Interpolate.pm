package BioX::Workflow::Command::run::Rules::Directives::Interpolate;

use Moose::Role;
use namespace::autoclean;

use Moose::Util qw/apply_all_roles/;

use Try::Tiny;

has 'interpol_directive_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'errors' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

#TODO This should not be here
has 'before_meta' => (
    traits    => ['String'],
    is        => 'rw',
    isa       => 'Str',
    default   => q{},
    predicate => 'has_before_meta',
    required  => 0,
    handles   => {
        add_before_meta     => 'append',
        replace_before_meta => 'replace',
    },
);

after 'BUILD' => sub {
    my $self = shift;

    return if $self->can('interpol_directive');

    my $role = 'BioX::Workflow::Command::run::Rules::Directives::Interpolate::'.$self->template_type;
    try {
        apply_all_roles( $self, $role );
    }
    catch {
        $self->app_log->warn( 'There was an error registering Template role ' . $role );
        $self->app_log->warn( $@ . "\n" );
    };
};

1;
