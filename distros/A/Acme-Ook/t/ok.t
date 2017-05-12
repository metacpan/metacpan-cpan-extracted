use File::Spec;
use Acme::Ook;
my $ook = File::Spec->catfile("ook", "ok.ook");
my $Ook = Acme::Ook->new;
$Ook->Ook($ook);
