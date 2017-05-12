# -*- perl -*-

use strict;
use warnings;
use Test::More;

use_ok('CSS::Scopifier::Group');

ok( 
  my $CSS = CSS::Scopifier::Group->read('t/var/example-groups.css'),
  'New CSS::Scopifier::Group object'
);

is($CSS->write_string,
q~h2 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.4em;
	letter-spacing: .1em;
}
h1 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.5em;
	letter-spacing: .1em;
}
body {
	font-family: "Palatino Linotype", Freeserif, serif;
	letter-spacing: .05em;
}

@media (min-width:768px) {
.form-inline .form-group {
	display: inline-block;
	margin-bottom: 0;
	vertical-align: middle;
}
.form-inline .form-control {
	display: inline-block;
	vertical-align: middle;
	width: auto;
}

}

@media print {
a:visited {
	text-decoration: underline;
}
a {
	text-decoration: underline;
}
* {
	background: transparent!important;
	box-shadow: none!important;
	color: #000!important;
	text-shadow: none!important;
}

}

@media print {
h5 {
	font-size: 200%;
}

@media (min-width:768px) {
h5 {
	font-size: 250%;
}

}

}
~,
'Expected pre-scopify CSS');


ok(
  $CSS->scopify('div.foo'),
  'Call scopify()'
);

is($CSS->write_string,
q~div.foo h2 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.4em;
	letter-spacing: .1em;
}
div.foo h1 {
	font-family: Georgia, "DejaVu Serif", serif;
	font-size: 1.5em;
	letter-spacing: .1em;
}
div.foo body {
	font-family: "Palatino Linotype", Freeserif, serif;
	letter-spacing: .05em;
}

@media (min-width:768px) {
div.foo .form-inline .form-group {
	display: inline-block;
	margin-bottom: 0;
	vertical-align: middle;
}
div.foo .form-inline .form-control {
	display: inline-block;
	vertical-align: middle;
	width: auto;
}

}

@media print {
div.foo a:visited {
	text-decoration: underline;
}
div.foo a {
	text-decoration: underline;
}
div.foo * {
	background: transparent!important;
	box-shadow: none!important;
	color: #000!important;
	text-shadow: none!important;
}

}

@media print {
div.foo h5 {
	font-size: 200%;
}

@media (min-width:768px) {
div.foo h5 {
	font-size: 250%;
}

}

}
~,
'Expected post-scopify CSS');


done_testing;
