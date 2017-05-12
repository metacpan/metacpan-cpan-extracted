package CatalystX::Crudite::Script::Starter;
use strict;
use warnings;
use Cwd qw(getcwd);
use Getopt::Long;
use CatalystX::Crudite;
use CatalystX::Crudite::Util qw(install_shared_files);

sub run {
    GetOptions(
        'verbose|v'   => \my $verbose,
        'overwrite|o' => \my $overwrite,
        'dryrun|n'    => \my $dryrun
    ) or die 'Getopt error';
    my $dist_name = shift @ARGV || die "Need a dist name.\n";
    $dist_name =~ s/::/-/g;    # flexibly allow a dist name or a module name
    my $dist_dir = getcwd . "/$dist_name";
    install_shared_files(
        dist_name  => $dist_name,
        dist_dir   => $dist_dir,
        share_path => 'starter',
        verbose    => $verbose,
        overwrite  => $overwrite,
        dryrun     => $dryrun,
        vars       => { crudite_version => $CatalystX::Crudite::VERSION },
    );
}
1;
