use strict;
use warnings FATAL => 'all';

use Test::More tests => 21;
use File::Temp qw(tempdir);
use File::Slurp;

BEGIN { use_ok('Apache::SWIT::Maker::FileWriter'); }

package H;
use base 'Apache::SWIT::Maker::FileWriter';
__PACKAGE__->add_file({ name => 'first' }, <<EF);
Hello [% p %]
EF

package main;

my $td = tempdir('/tmp/apache_swit_050_XXXXXX', CLEANUP => 1);
my $fw = H->new({ root_dir => $td });
$fw->write_first({ p => 'world' });
is(read_file("$td/first"), "Hello world\n");

H->add_file({ name => 'M/A.pm' }, 'Hello [% v %]');
$fw->write_m_a_pm({ v => 'pm' });
is(read_file("$td/M/A.pm"), "Hello pm");

$fw->write_m_a_pm({ v => 'pm' }, { path => 'M/B.pm' });
is(read_file("$td/M/B.pm"), "Hello pm");

write_file("$td/MANIFEST", "1");
H->add_file({ name => 'M/C.pm', manifest => 1 }, 'Mani [% v %]');
$fw->write_m_c_pm({ v => 'pm' });
is(read_file("$td/M/C.pm"), "Mani pm");
is(read_file("$td/MANIFEST"), "1\nM/C.pm\n");

H->add_file({ name => 'tmpl' }, 'Template [% cont1 %] is [% cont2 %]');
H->add_file({ name => 'M/N.pm', uses => 'tmpl', manifest => 1 },
		cont1 => 'strange [% d %]', cont2 => 'good [% e %]');
$fw->write_m_n_pm({ d => 'thing', e => 'laugh' });

is(read_file("$td/M/N.pm"), "Template strange thing is good laugh");
is(read_file("$td/MANIFEST"), "1\nM/C.pm\n\nM/N.pm\n");

H->add_file({ name => 'tmpl2', uses => 'tmpl' },
		cont1 => 'A [% a %]', cont2 => 'B [% b %]');
H->add_file({ name => 'M/M.pm', uses => 'tmpl2', manifest => 1 },
		a => 'a', b => 'b');
$fw->write_m_m_pm;
is(read_file("$td/M/M.pm"), "Template A a is B b");
is(read_file("$td/MANIFEST"), "1\nM/C.pm\n\nM/N.pm\n\nM/M.pm\n");

$fw->write_m_m_pm({}, { path => 'lib/A::C.pm' });
is(read_file("$td/lib/A/C.pm"), "Template A a is B b");
is(read_file("$td/MANIFEST"), "1\nM/C.pm\n\nM/N.pm\n\nM/M.pm\n\nlib/A/C.pm\n");

H->add_file({ name => 'N/N.pm', uses => 'tmpl2', manifest => 1,
		propagate => [ 'a' ] }, b => 'b');
$fw->write_n_n_pm({ a => 'one' });
is(read_file("$td/N/N.pm"), "Template A one is B b");
like(read_file("$td/MANIFEST"), qr/N\.pm/);

H->add_file({ name => 'm1' }, <<EM);
[% c %]
EM

$fw->write_m1({ c => 'hoho' }, { class => 'M1::M2' });
is(read_file("$td/lib/M1/M2.pm"), <<EM);
use strict;
use warnings FATAL => 'all';

package M1::M2;
hoho

1;
EM

eval { $fw->write_m1({ c => 'hoho' }, { class => 'M1::M2' }); };
like($@, qr/refusing/);

append_file("$td/lib/M1/M2.pm", "gjjg");
eval { $fw->write_m1({ c => 'hoho' }
		, { class => 'M1::M2', overwrite => 1 }); };
is($@, '');
unlike(read_file("$td/lib/M1/M2.pm"), qr/gjjg/);

my $cur = H->new;
is($cur->root_dir, '.');
undef $cur;

my $str = "ggg";
H->add_file({ name => 'dyn/a', path => sub {
	my $opts = shift;
	$opts->{vars}->{v} = 'hi';
	return "bb/$str.s";
} }, <<EM);
[% c %]
[% v %]
EM

$fw->write_dyn_a({ c => 'mu' });
is(read_file("$td/bb/ggg.s"), <<EM);
mu
hi
EM

$fw->write_dyn_a({ c => 'mu' }, { overwrite => 1, manifest => 1 });
like(read_file("$td/MANIFEST"), qr/ggg\.s/);
