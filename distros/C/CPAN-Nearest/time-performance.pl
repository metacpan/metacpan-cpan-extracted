#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin;
use Deploy 'do_system';
use IPC::Run3;
my $program = "$FindBin::Bin/nearest-module";
do_system ("make -f makeitfile nearest-module");
my @strings = qw/
                    Lingo::Jingo::Mojo
                    Lingua::Stopwords
                    Bust::A::Move
                    thequickbrownfoxjumpedoverthelazydogTHEQUICKBROWNFOXJUMPEDOVERTHELAZYDOG:
                    thequickbrownfoxjumpedoverthelazydogTHEQUICKBROWNFOX
                    thequickbrownfoxjumpedoverthelazydog
/;

for my $string (@strings) {
    my $aoutput;
    my $noutput;
    my $errors;
    run3 (["time", $program, "-a", $string], undef, \$aoutput, \$errors);
    my %atimes = process_times ($errors);
    run3 (["time", $program, $string], undef, \$noutput, \$errors);
    my %ntimes = process_times ($errors);
    if ($aoutput ne $noutput) {
        warn "Inconsistency: $aoutput $noutput";
    }
    my $time_diff = time_diff (\%atimes, \%ntimes);
    printf "Search term: '$string'\nNew time: %g Old time: %g Speedup factor: %2.5g\n\n",
    $atimes{real}, $ntimes{real}, $time_diff;
}

exit;

sub process_times
{
    my ($inputs) = @_;
    my %times;
    while ($inputs =~ /(\d+\.\d*)\s+(\w+)/g) {
        $times{$2} = $1;
    }
    return %times;
}

sub time_diff
{
    my ($atimes, $ntimes) = @_;
    return $ntimes->{real} / $atimes->{real};
}


