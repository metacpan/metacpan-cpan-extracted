# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use File::Slurper qw(write_text);

my $msg;
if (not $ENV{TEST_AUTHOR}) {
  $msg = 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
} else {
  for my $module (qw(Net::IP Net::DNS)) {
    if (not defined eval "require $module") {
      $msg = "You need to install the $module module for this test.";
      last;
    }
  }
}

plan skip_all => $msg if $msg;

our @use = qw(SpeedBump);

our @config = (<<'EOT');
package App::Phoebe::SpeedBump;
our $speed_bump_requests = 2;
our $speed_bump_window = 5;
package App::Phoebe;
our @known_fingerprints = qw(
    sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
EOT

require './t/test.pl';

# variables defined by test.pl
our $base;
our $dir;

my $page = query_gemini("$base/do/speed-bump/reset");
like($page, qr(^20), "Speed bump reset");

$page = query_gemini("$base/do/speed-bump/debug");
like($page, qr(^20), "Speed bump debug");
like($page, qr(\$VAR1 = undef), "Speed bump data is empty");

write_text("$dir/speed-bump.json", <<'EOT');
{
  "18.130.151.101": {
    "cidr":"18.130.0.0\/16",
    "probation":1613945781,
    "seconds":2419200,
    "until":1611526581,
    "visits":[1609107042,1609107035,1609107028,1609107021,1609107014,1609107006,1609106998,1609106991,1609106983,1609106976,1609106969],
    "warnings":[1,1,1,1,1,1,1,1,1,1,1]},
  "18.130.170.163": {
    "cidr":"18.130.0.0\/16",
    "probation":1613936315,
    "seconds":2419200,
    "until":1611517115,
    "visits":[1609092165,1609092153,1609092140,1609092114,1609092103,1609092076,1609092063,1609092048,1609092033,1609092008,1609091982,1609091955,1609091941,1609091928,1609091902,1609091888,1609091876],
    "warnings":[1,1,1,1,1,1,1,1,1,1,"","","",1,"","",""]},
  "18.132.209.113": {
    "cidr":"18.132.0.0\/14",
    "probation":1613945147,
    "seconds":2419200,
    "until":1611525947,
    "visits":[1609098108,1609098101,1609098092,1609098085,1609098068,1609098060,1609098042,1609098026,1609097991,1609097976,1609097960],
    "warnings":[1,1,1,1,1,1,1,1,1,1,1]},
  "18.134.12.41": {
    "cidr":"18.132.0.0\/14",
    "probation":1613929318,
    "seconds":2419200,
    "until":1611510118,
    "visits":[1609083966,1609083952,1609083932,1609083916,1609083901,1609083887,1609083870,1609083852,1609083835,1609083819,1609083803],
    "warnings":[1,1,1,1,1,1,1,1,1,1,1]},
  "18.135.104.61":{
    "cidr":"18.132.0.0\/14",
    "probation":1613951744,
    "seconds":2419200,
    "until":1611532544,
    "visits":[1609106840,1609106831,1609106824,1609106816,1609106807,1609106799,1609106791,1609106784,1609106778,1609106769,1609106762,1609106754],
    "warnings":[1,1,1,1,1,1,1,1,1,1,"",1]}}
EOT

$page = query_gemini("$base/do/speed-bump/load");
like($page, qr(^20), "Data loaded");

$page = query_gemini("$base/do/speed-bump/status");
like($page, qr(^20), "Status loaded");
like($page, qr(18\.135\.104\.61), "IP number found");
like($page, qr(CIDR\n.*18\.132\.0\.0/14), "CIDR number found");

$page = query_gemini("$base/");
like($page, qr(^20), "Request 1");

$page = query_gemini("$base/");
like($page, qr(^20), "Request 2");

$page = query_gemini("$base/");
like($page, qr(^44 60), "Request 3 is blocked for 60s");

$page = query_gemini("$base/do/speed-bump/status");
#  From    To Warns Block Until Probation IP
#   -5s   -5s  2/ 2   60s   55s      115s 127.0.0.1
like($page, qr(^ +0s +0s +2\/ 2\ +60s +60s +120s +127\.0\.0\.1)m, "Blocked for 60s!");

# also making sure all the data from the old JSON file expired
unlike($page, qr(18\.135\.104\.61), "IP number no longer found");
unlike($page, qr(CIDR\n.*18\.132\.0\.0/14), "CIDR number no longer found");

done_testing();
