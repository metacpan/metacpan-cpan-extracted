use Moose;
my $file = '/agllore/apple/gllor';
my $one = 'gllor';
my $two = 'gllore';

$file =~ s/(?<=\b)(?=$one\b)$one/$two/g;

print $file;