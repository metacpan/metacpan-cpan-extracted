package App::Mimosa::Aligner;
use Moose;

has program => (
    isa     => 'Str',
    is      => 'rw',
    default => 'blast',
);

has evalue => (
    isa     => 'Num',
    default => '1e-10',
    is      => 'rw',
);

has substitution_matrix => (
    isa     => 'Str',
    default => 'BLOSUM62',
    is      => 'rw',
);

has sequence_database => (
    isa     => 'Str',
    is      => 'rw',
);

1;
