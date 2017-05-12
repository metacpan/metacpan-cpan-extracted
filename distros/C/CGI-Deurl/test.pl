# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Deurl 'NOTCGI';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{my %hash;
    
print "deurl 'a=5&name=Jan+Krynicky&file=c%3A%5Ctemp%5Cfile_15.%24%24%24', \\%hash\n";
deurl 'a=5&name=Jan+Krynicky&file=c%3A%5Ctemp%5Cfile_15.%24%24%24', \%hash;

foreach (keys %hash) {
    print "\t$_ = $hash{$_}\n";
}

if ($hash{a} == 5 and $hash{name} eq 'Jan Krynicky' and $hash{file} eq 'c:\temp\file_15.$$$') {
    print "ok 2\n\n";
} else {
    print "not ok 2\n\n";
}

}
##########<???>

{ my %hash;
    
print "deurl '5&Jan+Krynicky&c%3A%5Ctemp%5Cfile_15.%24%24%24', \\%hash\n";
deurl '5&Jan+Krynicky&c%3A%5Ctemp%5Cfile_15.%24%24%24', \%hash;

foreach (keys %hash) {
    print "\t$_ = $hash{$_}\n";
}

if ($hash{0} == 5 and $hash{1} eq 'Jan Krynicky' and $hash{2} eq 'c:\temp\file_15.$$$') {
    print "ok 3\n\n";
} else {
    print "not ok 3\n\n";
}

}

#############<???>

{ my %hash;
    
print "deurl '5&Jan+Krynicky&a=5&name=Jan+Krynicky&c%3A%5Ctemp%5Cfile_15.%24%24%24&file=c%3A%5Ctemp%5Cfile_15.%24%24%24', \\%hash\n";
deurl '5&Jan+Krynicky&a=5&name=Jan+Krynicky&&c%3A%5Ctemp%5Cfile_15.%24%24%24&file=c%3A%5Ctemp%5Cfile_15.%24%24%24', \%hash;

foreach (keys %hash) {
    print "\t$_ = $hash{$_}\n";
}

print @{$hash{0}},"\n";

if ($hash{0} == 5 and $hash{1} eq 'Jan Krynicky' and $hash{2} eq 'c:\temp\file_15.$$$'
and $hash{a} == 5 and $hash{name} eq 'Jan Krynicky' and $hash{file} eq 'c:\temp\file_15.$$$') {
    print "ok 4\n\n";
} else {
    print "not ok 4\n\n";
}

}

#############<???>


