package BioX::Workflow::Command::run::Utils::Attributes;

use strict;
use warnings FATAL => 'all';
use MooseX::App::Role;
use namespace::autoclean;

use BioSAILs::Utils::Traits qw(ArrayRefOfStrs);
use Storable qw(dclone);
use File::Copy;
use File::Spec;
use File::Basename;
use DateTime;

=head1 Name

BioX::Workflow::Command::run::Utils::Attributes

=head2 Description

Attributes that are used for the duration of run

=cut

=head2 Command Line Options

=cut

option 'samples' => (
    traits        => ['Array'],
    is            => 'rw',
    required      => 0,
    isa           => ArrayRefOfStrs,
    documentation => 'Choose a subset of samples',
    default       => sub { [] },
    cmd_split     => qr/,/,
    handles       => {
        all_samples  => 'elements',
        has_samples  => 'count',
        join_samples => 'join',
    },
    cmd_aliases => ['s'],
);

has 'cached_workflow' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '',
    default => sub {
        my $self = shift;

        my ( $file, $dir, $ext ) = fileparse( $self->workflow, qr/\.[^.]*/ );
        my $now = DateTime->now;
        my $ymd = $now->ymd;
        my $hms = $now->hms;
        $hms =~ s/:/-/g;
        return File::Spec->catdir( $self->cache_dir, '.biox-cache', 'workflows',
            $file . "_$ymd" . "_$hms" . $ext );
    }
);

=head2 Attributes

=cut


=head3 local_rule1

Rule we are currently evaluating

=cut

has 'local_rule' => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

=head3 global_attr

Attributes defined in the global key of the config

=cut

has 'global_attr' => (
    is       => 'rw',
    isa      => 'BioX::Workflow::Command::run::Rules::Directives',
    required => 0,
);

=head3 local_attr

Attributes in the local key of the rule

=cut

has 'local_attr' => (
    is       => 'rw',
    isa      => 'BioX::Workflow::Command::run::Rules::Directives',
    required => 0,
);

has 'p_local_attr' => (
    is       => 'rw',
    isa      => 'BioX::Workflow::Command::run::Rules::Directives',
    required => 0,
);

has 'rule_name' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

has 'rule_names' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_rule_names         => 'elements',
        has_rule_names         => 'count',
        join_rule_names        => 'join',
        first_index_rule_names => 'first_index',
        grep_rule_names        => 'grep',
    },
);

has 'select_rule_keys' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_select_rule_keys         => 'elements',
        has_select_rule_keys         => 'count',
        join_select_rule_keys        => 'join',
        first_index_select_rule_keys => 'first_index',
        add_select_rule_key          => 'push',
    },
);

has 'omit_rule_keys' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_omit_rule_keys         => 'elements',
        has_omit_rule_keys         => 'count',
        join_omit_rule_keys        => 'join',
        first_index_omit_rule_keys => 'first_index',
        add_omit_rule_key          => 'push',
    },
);

has 'p_rule_name' => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,
);

=head3 process_obj

Store all the text from processing the rules

At the end we will decide which rules to print

=cut

has 'process_obj' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        seen_process_obj_pairs => 'kv',
        clear_seen_process_obj => 'clear',
    },
);

sub apply_local_attr {
    my $self = shift;

    return unless exists $self->local_rule->{ $self->rule_name }->{local};

    $self->local_attr->create_attr(
        $self->local_rule->{ $self->rule_name }->{local} );

}

sub apply_global_attributes {
    my $self = shift;

    my $global_attr = BioX::Workflow::Command::run::Rules::Directives->new();

    $self->global_attr($global_attr);

    return unless exists $self->workflow_data->{global};

    $self->global_attr->create_attr( $self->workflow_data->{global} );

#    if ( exists $self->global_attr->chunks->{start} ) {
#        $self->global_attr->use_chunks(1);
#    }
}

1;
