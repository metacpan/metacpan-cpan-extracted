use v5.40;
use Archive::BagIt;
use Path::Tiny;
# Validate a BagIt archive against its manifest
my $dir_str = shift @ARGV || die "need a bag dir given"; # testdir to use
my $dir = path($dir_str);

my $bag = Archive::BagIt->new({
    bag_path => $dir,
    use_plugins => qw(Archive::BagIt::Plugin::SHA256)
});

my $is_valid = $bag->verify_bag( {report_all_errors => 1} );
say "is valid? " . ($is_valid ? "yes" : "no");
