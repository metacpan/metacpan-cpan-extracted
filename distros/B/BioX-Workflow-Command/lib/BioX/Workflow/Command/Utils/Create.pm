package BioX::Workflow::Command::Utils::Create;
use MooseX::App::Role;
use BioX::Workflow::Command::Utils::Traits qw(ArrayRefOfStrs);
use Storable qw(dclone);

option 'rules' => (
    traits        => ['Array'],
    is            => 'rw',
    required      => 0,
    isa           => ArrayRefOfStrs,
    documentation => 'Add rules',
    default       => sub { ['rule1'] },
    cmd_split     => qr/,/,
    handles       => {
        all_rules  => 'elements',
        has_rules  => 'count',
        join_rules => 'join',
    },
    cmd_aliases => ['r'],
);

sub add_rules {
  my $self = shift;

    my $rules = [];

    my @process = (
        'INDIR: {$self->indir}',
        'INPUT: {$self->INPUT}',
        'outdir: {$self->outdir} ',
        'OUTPUT: {$self->OUTPUT->[0]}',
    );
    my $pr = join( "\n", @process );

    my $rule_template = {
        'local' => [
            { INPUT  => '{$self->root_dir}/some_input_rule1' },
            { OUTPUT => ['some_output_rule1'] },
        ],
        process => $pr
    };

    foreach my $rule ( $self->all_rules ) {
        my $href = { $rule => dclone($rule_template) };
        push( @{$rules}, $href );
    }

    return $rules;
}

1;
