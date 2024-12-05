use strict;
use warnings;
use Data::Section::Pluggable;
use lib 'corpus/lib';
use Foo;
use Test::More;

my $d = Data::Section::Pluggable->new('Foo');
my $x = $d->get_data_section();
is_deeply [ sort keys %$x ], [ qw(bar.tt foo.html) ];

is $d->get_data_section('foo.html'), <<HTML;
<html>
<body>Foo</body>
</html>

HTML

is $d->get_data_section('bar.tt'), <<TT;
[% IF foo %]
bar
[% END %]

TT

done_testing;

