#check specification of data categories
use t::TestRNG;
use Test::More 0.88; #TODO: removing this causes failure. why?
plan tests => 17;
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
=== admin
--- good
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="annotatedNote" id="fluff" datatype="text" xml:lang="es">fu</admin>
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
                            <admin type="bad_category" id="fluff" datatype="text" xml:lang="es">fu</admin>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>
--- xcs
        <adminSpec name="annotatedNote" datcatId="">
            <contents/>
        </adminSpec>
        <adminNoteSpec name="noteSource" datcatId="">
            <contents/>
        </adminNoteSpec>

=== admin note
--- good
            <termEntry id="c1">
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <adminGrp>
                            <admin type="annotatedNote" id="fluff" datatype="text" xml:lang="es" target="bar">fu</admin>
                            <adminNote type="noteSource" id="bar" datatype="text" xml:lang="en" target="fluff">bar</adminNote>
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
                            <admin type="annotatedNote" id="fluff" datatype="text" xml:lang="es" target="bar">bar</admin>
                            <adminNote type="bad_category" id="bar" datatype="text" xml:lang="en" target="fluff">baz</adminNote>
                        </adminGrp>
                    </tig>
                </langSet>
            </termEntry>
--- xcs
        <adminSpec name="annotatedNote" datcatId="">
            <contents/>
        </adminSpec>
        <adminNoteSpec name="noteSource" datcatId="">
            <contents/>
        </adminNoteSpec>

=== descripNote
TODO: may need to move this to another file with descrip, since they're related
and descrip is special
--- xcs

        <descripSpec name="context" datcatId="ISO12620A-0503">
            <contents/>
            <levels>langSet termEntry term</levels>
        </descripSpec>
        <descripNoteSpec name="contextDescription" datcatId="">
            <contents/>
        </descripNoteSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term>federated database</term>
                        <descripGrp>
                            <descrip type="context" id="foo">Users and applications interface with the federated
                                database managed by the federated server. </descrip>
                            <descripNote type="contextDescription" id="bar" target="foo" xml:lang="en" datatype="text">
                                some description
                            </descripNote>
                        </descripGrp>
                    </tig>
                </langSet>
            </termEntry>

--- bad
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term>federated database</term>
                        <descripGrp>
                            <descrip type="context" id="foo">Users and applications interface with the federated
                                database managed by the federated server. </descrip>
                            <descripNote type="bad_type" id="bar" target="foo" xml:lang="en" datatype="text">
                                some description
                            </descripNote>
                        </descripGrp>
                    </tig>
                </langSet>
            </termEntry>

=== ref
--- xcs

        <refSpec name="crossReference" datcatId="ISO12620A-1018">
            <contents targetType="element"/>
        </refSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <ref target="bar" type="crossReference" id="foo" datatype="text" xml:lang="en">
                            "foo" and "bar" go together</ref>
                    </tig>
                </langSet>
                <langSet xml:lang="en">
                    <tig>
                        <term id="bar">bar</term>
                    </tig>
                </langSet>
            </termEntry>

--- bad
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term>foo</term>
                        <ref target="bar" type="bad_type" id="foo" datatype="text" xml:lang="en">
                            "foo" and "bar" go together</ref>
                    </tig>
                </langSet>
                <langSet xml:lang="en">
                    <tig>
                        <term id="bar">bar</term>
                    </tig>
                </langSet>
            </termEntry>

=== transac
--- xcs

        <transacSpec name="transactionType" datcatId="ISO12620A-1001">
            <contents/>
        </transacSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term id="foo">foo</term>
                        <transacGrp>
                            <transac type="transactionType" id="bar" datatype="text" xml:lang="en" target="foo">
                                random transaction...</transac>
                        </transacGrp>
                    </tig>
                </langSet>
            </termEntry>

--- bad
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term id="foo">foo</term>
                        <transacGrp>
                            <transac type="bad_cat" id="bar" datatype="text" xml:lang="en" target="foo">
                                random transaction...</transac>
                        </transacGrp>
                    </tig>
                </langSet>
            </termEntry>

=== transacNote
--- xcs

        <transacSpec name="transactionType" datcatId="ISO12620A-1001">
            <contents/>
        </transacSpec>
        <transacNoteSpec name="generalNote" datcatId="">
            <contents/>
        </transacNoteSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term id="foo">foo</term>
                        <transacGrp>
                            <transac type="transactionType" id="bar" datatype="text" xml:lang="en" target="foo">
                                random transaction...</transac>
                            <transacNote type="generalNote" id="baz" datatype="text" xml:lang="en" target="bar">
                                just random</transacNote>
                        </transacGrp>
                    </tig>
                </langSet>
            </termEntry>

--- bad
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term id="foo">foo</term>
                        <transacGrp>
                            <transac type="transactionType" id="bar" datatype="text" xml:lang="en" target="foo">
                                random transaction...</transac>
                            <transacNote type="bad_cat" id="baz" datatype="text" xml:lang="en" target="bar">
                                just random</transacNote>
                        </transacGrp>
                    </tig>
                </langSet>
            </termEntry>

=== termCompList
--- xcs

        <termCompListSpec name="termElement" datcatId="ISO12620A-020802">
            <contents forTermComp="yes"/>
        </termCompListSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <ntig>
                        <termGrp>
                            <term id="foo">foo-bar</term>
                            <termCompList id="bar" type="termElement">
                                <termComp id="buzz" xml:lang="en">
                                    boo
                                </termComp>
                            </termCompList>
                        </termGrp>
                    </ntig>
                </langSet>
            </termEntry>

--- bad
            <termEntry>
                <langSet xml:lang="en">
                    <ntig>
                        <termGrp>
                            <term id="foo">foo-bar</term>
                            <termCompList id="bar" type="bad_category">
                                <termComp id="buzz" xml:lang="en">
                                    boo
                                </termComp>
                            </termCompList>
                        </termGrp>
                    </ntig>
                </langSet>
            </termEntry>

=== termNote
--- xcs

        <termNoteSpec name="generalNote" datcatId="">
            <contents/>
        </termNoteSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term id="foo">foo</term>
                        <termNote type="generalNote" id="bar" datatype="text" xml:lang="en" target="foo">
                            some note
                        </termNote>
                    </tig>
                </langSet>
            </termEntry>

--- bad
            <termEntry>
                <langSet xml:lang="en">
                    <tig>
                        <term id="foo">foo</term>
                        <termNote type="bad_cat" id="bar" datatype="text" xml:lang="en" target="foo">
                            some note
                        </termNote>
                    </tig>
                </langSet>
            </termEntry>
