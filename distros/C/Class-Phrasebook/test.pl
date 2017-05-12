# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Phrasebook;
use Log::LogLite;
$loaded = 1;
print "ok 1\n";
unlink("test.log"); # clean the test.log if it exits.
my $log = new Log::LogLite("test.log");

my $pb = new Class::Phrasebook($log, "test.xml");

print_ok($pb->load("EN"), 2, "load English dictionary");

my $phrase;

$phrase = $pb->get("HELLO_WORLD");
print_ok(clean_whites($phrase) eq clean_whites("Hello World!!!"), 3, 
	 "simple get");

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $hour_str = sprintf("%.2d:%.2d", $hour, $min);
$phrase = $pb->get("THE_HOUR", { hour => $hour_str });
print_ok(clean_whites($phrase) eq clean_whites("The time now is $hour_str."), 
	 4, "get with placeholder");

$phrase = $pb->get("ADDITION", { a => 10,
			         b => 11,
			         c => 21 });
print_ok(clean_whites($phrase) eq 
	 clean_whites("add 10 and 11 and you get 21"), 5, 
	 "get with several placeholders");

# now we load the Dutch dictionary
print_ok($pb->load("NL"), 6, "load Dutch dictionary");

$phrase = $pb->get("HELLO_WORLD");
print_ok(clean_whites($phrase) eq clean_whites("Hallo Wereld!!!"), 7, 
	 "simple get");

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $hour_str = sprintf("%.2d:%.2d", $hour, $min);
$phrase = $pb->get("THE_HOUR", { hour => $hour_str });
print_ok(clean_whites($phrase) eq clean_whites("Het is nu $hour_str."), 
	 8, "get with placeholder");

$phrase = $pb->get("ADDITION", { a => 10,
			         b => 11,
			         c => 21 });
print_ok(clean_whites($phrase) eq clean_whites("10 + 11 = 21"), 9, 
	 "get with several placeholders");

$phrase = $pb->get("THE_AUTHOR");
print_ok(clean_whites($phrase) eq clean_whites("Rani Pinchuk"), 10, 
	 "get from the default dictionary");

my $pbs;
for (my $i = 0; $i < 10; $i++) {
    $pbs->[$i] = new Class::Phrasebook($log, "test.xml");
    $pbs->[$i]->load("EN");
}
for (my $i = 10; $i < 15; $i++) {
    $pbs->[$i] = new Class::Phrasebook($log, "test.xml");
    $pbs->[$i]->load("NL");
}

# the phrases of all the first ten objects suppose to be kept in the same hash:
print_ok($pbs->[0]{PHRASES} == $pbs->[1]{PHRASES} && 
	 $pbs->[1]{PHRASES} == $pbs->[2]{PHRASES} && 
	 $pbs->[2]{PHRASES} == $pbs->[3]{PHRASES} && 
	 $pbs->[3]{PHRASES} == $pbs->[4]{PHRASES} && 
	 $pbs->[4]{PHRASES} == $pbs->[5]{PHRASES} && 
	 $pbs->[5]{PHRASES} == $pbs->[6]{PHRASES} && 
	 $pbs->[6]{PHRASES} == $pbs->[7]{PHRASES} && 
	 $pbs->[7]{PHRASES} == $pbs->[8]{PHRASES} && 
	 $pbs->[8]{PHRASES} == $pbs->[9]{PHRASES} &&
	 $pbs->[10]{PHRASES} == $pbs->[11]{PHRASES} && 
	 $pbs->[11]{PHRASES} == $pbs->[12]{PHRASES} && 
	 $pbs->[12]{PHRASES} == $pbs->[13]{PHRASES} && 
	 $pbs->[13]{PHRASES} == $pbs->[14]{PHRASES}, 11, 
	 "caching phrases of the same dictionary");
print_ok($pbs->[9]{PHRASES} != $pbs->[10]{PHRASES}, 12,
	 "caching phrases of the different dictionaries");
print_ok(Class::Phrasebook->Dictionaries_names_in_cache() == 2, 13, 
	 "cache holds two dictionaries - NL and EN");
# keep one of the objects and delete the rest
$pb = $pbs->[5];
$pbs = undef;
# try a simple get on the object we kept. the EN dictionary should be 
# still available.
$phrase = $pb->get("HELLO_WORLD");
print_ok(clean_whites($phrase) eq clean_whites("Hello World!!!"), 14, 
	 "checking the cache with a simple get");
print_ok(Class::Phrasebook->Dictionaries_names_in_cache() == 1, 15, 
	 "cache holds one dictionaries - EN");
$pb = undef;
print_ok(Class::Phrasebook->Dictionaries_names_in_cache() == 0, 16, 
	 "cache is empty");

my $pb = new Class::Phrasebook($log, "test.xml");
$pb->load("EN");
$phrase = $pb->get("THE_HOUR", { hour => '$hour_str' });
print_ok(clean_whites($phrase) eq clean_whites('The time now is $hour_str.'), 
	 17, "placeholder contains \$ and place_holders_conatain_dollars(0)");




#######################
# clean_whites
#######################
sub clean_whites {
    my $str = shift;
    $str =~ s/\s+/ /goi;
    $str =~ s/^\s//;
    $str =~ s/\s$//;
    return $str;
} # of clean_whites

#############################################
# print_ok ($expression, $number, $comment)
#############################################
sub print_ok {
    my $expression = shift;
    my $number =shift;
    my $string = shift || "";

    $string = "ok " . $number . " " . $string . "\n";
    if (! $expression) {
        $string = "not " . $string;
    }
    print $string;
} # print_ok





