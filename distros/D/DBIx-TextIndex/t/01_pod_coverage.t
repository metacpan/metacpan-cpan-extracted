use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    if $@;

my @modules = all_modules();
plan tests => scalar @modules;

my %private = (
    'DBIx::TextIndex' =>
        [ qw(
                all_doc_ids
                collection_count
                create_accessors
                fetch_all_docs_vector
                fetch_max_indexed_id
                get
                highlight
                html_highlight
                max_indexed_id
                pack_term_docs
                pack_term_docs_append_vint
                pack_vint
                pack_vint_delta
                pos_search
                pos_search_perl
                score_term_docs_okapi
                set
                term_doc_ids_arrayref
                term_docs_and_freqs
                term_docs_array
                term_docs_arrayref
                term_docs_hashref
        ) ],
);

foreach my $module (all_modules()) {
    pod_coverage_ok($module, { also_private => $private{$module} });
}
