## test script for Bio::Biblio and Bio::Biblio::IO
use utf8;
use strict;
use warnings;
use File::Spec;

use Test::More tests => 24;

BEGIN { use_ok("Bio::Biblio"); }
BEGIN { use_ok("Bio::Biblio::IO"); }

my $tfile_medline = File::Spec->catfile('t', 'data', 'stress_test_medline.xml');
my $tfile_pubmed  = File::Spec->catfile('t', 'data', 'stress_test_pubmed.xml');

my $biblio = Bio::Biblio->new(-location => 'http://localhost:4567');
ok (defined ($biblio));

my $io;

##
## check MEDLINE XML parser
##
$io = Bio::Biblio::IO->new('-format' => 'medlinexml',
                           '-file'   => $tfile_medline,
                           '-result' => 'raw');
ok (defined ($io));
is ($io->next_bibref->{'medlineID'}, 'Text1',   'citation 1');
is ($io->next_bibref->{'medlineID'}, 'Text248', 'citation 2');
is ($io->next_bibref->{'medlineID'}, 'Text495', 'citation 3');

## Getting citations using callback
my @ids = ('Text1', 'Text248', 'Text495');
my $callback_used = 'no';
sub callback {
    my $citation = shift;
    $callback_used = 'yes';
    is ($citation->{'_identifier'}, shift @ids, 'in callback');
}
$io = Bio::Biblio::IO->new('-format'   => 'medlinexml',
                           '-file'     => $tfile_medline,
                           '-callback' => \&callback);
is ($callback_used, 'yes', 'calling callback');

$io = Bio::Biblio::IO->new('-format'   => 'medlinexml',
                           '-data'     => "<MedlineCitationSet>
                                           <MedlineCitation>
                                           <MedlineID>12345678</MedlineID>
                                           <Article><Journal></Journal></Article>
                                           </MedlineCitation>
                                           <MedlineCitation>
                                           <MedlineID>abcdefgh</MedlineID>
                                           <Article><Journal></Journal></Article>
                                           </MedlineCitation>
                                           </MedlineCitationSet>");
is ($io->next_bibref->identifier, '12345678', 'citation 1');
is ($io->next_bibref->identifier, 'abcdefgh', 'citation 2');

## Reading and parsing XML string handle
my $data = "<MedlineCitationSet>
            <MedlineCitation>
            <MedlineID>87654321</MedlineID>
            <Article><Journal></Journal></Article>
            </MedlineCitation>
            <MedlineCitation>
            <MedlineID>hgfedcba</MedlineID>
            <Article><Journal></Journal></Article>
            </MedlineCitation>
            </MedlineCitationSet>";
open (my $dataio, "<", \$data);
$io = Bio::Biblio::IO->new('-format' => 'medlinexml',
                           '-fh'     => $dataio);
is ($io->next_bibref->identifier, '87654321', 'citation 1');
is ($io->next_bibref->identifier, 'hgfedcba', 'citation 2');

##
## check PUBMED XML parser
##
$io = Bio::Biblio::IO->new('-format' => 'pubmedxml',
                           '-file'   => $tfile_pubmed);
ok (defined ($io));
is ($io->next_bibref->identifier, '11223344', 'citation 1');
is ($io->next_bibref->identifier, '21583752', 'citation 2');
is ($io->next_bibref->identifier, '21465135', 'citation 3');
is ($io->next_bibref->identifier, '21138228', 'citation 4');

## Testing FH
my @expvals = qw(11223344 21583752 21465135 21138228);
$io = Bio::Biblio::IO->newFh('-format' => 'pubmedxml',
                             '-file'   => $tfile_pubmed,
                             '-result' => 'pubmed2ref');
is ($_->identifier, shift (@expvals), 'filehandle test') while (<$io>);
