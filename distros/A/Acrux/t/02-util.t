#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use Test::More;
use Acrux::Util qw/fdatetime truncstr words/;

ok(fdatetime(time), 'DateTime');

# TruncSTR
{
	is(truncstr("qwertyuiop", 3), 'q.p', 'Truncate string to 3 symbols');
	is(truncstr("qwertyuiop", 7, '*'), 'qw***op', 'Truncate string to 7 symbols');
}

#note fdt("%DD.%MM.%YYYY %hh:%mm:%ss %Z %z"); # 12.02.2013 16:16:53
#my $data = indent("foo", 1, '> ');
#note $data;
#spew('test-spew.txt', $data);

# Words
{
	is_deeply(
		words(
			'  foo, bar   baz ;; ;, qux      ',
			'foo, bar   grault ;; ;, qux     ',
		), [qw/foo bar baz qux grault/], 'Two strings');
	is_deeply(words(['', '']), [], 'Two empty strings');
	is_deeply(words(), [], 'Nothing');
	is_deeply(words(words('Foo, Bar')), [qw/Foo Bar/], 'Foo Bar');
	#note explain words( [' foo bar '], ['  baz bar '] ); # ['foo', 'bar', 'baz']
}

done_testing;

1;

__END__
