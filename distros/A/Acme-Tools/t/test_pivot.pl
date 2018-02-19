my $data={
    'Dirt' => {
	'Sample1.16' => 4,
	'Sample1.14' => 1
    },
    'Air' => {
	'Sample1.16' => 1,
	'Sample2.45' => 4
    },
    'Water' => {
	'Sample1.14' => 3
    }
};
use Acme::Tools;
use Data::Pivot;
print "$Acme::Tools::VERSION\n";
my %sample;
$sample{$_}++ for map keys(%$_), values %$data;
my $data2=[
    map { my $x=$_;  map [$x,$_,$$data{$x}{$_}||' 0'], sort keys %sample }
    sort keys %$data
];
print srlz($data2,'data2','',1);
my @ap=Acme::Tools::pivot($data2,"Element");
print srlz(\@ap,'ap','',1);
print tablestring([@ap]);
print "--------------------------------------------------------------------------------\n";
my @p = Data::Pivot::pivot( table=>$data2,
			    headings=>['x',sort keys %sample],
			    pivot_column=>2,
			    format=>'%5.2f',
                            layout => 'vertical',
    );
print srlz(\@p,'p','',1);
