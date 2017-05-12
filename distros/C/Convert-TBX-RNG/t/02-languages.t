#check specification of langSet languages
use t::TestRNG;
use Test::More 0.88;
plan tests => 3;
use Test::NoWarnings;
use Convert::TBX::RNG qw(generate_rng);
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

#write temp.xcs during tests
filters_delay;
filters {
    xcs => [qw(xcs_with_languages write_xcs)],
    good => 'tbx_with_body',
    bad => 'tbx_with_body'
};

# for each block, create an RNG from an XCS file,
# then test it against valid and invalid TBX
# double check validity with TBX::Checker
for my $block(blocks){

    note $block->name;
    $block->run_filters;

    #create an RNG and write it to a temporary file
    my $rng = generate_rng(xcs_file => $block->xcs);

    for my $good( $block->good ){
        compare_validation($rng, $good, 1);
    }

    for my $bad( $block->bad ){
        compare_validation($rng, $bad, 0);
    }
}

remove_temps();

__DATA__
=== langSet languages
--- xcs
    <langInfo>
        <langCode>en</langCode>
        <langName>English</langName>
    </langInfo>
    <langInfo>
        <langCode>fr</langCode>
        <langName>French</langName>
    </langInfo>
    <langInfo>
        <langCode>de</langCode>
        <langName>German</langName>
    </langInfo>
--- bad
            <termEntry id="c2">
                <!-- Should fail, since XCS doesn't have Lushootseed -->
                <langSet xml:lang="lut">
                    <tig>
                        <term>bar</term>
                    </tig>
                </langSet>
            </termEntry>
--- good
            <termEntry id="c2">
                <langSet xml:lang="fr">
                    <tig>
                        <term>bar</term>
                    </tig>
                </langSet>
            </termEntry>
