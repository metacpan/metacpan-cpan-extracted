use warnings;
use Test::More;

use Bio::Gonzales::Seq::IO qw(faslurp);

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing" if $@;
    
    use_ok('Bio::Gonzales::Align::Jalview'); }

my $d;
sub TEST { $d = $_[0]; }

#TESTS
    my @track = (
        [1,2,'testtrack'],
    );

TEST 'track marks';
{


  my $seq = (faslurp("t/data/example.pep.fa"))[0];
    my $jannot = Bio::Gonzales::Align::Jalview->new(sequence => $seq);
    my $result = "NO_GRAPH\ttrack\tdesc\t";
    $result .= "H,testtrack,[000000]|H,[000000]" . "|" x 129;
    


    is ($jannot->track_marks({name => 'track', description => 'desc', track => \@track}), $result, $d);
}

TEST 'complete annotation';
{
  my $seq = (faslurp("t/data/example.pep.fa"))[0];
    my $jannot = Bio::Gonzales::Align::Jalview->new(sequence => $seq);

    my $result = <<"EOF";
JALVIEW_ANNOTATION

SEQUENCE_REF\tAcoerulea|AcoGoldSmith_v1.000084m.g
NO_GRAPH\ttrack\tdesc\tH,testtrack,[000000]|H,[000000]|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
EOF
    is ($jannot->annotation_track({name => 'track', description => 'desc', track => \@track}), $result, $d);

}
    
done_testing();
