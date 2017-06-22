package BlankOnDev::Repo;
use strict;
use warnings FATAL => 'all';

# Impor Module :
use BlankOnDev::Utils::file;

# Version :
our $VERSION = '0.1005';;

# Subroutine for Read Repository :
# ------------------------------------------------------------------------
sub read {
    my ($self, $dir_dev) = @_;
    my $locfile_repo = '/etc/apt/sources.list';

    # Read Sources list :

}
# Subroutine for update database repository on local system :
# ------------------------------------------------------------------------
sub update {
    # repo update :
    system('sudo apt-get update');
}
# Subroutine for install packages before build :
# ------------------------------------------------------------------------
sub pkg_build {
    my $self = shift;
    my $depend = get_pkg_support();
    my $build_pkg = $depend->{'build'};
    my $git_depkg = $depend->{'bzr'};
    my $bzr_depkg = $depend->{'git'};

    # Update Before Install :
    update();
    system("sudo apt-get install -y $build_pkg");
    system("sudo apt-get install -y $git_depkg");
    system("sudo apt-get install -y $bzr_depkg");

    return 1;
}
# Subroutine for Get dependensi :
# ------------------------------------------------------------------------
sub get_pkg_support {
    my %data = (
        'build' => 'devscripts build-essential fakeroot debhelper gnupg pbuilder dh-make dpkg-dev dpatch equivs lintian quilt dh-make-perl git-core bzr rng-tools haveged apt-rdepends',
        'bzr' => 'bzr-fastimport',
        'git' => 'bzr-git',
    );
    return \%data;
}
# Subroutine for repo address :
# ------------------------------------------------------------------------
sub address {
    my @data = (
        'repo.ridon.id'
    );
    return \@data;
}
1;