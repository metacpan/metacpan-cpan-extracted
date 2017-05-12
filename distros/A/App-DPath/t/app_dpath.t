#! /usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Deep;
use JSON;
use YAML::Syck;
use Config::General;
use Config::INI::Serializer;
use Data::Structure::Util 'unbless';

sub check {
        my ($intype, $outtype, $path, $expected, $just_diag) = @_;

        $path       ||= '//lines//description[ value =~ m(use Data::DPath) ]/../_children//data//name[ value eq \'Hash two\']/../value';
        $expected   ||= [ "2" ];
        my $program   = "$^X -Ilib bin/dpath";
        #my $unblessed = $outtype eq "json" ? "_unblessed" : "";
        my $infile    = "t/testdata.$intype";
        my $cmd       = "$program -i $intype -o $outtype \"$path\" $infile";
        #diag $cmd;
        my $output    = `$cmd`;

        my $result;
        if ($outtype eq "json")
        {
                $result = JSON::from_json(unbless $output);
        }
        elsif ($outtype eq "yaml") {
                $result = YAML::Syck::Load($output);
        }
        elsif ($outtype eq "cfggeneral") {
                my %data = Config::General->new(-String => $output)->getall;
                $result = \%data;
        }
        elsif ($outtype eq "dumper")
        {
                eval "\$result = my $output";
        }
        elsif ($outtype eq "ini") {
                $result = Config::INI::Serializer->new->deserialize($output);
        }
        if ($just_diag) {
                diag Dumper($result);
        } else {
                cmp_deeply $result, $expected, "$intype - dpath - $outtype";
        }
}

check (qw(tap json));
check (qw(yaml json));
check (qw(yaml dumper));
check (qw(json dumper));
# XML <-> data mapping is somewhat artificial, so another path is needed
check (qw(xml dumper), '//description[ value =~ m(use Data::DPath) ]/../_children//data//Hash two/value');
check (qw(ini dumper), '//description[ value =~ m(use Data::DPath) ]/../number', [ "1" ]);
check (qw(ini json),   '//description[ value =~ m(use Data::DPath) ]/../number', [ "1" ]);
check (qw(ini yaml),   '//description[ value =~ m(use Data::DPath) ]/../number', [ "1" ]);
# Config::INI::Serializer hashifies arrays - array indexes become hashkeys
check (qw(ini ini),    '//description[ value =~ m(use Data::DPath) ]/../number', { '0' => "1" });
check (qw(xml ini),    '//description[ value =~ m(use Data::DPath) ]/../number', { '0' => "1" });
check (qw(ini ini),    '/start_time', { '0' => "1236463400.25151" });

# Config::General is also somewhat special
check (qw(cfggeneral json), '/etc/base', [ "/usr" ]);
check (qw(cfggeneral json), '//home', [ "/usr/home/max" ]);
check (qw(cfggeneral json), '//mono//bl', [ 2 ]);
check (qw(cfggeneral json), '//log', [ "/usr/log/logfile" ]);

check (qw(cfggeneral yaml), '/etc/base', [ "/usr" ]);
check (qw(cfggeneral yaml), '//home', [ "/usr/home/max" ]);
check (qw(cfggeneral yaml), '//mono//bl', [ 2 ]);
check (qw(cfggeneral yaml), '//log', [ "/usr/log/logfile" ]);

# taparchive
check (qw(taparchive ini),    '//description[ value =~ m(use Data::DPath) ]/../number', { '0' => "1" });
check (qw(taparchive json),   '//description[ value =~ m(use Data::DPath) ]/../number', ["1"]) ;
check (qw(taparchive yaml),   '//description[ value =~ m(use Data::DPath) ]/../number', ["1"]);
check (qw(taparchive dumper), '//description[ value =~ m(use Data::DPath) ]/../number', ["1"]);

diag qq{Ignore "unsupported innermost nesting" errors, that is what we test...};

my $program;
my $infile;
my $path;
my $ret;

$program   = "$^X -Ilib bin/dpath";
$infile    = "t/flatabledata.yaml";

$path      = "//UnsupportedInnermostHash";
$ret = system("$program -o flat '$path' $infile");
isnt ($ret, 0, "deny unsupported innermost HASH");

$path      = "//UnsupportedInnermostArray";
$ret = system("$program -o flat '$path' $infile");
isnt ($ret, 0, "deny unsupported innermost ARRAY");

done_testing;
