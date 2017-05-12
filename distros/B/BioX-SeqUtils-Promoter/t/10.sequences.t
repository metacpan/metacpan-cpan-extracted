use Test::More tests =>2;

use BioX::SeqUtils::Promoter::Sequences;

$tstring = 'ATGCGNT';
$tstring2 = 'TANTCG';
$tstring3 = join('',$tstring,$tstring2);

#print $tstring3;

my $sequences = BioX::SeqUtils::Promoter::Sequences->new();
$sequences->add_sequence({ label => 'label1', sequence => $tstring });
$sequences->add_sequence({ label => 'label2', sequence => $tstring });

my $seqs = $sequences->get_sequences();

foreach my $key (keys %$seqs ){ print $key; } 
ok($seqs, "Sequences parameter");

$sequences->add_segment({ label => 'label1', sequence => $tstring });
$seqs = $sequences->get_sequences();
foreach my $key (keys %$seqs ){ print $seqs->{$key}->get_sequence(),"\n"; } 
ok($seqs, "Sequences parameter");
