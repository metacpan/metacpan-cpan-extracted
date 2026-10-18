use v5.40;
use Archive::BagIt;
use Path::Tiny;
my $dir_str = shift @ARGV || die "need a testdir given"; # testdir to use
my $dir = path($dir_str);

Archive::BagIt->make_bag($dir, {
        use_plugins => qw(Archive::BagIt::Plugin::SHA512)
});

