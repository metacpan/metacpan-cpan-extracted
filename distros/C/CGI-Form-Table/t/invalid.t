use Test::More tests => 9;

use strict;
use warnings;

use CGI;
BEGIN {
	use_ok("CGI::Form::Table");
	use_ok("CGI::Form::Table::Reader");
}

is(
	CGI::Form::Table::Reader->new(),
	undef,
	"missing both params"
);

is(
	CGI::Form::Table::Reader->new(query => 1),
	undef,
	"missing prefix param"
);

is(
	CGI::Form::Table::Reader->new(prefix => 1),
	undef,
	"missing query param"
);

{
	my $query = CGI->new;

	is(
		CGI::Form::Table::Reader->new(prefix => 'foo', query => $query)->rows,
		undef,
		"no rows, because no positions"
	);
}

{
	my $form = CGI::Form::Table->new();
	is($form, undef, "missing all params to CFT->new");
}

{
	my $form = CGI::Form::Table->new(columns => [qw(x y z)]);
	is($form, undef, "missing prefix param to CFT->new");
}

{
	my $form = CGI::Form::Table->new(prefix => 'someform');
	is($form, undef, "missing columns param to CFT->new");
}
