package BlankOnDev;
use strict;
use warnings;

# Import :
use BlankOnDev::DataDev;
use BlankOnDev::Version;

# Version :
our $VERSION = '0.1003';

# Subroutine for check Home Dir :
# ------------------------------------------------------------------------
sub check_homedir {
    my $homedir = $ENV{"HOME"};
    if ($homedir =~ m/root/) {
        return 0;
    } else {
        return 1;
    }
}

# Subroutine for check directory BlankOnDev :
# ------------------------------------------------------------------------
sub check_dir_boidev {
    # For Data Developer :
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $home_dir = $data_dev->{'home_dir'};
    my $dir_dev = $data_dev->{'dir_dev'};
    my $prefix_flcfg = $data_dev->{'prefix_flcfg'};
    my $file_cfg_ext = $data_dev->{'fileCfg_ext'};
    my $dir_pkgs = $data_dev->{'dir_pkg'};

    my $result = 0;
    unless (-d $dir_dev) {
        $result = 0;
    } else {
        my $loc_dirpkg = $dir_dev.$dir_pkgs;
        unless (-d $loc_dirpkg) {
            $result = 0;
        } else {
            $result = 1;
        }
    }

    return $result;
}

# Subroutine for list blankon release :
# ------------------------------------------------------------------------
sub list_rilis {
    my %data = ();
    $data{'tambora'} = '10';
    $data{'uluwatu'} = '11';
    return \%data;
}

# Subroutine for form blankon release :
# ------------------------------------------------------------------------
sub form_boi_rilis {
    my $num_data_rilis;
    my %data = ();
    my $boi_rilis = 'tambora';
    my $status = 0;
    print "\n";
    print "Choose rilis \n";
    print "---" x 15 . "\n";
#    my $daftar_rilis = list_rilis();
#    my $num = 0;
#    my %choose_rilis = ();
#    while (my ($key, $value) = each %{$daftar_rilis}) {
#        my $num_rilis = $num + 1;
#        $choose_rilis{$num_rilis} = $key;
#        print "$num_rilis. $key\n";
#        $num++;
#    }
    print "1. Tambora\n";
    print "2. Uluwatu\n";
    print "Enter number choice : ";
    chomp($num_data_rilis = <STDIN>);
    if ($num_data_rilis ne '' and $num_data_rilis eq '1') {
        $boi_rilis = 'tambora';
        $status = 1;
    } elsif ($num_data_rilis eq 2) {
        $boi_rilis = 'uluwatu';
        $status = 1;
    }
    else {
        $boi_rilis = 'tambora';
        $status = 1;
    }

    $data{'result'} = $status;
    $data{'data'} = $boi_rilis;

    return \%data;
}

# Subroutine for option help.
# This subroutine using in option "help" on script file "boidev".
# ------------------------------------------------------------------------
sub usage {
    print "\n";
    print "---------" x 8 . "\n";
    print " For Help Command : \n";
    print "---------" x 8 . "\n";
    print "\n";

    print "USAGE :\n";
    print "---------" x 11 . "\n";
    print "   boidev <OPTIONS1>\n";
    print " -- or --\n";
    print "   boidev <OPTIONS1> <OPTIONS2>\n";
    print " -- or --\n";
    print "   boidev <OPTIONS1> <OPTION2> <OPTIONS3>\n";
    print " -- or --\n";
    print "   boidev <OPTIONS1> <OPTION2> <INPUT>\n";
    print "\n";

    print "For USAGE : boidev <OPTIONS1>\n";
    printf("  %-20s %s\n", "prepare", "Mempersiapkan sistem sebelum melakukan aktiftas pemaket");
    printf("  %-20s %s\n", "gpg-genkey", "Untuk generate key GnuPG");
    printf("  %-20s %s\n", "gpg-auth", "Untuk melihat name, email dan passphrase generate key");
    printf("  %-20s %s\n", "gpg-auth-dec", "Untuk melihat name, email dan passphrase yang tidak diencode");
    printf("  %-20s %s\n", "install-pkg", "Untuk menginstall beberapa paket sebelum melakukan aktiftas pemaket");
    printf("  %-20s %s\n", "bzr2git", "Untuk mengambil data Repository dari Bazaar Server dan dimigrasi ke GitHub");
    printf("  %-20s %s\n", "list-cfg", "Untuk melihat konfigurasi yang sudah dilakukan");
    printf("  %-20s %s\n", "list-file", "Untuk melihat file configurasi konfigurasi yang sudah ada");
    print "\n";

    print "For USAGE : boidev bzr2git <OPTIONS2> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git();
    print "\n";

    print "For USAGE : boidev bzr2git addpkg <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_addpkg();
    print "\n";

    print "For USAGE : boidev bzr2git addpkg-file <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_addpkgfile();
    print "\n";

    print "For USAGE : boidev bzr2git list-pkg <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_listpkg();
    print "\n";

    print "For USAGE : boidev bzr2git rename-pkg-group <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_renamepkg_group();
    print "\n";

    print "For USAGE : boidev bzr2git remove-pkg-group <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_removepkg_group();
    print "\n";

    print "For USAGE : boidev bzr2git remove-pkg <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_removepkg();
    print "\n";

    print "For USAGE : boidev bzr2git search-pkg <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_searchpkg();
    print "\n";

    print "For USAGE : boidev bzr2git branch <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_branch();
    print "\n";

    print "For USAGE : boidev bzr2git bzr-cvr <INPUT> \n";
    print "---------" x 11 . "\n";
    usage_bzr2git_bzrconvert();
    print "\n";
    exit 0;
}
# Subroutine for option help on option bzr2git :
# ------------------------------------------------------------------------
sub usage_bzr2git {
    printf("  %-20s %s\n", "addpkg-group", "Untuk Menambahkan nama Group Paket yang akan dimigrasi");
    printf("  %-20s %s\n", "addpkg", "Untuk Menambahkan Paket yang akan dimigrasi");
    printf("  %-20s %s\n", "addpkg-file", "Untuk Menambahkan Paket yang akan dimigrasi dari file list paket .boikg");
    printf("  %-20s %s\n", "addpkg-in-file", "Untuk Menambahkan nama Paket yang akan dimigrasi ke file list paket .boikg");
    printf("  %-20s %s\n", "rename-pkg-group", "Untuk mengubah nama group paket beserta nama group di dalam paket terkait");
    printf("  %-20s %s\n", "remove-pkg-group", "Untuk menghapus nama Paket yang sudah ada dalam system aplikasi");
    printf("  %-20s %s\n", "remove-pkg", "Untuk menghapus nama Paket yang sudah ada dalam system aplikasi");
    printf("  %-20s %s\n", "list-pkg", "Untuk melihat daftar paket yang sudah terdaftar dalam system aplikasi.");
    printf("  %-20s %s\n", "list-pkg-group", "Untuk melihat daftar group paket yang sudah terdaftar dalam system aplikasi.");
    printf("  %-20s %s\n", "search-pkg", "untuk mencari data paket yang terdaftar pada system aplikasi");
    printf("  %-20s %s\n", "branch", "Untuk branch dari repo bazaar berdasarkan list paket yang tersimpan pada system aplikasi");
    printf("  %-20s %s\n", "bzr-cvr", "Untuk convert repository bazaar ke github repository");
    printf("  %-20s %s\n", "git-push", "Untuk push ke git berdasarkan semua list paket yang tersimpan pada system aplikasi atau hanya 1 paket saja.");
    printf("  %-20s %s\n", "git-push-new", "Untuk push ke git tanpa convert dari Bazaar");
    printf("  %-20s %s\n", "re-branch", "Untuk branch paket yang ada pada bazaar server");
    printf("  %-20s %s\n", "re-gitpush", "Untuk Deploy ulang ke github");
#    printf("  %-20s %s\n", "", "");
#    printf("  %-20s %s\n", "", "");
}
sub usage_bzr2git_addpkg_group {
    printf("  %-20s %s\n", "[input_name]", "Berisi nama group yang akan ditambahkan, dan inputan tidak boleh menggunakan karakter [spasi]");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git addpkg-group <INPUT>\".");
}
sub usage_bzr2git_addpkg {
    printf("  %-20s %s\n", "[input_name]", "Berisi nama paket yang akan ditambkan, dan input tidak boleh menggunakan karakter [spasi]");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git addpkg\".");
}
sub usage_bzr2git_addpkgfile {
    my $data_dev = BlankOnDev::DataDev::data_dev();
    my $filepkg_ext = $data_dev->{'filePkg_ext'};
    printf("  %-20s %s\n", "[input_loc_file]", "Berisi lokasi file daftar paket yang akan ditambahkan. Ex: /your/path/file_name.$filepkg_ext");
    printf("  %-20s %s\n", "", "Extension file must \"$filepkg_ext\".");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git addpkg-file\".");
}
sub usage_bzr2git_listpkg {
    printf("  %-20s %s\n", "[group_name]", "Nama group paket yang tersimpan dalam system.");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git list-pkg\".");
}
sub usage_bzr2git_renamepkg_group {
    printf("  %-20s %s\n", "[name_of_group_packages]", "Nama paket group yang akan diubah");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git rename-pkg-group\".");
}
sub usage_bzr2git_removepkg_group {
    printf("  %-20s %s\n", "[name_of_group_packages]", "Nama group paket yang akan dihapus, kemudian di rename");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git remove-pkg-group\".");
}
sub usage_bzr2git_removepkg {
    printf("  %-20s %s\n", "[name_packages]", "Nama paket yang akan dihapus dari system aplikasi.");
    printf("  %-20s %s\n", "[name_of_group_packages]", "Menghapus paket dari system aplikasi berdasarkan nama group paket");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git remove-pkg\".");
}
sub usage_bzr2git_searchpkg {
    printf("  %-20s %s\n", "[name_of_packages]", "Nama paket yang akan dicari.");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git search-pkg\".");
}
sub usage_bzr2git_branch {
    printf("  %-20s %s\n", "[name_of_packages]", "Nama paket yang akan didownload melalui \"bzr branch\".");
    printf("  %-20s %s\n", "[name_of_group_packages]", "nama group paket untuk mengdownload semua paket yang terkait dengan group melalui \"bzr branch\".");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git search-pkg\".");
}
sub usage_bzr2git_bzrconvert {
    printf("  %-20s %s\n", "[name_of_packages]", "Nama paket yang akan dikonversi ke repo github");
    printf("  %-20s %s\n", "[name_of_group_packages]", "Nama group paket untuk meng-konversi semua paket yang terkait dengan group");
    printf("  %-20s %s\n", "", "ke format repositori github");
    printf("  %-20s %s\n", "help", "Berisi help penggunaan command \"boidev bzr2git search-pkg\".");
}

# For Help in list pkg :
# ------------------------------------------------------------------------
sub help_list_pkg {
#    printf("   %-60s %s\n", "testing", "bzrBranch = 0 --> Another Error, See Logs");
    printf("   %-45s %s\n", "bzrBranch = 0 --> Another Error, See Logs", "gitPush = 0 --> Another Error, See Logs");
    printf("   %-45s %s\n", "bzrBranch = 1 --> Success Branch", "gitPush = 1 --> Success Git Push");
    printf("   %-45s %s\n", "bzrBranch = 2 --> Already Branch", "gitPush = 2 --> ...");
    printf("   %-45s %s\n", "bzrBranch = 3 --> Error URL Branch", "gitPush = 3 --> URL Repo git is not valid or URL Repo git is empty");
    print "\n";
    printf("   %s\n", "bzrConvertGit = 0 --> Another Error, See Logs");
    printf("   %s\n", "bzrConvertGit = 1 --> Success Convert to Git");
    printf("   %s\n", "bzrConvertGit = 2 --> Not bazaar repository");
}
# Suroutine for command "boidev -v" or "boidev --version" :
# ------------------------------------------------------------------------
sub version_apps {
    print "\n";
    print "This is BlankOnDev Application, version $BlankOnDev::Version::appVer, subversion $BlankOnDev::Version::SubVer\n\n";
    print "Copyright 1438 H, Achmad Yusri Afandi.\n\n";

    print "The purpose of application for Packages Maintainer on BlankOn GNU/Linux Developer.\n";
    print "This program covered several tools for Developer, include : \n";
    print "- Migration Bazaar repositories format to GitHub Repositories format\n";
    print "- Management repositories in your system. [Plan Feature] \n";
    print "- Build Debian Packages from source. [Plan Feature] \n";

    print "\n";
}
1;
__END__
