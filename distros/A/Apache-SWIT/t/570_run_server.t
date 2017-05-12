use strict;
use warnings FATAL => 'all';

use Test::More tests => 31;
use Test::TempDatabase;
use Apache::SWIT::Test::Utils;
use File::Slurp;
use LWP::UserAgent;
use IPC::Run qw( start pump finish timeout ) ;

BEGIN { use_ok('Apache::SWIT::Maker');
	use_ok('Apache::SWIT::Test::ModuleTester');
}

Apache::SWIT::Test::ModuleTester::Drop_Root();

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->make_swit_project;
ok(-f 'LICENSE');
`perl Makefile.PL && make 2>&1`;

my $psql = `psql -l`;
$ENV{ASTU_MEM} = 1;
my @cmd = ("./scripts/swit_app.pl", "run_server"); 
my ($in, $out, $err);
my $t = timeout(30);

my $h = start(\@cmd, \$in, \$out, \$err, $t);
eval { pump $h until $err =~ /Press Enter to finish \.\.\./; };
if ($@) {
	diag("Error in pumping: $@\n$err");
	exit 1;
}

my ($host) = ($out =~ /server ([^\n]+) started/);
like($err, qr/Press Enter to finish \.\.\./);
like($err, qr/Apache memory before/);
isnt($host, undef) or $host = '';

my $ua = LWP::UserAgent->new;
my $cont = $ua->get("http://$host/ttt/index/r")->content;
like($cont, qr/first/) or ASTU_Wait(read_file('t/logs/error_log'));
like($err, qr#http://$host#);

unlike($out, qr/Leaving/);
$in .= "\n";
pump $h;

while(pump $h) {}
like($out, qr/Leaving/);
like($err, qr/Apache memory after/);
finish $h or die "cmd returned $?" ;

($in, $out, $err) = ();
my $help = `./scripts/swit_app.pl 2>&1`;
like($help, qr/run_server.*host.*port/);

system("make realclean 2>/dev/null 1>/dev/null");
push @cmd, "goo.ga:11111";

delete $ENV{ASTU_MEM};
$h = start(\@cmd, \$in, \$out, \$err, $t);
pump $h until $err =~ /Press Enter to finish \.\.\./;
($host) = ($out =~ /server ([^\n]+) started/);
like($err, qr/Press Enter to finish \.\.\./);
unlike($err, qr/memory before/);
is($host, "goo.ga:11111");
finish $h or die "cmd returned $?" ;
unlike($err, qr/memory after/);

$mt->insert_into_schema_pm('
$dbh->do("create table one_col_table (id serial primary key, ocol text)");
');

push @cmd, "swit_run_server_db";
$h = start(\@cmd, \$in, \$out, \$err, $t);
eval { pump $h until $err =~ /Press Enter to finish \.\.\./; };
is($@, '') or ASTU_Wait($err);
($host) = ($out =~ /server ([^\n]+) started/);
like($err, qr/Press Enter to finish \.\.\./);
is($host, "goo.ga:11111");
like(`psql -l`, qr/swit_run_server_db/);
finish $h or die "cmd returned $?" ;

like(`psql -l`, qr/swit_run_server_db/);

`psql -c "insert into one_col_table (ocol) values ('gggg')" swit_run_server_db`;
is($?, 0);

`./scripts/swit_app.pl scaffold one_col_table 2>&1`;
is($?, 0);
ok(-f 'lib/TTT/DB/OneColTable.pm');

$cmd[2] = 1;
$h = start(\@cmd, \$in, \$out, \$err, $t);
eval { pump $h until $err =~ /Press Enter to finish \.\.\./; };
is($@, '') or ASTU_Wait("$out,\n$err");
($host) = ($out =~ /server ([^\n]+) started/);
like($err, qr/Press Enter to finish \.\.\./);
like($ua->get("http://$host/ttt/onecoltable/list/r")->content, qr/gggg/)
	or ASTU_Wait($td);

my $f = "blib/templates/onecoltable/list.tt";
ok(-f $f);
`chmod +w $f`;
append_file($f, "hhhhh");
sleep 1;
$ua = LWP::UserAgent->new;
like($ua->get("http://$host/ttt/onecoltable/list/r")->content, qr/hhhhh/)
	or diag(read_file($f));

finish $h or die "cmd returned $?" ;

like(`psql -l`, qr/swit_run_server_db/);

END {
`dropdb swit_run_server_db 2>&1 1>/dev/null`;
is(`psql -l`, $psql);
};

chdir '/';

