#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set AUTHOR_TESTING to enable this test' unless $ENV{AUTHOR_TESTING};

eval "use Test::Spelling 0.19";
plan skip_all => 'Test::Spelling 0.19 required' if $@;

add_stopwords(qw(
    AuditAny AuditObj SchemaObj ResultSource datapoint datapoints Datapoint tiedContexts
    changeset ChangeSet ChangeSets ChangeContext ChangeSetContext SourceContext 
    DBIC schemas TODO ro rw fk param params attr attrs Str TBD codebase
    Styn IntelliTree llc customizable localizable util uniq Util customizations
));

set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok();

done_testing();
