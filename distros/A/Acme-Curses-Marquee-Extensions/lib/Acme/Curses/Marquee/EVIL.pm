#No joy with Filter::Simple, so we'll have to be crafty.
open(BASE, '<', $INC{'Acme/Curses/Marquee.pm'}) || die $!;
$_ = join('', <BASE>);
close(BASE);

my $pp = <<'PPF';
my @fig = $self->{_font}->{$self->{font}}->figify(-A=>$text,-w=>-1);
PPF
s/^[^#]*(?:qx.|`)figlet.*$/$pp/m;

#For some reasons being conservative causes compilation to fail :-(
#s/^(.*use\s+warnings.+)$/\1no warnings 'redefined';/m;
s/^(.*use\s+warnings.+)$//m;

eval;

1;
