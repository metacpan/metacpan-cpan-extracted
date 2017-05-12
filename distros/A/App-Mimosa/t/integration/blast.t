use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use App::Mimosa::Test;
use aliased 'App::Mimosa::Test::Mech';
use Test::DBIx::Class;
use File::Slurp qw/slurp/;
use File::Spec::Functions;

fixtures_ok('basic_ss');

my $mech = Mech->new;
my $seq  = slurp(catfile(qw/t data blastdb_test.nucleotide.seq/));
my $fasta = <<FASTA;
>OMGBBQWTF
TCTGCGAGATGCAGAAACTAAAATAGTTCCAATTCCAATATCTCACAAAGCCACTACCCC
CCACCCCCACTCCCCCAAAAAAAAGGCTGCCACACTAAGATATAGTAAGGCTCAACCATC
TAATAAATAAAGAATGAAAATCATTACTGCCTGATTGAGAACTTATTTTGCTAAATAAAA
FASTA

$mech->get_ok('/');

$mech->submit_form_ok({
    form_name => 'main_input_form',
    fields => {
        sequence                => $seq,
        mimosa_sequence_set_ids => 1,
        program                 => "blastn",
      },
},
'submit single sequence with defaults',
) or diag $mech->content;

$mech->content_contains('All hits shown');


# now try a spammy submission
$mech->get_ok('/');
$mech->submit_form(
    form_name => 'main_input_form',
    fields => {
        sequence               => '<a href="spammy.html">Spammy McSpammerson!</a>',
        mimosa_sequence_set_ids => 1,
        program                => 'blastn',
    },
);

is $mech->status, 400, 'error for illegal characters in sequence';

$mech->content_like( qr!contains illegal!i, 'spammy submission errors' );

# now try a spammy submission
$mech->get_ok('/');
$mech->submit_form(
    form_name => 'main_input_form',
    fields => {
        sequence               => '',
        mimosa_sequence_set_ids => 1,
    },
);
$mech->content_like( qr/error/i, 'Spammy submission errors' );
is $mech->status, 400, 'input error for empty sequence';

#try an submission that will be sure to get us an ungapped error
$mech->get_ok('/');
$mech->submit_form(
    form_name => 'main_input_form',
    fields => {
        filtered               => 'T',
        sequence               => 'A'x40,
        mimosa_sequence_set_ids => 1,
        program                => "blastn",
    },
);
$mech->content_like( qr/error/i );
is $mech->status, 400, 'input error for ungapped stuff';

$mech->get_ok('/');
$mech->submit_form(
    form_name => 'main_input_form',
    fields => {
        filtered               => 'T',
        mimosa_sequence_set_ids => 1,
        sequence               => 'ATGCTAGTCGTCGATAGTCGTAGTAGCTGA',
        program => '',
    },
);
$mech->content_like( qr/Error!/i);
is $mech->status, 400, 'input error if no program is selected' or diag $mech->content;

{


sub test_blast_hits() {
    $mech->get_ok('/');
    $mech->submit_form_ok({
        form_name => 'main_input_form',
        fields => {
            mimosa_sequence_set_ids => 1,
            filtered               => 'T',
            sequence               => $fasta,
            program                => "blastn",
        },
    });
    $mech->content_like( qr/Sbjct: /, 'got a blast hit') or diag $mech->content;
    $mech->content_like( qr/OMGBBQWTF/, 'fasta defline found in report') or diag $mech->content;

    my @links = $mech->find_all_links( url_regex => qr!/api/! );
    $mech->links_ok( \@links, "All /api links work: " . join(" ",map { $_->url } @links) );

    for my $img ($mech->find_all_images()) {
        $mech->get_ok($img->url, $img->url . " works");
    }

}
    test_blast_hits();
    # do it again to exercise cached codepaths
    test_blast_hits();

}

sub test_composite_blast_hits() {
    my $mech = Mech->new;
    $mech->get_ok('/');
    $mech->submit_form_ok({
        form_name => 'main_input_form',
        fields => {
            mimosa_sequence_set_ids => "1,2",
            filtered               => 'T',
            sequence               => $fasta,
            program                => "blastn",
        },
    }, 'submit composite sequence sets');
    $mech->content_like( qr/Sbjct: /, 'got a blast hit') or diag $mech->content;
    $mech->content_like( qr/OMGBBQWTF/, 'fasta defline found in report') or diag $mech->content;

    my @links = $mech->find_all_links( url_regex => qr!/api/! );
    $mech->links_ok( \@links, "All /api links work: " . join(" ",map { $_->url } @links) );
    for my $l (@links){
        $mech->get($l->url);
        $mech->content_unlike(qr/(Error|sequence set cannot be found)/);
    }
    for my $img ($mech->find_all_images()) {
        $mech->get_ok($img->url, $img->url . " works");
    }

}

test_composite_blast_hits();
# do it again to exercise cached codepaths
test_composite_blast_hits();

done_testing;
