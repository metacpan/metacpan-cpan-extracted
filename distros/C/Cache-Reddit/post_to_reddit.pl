use Cache::Reddit;

my $data = { important_Data => 'New York Hack Night' };

my $key = set($data);
print "$key\n";
