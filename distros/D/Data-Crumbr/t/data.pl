use utf8;
my $data = {
   one => '1',
   two => 2,
   three => 3.1,
   four => '4.0',
   true => \1,
   false => \0,
   array => [ qw< what ever >, { inner => 'part', empty => [] } ],
   hash => {
      'with ♜' => {},
      ar => [ 1..3 ],
      something => "funny \x{263A} ☻",
   },
};
