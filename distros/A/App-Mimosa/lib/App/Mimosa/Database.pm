package App::Mimosa::Database;
use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use Cwd;

use File::Spec::Functions;
use File::Basename;
use autodie ':all';

use Bio::BLAST::Database;
#use Carp::Always;

# TODO: store this in a shared place, because App::Mimosa::Job has it too
enum 'Alphabet' => qw(protein nucleotide);

has alphabet => (
    isa     => 'Alphabet',
    is      => 'rw',
    required => 1,
);

has db_basename => (
    isa     => 'Str',
    is      => 'rw',
    required => 1,
);

has db => (
    isa => 'Bio::BLAST::Database',
    is  => 'rw',
);

has context => (
    is  => 'rw',
);

sub get_sequence {
    my ($self, $name) = @_;

    my $db = Bio::BLAST::Database->open(
        full_file_basename => $self->db_basename,
        type               => $self->alphabet,
        write              => 1,
        create_dirs        => 1,
    );

    $self->db($db);

    $self->debug("Is it indexed? " . ( $self->db->indexed_seqs ? 1 : 0 ));
    $self->debug("Complete? " . ( $self->db->files_are_complete ? 1 : 0 ));

    $self->debug("get_sequence($name)");
    my $sequence = $db->get_sequence($name);

    return $sequence;
}

sub debug {
    my ($self, $msg) = @_;
    if ($self->context) {
        $self->context->log->debug($msg);
    }
}

sub index {
    my ($self, %opts) = @_;
    my $dir = dirname($self->db_basename);
    my $cwd = getcwd;
    chdir $dir;

    my $seqfile = catfile($self->db_basename);

    my $db = Bio::BLAST::Database->open(
        full_file_basename => $self->db_basename,
        type               => $self->alphabet,
        write              => 1,
        create_dirs        => 1,
    );
    $self->debug("Created Bio::BLAST::Database $db");
    $self->db($db);

    unless ($self->already_indexed) {
        $self->debug("indexing $seqfile");
        $seqfile .= '.seq' unless $seqfile =~ m/\.seq$/;
        $self->db->format_from_file(
            seqfile      => "$seqfile",
            title        => basename($self->db_basename),
            indexed_seqs => 1,
        );
    }

    chdir $cwd;
    return $self;
}

sub already_indexed {
    my ($self, %opts) = @_;

    my $basename        = $self->db_basename;
    my @nucleotide_exts = qw/nhr nin nsq/;
    my @protein_exts    = qw/phr pin psq/;

    if($self->alphabet eq 'nucleotide') {
        map { return 0 unless -s "$basename.$_" } @nucleotide_exts;
    } elsif ($self->alphabet eq 'protein') {
        map { return 0 unless -s "$basename.$_" } @protein_exts;
    }
    return 1;
}

1;
