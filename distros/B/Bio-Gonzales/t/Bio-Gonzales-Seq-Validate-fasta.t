use warnings;
use Test::More;
use Carp;
use Data::Dumper;

BEGIN { use_ok('Bio::Gonzales::Seq::Validate::fasta'); }

my $d;
sub TEST { $d = $_[0]; }

#TESTS
TEST 'validate';
{
    open my $fh, '<', "t/data/rprot-domains_ebakker.fasta" or croak "Can't open filehandle: $!";
    my $z = Bio::Gonzales::Seq::Validate::fasta->new( fh => $fh );
    my $errors = $z->validate;
    is_deeply(
        $errors,
        {
            '274' => ['No sequence after header.'],
            '238' => ['Wrong header format, seems to be sequence in the header: >>AGCGKTTLA ... PPFVEQMSQ<<'],
            '128' => ['Found unknown characters: >>|7110565||36987.1|234174_1<<'],
            '131' => ['Found unknown characters: >>|7110565||36987.1|234174_1<<'],
            '134' => ['Found unknown characters: >>|7110565||36987.1|234174_1<<'],
            '122' => ['Found unknown characters: >>|7110565||36987.1|234174_1 <<'],
            '361' => ['Wrong header format, seems to be sequence in the header: >>MAYAAVTSL ... GGRELEVVS<<'],
            '336' => ['Wrong header format, seems to be sequence in the header: >>MAEVVLAGL ... DGDDIFNQL<<'],
            '258' => ['Wrong header format, \'>\' not in the beginning.'],
            '243' => ['Wrong header format, seems to be sequence in the header: >>GIWGMPGIG ... TFKRAQGSE<<'],
            '254' => ['Wrong header format, \'>\' not in the beginning.'],
            '0'   => ['File seems to be in DOS format'],
            '256' => ['Wrong header format, \'>\' not in the beginning.'],
            '125' => ['Found unknown characters: >>|7110565||36987.1|234174_1<<'],
            '275' => [ 'Wrong header format, \'>\' not in the beginning.', 'No sequence after header.' ],
            '270' => ['ID is ambiguous.']
        },
        $d
    );

}

done_testing();
