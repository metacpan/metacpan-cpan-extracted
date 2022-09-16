package DBIx::Class::Helper::ResultSet::CrossTab::Util;

use Exporter 'import';
our @EXPORT = qw(summary_function_to_pivot_field_def summary_function_to_pivot_field_func summary_function_to_pivot_field_name);  # symbols to export on request

use strict;

use Text::Balanced qw (extract_bracketed) ;
# use Data::Dump qw/dump/;

use String::SQLColumnName qw/fix_name/;

my $quote = sub { sprintf "'%s'", shift };

sub summary_function_to_pivot_field_def {
    my $func = summary_function_to_pivot_field_func(@_);
    my $name = summary_function_to_pivot_field_name(@_);

    return "$func as $name";
}

sub summary_function_to_pivot_field_func {
    my $pivot = shift;
    my $field = shift;
    my $value = shift;
    my $quote = shift || $quote;

    my ($aggs, $clause, $extracted, $rems) = parse_summary_function($pivot, $field);

    $extracted = sprintf '(%s CASE WHEN %s=%s then %s ELSE NULL END)', $clause, $field, $quote->($value), $extracted;
    my $res = join '', (join '(', @$aggs), $extracted, (join ')', @$rems)
}

sub parse_summary_function {
    my $pivot = shift;
    my $field = shift;
    my $value = shift;
    my $quote = shift || $quote;

    my (@aggs, @rems, $extracted);

    if (ref $pivot eq 'HASH') {
	my ($sum_func, $sum_field) = (%$pivot);
	return [$sum_func], '', $sum_field, [];
    }

    $pivot = $$pivot if (ref $pivot eq 'SCALAR');

    my (@aggs, @rems, $extracted);
    while ($pivot =~ s/\s*(\w+)\s*\(//) {
	push @aggs, $1;
	my $remainder;
	($extracted, $remainder) = extract_bracketed('(' . $pivot, '()');
	unshift @rems, $remainder if $remainder;
    }

    my $clause = '';
    for ($extracted) {
	s/\(\s*distinct\s/(/ && do {
	    $clause = 'distinct';
	    next;
	};
	s/\(\s*all\s/(/ && do {
	    $clause = 'all';
	    next;
	};
    }
    return \@aggs, $clause, $extracted, \@rems;
}

sub summary_function_to_pivot_field_name {
    my $pivot = shift;
    my $field = shift;
    my $value = shift;
    my $quote = shift || $quote;

    my ($aggs, $clause, $extracted, $rems) = parse_summary_function($pivot, $field);

    my $res = join '_', (join '_', @$aggs), $extracted, $field, $value;
    return fix_name($res);
}

1
