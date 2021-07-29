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
use File::Slurper qw(read_text read_dir);
use Pod::Checker;

for my $file (sort grep /\.pm$/, read_dir("blib/lib/App/Phoebe")) {
  # ok(0 == system($^X, '-c', "lib/App/Phoebe/$file"), "Syntax OK");
  my $test = $file;
  $test =~ s/pm$/t/;
  ok(-f "t/$test", "$test exists");
  my $module = $file;
  $module =~ s/\.pm//;
  # these tests don't use 'like' to prevent errors from printing the entire source
  my $source = read_text("lib/App/Phoebe/$file");
  ok($source =~ /^package App::Phoebe::$module/m, "$file is in a separate package");
  ok($source =~ /^use App::Phoebe qw/m, "$file uses the App::Phoebe module");
  ok($source =~ /^=head1 /m, "$file has some documentation");
}

for my $file (qw(script/phoebe blib/lib/App/Phoebe.pm),
	      map { "blib/lib/App/Phoebe/$_" } sort grep /\.pm$/, read_dir("blib/lib/App/Phoebe")) {
  my $source = read_text($file);
  for my $test ($source =~ /# tested by (\S+)/g) {
    ok(-f $test, "$test exists");
  }
}

my $checker = Pod::Checker->new(-warnings => 2);
for my $path (qw(script/phoebe blib/lib/App/Phoebe.pm),
	      (map { "blib/lib/App/Phoebe/$_" } sort grep /\.pm$/, read_dir("blib/lib/App/Phoebe")),
	      (map { "blib/script/$_" } sort grep /^[a-z].*[a-z]$/, read_dir("blib/script"))) {
  $checker = $checker->parse_from_file($path, \*STDERR);
  my $file = $path;
  $file =~ s/.*\///; # strip directory for the message
  is($checker->num_errors(), 0, "$file has no pod errors");
  is($checker->num_warnings(), 0, "$file has no pod warnings");
}

done_testing;
