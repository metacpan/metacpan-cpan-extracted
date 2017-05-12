use strict;
use warnings;
use Test::More;
plan skip_all => "sweeper functionality is currently broken and disabled";
use Cwd;
our @fake_error = (1); # same working
our %process_state = (
    unprocessed => 0,
    working     => 1,
    processed   => 2,
    failed      => 3,
);
our @expect_fail=[51,0,3];

@expect_fail = @expect_fail; # silence warnings on 5.6.2
%process_state = %process_state; # silence warnings on 5.6.2
@fake_error = @fake_error; # silence warnings on 5.6.2

my $file='t/01-mysql.t';
my $res = do $file;
if (!defined $res) {
    die "Error executing '$file': ",$@||$!,"\nCwd=". cwd(),"\n";
}


