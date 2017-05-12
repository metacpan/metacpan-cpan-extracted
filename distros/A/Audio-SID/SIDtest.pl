eval 'exec perl -w -S $0 ${1+"$@"}'
                if 0;

use Audio::SID;

$mySID = new Audio::SID ("Ala.sid") or die "Whoops!";

@array = $mySID->getFieldNames();
print "Fieldnames = " . join(' ', @array) . "\n";

print "Name = " . $mySID->get('name') . "\n";

$mySID->set(author => 'LaLa',
             name => 'Trallalala',
             copyright => '1999 Hungarian Cracking Crew');

$mySID->setSpeed(1,1);

my $clock = $mySID->getClockByName();
print "Clock (video standard) before = $clock\n";

$mySID->setClockByName('PAL');

my $SIDModel = $mySID->getSIDModel();
print "SIDModel before = $SIDModel\n";

$mySID->setSIDModelByName('8580');

$mySID->alwaysValidateWrite(1);
$mySID->write("Ala2.sid") or die "Couldn't write!";

$mySID->read("Ala2.sid") or die "Couldn't open!";

$clock = $mySID->getClockByName();
print "Clock (video standard) after = $clock\n";

$SIDModel = $mySID->getSIDModelByName();
print "SIDModel after = $SIDModel\n";
