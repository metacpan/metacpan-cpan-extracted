#!perl
use 5.020;
use Test2::V0 '-no_srand';
use Data::Dumper;
use Date::Find 'guess_ymd', 'find_all_ymd';

my @tests_find = (
    { name => 'Simple ymd',
      expected => {
                    ymd => { year => '2022', month => '11', day => '06'},
                    ym  => { year => '2022', month => '11', day => '00'},
                    y   => { year => '2022', month => '00', day => '00'},
                  },
      value    => '20221106'
    },
    { name => 'Simple d.m.y',
      expected => {
                    dmy => { year => '2022', month => '11', day => '06'},
                    my  => { year => '2022', month => '11', day => '00'},
                    y   => { year => '2022', month => '00', day => '00'},
                  },
      value    => '06.11.2022'
    },
);

my @tests_guess = (
    { name => 'Simple ymd',
      expected => [{ value => '20221106', year => '2022', month => '11', day => '06'},],
      list => ['20221106']
    },
    { name => 'Simple ymd, mixed',
      expected => [
          { value => '20221106',   year => '2022', month => '11', day => '06'},
          { value => '2022-11-06', year => '2022', month => '11', day => '06'},
      ],
      list => ['20221106', '2022-11-06']
    },
    { name => 'Any component, ymd',
      expected => [
          { value => '20221106',   year => '2022', month => '11', day => '06'},
          { value => '2022-11-06', year => '2022', month => '11', day => '06'},
          { value => '06.11.2022', year => '2022', month => '11', day => '06'},
      ],
      options => { components => 'dmy' },
      list => ['20221106', '2022-11-06', '06.11.2022']
    },
    { name => 'Only a year, but best attempt',
      expected => [
          { value => '1042099_2022.pdf', year => '2022', month => '00', day => '00'},
          { value => '2099_2022_0004.pdf', year => '2022', month => '00', day => '00'},
      ],
      options => { components => 'y' },
      list => ['1042099_2022.pdf', '2099_2022_0004.pdf']
    },
    { name => 'Spelled out month names',
      expected => [
          { value => '8 May 2023', year => '2023', month => '05', day => '08'},
          { value => '8. Mai 2023', year => '2023', month => '05', day => '08'},
      ],
      options => { components => 'xdy' },
      list => ['8 May 2023', '8. Mai 2023']
    },
    # 2025.07.05_20250709205555.pdf
    { name => 'Multiple potential years',
      expected => [
          { value => '2025.07.05_20250709205555.pdf', year => '2025', month => '00', day => '00'},
      ],
      options => { components => 'y' },
      list => ['2025.07.05_20250709205555.pdf']
    },
);

plan tests => 0+@tests_guess+@tests_find;

for my $t (@tests_find) {
    my %res = find_all_ymd($t->{value});
    is \%res, $t->{expected}, $t->{name}
        or diag Dumper \%res;
}


for my $t (@tests_guess) {
    my %options = $t->{options} ? %{ $t->{options} } : ();
    my @res = guess_ymd($t->{list}, %options);
    is \@res, $t->{expected}, $t->{name}
        or diag Dumper \@res;
}
