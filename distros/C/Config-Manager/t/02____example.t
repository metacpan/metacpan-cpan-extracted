#!perl -w

package Config::Manager::listconf;

use strict;
no strict "vars";

print "1..30\n";

$n = 1;

eval
{
    require Config::Manager::Base;
    Config::Manager::Base->import();
};
if ($@)
{
    print "not ok $n\n";
    $n++;
    print "not ok $n\n";
}
else
{
    print "ok $n\n";
    $n++;
    if ($Config::Manager::Base::VERSION eq '1.7')
    {print "ok $n\n";} else {print "not ok $n\n";}
}
$n++;

eval
{
    require Config::Manager::Conf;
    Config::Manager::Conf->import();
};
if ($@)
{
    print "not ok $n\n";
    $n++;
    print "not ok $n\n";
}
else
{
    print "ok $n\n";
    $n++;
    if ($Config::Manager::Conf::VERSION eq '1.7')
    {print "ok $n\n";} else {print "not ok $n\n";}
}
$n++;

eval
{
    require Config::Manager::User;
    Config::Manager::User->import(qw(user_id user_conf));
};
if ($@)
{
    print "not ok $n\n";
    $n++;
    print "not ok $n\n";
}
else
{
    print "ok $n\n";
    $n++;
    if ($Config::Manager::User::VERSION eq '1.7')
    {print "ok $n\n";} else {print "not ok $n\n";}
}
$n++;

$user = $Config::Manager::Base::VERSION +
        $Config::Manager::Conf::VERSION +
        $Config::Manager::User::VERSION;

if (defined ($user = &user_id()))
{print "ok $n\n";} else {print "not ok $n\n";$user='';}
$n++;

if (defined ($conf = &user_conf($user)))
{print "ok $n\n";} else {print "not ok $n\n";$conf=Config::Manager::Conf->new();}
$n++;

if (defined ($list = $conf->get_all()))
{print "ok $n\n";} else {print "not ok $n\n";$list=[];}
$n++;

$orig =
[
    [ 1, '$[DEFAULT]{CONFIGPATH}',  't',                   '^.+/Config/Manager/Conf\\.ini$', 29 ],
    [ 1, '$[DEFAULT]{LASTCONF}',    't/soft_defaults.ini', '^t/hard_defaults\\.ini$',         6 ],
    [ 1, '$[DEFAULT]{LOGFILEPATH}', '.',                   '^.+/Config/Manager/Conf\\.ini$', 30 ],
    [ 1, '$[DEFAULT]{PROJCONF}',    't/project.ini',       '^t/hard_defaults\\.ini$',         5 ],
    [ 1, '$[DEFAULT]{USERCONF}',    't/user.ini',          '^t/hard_defaults\\.ini$',         4 ],
    [ 1, '$[Eureka]{Hat_geklappt}', 'Juppie',              '^t/soft_defaults\\.ini$',         3 ],
    [ 1, '$[Manager]{NEXTCONF}',    't/hard_defaults.ini', '^.+/Config/Manager/Conf\\.ini$', 33 ],
    [ 1, '$[Person]{Name}',         'Steffen Beyer',       '^t/user\\.ini$',                  3 ],
    [ 1, '$[Person]{Telefon}',      '0162 77 49 721',      '^t/user\\.ini$',                  4 ],
    [ 1, '$[TEST]{NEXTCONF}',       't/TEST.ini',          '^.+/Config/Manager/Conf\\.ini$', 36 ]
];

$index = 0;
for ( $count = 0; $count < @{$list}; $count++ )
{
    $item = ${$list}[$count];
    next if ($$item[3] =~ /^<.+>$/);
    $comp = ${$orig}[$index++];
    $ok = 1;
    for ( $i = 0; $i < @{$item}; $i++ )
    {
        if ($i == 3)
        {
            unless ($$item[$i] =~ m!$$comp[$i]!) { $ok = 0; last; }
        }
        elsif ($i == 0 or $i == 5)
        {
            unless ($$item[$i] == $$comp[$i])    { $ok = 0; last; }
        }
        else
        {
            unless ($$item[$i] eq $$comp[$i])    { $ok = 0; last; }
        }
    }
    if ($ok)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$self = '02____example';

if (-d $self)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$file = Config::Manager::Report->logfile();

if ($file =~ m!/02____example(?:/\S+)?/02____example-\S*-\d{6}-\d{6}-\d+-\d+\.log$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-f $file)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

open(FILE, "<$file");
@log = <FILE>;
close(FILE);

if (@log == 7)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[0] =~ m!^_+$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[1] =~ m!^\s*$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[2] =~ m!^ STARTED: 02____example - \d\d-[A-Z][a-z][a-z]-\d+ \d\d:\d\d:\d\d - Steffen Beyer \(.*?\)$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[3] =~ m!^_+$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[4] =~ m!^\s*$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[5] =~ m!^ COMMAND: '[^']+' 't.02____example\.t'$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($log[6] =~ m!^\s*$!)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

