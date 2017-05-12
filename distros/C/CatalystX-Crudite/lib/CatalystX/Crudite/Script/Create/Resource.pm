package CatalystX::Crudite::Script::Create::Resource;
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(realpath);
use File::Spec;
use Getopt::Long;
use CatalystX::Crudite::Util qw(install_shared_files);

sub run {
    my ($class, $dist_name) = @_;
    GetOptions(
        'verbose|v'   => \my $verbose,
        'overwrite|o' => \my $overwrite,
        'dryrun|n'    => \my $dryrun
    ) or die 'Getopt error';
    my $resource_name = shift @ARGV || die "Need a resource name.\n";

    # Assume that the executable script crudite_create.pl lives in the
    # standard <repo>/script/ dir.
    my $dist_dir = realpath(File::Spec->rel2abs("$Bin/.."));
    -d "$dist_dir/lib" or die "lib/ not found - is this a Perl dist?\n";
    install_shared_files(
        dist_name  => $dist_name,
        dist_dir   => $dist_dir,
        share_path => 'create/resource',
        verbose    => $verbose,
        overwrite  => $overwrite,
        dryrun     => $dryrun,
        vars       => {
            resource_name => $resource_name,

            # E.g., name "ContentType" means symbol "content_type"
            resource_symbol => lc($resource_name =~ s/\w\K(?=[A-Z])/_/r),
        },
        filename_replace => {
            MyResource => $resource_name,
            myresource => "\L$resource_name",
        },
    );
}
1;
