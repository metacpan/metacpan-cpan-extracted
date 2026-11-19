use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
my $root="$FindBin::Bin/..";
SKIP: {
    skip 'Generated CPAN module exists only inside a dzil build', 4 unless -f "$root/lib/App/Pvim.pm";
    require "$root/lib/App/Pvim.pm";
    open my $fh,'<',"$root/pvim" or die $!; local $/; my $source=<$fh>; close $fh;
    my ($version)=$source =~ /our\s+\$VERSION\s*=\s*'([^']+)'/;
    is($App::Pvim::VERSION,$version,'CPAN namespace version comes from standalone source');
    open $fh,'<',"$root/script/pvim" or die $!; my $script=<$fh>; close $fh;
    is($script,$source,'installed-script source is an exact copy of standalone runtime');
    is(system($^X,"$root/script/pvim",'--version'),0,'CPAN executable runs without library runtime dependencies');
    ok(-f "$root/META.json" && -f "$root/META.yml",'CPAN metadata included');
}
done_testing;
