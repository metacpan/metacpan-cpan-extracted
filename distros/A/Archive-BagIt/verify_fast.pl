use Archive::BagIt::Fast;
# Validate a BagIt archive against its manifest
my $bag4 = Archive::BagIt::Fast->new(@ARGV);
my $is_valid2 = $bag4->verify_bag( {report_all_errors => 1} );
