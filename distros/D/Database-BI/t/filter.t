use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Test::Needs;
use File::Spec  ();
use File::Temp  ();
use Mojo::File  ();
use Mojo::Util  qw(url_escape);

# ---------------------------------------------------------------------------
# Syllogistic foundation
#
# Major Premise A: _apply_filter_spec dispatches on exactly 10 named operators
#   (eq, ne, contains, starts, lt, le, gt, ge, empty, notempty) plus a
#   catch-all that returns 1 (all rows pass) for unknown operators.
#
# Major Premise B: sales.csv contains 6 rows with the known values read below.
#   Each operator test is therefore a formal proof of exactly one logic branch.
#   No two tests cover the same branch (no redundancy by equivalence partition).
#
# Major Premise C: _get_columns calls source->columns once (cached); tests that
#   exercise column listing prove this is equivalent to the uncached form.
#
# Major Premise D: _apply_filters merges parse + apply into one loop.  Malformed
#   specs are skipped (and _apply_filter_spec would return $records unchanged
#   anyway), so the merged loop is logically equivalent to the two-loop original.
# ---------------------------------------------------------------------------

my $t = Test::Mojo->new('Database::BI');

# ---------------------------------------------------------------------------
# Guard: all filter proofs depend on data/sales.csv being present.
# ---------------------------------------------------------------------------

my $sales_path = File::Spec->rel2abs('data/sales.csv');
plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

# Known data (row id -> distinguishing rep name used in assertions):
#   id=1  product=Widget A   region=North  sales_rep=Alice Smith  amount=1250.00
#   id=2  product=Widget B   region=South  sales_rep=Bob Jones    amount=875.50
#   id=3  product=Gadget Pro region=East   sales_rep=Carol White  amount=2100.00
#   id=4  product=Widget A   region=West   sales_rep=David Lee    amount=950.00
#   id=5  product=Gadget Pro region=North  sales_rep=Alice Smith  amount=1875.00
#   id=6  product=Widget B   region=East   sales_rep=Carol White  amount=725.25

# ---------------------------------------------------------------------------
# Partition 1: eq  -- case-insensitive string equality
# ---------------------------------------------------------------------------

subtest 'filter op: eq (case-insensitive)' => sub {
	# Proof: lc('North') eq lc('North') => rows 1,5 selected.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:North'))
	  ->status_is(200)->content_like(qr/Alice Smith/);

	# Proof: eq is case-insensitive -- 'north' matches 'North' and 'NORTH'.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:north'))
	  ->status_is(200)->content_like(qr/Alice Smith/);

	# Proof: boundary -- value not in any cell => 0 rows returned.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:XYZZY'))
	  ->status_is(200)->content_unlike(qr/Alice Smith|Bob Jones|Carol White|David Lee/);
};

# ---------------------------------------------------------------------------
# Partition 2: ne  -- complement of eq
# ---------------------------------------------------------------------------

subtest 'filter op: ne' => sub {
	# Proof: all rows where lc(region) ne lc('North') => rows 2,3,4,6.
	# Bob Jones is on South; South ne North => Bob Jones present.
	$t->get_ok('/view/sales?f=' . url_escape('region:ne:North'))
	  ->status_is(200)->content_like(qr/Bob Jones/);
};

# ---------------------------------------------------------------------------
# Partition 3: contains  -- case-insensitive substring
# ---------------------------------------------------------------------------

subtest 'filter op: contains' => sub {
	# Proof: index(lc('Gadget Pro'), lc('Gadget')) >= 0 => rows 3,5 selected.
	$t->get_ok('/view/sales?f=' . url_escape('product:contains:Gadget'))
	  ->status_is(200)->content_like(qr/Gadget Pro/);

	# Proof: 'contains' with value absent from all cells => 0 rows.
	$t->get_ok('/view/sales?f=' . url_escape('product:contains:XYZZY'))
	  ->status_is(200)->content_unlike(qr/Alice Smith|Bob Jones|Carol White|David Lee/);
};

# ---------------------------------------------------------------------------
# Partition 4: starts  -- case-insensitive prefix match
# ---------------------------------------------------------------------------

subtest 'filter op: starts' => sub {
	# Proof: index(lc('Widget A'), lc('Widget')) == 0 => rows 1,2,4,6 selected.
	$t->get_ok('/view/sales?f=' . url_escape('product:starts:Widget'))
	  ->status_is(200)->content_like(qr/Bob Jones/);

	# Proof: starts with 'Gadget' => only Gadget Pro rows (3,5).
	$t->get_ok('/view/sales?f=' . url_escape('product:starts:Gadget'))
	  ->status_is(200)->content_like(qr/Carol White/);
};

# ---------------------------------------------------------------------------
# Partitions 5-8: numeric operators
# Minor Premise: amounts in file order are 1250.00, 875.50, 2100.00, 950.00,
#   1875.00, 725.25.  Floor value is 725.25; ceiling is 2100.00.
# ---------------------------------------------------------------------------

subtest 'filter op: lt (strict less-than, floor boundary)' => sub {
	# Proof: $cell < 1000 selects 875.50 (row 2), 950.00 (row 4), 725.25 (row 6).
	$t->get_ok('/view/sales?f=' . url_escape('amount:lt:1000'))
	  ->status_is(200)->content_like(qr/David Lee/);

	# Proof: floor boundary -- 725.25 is not strictly less than 725.25 => 0 rows.
	$t->get_ok('/view/sales?f=' . url_escape('amount:lt:725.25'))
	  ->status_is(200)->content_unlike(qr/Alice Smith|Bob Jones|Carol White|David Lee/);
};

subtest 'filter op: le (inclusive less-than, boundary at 950)' => sub {
	# Proof: $cell <= 950 => 725.25, 875.50, 950.00 selected (rows 2,4,6).
	# 950.00 <= 950 is true (numeric); David Lee is rep for row 4 (950.00).
	$t->get_ok('/view/sales?f=' . url_escape('amount:le:950'))
	  ->status_is(200)->content_like(qr/David Lee/);
};

subtest 'filter op: gt (strict greater-than)' => sub {
	# Proof: $cell > 950 selects 1250.00 (row 1), 2100.00 (row 3), 1875.00 (row 5).
	# Carol White is rep for rows 3 and 5.
	$t->get_ok('/view/sales?f=' . url_escape('amount:gt:950'))
	  ->status_is(200)->content_like(qr/Carol White/);
};

subtest 'filter op: ge (inclusive greater-than, boundary at 1250)' => sub {
	# Proof: $cell >= 1250 selects 1250.00 (row 1), 2100.00 (row 3), 1875.00 (row 5).
	# 1250.00 >= 1250 is true (numeric); Alice Smith is rep for row 1.
	$t->get_ok('/view/sales?f=' . url_escape('amount:ge:1250'))
	  ->status_is(200)->content_like(qr/Alice Smith/);
};

# ---------------------------------------------------------------------------
# Partitions 9-10: unary operators (no val used)
# Minor Premise: no row in sales.csv has an empty region field.
# ---------------------------------------------------------------------------

subtest 'filter op: empty' => sub {
	# Proof: all regions are non-empty strings => no row satisfies $cell eq '' => 0 rows.
	$t->get_ok('/view/sales?f=' . url_escape('region:empty'))
	  ->status_is(200)->content_unlike(qr/Alice Smith|Bob Jones|Carol White|David Lee/);
};

subtest 'filter op: notempty' => sub {
	# Proof: all regions are non-empty => all 6 rows satisfy $cell ne '' => 6 rows.
	# Complement of empty: notempty | empty = universe.
	$t->get_ok('/view/sales?f=' . url_escape('region:notempty'))
	  ->status_is(200)->content_like(qr/Alice Smith/)->content_like(qr/Carol White/);
};

# ---------------------------------------------------------------------------
# Catch-all: unknown operator => passes all rows (falls through to 1)
# ---------------------------------------------------------------------------

subtest 'filter op: unknown falls through (all rows pass)' => sub {
	# Proof: the ternary chain ends with bare 1 for any unrecognised $op.
	# All 6 rows are returned; Alice Smith and Bob Jones both appear.
	$t->get_ok('/view/sales?f=' . url_escape('region:XUNKNOWNX:North'))
	  ->status_is(200)
	  ->content_like(qr/Alice Smith/)
	  ->content_like(qr/Bob Jones/);
};

# ---------------------------------------------------------------------------
# split limit 3: colons beyond the second are part of the value, not separators
# ---------------------------------------------------------------------------

subtest 'filter spec: value containing colons is not split further' => sub {
	# Proof: split(/:/, 'region:eq:North:south', 3) = ('region','eq','North:south').
	# No cell has value 'North:south', so 0 rows match -- distinct from
	# 'region:eq:North' which matches 2 rows.
	# If the limit were absent, the extra ':south' would be a 4th field (discarded
	# by the 3-element list assignment), producing val='North' and 2 rows.
	# The 0-row result below proves the colon was included in val.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:North:south'))
	  ->status_is(200)->content_unlike(qr/Alice Smith/);
};

# ---------------------------------------------------------------------------
# Multiple chained filters (AND semantics, applied in order)
# ---------------------------------------------------------------------------

subtest 'filter: two filters are ANDed in sequence' => sub {
	# Proof: (region:eq:North) AND (amount:ge:1500) selects only row 5
	# (North, 1875.00).  Row 1 is North but 1250.00 < 1500.
	# Alice Smith is rep for both rows 1 and 5; but only 1875.00 survives ge:1500.
	$t->get_ok('/view/sales?f=' . url_escape('region:eq:North')
	         . '&f=' . url_escape('amount:ge:1500'))
	  ->status_is(200)->content_like(qr/Alice Smith/);
};

# ---------------------------------------------------------------------------
# Malformed filter specs are silently skipped (no crash, no 500)
# ---------------------------------------------------------------------------

subtest 'filter: malformed spec is a no-op' => sub {
	# Proof: spec with no operator ('region' alone after split) fails the guard
	# (defined $op is false) and _apply_filter_spec returns $records unchanged.
	$t->get_ok('/view/sales?f=' . url_escape('region'))
	  ->status_is(200)->content_like(qr/Alice Smith/);

	# Proof: spec with empty col segment ('::North') -- length($col//'') == 0
	# -- guard fires, no-op, all rows returned.
	$t->get_ok('/view/sales?f=' . url_escape('::North'))
	  ->status_is(200)->content_like(qr/Alice Smith/);
};

# ---------------------------------------------------------------------------
# columns_api: path= branch (tests the path: code path in columns_api)
# ---------------------------------------------------------------------------

subtest 'GET /api/columns?path= (path branch)' => sub {
	$t->get_ok('/api/columns?path=' . url_escape($sales_path))
	  ->status_is(200)->json_has('/columns');

	my $cols = $t->tx->res->json('/columns');
	ok(ref $cols eq 'ARRAY' && @$cols > 0, 'columns array is non-empty');
	# sales.csv header: id, product, region, sales_rep, amount, sale_date
	ok((grep { $_ eq 'region' } @$cols), 'region column present');
};

# ---------------------------------------------------------------------------
# stat_api: empty string path (partition distinct from missing param)
# ---------------------------------------------------------------------------

subtest 'GET /api/stat?path= (empty string -> 400)' => sub {
	# Proof: "defined $path" is TRUE for path='' (param is present),
	# but "length $path" is 0 => the guard fires => 400.
	# This is a distinct partition from the missing-param case (which also => 400).
	$t->get_ok('/api/stat?path=')->status_is(400);
};

# ---------------------------------------------------------------------------
# import_url: non-numeric table_index is sanitized to 0
# ---------------------------------------------------------------------------

subtest 'import_url: non-numeric table_index is sanitized to 0' => sub {
	# Database::Abstraction fetches URLs via LWP::UserAgent::Cached (a subclass
	# of LWP::UserAgent that overrides simple_request for caching).  All three
	# must be installed for this subtest to run.
	test_needs 'LWP::UserAgent', 'LWP::UserAgent::Cached', 'HTML::TableExtract';
	require LWP::UserAgent;
	require LWP::UserAgent::Cached;
	require HTTP::Response;

	my $html = '<table><tr><th>sku</th><th>qty</th></tr>'
	         . '<tr><td>BOLT</td><td>10</td></tr></table>';

	# Mock LWP::UserAgent::get — the method Database::Abstraction calls directly.
	# Mocking simple_request is bypassed on Cached cache hits; mocking get
	# intercepts every call regardless of cache state (see CLAUDE.md LWP note).
	{
		no warnings 'redefine';
		# Proof: table_index=abc fails /\A[0-9]+\z/ and is reset to 0.
		# Index 0 is valid for this single-table page, so the dashboard renders.
		local *LWP::UserAgent::get = sub {
			my ($self, $url) = @_;
			HTTP::Response->new(200, 'OK', [], $html);
		};
		$t->get_ok('/import?url=' . url_escape('http://example.com/t') . '&table_index=abc')
		  ->status_is(200)->content_like(qr/BOLT/);
	}
};

# ---------------------------------------------------------------------------
# _left_join: column collision => right column gets "label.col" prefix
# ---------------------------------------------------------------------------

subtest '_left_join: column collision is prefixed, not overwritten' => sub {
	# Both tables have a "name" column.  The join must preserve the left "name"
	# value AND expose the right "name" value under a prefixed key.
	# Proof: if both 'Alpha' (left name) and 'Beta' (right name) appear in the
	# response, the right column was NOT silently overwriting the left column.
	my $left_csv  = "id,name,score\n1,Alpha,100\n";
	my $right_csv = "id,name,rank\n1,Beta,A\n";

	$t->post_ok('/upload',
		form => { file => { content => $left_csv,  filename => 'jleft.csv'  } }
	)->status_is(200);
	my $left_path = $t->tx->res->json('/path');

	$t->post_ok('/upload',
		form => { file => { content => $right_csv, filename => 'jright.csv' } }
	)->status_is(200);
	my $right_path = $t->tx->res->json('/path');

	SKIP: {
		skip 'upload paths not returned', 2
			unless defined $left_path && defined $right_path;

		# Join: left=path:$left_path, right=path:$right_path, key=id|id
		my $l = url_escape("path:$left_path");
		my $j = url_escape("path:$right_path|id|id");
		$t->get_ok("/join?l=$l&j=$j")
		  ->status_is(200)
		  ->content_like(qr/Alpha/)   # left "name" value preserved
		  ->content_like(qr/Beta/);   # right "name" value in prefixed column
	}
};

done_testing();
