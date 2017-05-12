#! /usr/bin/perl

use warnings;
use strict qw/subs refs/;
use utf8;

use Config;

$::name = "install"; # It's here twice on purpose.
$::name = "install"; # It avoids the warning...

END { finalize(); }

use Test::More tests => 5;#FILLME

our $perl = $Config{perlpath};
our $exe = $Config{_exe};
$perl .= $exe unless substr($perl, -length($exe)) eq $exe;
our $sort = qq{$Config{perlpath}$Config{_exe} -e 'print(sort(<STDIN>))'};

# TEST 1
do 't/setup.i'; # The setup. It runs one test, loading of Config::Maker.

$conffile = puttemp(config => <<'EOF');
EOF

$tmplfile = puttemp(template => <<'EOF');
one
two
three
four
five
EOF

$outfile = tf('output');
$outcmd = tf('cmdout');

puttemp(desout => $desout = <<"EOF");
one
two
three
four
five
EOF

puttemp(descmd => $descmd = <<"EOF");
five
four
one
three
two
EOF

# TEST 2
$metafile = puttemp(metacfg => <<"EOF");
search-path '.';
output-dir '.';

config '$conffile' {
    template {
	src '$tmplfile';
	out '$outfile';
    }
}
EOF

Config::Maker::Metaconfig->do($metafile);
$real = gettemp('output');

ok($real eq $desout, "Install file");

# TEST 3
$metafile = puttemp(metacfg => <<"EOF");
search-path '.';
output-dir '.';

config '$conffile' {
    template {
	src '$tmplfile';
	command "$sort > $outcmd";
    }
}
EOF

Config::Maker::Metaconfig->do($metafile);
$real = gettemp('cmdout');

ok($real eq $descmd, "Pass to command");

# TEST 4, 5

$metafile = puttemp(metacfg => <<"EOF");
search-path '.';
output-dir '.';

config '$conffile' {
    template {
	src '$tmplfile';
	out '$outfile';
	command "$sort > $outcmd";
    }
}
EOF

Config::Maker::Metaconfig->do($metafile);

$real = gettemp('output');
ok($real eq $desout, "Both, check file");

$real = gettemp('cmdout');
ok($real eq $descmd, "Both, check command output");


# arch-tag: e0c372d8-de89-4355-a8c6-c91b49794b86
# vim: set ft=perl:
