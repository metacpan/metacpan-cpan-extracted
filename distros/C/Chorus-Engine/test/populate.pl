use Chorus::Frame;

my @stock = ();

my @slotName = ('aaa','bbb','ccc');

my $F1 = Chorus::Frame->new(  
  'AAA' => 'OK',
);

my $F2 = Chorus::Frame->new(
  _ISA  => $F1,
  'BBB' => 'OK',
);
  
print "Populating .. ";

for (1 .. 20000) {
  
  my $slot = $slotName[int(rand(3))];
  my $f = Chorus::Frame->new(
     $slot => rand(1),
     stest => 'y'
  );
  
  $f->_inherits($F2) if $slot eq 'aaa';
  push @stock,$f;
  
}

print "done\n\n";

print "MATCH 1 .. ";
my @l = fmatch(slot=>['aaa', 'stest']);
print scalar(@l) . "\n";

print "MATCH 2 .. ";
@l = fmatch(slot=>['AAA', 'stest']);
print scalar(@l) . "\n";
