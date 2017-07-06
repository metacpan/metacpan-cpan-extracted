use lib '.';
use t::Helper;
use File::Path 'remove_tree';
use File::Spec::Functions 'catdir';

plan skip_all => '.git missing' unless -d '.git';

my $tt   = t::Helper->tt;
my $year = 1900 + (localtime)[5];
my @args = ("$year-09-17T09:00:00", "17:00:00");

is $tt->cmd_register(@args), 0, 'register with missing args';
like $main::out, qr{import data from other sources}, 'register help';

push @args, 'project-name', 'some description', 'foo,bar';
is $tt->cmd_register(@args), 0, 'register project-name';

@args[0 .. 2] = ("$year-10-17T09:00:00", '17:00:00', 'other');
is $tt->cmd_register(@args), 0, 'register with hh::mm::ss';

@args[1] = '18:00:00';
is $tt->cmd_register(@args), 1, 'register with same time';

$main::out = '';
is $tt->cmd_log('year'), 0, 'cmd_log';
like $main::out, qr{\s+17\s+09:00\s+8:00\s+project-name\s+foo,bar}i, 'log sep';
like $main::out, qr{\s+17\s+09:00\s+8:00\s+other\s+foo,bar}i,        'log oct';

remove_tree(catdir qw(t .TimeTracker-start-stop.t));

done_testing;
