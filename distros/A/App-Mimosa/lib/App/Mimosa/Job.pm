package App::Mimosa::Job;
use Moose;
use namespace::autoclean;
use autodie ':all';

use Bio::SeqIO;
use Moose::Util::TypeConstraints;
use Bio::BLAST::Database;
use File::Spec::Functions;

use IPC::Run qw/timeout/;

# Good breakdown of commandline flags
# http://www.molbiol.ox.ac.uk/analysis_tools/BLAST/BLAST_blastall.shtml
subtype 'Program'
             => as Str
             => where {
                    /^(blastn|tblastx|tblastn)$/;
                };
subtype 'SubstitutionMatrix'
             => as Str
             => where {
                    /^(BLOSUM|PAM)\d\d$/;
                };

has program => (
    isa     => 'Program',
    is      => 'rw',
    default => 'blastn',
);

has input_file => (
    isa => 'Str',
    is  => 'rw',
);

has context => (
    is  => 'rw',
);

has output_file => (
    isa => 'Str',
    is  => 'rw',
);

has evalue => (
    isa => 'Num',
    is  => 'rw',
    default => 0.01,
);

has maxhits => (
    isa => 'Int',
    is  => 'rw',
    default => 100,
);

has matrix => (
    isa     => 'SubstitutionMatrix',
    is      => 'rw',
    default => 'BLOSUM62',
);

enum 'BoolStr' => qw(T F);

enum 'Alphabet' => qw(protein nucleotide);

has alphabet => (
    isa     => 'Alphabet',
    is      => 'rw',
    required => 1,
);

has filtered => (
    isa     => 'BoolStr',
    is      => 'rw',
    default => 'T',
);

has db_basename => (
    isa     => 'Str',
    is      => 'rw',
    required => 1,
);

has config => (
    is      => 'rw',
);

has job_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => 30,
);

has alignment_view => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

sub debug {
    my ($self, $msg) = @_;
    if ($self->context) {
        $self->context->log->debug($msg);
    }
}

sub run {
    my ($self) = @_;
    my ($error, $output);

    $self->debug("creating Mimosa::Database");

    App::Mimosa::Database->new(
        context     => $self->context,
        alphabet    => $self->alphabet,
        db_basename => $self->db_basename,
    )->index;

    # Consult our configuration to see if qsub should be used

    if( $self->config->{disable_qsub} ) {
        my @blast_cmd = (
            'blastall',
            -v => 1,
            -d => $self->db_basename,
            -M => $self->matrix,
            -b => $self->maxhits,
            -e => $self->evalue,
            -p => $self->program,
            -F => $self->filtered,
            -i => $self->input_file,
            -o => $self->output_file,
            -m => $self->alignment_view,
        );
        $self->debug("Running (timeout=" . $self->timeout. ") @blast_cmd");

        my $harness        = IPC::Run::harness \@blast_cmd, \*STDIN, \$output, \$error, timeout( $self->timeout );

        $harness->start;
        $harness->finish;

    } else { # invoke qsub, if it was detected

    }

    return $error;
}

1;
