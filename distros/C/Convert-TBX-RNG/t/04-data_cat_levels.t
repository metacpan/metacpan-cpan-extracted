#check specification of data categories
use t::TestRNG;
use Test::More 0.88; #TODO: removing this causes failure. why?
plan tests => 19;
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

=== termNote with forTermComp
TODO: TBXChecker doesn't verify this
--- SKIP
--- xcs

        <termCompListSpec name="termElement" datcatId="ISO12620A-020802">
            <contents forTermComp="yes"/>
        </termCompListSpec>

        <termNoteSpec name="generalNote" datcatId="">
            <contents/>
        </termNoteSpec>

        <termNoteSpec name="compNote" datcatId="">
            <contents forTermComp="yes"/>
        </termNoteSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <ntig>
                        <termGrp>
                            <term id="foo">foo</term>
                            <termNote type="generalNote" id="bar" xml:lang="en">
                                some note
                            </termNote>
                            <termNote type="compNote" id="baz" xml:lang="en">
                                some note
                            </termNote>
                            <termCompList type="termElement">
                                <termCompGrp>
                                    <termComp id="buzz" xml:lang="en">
                                        some
                                    </termComp>
                                    <termNote type="compNote" id="biz" xml:lang="en" target="buzz">
                                        some note
                                    </termNote>
                                </termCompGrp>
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
                            <term id="foo">foo</term>
                            <termCompList type="termElement">
                                <termCompGrp>
                                    <termComp id="buzz" xml:lang="en">
                                        some
                                    </termComp>
                                    <!-- This is disallowed at this level-->
                                    <termNote type="generalNote" id="biz" xml:lang="en" target="buzz">
                                        bad note
                                    </termNote>
                                </termCompGrp>
                            </termCompList>
                        </termGrp>
                    </ntig>
                </langSet>
            </termEntry>

=== termNote with forTermComp, in termNoteGrp
TODO: TBXChecker doesn't verify this
--- SKIP
--- xcs

        <termCompListSpec name="termElement" datcatId="ISO12620A-020802">
            <contents forTermComp="yes"/>
        </termCompListSpec>

        <termNoteSpec name="generalNote" datcatId="">
            <contents/>
        </termNoteSpec>

        <termNoteSpec name="compNote" datcatId="">
            <contents forTermComp="yes"/>
        </termNoteSpec>

--- good
            <termEntry>
                <langSet xml:lang="en">
                    <ntig>
                        <termGrp>
                            <term id="foo">foo</term>
                            <termNote type="generalNote" id="bar" xml:lang="en">
                                some note
                            </termNote>
                            <termNote type="compNote" id="baz" xml:lang="en">
                                some note
                            </termNote>
                            <termCompList type="termElement">
                                <termCompGrp>
                                    <termComp id="buzz" xml:lang="en">
                                        some
                                    </termComp>
                                    <termNoteGrp id="quz">
                                        <termNote type="compNote" id="biz" xml:lang="en" target="buzz">
                                            some note
                                        </termNote>
                                        <note>Here is a group!</note>
                                    </termNoteGrp>
                                </termCompGrp>
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
                            <term id="foo">foo</term>
                            <termCompList type="termElement">
                                <termCompGrp>
                                    <termComp id="buzz" xml:lang="en">
                                        some
                                    </termComp>
                                    <!-- This is disallowed at this level-->
                                    <termNoteGrp id="quz">
                                        <termNote type="bad_cat" id="biz" xml:lang="en" target="buzz">
                                            some note
                                        </termNote>
                                        <note>Here is a group!</note>
                                    </termNoteGrp>
                                </termCompGrp>
                            </termCompList>
                        </termGrp>
                    </ntig>
                </langSet>
            </termEntry>

=== descrip in termCompList
TODO: TBXChecker doesn't check this
--- SKIP
--- xcs
        <termCompListSpec name="termElement" datcatId="ISO12620A-020802">
            <contents forTermComp="yes"/>
        </termCompListSpec>
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

--- good
           <termEntry>
                <langSet xml:lang="en">
                    <ntig>
                        <termGrp>
                            <term id="foo">foo</term>
                            <termCompList type="termElement">
                                <termCompGrp>
                                    <termComp id="buzz" xml:lang="en">
                                        some
                                    </termComp>
                                </termCompGrp>
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
                            <term id="foo">foo</term>
                            <termCompList type="termElement">
                                <descrip type="general" xml:lang="en" id="desc">
                                    description
                                </descrip>
                                <termCompGrp>
                                    <termComp id="buzz" xml:lang="en">
                                        some
                                    </termComp>
                                </termCompGrp>
                            </termCompList>
                        </termGrp>
                    </ntig>
                </langSet>
            </termEntry>

=== descrip bad termEntry level
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termLangSet" datcatId="">
            <contents/>
            <levels>term langSet</levels>
        </descripSpec>

--- good
            <termEntry id="entry">

                <descrip type="general" xml:lang="en" id="desc" target="entry">
                    description
                </descrip>

                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <descrip type="termLangSet" xml:lang="en" id="desc" target="entry">
                    description
                </descrip>

                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>

=== descrip bad langSet level
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termTermEntry" datcatId="">
            <contents/>
            <levels>term termEntry</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <descrip type="general" xml:lang="en" id="desc" target="entry">
                        description
                    </descrip>
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <descrip type="termTermEntry" xml:lang="en" id="desc" target="entry">
                        description
                    </descrip>
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>

=== descrip bad term level in tig
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryLangSet" datcatId="">
            <contents/>
            <levels>termEntry langSet</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                        <descrip type="general" xml:lang="en" id="desc" target="entry">
                            description
                        </descrip>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                        <descrip type="termEntryLangSet" xml:lang="en" id="desc" target="entry">
                            description
                        </descrip>
                    </tig>
                </langSet>
            </termEntry>

=== descrip bad term level in ntig
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryLangSet" datcatId="">
            <contents/>
            <levels>termEntry langSet</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <ntig>
                        <termGrp>
                            <term id="term1">foo bar</term>
                        </termGrp>
                        <descrip type="general" xml:lang="en" id="desc" target="entry">
                            description
                        </descrip>
                    </ntig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <ntig>
                        <termGrp>
                            <term id="term1">foo bar</term>
                        </termGrp>
                        <descrip type="termEntryLangSet" xml:lang="en" id="desc" target="entry">
                            description
                        </descrip>
                    </ntig>
                </langSet>
            </termEntry>
=== descripGrp bad termEntry level
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termLangSet" datcatId="">
            <contents/>
            <levels>term langSet</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <descripGrp>
                    <descrip type="general" xml:lang="en" id="desc" target="entry">
                        description
                    </descrip>
                </descripGrp>

                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <descripGrp>
                    <descrip type="termLangSet" xml:lang="en" id="desc" target="entry">
                        description
                    </descrip>
                </descripGrp>

                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>

=== descripGrp bad langSet level
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termTermEntry" datcatId="">
            <contents/>
            <levels>term termEntry</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <descripGrp>
                        <descrip type="general" xml:lang="en" id="desc" target="entry">
                            description
                        </descrip>
                    </descripGrp>
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <descripGrp>
                        <descrip type="termTermEntry" xml:lang="en" id="desc" target="entry">
                            description
                        </descrip>
                    </descripGrp>
                    <tig>
                        <term id="term1">foo bar</term>
                    </tig>
                </langSet>
            </termEntry>

=== descripGrp bad term level in tig
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryLangSet" datcatId="">
            <contents/>
            <levels>termEntry langSet</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                        <descripGrp>
                            <descrip type="general" xml:lang="en" id="desc" target="entry">
                                description
                            </descrip>
                        </descripGrp>
                    </tig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <tig>
                        <term id="term1">foo bar</term>
                        <descripGrp>
                            <descrip type="termEntryLangSet" xml:lang="en" id="desc" target="entry">
                                description
                            </descrip>
                        </descripGrp>
                    </tig>
                </langSet>
            </termEntry>

=== descripGrp bad term level in ntig
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryLangSet" datcatId="">
            <contents/>
            <levels>termEntry langSet</levels>
        </descripSpec>

--- good
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <ntig>
                        <termGrp>
                            <term id="term1">foo bar</term>
                        </termGrp>
                        <descripGrp>
                            <descrip type="general" xml:lang="en" id="desc" target="entry">
                                description
                            </descrip>
                        </descripGrp>
                    </ntig>
                </langSet>
            </termEntry>
--- bad
            <termEntry id="entry">
                <langSet xml:lang="en" id="langSet">
                    <ntig>
                        <termGrp>
                            <term id="term1">foo bar</term>
                        </termGrp>
                        <descripGrp>
                            <descrip type="termEntryLangSet" xml:lang="en" id="desc" target="entry">
                                description
                            </descrip>
                        </descripGrp>
                    </ntig>
                </langSet>
            </termEntry>

=== descrip all okay levels
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termLangSet" datcatId="">
            <contents/>
            <levels>term langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryLangSet" datcatId="">
            <contents/>
            <levels>termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryTerm" datcatId="">
            <contents/>
            <levels>termEntry term</levels>
        </descripSpec>

        <descripSpec name="term" datcatId="">
            <contents/>
            <levels>term</levels>
        </descripSpec>

        <descripSpec name="termEntry" datcatId="">
            <contents/>
            <levels>termEntry</levels>
        </descripSpec>

        <descripSpec name="langSet" datcatId="">
            <contents/>
            <levels>langSet</levels>
        </descripSpec>

--- good
            <!-- Test all locations of descrip and descripGrp -->
            <termEntry id="entry">

                <!-- Descrips allowed in termEntry level -->
                <descrip type="general" xml:lang="en" id="desc1" target="entry">
                    description
                </descrip>
                <descrip type="termEntryLangSet" xml:lang="en" id="desc2" target="entry">
                    description
                </descrip>
                <descrip type="termEntryTerm" xml:lang="en" id="desc3" target="entry">
                    description
                </descrip>
                <descrip type="termEntry" xml:lang="en" id="desc4" target="entry">
                    description
                </descrip>
                <!-- End descrips -->

                <langSet xml:lang="en" id="langSet">

                    <!-- Descrips allowed in langSet level -->
                    <descrip type="general" xml:lang="en" id="desc9" target="langSet">
                        description
                    </descrip>
                    <descrip type="termEntryLangSet" xml:lang="en" id="desc10" target="langSet">
                        description
                    </descrip>
                    <descrip type="termLangSet" xml:lang="en" id="desc11" target="langSet">
                        description
                    </descrip>
                    <descrip type="langSet" xml:lang="en" id="desc12" target="langSet">
                        description
                    </descrip>
                    <!-- End descrips -->

                    <tig>
                        <term id="term1">foo bar</term>

                        <!-- Descrips allowed in term level -->
                        <descrip type="general" xml:lang="en" id="desc17" target="term1">
                            description
                        </descrip>
                        <descrip type="termEntryTerm" xml:lang="en" id="desc18" target="term1">
                            description
                        </descrip>
                        <descrip type="termLangSet" xml:lang="en" id="desc19" target="term1">
                            description
                        </descrip>
                        <descrip type="term" xml:lang="en" id="desc20" target="term1">
                            description
                        </descrip>
                        <!-- End descrips -->

                    </tig>
                    <ntig id="ntig">

                        <termGrp>
                            <term id="term2">baz</term>
                        </termGrp>

                        <!-- Descrips allowed in term level -->
                        <descrip type="general" xml:lang="en" id="desc25" target="ntig">
                            description
                        </descrip>
                        <descrip type="termEntryTerm" xml:lang="en" id="desc26" target="ntig">
                            description
                        </descrip>
                        <descrip type="termLangSet" xml:lang="en" id="desc27" target="ntig">
                            description
                        </descrip>
                        <descrip type="term" xml:lang="en" id="desc28" target="ntig">
                            description
                        </descrip>
                        <!-- End descrips -->

                    </ntig>
                </langSet>
            </termEntry>

=== descripGrp all okay levels
--- xcs
        <descripSpec name="general" datcatId="">
            <contents/>
            <levels>term termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termLangSet" datcatId="">
            <contents/>
            <levels>term langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryLangSet" datcatId="">
            <contents/>
            <levels>termEntry langSet</levels>
        </descripSpec>

        <descripSpec name="termEntryTerm" datcatId="">
            <contents/>
            <levels>termEntry term</levels>
        </descripSpec>

        <descripSpec name="term" datcatId="">
            <contents/>
            <levels>term</levels>
        </descripSpec>

        <descripSpec name="termEntry" datcatId="">
            <contents/>
            <levels>termEntry</levels>
        </descripSpec>

        <descripSpec name="langSet" datcatId="">
            <contents/>
            <levels>langSet</levels>
        </descripSpec>

--- good
            <!-- Test all locations of descrip and descripGrp -->
            <termEntry id="entry">

                <!-- DescripGrps allowed in termEntry level -->

                <descripGrp>
                    <descrip type="general" xml:lang="en" id="desc5" target="entry">
                        description
                    </descrip>
                </descripGrp>
                <descripGrp>
                    <descrip type="termEntryLangSet" xml:lang="en" id="desc6" target="entry">
                        description
                    </descrip>
                </descripGrp>
                <descripGrp>
                    <descrip type="termEntryTerm" xml:lang="en" id="desc7" target="entry">
                        description
                    </descrip>
                </descripGrp>
                <descripGrp>
                    <descrip type="termEntry" xml:lang="en" id="desc8" target="entry">
                        description
                    </descrip>
                </descripGrp>
                <!-- End descrips -->

                <langSet xml:lang="en" id="langSet">

                    <!-- DescripGrps allowed in langSet level -->
                    <descripGrp>
                        <descrip type="general" xml:lang="en" id="desc13" target="langSet">
                            description
                        </descrip>
                    </descripGrp>
                    <descripGrp>
                        <descrip type="termEntryLangSet" xml:lang="en" id="desc14" target="langSet">
                            description
                        </descrip>
                    </descripGrp>
                    <descripGrp>
                        <descrip type="termLangSet" xml:lang="en" id="desc15" target="langSet">
                            description
                        </descrip>
                    </descripGrp>
                    <descripGrp>
                        <descrip type="langSet" xml:lang="en" id="desc16" target="langSet">
                            description
                        </descrip>
                    </descripGrp>
                    <!-- End descrips -->

                    <tig>
                        <term id="term1">foo bar</term>

                        <!-- DescripGrps allowed in term level -->
                        <descripGrp>
                            <descrip type="general" xml:lang="en" id="desc21" target="term1">
                                description
                            </descrip>
                        </descripGrp>
                        <descripGrp>
                            <descrip type="termEntryTerm" xml:lang="en" id="desc22" target="term1">
                                description
                            </descrip>
                        </descripGrp>
                        <descripGrp>
                            <descrip type="termLangSet" xml:lang="en" id="desc23" target="term1">
                                description
                            </descrip>
                        </descripGrp>
                        <descripGrp>
                            <descrip type="term" xml:lang="en" id="desc24" target="term1">
                                description
                            </descrip>
                        </descripGrp>
                        <!-- End descrips -->

                    </tig>
                    <ntig id="ntig">

                        <termGrp>
                            <term id="term2">baz</term>
                        </termGrp>

                        <!-- DescripGrps allowed in term level -->
                        <descripGrp>
                            <descrip type="general" xml:lang="en" id="desc29" target="ntig">
                                description
                            </descrip>
                        </descripGrp>
                        <descripGrp>
                            <descrip type="termEntryTerm" xml:lang="en" id="desc30" target="ntig">
                                description
                            </descrip>
                        </descripGrp>
                        <descripGrp>
                            <descrip type="termLangSet" xml:lang="en" id="desc31" target="ntig">
                                description
                            </descrip>
                        </descripGrp>
                        <descripGrp>
                            <descrip type="term" xml:lang="en" id="desc32" target="ntig">
                                description
                            </descrip>
                        </descripGrp>
                        <!-- End descrips -->

                    </ntig>
                </langSet>
            </termEntry>
