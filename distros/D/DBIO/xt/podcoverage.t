use warnings;
use strict;

use Test::More;
plan skip_all => "Skipping finicky test on older perl"
  if "$]" < 5.008005;

# This test must run via 'dzil test', not 'prove xt/' directly —
# PodWeaver must have already processed the source files.
#
# The sample must be a file PodWeaver demonstrably gives one of these headings
# to, or the guard skips everywhere and the test never runs at all — which is
# what lib/DBIO/Admin.pm did here until k176: it carries no =method/=attr tags,
# so no weave ever produces the heading and the "built dist" case was
# indistinguishable from the "raw repo" case. lib/DBIO.pm carries =method tags,
# so its woven form has =head1 METHODS and its repo form does not.
do {
  my $sample = do { local (@ARGV, $/) = 'lib/DBIO.pm'; <> };
  plan skip_all => 'Run via dzil test — PodWeaver must process files first (prove xt/ not supported)'
    unless $sample =~ /^=head1 (?:ATTRIBUTES|METHODS)/m;
};

require DBIO;
unless ( DBIO::Optional::Dependencies->req_ok_for ('test_podcoverage') ) {
  my $missing = DBIO::Optional::Dependencies->req_missing_for ('test_podcoverage');
  $ENV{RELEASE_TESTING}
    ? die ("Failed to load release-testing module requirements: $missing")
    : plan skip_all => "Test needs: $missing"
}

# this has already been required but leave it here for CPANTS static analysis
require Test::Pod::Coverage;

# Since this is about checking documentation, a little documentation
# of what this is doing might be in order.
# The exceptions structure below is a hash keyed by the module
# name. Any * in a name is treated like a wildcard and will behave
# as expected. Modules are matched by longest string first, so
# A::B::C will match even if there is A::B*

# The value for each is a hash, which contains one or more
# (although currently more than one makes no sense) of the following
# things:-
#   skip   => a true value means this module is not checked
#   ignore => array ref containing list of methods which
#             do not need to be documented.
my $exceptions = {
    'DBIO' => {
        ignore => [qw/
            MODIFY_CODE_ATTRIBUTES
            component_base_class
            mk_classdata
            mk_classaccessor
        /]
    },
    'DBIO::Carp' => {
        ignore => [qw/
            unimport
        /]
    },
    'DBIO::Row' => {
        ignore => [qw/
            MULTICREATE_DEBUG
            clean_rs
            serializable_columns
        /],
    },
    'DBIO::FilterColumn' => {
        ignore => [qw/
            new
            update
            store_column
            get_column
            get_columns
            get_dirty_columns
            has_column_loaded
        /],
    },
    'DBIO::ResultSource' => {
        ignore => [qw/
            compare_relationship_keys
            pk_depends_on
            resolve_condition
            resolve_join
            resolve_prefetch
            STORABLE_freeze
            STORABLE_thaw
        /],
    },
    'DBIO::ResultSet' => {
        ignore => [qw/
            STORABLE_freeze
            STORABLE_thaw
            bare
            explain
            no_columns
            one_row
            rand
        /],
    },
    'DBIO::Storage' => {
        ignore => [qw/
            schema
            cursor
        /]
    },
    'DBIO::Schema' => {
        ignore => [qw/
            setup_connection_class
            datetime_parser
            format_datetime
            parse_datetime
        /]
    },

    'DBIO::Storage::Debug::PrettyTrace'      => {
        ignore => [ qw/
          print
          query_start
          query_end
        /]
    },

    'DBIO::Optional::Dependencies'           => { skip => 1 },
    'DBIO::Componentised'                    => { skip => 1 },
    'DBIO::Relationship::*'                  => { skip => 1 },
    'DBIO::ResultSourceProxy'                => { skip => 1 },
    'DBIO::ResultSource::*'                  => { skip => 1 },
    'DBIO::Storage::Statistics'              => { skip => 1 },
    'DBIO::GlobalDestruction'                => { skip => 1 },
    'DBIO::Storage::BlockRunner'             => { skip => 1 }, # temporary

# internals
    'DBIO::Util'                            => { skip => 1 },
    'DBIO::SQLMaker*'                        => { skip => 1 },
    'DBIO::Storage::DBI*'                    => { skip => 1 },
    'SQL::Translator::*'                            => { skip => 1 },

# deprecated / backcompat stuff
    'DBIO::Serialize::Storable'              => { skip => 1 },

# test infrastructure — not public API
    'DBIO::Test*'                            => { skip => 1 },

# loader internals (inherited from Schema::Loader)
    'DBIO::Loader*'                          => { skip => 1 },
};

my $ex_lookup = {};
for my $string (keys %$exceptions) {
  my $ex = $exceptions->{$string};
  $string =~ s/\*/'.*?'/ge;
  my $re = qr/^$string$/;
  $ex_lookup->{$re} = $ex;
}

my @modules = sort { $a cmp $b } Test::Pod::Coverage::all_modules('lib');

foreach my $module (@modules) {
  SKIP: {

    my ($match) =
      grep { $module =~ $_ }
      (sort { length $b <=> length $a || $b cmp $a } (keys %$ex_lookup) )
    ;

    my $ex = $ex_lookup->{$match} if $match;

    skip ("$module exempt", 1) if ($ex->{skip});

    skip ("$module not loadable", 1) unless eval "require $module";

    # build parms up from ignore list
    my $parms = {};
    $parms->{trustme} =
      [ map { qr/^$_$/ } @{ $ex->{ignore} } ]
        if exists($ex->{ignore});

    # run the test with the potentially modified parm set
    Test::Pod::Coverage::pod_coverage_ok($module, $parms, "$module POD coverage");
  }
}

done_testing;
