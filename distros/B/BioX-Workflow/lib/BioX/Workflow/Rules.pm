package BioX::Workflow::Rules;

use Moose::Role;

=head1 BioX::Workflow::Rules

Check rules, select rules, match against rules. Its all about the rules.

=head2 Variables

=head3 select_rules

Select a subsection of rules

=cut

has 'select_rules' => (
    traits   => ['Array'],
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
    required => 0,
    handles  => {
        all_select_rules    => 'elements',
        add_select_rule     => 'push',
        map_select_rules    => 'map',
        filter_select_rules => 'grep',
        find_select_rule    => 'first',
        get_select_rule     => 'get',
        join_select_rules   => 'join',
        count_select_rules  => 'count',
        has_select_rules    => 'count',
        has_no_select_rules => 'is_empty',
        sorted_select_rules => 'sort',
    },
    documentation => q{Select a subselection of rules.},
);

=head3 match_rules

Select a subsection of rules by regexp

=cut

has 'match_rules' => (
    traits   => ['Array'],
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
    required => 0,
    handles  => {
        all_match_rules    => 'elements',
        add_match_rule     => 'push',
        map_match_rules    => 'map',
        filter_match_rules => 'grep',
        find_match_rule    => 'first',
        get_match_rule     => 'get',
        join_match_rules   => 'join',
        count_match_rules  => 'count',
        has_match_rules    => 'count',
        has_no_match_rules => 'is_empty',
        sorted_match_rules => 'sort',
    },
    documentation => q{Select a subselection of rules by regular expression},
);

=head3 number_rules

    Instead of
    outdir/
        rule1
        rule2

    outdir/
        001-rule1
        002-rule2

=cut

has 'number_rules' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

=head3 counter_rules

Keep track of the number of our rules. Only used when --number_rules enabled

=cut

has 'counter_rules' => (
    traits  => ['Counter'],
    is => 'rw',
    isa => 'Num',
    default => 1,
    handles => {
        inc_counter_rules   => 'inc',
        dec_counter_rules   => 'dec',
        reset_counter_rules => 'reset',
    },
);

=head3 override_process

local:
    - override_process: 1

=cut

has 'override_process' => (
    traits    => ['Bool'],
    is        => 'rw',
    isa       => 'Bool',
    default   => 0,
    predicate => 'has_override_process',
    documentation =>
        q(Instead of for my $sample (@sample){ DO STUFF } just DOSTUFF),
    handles => {
        set_override_process   => 'set',
        clear_override_process => 'unset',
    },
);

=head2 Subroutines

=head3 check_rules

If we have select_rules or match_rule only process those rules and skip all others

=cut

sub check_rules{
    my $self = shift;

    my $ret = 0;
    my $p = $self->key;

    $DB::single=2;
    $DB::single=2;

    if ( $self->has_select_rules ) {
        if ( !$self->filter_select_rules( sub {/^$p$/} ) ) {
            $ret = 1;
        }
    }

    if ( $self->has_match_rules ) {
        if ( !$self->map_match_rules( sub {$p =~ m/$_/} ) ) {
            $ret = 1;
        }
    }

    if($ret){
        $self->OUTPUT_to_INPUT;
        $self->clear_process_attr;

        $self->pkey( $self->key );
        $self->indir( $self->outdir . "/" . $self->pkey )
            if $self->auto_name;
    }

    return $ret;
}

1;
