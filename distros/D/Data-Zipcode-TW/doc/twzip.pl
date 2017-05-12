use v5.14;
use utf8;
use encoding 'utf8';
use IO::All;
use Perl6::Perl qw(perl);
use Data::Dumper;


my $in = io("twzip.txt")->utf8->chomp;

my %zip;
my $area;
while(defined($_ = $in->getline)) {
    next unless $_;
    if (/^\s*(.+)\s+(\d+)$/) {
        if (exists $zip{$1}) {
            $zip{$1} = undef;
        }
        else {
            $zip{$1} = $2;
        }

        $zip{"$area$1"} = $2;
        $zip{$2} = "$area$1";
    }
    else {
        $area = $_;
    }
}

# say perl(\%zip);
$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;

{
    no warnings 'redefine';
    sub Data::Dumper::qquote {
        my $s = shift;
        return "'$s'";
    }
}

print 'my $ZIPCODE = ' . Dumper(\%zip) . ";\n";


