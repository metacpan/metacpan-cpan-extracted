package BioX::Workflow::Command::run::Utils::Files::ResolveDeps;

use MooseX::App::Role;
use namespace::autoclean;

use String::Approx 'amatch';
use Algorithm::Dependency::Source::HoA;
use Algorithm::Dependency::Ordered;
use Try::Tiny;
use Path::Tiny;
use Text::ASCIITable;
use Data::Dumper;

option 'auto_deps' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation =>
      'Create a dependency tree using the INPUT/OUTPUTs of a rule',
);

has 'rule_deps' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        seen_rule_deps_pairs => 'kv',
        clear_seen_rule_deps => 'clear',
    },
);

has 'graph' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        seen_graph_pairs => 'kv',
        clear_seen_graph => 'clear',
    },
);

sub add_graph {
    my $self = shift;
    my $cond = shift;

    return unless $self->files;
    return unless $self->has_files;

    for my $file ( $self->all_files ) {
        if ( !exists $self->rule_deps->{ $self->rule_name }->{$cond}->{$file} )
        {
            $self->rule_deps->{ $self->rule_name }->{$cond}->{$file} = 1;
        }
    }
}

sub post_process_rules {
    my $self = shift;

    #Create flags for outputs that have a similar input
    $self->app_log->info();

    $self->dedeps;
    $self->process_auto_deps;

    $self->print_process_workflow;
}

sub print_stats_rules {
    my $self = shift;
    my $rule = shift;

    return unless $self->process_obj->{$rule}->{run_stats};
    $self->fh->say("");

    $self->fh->say( $self->comment_char );
    $self->fh->say(
        $self->comment_char . " Starting " . $rule . "_biox_stats" );
    $self->fh->say( $self->comment_char );
    $self->fh->say("");

    $self->fh->say( $self->comment_char );
    $self->fh->say( '### HPC Directives' . "\n" );
    $self->fh->say( $self->comment_char );
    $self->fh->say( '#HPC jobname=' . $rule . "_biox_stats" );
    $self->fh->say( '#HPC deps=' . $rule );
    $self->fh->say('#HPC mem=2GB');
    $self->fh->say('#HPC cpus_per_task=1');
    $self->fh->say('#HPC commands_per_node=1000');
    $self->fh->say( $self->comment_char );
    $self->fh->say("");

    foreach my $sample ($self->all_samples){
    $self->fh->say("");
    $self->fh->say(
        "biox stats --samples " . $sample . " \\" );
    $self->fh->say( "--select_rules " . $rule . " \\" );
    $self->fh->say( "-w " . $self->cached_workflow );
    $self->fh->say("");
    }
}

=head3 dedeps

If using select_rules comment out the #HPC deps portion on the first rule

#TODO add this in to iter_hash_hpc instead of here, account for select_btwn

=cut

sub dedeps {
    my $self = shift;

    return unless $self->has_select_rule_keys;
    return unless $self->select_effect;

    my $first_rule = $self->select_rule_keys->[0];

    my $meta = $self->process_obj->{$first_rule}->{meta};
    $meta = [] unless $meta;
    my $before_meta = join( "\n", @{$meta} );

    $before_meta =~ s/#HPC deps=/##HPC deps=/g;
    my @text = split( "\n", $before_meta );
    $self->process_obj->{$first_rule}->{meta} = \@text;
}

=head3

Iterate over rule_names
If they are in select_rules use those also
Otherwise only use the schedule
If using timestamps we have a timestamp, but in no particular order
If select rules we have select_rules, but also in no particular Ordered
for $s @schedule { if print_rule (print the process_obj)}
We also need to update the #HPC meta to include deps

=cut

sub process_auto_deps {
    my $self = shift;

    return unless $self->auto_deps;

    foreach my $rule ( $self->all_select_rule_keys ) {

        $self->graph->{$rule} = [] if !exists $self->graph->{$rule};
        my $meta = $self->process_obj->{$rule}->{meta};
        $meta = [] unless $meta;
        my $before_meta = join( "\n", @{$meta} );

        if ( $before_meta =~ m/#HPC deps=/ ) {
            next;
        }
        my @deps = @{ $self->graph->{$rule} };
        if (@deps) {
            chomp($before_meta);
            $before_meta .= "\n#HPC deps=" . join( ',', @deps ) . "\n\n";
        }
        my @text = split( "\n", $before_meta );
        $self->process_obj->{$rule}->{meta} = \@text;
    }
}

1;
