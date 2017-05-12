#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  Copyright (C) 2011 - Anthony J. Lucas - kaoyoriketsu@ansoni.com



package main;



use strict;
use warnings;
use Test::More;



BEGIN { use_ok( 'Config::YAARG', qw( :script ));}


#setup test
use constant ARG_NAME_MAP => { Debug => 'debug', Opts => 'options', 'Verbose' => 'verbose' };
use constant ARG_NAME_LIST => [qw/Debug Opts Verbose=b/];
use constant ARG_VALUE_TRANS => { Debug => sub{2}, Opts => sub{+{split /,/, $_[0]}} };


my $test_values = { Debug => 1, Opts => join(',', 1..4) };
my $test_values_output = { Debug => 2, Opts => {1..4} };

push @ARGV, (map { ("--$_", $test_values->{$_}) } keys %$test_values);
push(@ARGV, '--Verbose');

$test_values->{'Verbose'} = 1;
$test_values_output->{'Verbose'} = 1;

my %args;
ok( %args = ARGS(), 'process and retrieve args, &ARGS');

#perform test
my $failed = 0;
foreach (keys(%$test_values)) {

    is_deeply($args{ARG_NAME_MAP->{$_}}, $test_values_output->{$_},
        "input matches expected output for: $_")
        or $failed++;
}
ok ($failed < 1, 'input arguments match expected output for all arguments');


done_testing();
