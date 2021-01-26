use Test::More;

use Crayon;

my $crayon = Crayon->new(
	pretty => 1
);

$crayon->parse(q|
	body .class {
		background: lighten(#000, 50%);
		color: darken(#fff, 50%);
	}
|);

$crayon->parse(q|
	body {
		.other {
			background: lighten(#000, 50%);
			color: darken(#fff, 50%);
		}
	}
|);

my $css = $crayon->compile();

my $expected = q|body .class, body .other {
	background: #7f7f7f;
	color: #7f7f7f;
}
|;

is($css, $expected);

done_testing;
