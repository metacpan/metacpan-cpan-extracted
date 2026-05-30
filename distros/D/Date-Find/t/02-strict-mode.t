#!perl
use 5.020;
use Test2::V0 '-no_srand';
use Data::Dumper;
use Date::Find 'guess_ymd', 'find_all_ymd';

my @tests_guess = (
    { name => 'Simple ymd',
      options => { mode => 'strict'},
      expected => qr/Entries without a date found:.*random\.pdf.*/,
      list => ['random.pdf']
    },
);

plan tests => 0+@tests_guess*2;

for my $t (@tests_guess) {
    my %options = $t->{options} ? %{ $t->{options} } : ();
    my @res;
    my $lives = eval { guess_ymd($t->{list}, %options); 1 };
    my $err = $@;

    is $lives, undef, "We croaked";
    like $err, $t->{expected}, "We found the filename in the error message";
}
