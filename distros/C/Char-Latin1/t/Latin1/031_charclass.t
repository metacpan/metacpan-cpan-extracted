# encoding: Latin1
use Latin1;
print "1..1\n";

my $__FILE__ = __FILE__;

# [\{]
if ("{" =~ m/[\{]/) {
    print qq<ok - 1 "{" =~ m/[\\{]/ $^X $__FILE__\n>;
}
else{
    print qq<not ok - 1 "{" =~ m/[\\{]/ $^X $__FILE__\n>;
}

__END__

