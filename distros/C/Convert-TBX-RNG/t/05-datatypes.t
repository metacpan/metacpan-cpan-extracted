#check specification of data categories
use t::TestRNG;
use Test::More 0.88; #TODO: removing this causes failure. why?
plan tests => 7;
use Test::NoWarnings;
use Convert::TBX::RNG qw(generate_rng);
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;
use Data::Dumper;

#write temp.xcs during tests
filters_delay;
filters {
    xcs => [qw(xcs_with_datCats write_xcs)],
    good => 'tbx_with_body',
    bad => 'tbx_with_body',
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
=== noteText constrained to basicText
--- xcs
        <!-- Default for admin is noteText-->
        <adminSpec name="noteText" datcatId="">
            <contents datatype="noteText"/>
        </adminSpec>
        <adminSpec name="basicText" datcatId="">
            <contents datatype="basicText"/>
        </adminSpec>
        <adminSpec name="plainText" datcatId="">
            <contents datatype="plainText"/>
        </adminSpec>

--- good
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="noteText">
                                <foreign>fu-bor<hi>qux</hi></foreign>
                            </admin>
                        </adminGrp>
                        <adminGrp>
                            <admin type="basicText">
                                <hi>qux</hi>
                            </admin>
                        </adminGrp>
                        <adminGrp>
                            <admin type="plainText">
                                qux
                            </admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="basicText">
                                <foreign>fu-bor<hi>qux</hi></foreign>
                            </admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>

=== categories with default noteText datatype
TBXChecker doesn't do these right.
--- SKIP
--- xcs
        <!-- Default for admin is noteText-->
        <adminSpec name="default" datcatId="">
            <contents/>
        </adminSpec>
        <termNoteSpec name="def" datcatId="">
            <contents/>
        </termNoteSpec>
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

--- good
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="default">
                                <foreign>fu-bor<hi>qux</hi></foreign>
                            </admin>
                        </adminGrp>
                        <descrip type="general">
                            <foreign>fu-bor<hi>qux</hi></foreign>
                        </descrip>
                        <termNote type="def">
                            <foreign>fu-bor<hi>qux</hi></foreign>
                        </termNote>
                    </tig>
                </langSet>
            </termEntry>

=== noteText constrained to plainText
--- xcs
        <adminSpec name="noteText" datcatId="">
            <contents datatype="noteText"/>
        </adminSpec>
        <adminSpec name="plainText" datcatId="">
            <contents datatype="plainText"/>
        </adminSpec>

--- good
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="noteText">
                                <foreign>fu-bor<hi>qux</hi></foreign>
                            </admin>
                        </adminGrp>
                        <adminGrp>
                            <admin type="plainText">
                                qux
                            </admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="plainText">
                                <hi>qux</hi>
                            </admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>

=== noteText constrained to pickList
--- xcs
        <!-- Default for admin is noteText-->
        <adminSpec name="default" datcatId="">
            <contents/>
        </adminSpec>
        <adminSpec name="foo" datcatId="">
            <contents datatype="picklist"> option1 option2 option3 </contents>
        </adminSpec>

--- good
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="foo">option1</admin>
                        </adminGrp>
                        <adminGrp>
                            <admin type="foo">option2</admin>
                        </adminGrp>
                        <adminGrp>
                            <admin type="foo">option3</admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>
--- bad

            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="foo">option8</admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>
