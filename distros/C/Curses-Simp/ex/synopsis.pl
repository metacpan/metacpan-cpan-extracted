use Curses::Simp;
my @text; my $keey = '';
my $simp = tie(@text, 'Curses::Simp');
@text =('1337', 'nachoz', 'w/', 'cheese' x 7);
while($keey ne 'x'){         # wait for 'x' to eXit
  $keey = $simp->GetKey(-1); # get a blocking keypress
  push(@text, $keey);
}

