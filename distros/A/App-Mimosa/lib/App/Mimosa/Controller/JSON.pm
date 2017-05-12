package App::Mimosa::Controller::JSON;
use Moose;
use Bio::Chado::Schema;
use File::Spec::Functions;
use Set::Scalar;
use Digest::SHA1 'sha1_hex';
use App::Mimosa::Util qw/slurp/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    'map' => {
        # Work around an ExtJS bug that sends the wrong content-type
        'text/html'        => 'JSON',
    }

);

sub grid_json :Path("/api/grid/json.json") :ActionClass('REST') :Local { }

# Answer GET requests to the above Path
sub grid_json_GET {
    my ( $self, $c ) = @_;

    my $data = _grid_json_data($c);
    # Return a 200 OK, with the data in entity serialized in the body
    $self->status_ok( $c, entity => $data );
}

sub autodetect :Private {
    my ($self, $c) = @_;
    my $bcs        = $c->model('BCS');
    my $config     = $self->_app->config;
    my $seq_dir    = $config->{sequence_data_dir};

    # This isn't madness, this is FASTA!
    # http://en.wikipedia.org/wiki/FASTA_format#File_extension
    my @fasta_extensions = qw/fasta fna ffn faa frn fa seq mpfa/;
    my @globs            = glob(join " ", map { catfile($seq_dir, "*.$_") } @fasta_extensions);
    my @seq_files  = map { $_ =~ s!$seq_dir/(.*)!$1!g; $_ } grep { !-d } @globs;
    my $rs         = $bcs->resultset('Mimosa::SequenceSet');
    my @shortnames = map { $_->shortname } ($rs->all);

    # set difference
    my @new_sets = (Set::Scalar->new(@seq_files) - Set::Scalar->new(@shortnames))->elements;

    # nonzero difference means we have new sequence files, so we grab metadata about them
    if (@new_sets) {
        for my $seq_set (@new_sets) {
            my $fasta      = slurp("$seq_dir/$seq_set");
            my $sha1       = sha1_hex($fasta);
            $c->log->debug("adding $seq_dir/$seq_set ($sha1) to the db");
            # insert data about new sequences
            $rs->create({
                title     => "stuff and thangs",
                sha1      => $sha1,
                shortname => $seq_set,
                # do we have to guess this?
                alphabet  => 'nucleotide',
                info_url  => 'http://localhost',
            });
        }
    }
}

sub _grid_json_data {
    my ($c) = @_;

    $c->forward('autodetect');

    my $bcs = $c->model('BCS');

    # Mimosa resultsets
    my @sets   = $bcs->resultset('Mimosa::SequenceSet')->all;
    my $sso_rs = $bcs->resultset('Mimosa::SequenceSetOrganism');

    # Chado resultsets
    my $org_rs = $bcs->resultset('Organism');
    my ($common_name, $binomial, $name);

    return { total => $#sets, rows =>
        [ map {         my $rs = $sso_rs->search( { mimosa_sequence_set_id => $_->mimosa_sequence_set_id });
                        if ($rs->count) {
                            my $org      = $org_rs->find( { organism_id => $rs->single->organism_id });
                            $common_name = $org->common_name;
                            $binomial    = $org->species;
                            $name        = $binomial;
                            $name       .= " ($common_name)" if $common_name;
                        } else {
                            $name = $_->shortname;
                        }

                        +{
                            mimosa_sequence_set_id => $_->mimosa_sequence_set_id,
                            description            => $_->description,
                            name                   => $name,
                            alphabet               => $_->alphabet,
                        };
            } @sets
        ]
    };

}

1;
