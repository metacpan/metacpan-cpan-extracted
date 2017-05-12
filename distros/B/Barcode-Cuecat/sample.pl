
use Barcode::Cuecat;

my $bc = new Barcode::Cuecat();

while (<>) {
    $bc->scan($_);
    print "Type = ", $bc->type(), "\n";
    print "Code = ", $bc->code(), "\n";
    print "S/N  = ", $bc->serial(), "\n";
    print " ------------\n"
}
