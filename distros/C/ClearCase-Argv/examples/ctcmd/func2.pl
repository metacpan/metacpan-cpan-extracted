use ClearCase::CtCmd qw(cleartool);

# In scalar context, returns stdout.
my $cwv = cleartool('pwv -s');
chomp($cwv);
print "Current View is '$cwv'\n";
