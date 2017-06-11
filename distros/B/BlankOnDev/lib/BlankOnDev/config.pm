package BlankOnDev::config;
use strict;
use warnings FATAL => 'all';

# Import Module :
use Data::Dumper;
use JSON;
use JSON::XS;
use UNIVERSAL::ref;
use Hash::MultiValue;
use Term::ReadKey;
use GnuPG qw( :algo );
use BlankOnDev::Utils::file;
use BlankOnDev::enkripsi;
use BlankOnDev::DataDev;
use BlankOnDev::config::save;
use BlankOnDev::Migration::bazaar2GitHub::tmp_cfg;

# Version :
our $VERSION = '0.1003';

# Our vars :
our $rilis = '';
our $allconfig = {};
our $filename_cfg = '';
our $dirdev_cfg = '';
our $prepareCfg = 0;
our $rilisCfg = '';
our $gpgCfg = {};
our $bzrCfg = {};
our $gitCfg = {};
our $r_bzrcfg = 0;
our $r_gitcfg = 0;
our $r_gpgcfg = 0;
our $r_config = {};
our $time_zone = 'Asia/Makassar';
our $_setup = {};

# Subroutine for option "prepare" :
# ------------------------------------------------------------------------
sub _prepare {
    # Run Config :
    config();

    # Bazaar URL Config :
    bzr_config();

    # Git URL Config :
    git_config();

    # Define scalar to save config :
    $prepareCfg = 1;
    my $data_gpg = exists $gpgCfg->{'gpg'} ? $gpgCfg->{'gpg'} : $allconfig->{'build'}->{'gpg'};
    my $pkg = $r_config->{'pkg'};
    my $data = {
        'r_config' => {
            'timezone' => $time_zone,
            'prepare' => $prepareCfg,
            'build' => {
                'rilis' => $rilisCfg,
                'gpg' => $data_gpg,
            },
            'bzr' => exists $bzrCfg->{'url'} ? $bzrCfg : $allconfig->{'bzr'},
            'git' => exists $gitCfg->{'url'} ? $gitCfg : $allconfig->{'git'},
            'pkg' => $pkg
        },
        'filename' => $filename_cfg,
        'dir_dev' => $dirdev_cfg
    };

    BlankOnDev::config::save->prepare($data);
}
# Subroutine for option "gpg-gen-key :
# ------------------------------------------------------------------------
sub _gpg_genkey {
    # Get data Setup :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_flcfg = $data_setup->{'prefix_flcfg'};
    my $file_cfg_ext = $data_setup->{'fileCfg_ext'};

    # Get All Data Config :
    my $prepare = $allconfig->{'prepare'};
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $build_pgp = $build->{'pgp'};
    my $bzr = $allconfig->{'bzr'};
    my $git = $allconfig->{'git'};
    my $pkg = $allconfig->{'pkg'};

    # Enter Rilis :
#    boi_rilis();

    # Check File Config :
    my $file_cfg = $prefix_flcfg.$rilisCfg.$file_cfg_ext;
    my $loc_file = $dir_dev.$file_cfg;
    $filename_cfg = $file_cfg;
    $dirdev_cfg = $dir_dev;
    print "Filename : $file_cfg\n";
    if (-e $loc_file) {
        # GPG Generate Key :
        my $gpg_cfg = gpg_config();

        # Define hash for new data :
        my $data = {
            'r_config' => {
                'timezone' => $time_zone,
                'prepare' => $prepare,
                'build'   => {
                    'rilis' => $build_rilis,
                    'gpg'   => $gpg_cfg->{'gpg'},
                },
                'bzr' => $bzr,
                'git' => $git,
                'pkg' => $pkg,
            },
            'filename' => $filename_cfg,
            'dir_dev' => $dirdev_cfg
        };

        BlankOnDev::config::save->gpg_genkey($data);
    }
}
# Subroutine for get list gpg auth :
# ------------------------------------------------------------------------
sub _gpg_auth {
    # Get data Setup :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_flcfg = $data_setup->{'prefix_flcfg'};
    my $file_cfg_ext = $data_setup->{'fileCfg_ext'};

    # Get All Data Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $build_gpg = $build->{'gpg'};
    my $name_gpg = $build_gpg->{'name'};
    my $email_gpg = $build_gpg->{'email'};
    my $passphrase_gpg = $build_gpg->{'passphrase'};

    # Print Result :
    print "\n";
    print "---------" x 8 . "\n";
    print " List GPG Auth : \n";
    print "---------" x 8 . "\n";

    print "Name : $name_gpg\n";
    print "Email : $email_gpg\n";
    print "passphrase : $passphrase_gpg\n\n";
}
# Subroutine for get list gpg auth with Decode passphrase:
# ------------------------------------------------------------------------
sub _gpg_auth_dec {
    # Get data Setup :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_flcfg = $data_setup->{'prefix_flcfg'};
    my $file_cfg_ext = $data_setup->{'fileCfg_ext'};

    # Get All Data Config :
    my $build = $allconfig->{'build'};
    my $build_rilis = $build->{'rilis'};
    my $build_gpg = $build->{'gpg'};
    my $name_gpg = $build_gpg->{'name'};
    my $email_gpg = $build_gpg->{'email'};
    my $passphrase_gpg = $build_gpg->{'passphrase'};
    my $thepassphrase = dec_gpg_genkey($email_gpg, $passphrase_gpg);

    # Print Result :
    print "\n";
    print "---------" x 8 . "\n";
    print " List GPG Auth : \n";
    print "---------" x 8 . "\n";

    print "Name : $name_gpg\n";
    print "Email : $email_gpg\n";
    print "passphrase : $thepassphrase\n\n";
}
# Subroutine for get list configure :
# ------------------------------------------------------------------------
sub _list_cfg {
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_flcfg = $data_setup->{'prefix_flcfg'};
    my $file_cfg_ext = $data_setup->{'fileCfg_ext'};

    # Get Data current Configure :
    my $prepare = $allconfig->{prepare};
    my $build = $allconfig->{build};
    my $build_rilis = $build->{'rilis'};
    my $build_pgp = $build->{'gpg'};
    my $pgp_name = $build_pgp->{'name'};
    my $pgp_email = $build_pgp->{'email'};
    my $bzr = $allconfig->{bzr};
    my $bzr_url = $bzr->{'url'};
    my $git = $allconfig->{git};
    my $git_url = $git->{'url'};
    my $pkg = $allconfig->{'pkg'};
    my $dirpkg = $pkg->{'dirpkg'};

    # Print Result :
    print "\n";
    print "---------" x 8 . "\n";
    print " List Configure : \n";
    print "---------" x 8 . "\n";
    print "\n";

    print "PGP Configure :\n";
    print "Name : $pgp_name\n";
    print "Email : $pgp_email\n\n";

    print "URL Configure : \n";
    print "Bzr Branch : $bzr_url\n";
    print "Git Branch : $git_url\n\n";

    print "Packages Configure : \n";
    print "Package Directory : $dirpkg\n\n";
}
# Subroutine for list file configure :
# ------------------------------------------------------------------------
sub _list_file {
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_flcfg = $data_setup->{'prefix_flcfg'};
    my $file_cfg_ext = $data_setup->{'fileCfg_ext'};

    opendir(my $dir, $dir_dev) or die "Cannot open directory: $!";
    my @files = grep { $_ ne '.' && $_ ne '..' && $_ ne 'packages' } readdir $dir;
    closedir $dir;

    print "\n";
    print "---------" x 8 . "\n";
    print " List File Configure : \n";
    print "---------" x 8 . "\n";
    print "\n";

    print "Directory Location : $dir_dev\n";

    my $i = 0;
    while ($i < scalar @files) {
        if ($files[$i] =~ m/\.config$/) {
            if ($files[$i] =~ m/tambora/) {
                print "Tambora : $files[$i]\n";
            }
            if ($files[$i] =~ m/uluwatu/) {
                print "Uluwatu : $files[$i]\n";
            }
        }
        $i++;
    }
    print "\n";
}
# Subroutine for option "config" :
# ------------------------------------------------------------------------
sub config {
    my $timezone;
    my $confirmation;
    my $cache_auth;
    my $gnupg_genkey;
    my $gitname;
    my $gitemail;
    my $r_gitset = 1;
    my $read_fileCfg;
    my $home_dir = $ENV{"HOME"};


    # Get Command :
    # ----------------------------------------------------------------
    my $get_cmd = cmd_list();
    my $getGit_cmd = $get_cmd->{'git'};
    my $gitCmd_name = $getGit_cmd->{'cfg-name'};
    my $gitCmd_email = $getGit_cmd->{'cfg-email'};
    my $gitCmd_authCache = $getGit_cmd->{'cfg-credential-cache'};
    my $gitCmd_authCache_clear = $getGit_cmd->{'cfg-creden-cache-clear'};
    my $gitCmd_list = $getGit_cmd->{'cfg-list'};
    my $gnupg_cmd = $get_cmd->{'gpg'};

    # For TimeZone :
    # ----------------------------------------------------------------
    print "Example name TimeZone \"Asia/Makassar\" \n";
    print "Set your timezone name : ";
    chomp($timezone = <STDIN>);
    if ($timezone ne '') {
        $time_zone = $timezone;
    }

    # For GitHub Configure
    # ------------------------------------------------------------------------
    if (-e $home_dir."/.gitconfig") {
        # Form Confirmation :
        print "You want reconfig github [y/n]:";
        chomp($confirmation = <STDIN>);
        if ($confirmation eq 'y') {

            $read_fileCfg = BlankOnDev::Utils::file->read($home_dir."/.gitconfig");
            my $name_git;
            my $email_git;
            if ($read_fileCfg =~ m/(name)\s(\=)\s(.*)/) {
                $name_git = $3;
            }
            if ($read_fileCfg =~ m/(email)\s(\=)\s(.*)/) {
                $email_git = $3;
            }

            # Print FORM :
            print "Enter your github fullname [$name_git] : ";
            chomp($gitname = <STDIN>);
            print "Enter your github email [$email_git] : ";
            chomp($gitemail = <STDIN>);
            if ($gitname eq '') {
                $gitname = $name_git;
            }
            if ($gitemail eq '') {
                $gitemail = $email_git;
            }

            if ($gitname ne '' and $gitemail ne '') {
                system("$gitCmd_name \"$gitname\"");
                system("$gitCmd_email \"$gitemail\"");
                $r_gitset = 1;
            } else {
                $r_gitset = 0;
                print "git user.name or user.email not enter\n";
                exit 0;
            }
        }
    } else {
        # GitHub Local Config :
        print "Enter your github fullname : ";
        chomp($gitname = <STDIN>);
        print "Enter your github email : ";
        chomp($gitemail = <STDIN>);
        if ($gitname ne '' and $gitemail ne '') {
            system("$gitCmd_name \"$gitname\"");
            system("$gitCmd_email \"$gitemail\"");
            $r_gitset = 1;
        } else {
            $r_gitset = 0;
            print "git user.name or user.email not enter\n";
            exit 0;
        }
    }

    $read_fileCfg = BlankOnDev::Utils::file->read($home_dir."/.gitconfig");
    my $auth_cache_git;
    if ($read_fileCfg =~ m/(helper)\s(\=)\s(.*)/) {
        # For cache user and password git push :
        print "Cache user and password is activated\n";
        print "You want to clear [y/n]: ";
        chomp($cache_auth = <STDIN>);
        if ($cache_auth eq 'y') {
#            $read_fileCfg =~ s/^\[credential.*//g;
#            $read_fileCfg =~ s/(^\s+helper.*)+//g;
#            chmod 0666, $home_dir.'/.gitcontif';
#            BlankOnDev::Utils::file->create('/.gitconfig', $home_dir, $read_fileCfg);
#            chmod 0644, $home_dir.'/.gitcontif';
            system($gitCmd_authCache_clear);
        }
    } else {
        # For cache user and password git push :
        print "You want cache user and password git [y/n]: ";
        chomp($cache_auth = <STDIN>);
        if ($cache_auth eq 'y' or $cache_auth eq '') {
            system("$gitCmd_authCache --timeout=86400");
        }
    }

    # get List git config :
    system($gitCmd_list);

    # For gpg gen key :
    print "You want GnuPG Generate key [y/n] : ";
    chomp($gnupg_genkey = <STDIN>);
    if ($gnupg_genkey eq 'y') {
        gpg_config();
    }
#    print Dumper $allconfig;
}
# Subroutine for blankon Config :
# ------------------------------------------------------------------------
sub data_setup {
    my $data_dev = BlankOnDev::DataDev::data_dev();

    return $data_dev;
}
# Subroutine for Set name BlankOn Rilis :
# ------------------------------------------------------------------------
sub boi_rilis {
    my $form_rilis = BlankOnDev::form_boi_rilis();
    my $boi_rilis;
    if ($form_rilis->{'result'} == 1) {
        $boi_rilis = $form_rilis->{'data'};
    } else {
        $boi_rilis = 'tambora';
    }
    $rilisCfg = $boi_rilis;
}
# Subroutine for Encode passphrase GnuPG Generate Key :
# ------------------------------------------------------------------------
sub enc_ggp_genkey {
    my ($email, $passphrase) = @_;
#    print "Input Email : $email\n";
#    print "Input Passphrase : $passphrase\n";

    my $plan_key = BlankOnDev::enkripsi->getKey_enc($email);
    my $encoder = BlankOnDev::enkripsi->Encoder($passphrase, $plan_key);

    return $encoder;
}
# Subroutine for Decode passphrase GnuPG Generate Key :
# ------------------------------------------------------------------------
sub dec_gpg_genkey {
    my ($email, $passphrase) = @_;
#    print "Input Email : $email\n";
#    print "Input Passphrase : $passphrase\n";

    my $plan_key = BlankOnDev::enkripsi->getKey_enc($email);
    my $decoder = BlankOnDev::enkripsi->Decoder($passphrase, $plan_key);
    $decoder =~ s/\|+//g;

    return $decoder;
}
# Subroutine for GNUpg configure :
# ------------------------------------------------------------------------
sub gpg_config {
    # Define hash :
    my %data = ();

    # Define scalar for Form :
    my $input_gpg_algo = 1;
    my $gpg_algo = '';
    my $gpg_name = '';
    my $gpg_email = '';
    my $gpg_passph = '';
    my $gpg_passph_enc = '';

    # Define scalar for current data :
    my $curr_gpg_algo = '';
    my $curr_gpg_name = '';
    my $curr_gpg_email = '';
    my $curr_gpg_passph = '';
    my $curr_gpg_passph_dec = '';
    my $currdt_gpg_name = '';
    my $currdt_gpg_email = '';
    my $currdt_gpg_passph = '';
    my $currdt_gpg_passph_dec = '';

    # Read Current config ;
    my $curren_cfg = $allconfig;
    my $build_cfg = $allconfig->{'build'};
    my $build_gpg = $build_cfg->{'gpg'};
    if (exists $build_gpg->{'name'}) {
        $curr_gpg_name = '['.$build_gpg->{'name'}.']' if $build_gpg->{'name'} ne '';
        $curr_gpg_email = '['.$build_gpg->{'email'}.']' if $build_gpg->{'email'} ne '';
        $curr_gpg_passph = '['.$build_gpg->{'passphrase'}.']' if $build_gpg->{'passphrase'} ne '';
        $curr_gpg_passph_dec = $build_gpg->{'passphrase'} if $build_gpg->{'passphrase'} ne '';
        $currdt_gpg_name = $build_gpg->{'name'} if $build_gpg->{'name'} ne '';
        $currdt_gpg_email = $build_gpg->{'email'} if $build_gpg->{'email'} ne '';
        $currdt_gpg_passph = $build_gpg->{'passphrase'} if $build_gpg->{'passphrase'} ne '';
        $currdt_gpg_passph_dec = $build_gpg->{'passphrase'} if $build_gpg->{'passphrase'} ne '';
    }

    # Title Form :
    print "\n";
    print "-----" x 15 . "\n";
    print " For GnuPG Generate Key : \n";
    print "-----" x 15 . "\n";
    print "\n";

    # Form Algorithm GnuPG :
#    print "Choose Algorithm GnuPG : \n";
#    print "1. RSA,\n";
#    print "2. DSA,\n";
#    if ($curr_gpg_algo ne '') {
#        print "You have current GnuPG config on system = $curr_gpg_algo\n";
#    }
#    chomp($input_gpg_algo = <STDIN>);
    if ($input_gpg_algo eq '1') {
        $gpg_algo = 'RSA';
    } elsif ($input_gpg_algo eq '2') {
        $gpg_algo = 'DSA_ELGAMAL'
    } else {
        $gpg_algo = 'DSA_ELGAMAL';
    }

    # Form Name GnuPG generate key :
    print "Enter Name $curr_gpg_name : ";
    chomp($gpg_name = <STDIN>);
    if ($gpg_name eq '') {
        $gpg_name = $currdt_gpg_name;
    }

    # Form Email for GnuPG generate key :
    print "Enter E-mail $curr_gpg_email : ";
    chomp($gpg_email = <STDIN>);
    if ($gpg_email eq '') {
        $gpg_email = $currdt_gpg_email;
    }

    # From PassPhrase for GnuPG generate key :
    print "Enter passphrase : ";
    ReadMode('noecho');
    $gpg_passph = ReadLine(0);
    if ($gpg_passph eq '') {
        if ($curr_gpg_passph eq '') {
            $curr_gpg_passph = 'admin123';
            print "Please enter your passphrase GnuPG !!!\n";
            exit 0;
        }
        $gpg_passph_enc = enc_ggp_genkey($gpg_email, $currdt_gpg_passph);
        $gpg_passph = $currdt_gpg_passph;
    } else {
        $gpg_passph_enc = enc_ggp_genkey($gpg_email, $gpg_passph);
    }
    $r_gpgcfg = 1;
    ReadMode 1;

    # Initialize GnuPG Module :
    my $gpg = GnuPG->new();
    $gpg->gen_key(
#        algo => $gpg_algo,
        name => $gpg_name,
        email => $gpg_email,
        passphrase => $gpg_passph_enc,
    );

    # Place data :
    $data{'gpg'} = {
        'alg' => $gpg_algo,
        'name' => $gpg_name,
        'email' => $gpg_email,
        'passphrase' => $gpg_passph_enc
    };

    # Return :
    $gpgCfg = \%data;
    return \%data;

    # Config Password :
    #    print "Enter your full name : ";
    #    chomp($git_username = <STDIN>);
    #    print "Enter your email : ";
    #    chomp($email = <STDIN>);
    #    print "Enter your passphrase : ";
    #    ReadMode('noecho');
    #    $git_password = ReadLine(0);
}
# Subroutine for Bazaar Configure :
# ------------------------------------------------------------------------
sub bzr_config {
    # Define scalar :
    my $bzr_url = '';

    # Form :
    my $data_bzrcfg = $allconfig->{'bzr'};
#    print "URL BZR : $data_bzrcfg\n";
    my $url_bzr = $data_bzrcfg->{'url'} if exists $data_bzrcfg->{'url'};
    if ($url_bzr eq '') {
        print "Enter bzr url : ";
        chomp($bzr_url = <STDIN>);
    } else {
        print "Enter bzr url [$url_bzr] : ";
        chomp($bzr_url = <STDIN>);
    }

    if ($bzr_url eq '') {
        $bzr_url = {
            'url' => $allconfig->{'bzr'}->{'url'}
        };
        $r_bzrcfg = 0;
    } else {
        $bzr_url =~ s/\/$//g;
        $bzrCfg = {
            'url' => $bzr_url
        };
        $r_bzrcfg = 1;
    }
}
# Subroutine for Git Configure :
# ------------------------------------------------------------------------
sub git_config {
    # Define scalar :
    my $git_url = '';

    # Form :
    my $data_gitcfg = $allconfig->{'git'};
    my $url_git = $data_gitcfg->{'url'} if exists $data_gitcfg->{'url'};
    if ($url_git eq '') {
        print "Enter git url : ";
        chomp($git_url = <STDIN>);
    } else {
        print "Enter git url [$url_git] : ";
        chomp($git_url = <STDIN>);
    }

    if ($git_url eq '') {
        $gitCfg = {
            'url' => $allconfig->{'git'}->{'url'},
        };
        $r_gitcfg = 0;
    } else {
        $git_url =~ s/\/$//g;
        $gitCfg = {
            'url' => $git_url,
        };
        $r_gitcfg = 1;
    }
}
# Subroutine for read config :
# ------------------------------------------------------------------------
sub read_config {
    my $data = '';
    my %data_pkg = ();
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_file_cfg = $data_setup->{'prefix_flcfg'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $home_dir = $ENV{"HOME"};
    my $pkgs_dir = $data_setup->{'dir_pkg'};
    my $logs_dir = $data_setup->{'dirlogs'};

    # For Release set :
    # ----------------------------------------------------------------
    boi_rilis();
    my $file_cfg = $prefix_file_cfg . $rilisCfg. $ext_flcfg;
    my $loc_flcfg = $dir_dev.$file_cfg;
    my $locdir_pkg = $dir_dev.$pkgs_dir;
    $filename_cfg = $file_cfg;
    $dirdev_cfg = $dir_dev;
    my $adddt_pkg;
    my $result_adddtPkg;

    # Define scalar :
    my $timezone;
    my $prepare;
    my $build;
    my $build_rilis;
    my $build_gpg;
    my $bzr;
    my $git;
    my $pkg;

    # For Dir Dev :
    my $dir_data_boidev = $dir_dev;
    my $dir_pkg = $dir_dev.$pkgs_dir;
    my $dir_pkgrilis = $dir_pkg.'/'.$rilisCfg;
    my $log_dir_rilis = $logs_dir.$rilisCfg;

    # Get format data config :
    my $format_config = format_data();

    # Check File Config :
    if (-d $dir_data_boidev) {
        if (-e $loc_flcfg) {
            my $get_allcfg = BlankOnDev::Utils::file->read($loc_flcfg);
            my $data_allcfg = decode_json($get_allcfg);
            my $size_allcfg = scalar keys(%{$data_allcfg});
            if ($size_allcfg > 0) {
                $timezone = $data_allcfg->{'timezone'} if exists $data_allcfg->{'timezone'};
                $prepare = $data_allcfg->{'prepare'} if exists $data_allcfg->{'prepare'};
                $build = $data_allcfg->{'build'} if exists $data_allcfg->{'build'};
                $build_rilis = $build->{'rilis'} if exists $build->{'rilis'};
                $build_gpg = $build->{'gpg'} if exists $build->{'gpg'};
                $bzr = $data_allcfg->{'bzr'} if exists $data_allcfg->{'bzr'};
                $git = $data_allcfg->{'git'} if exists $data_allcfg->{'git'};
                $pkg = $data_allcfg->{'pkg'} if exists $data_allcfg->{'pkg'};
                my $data_format = $format_config;
#                $data_format->{prepare} = 0;
#                $data_format->{'build'} = $build;
#                $data_format->{'build'}->{'rilis'} = $rilisCfg;
#                $data_format->{'build'}->{'gpg'} = $build_gpg;
#                $data_format->{'bzr'} = $bzr;
#                $data_format->{'git'} = $git;
#                $data_format->{'pkg'} = $pkg;
                $data = $data_allcfg;
            } else {
                $adddt_pkg = Hash::MultiValue->new();
                $adddt_pkg->add('dirpkg' => $dir_pkgrilis);
                $adddt_pkg->add('group' => {});
                $adddt_pkg->add('pkgs' => {});
                $result_adddtPkg = $adddt_pkg->as_hashref;
                $format_config->{'pkg'} = $result_adddtPkg;
                $data = $format_config;
            }
        } else {
            BlankOnDev::Utils::file->create($file_cfg, $dir_dev, encode_json($format_config));
#            $format_config->{'pkg'}->{'dirpkg'} = $dir_pkgrilis;
            $adddt_pkg = Hash::MultiValue->new();
            $adddt_pkg->add('dirpkg' => $dir_pkgrilis);
            $adddt_pkg->add('group' => {});
            $adddt_pkg->add('pkgs' => {});
            $result_adddtPkg = $adddt_pkg->as_hashref;
            $format_config->{'pkg'} = $result_adddtPkg;
            $data = $format_config;
        }
    } else {
        mkdir($dir_data_boidev);
#        $format_config->{'pkg'}->{'dirpkg'} = $dir_pkgrilis;
        $adddt_pkg = Hash::MultiValue->new();
        $adddt_pkg->add('dirpkg' => $dir_pkgrilis);
        $adddt_pkg->add('group' => {});
        $adddt_pkg->add('pkgs' => {});
        $result_adddtPkg = $adddt_pkg->as_hashref;
        $format_config->{'pkg'} = $result_adddtPkg;
        $data = $format_config;
    }

    # For Directory data Packages :
    unless (-d $dir_pkg) {
        mkdir($dir_pkg);

        # For Directory data packages rilis :
        unless (-d $dir_pkgrilis) {
            mkdir($dir_pkgrilis);
        }
    } else {

        # For Directory data packages rilis :
        unless (-d $dir_pkgrilis) {
            mkdir($dir_pkgrilis);
        }
    }

    # For Logs :
    unless (-d $logs_dir) {
        mkdir($logs_dir);
        unless (-d $log_dir_rilis) {
            mkdir($log_dir_rilis);
        }
    } else {
        unless (-d $log_dir_rilis) {
            mkdir($log_dir_rilis);
        }
    }

#    BlankOnDev::Migration::bazaar2GitHub::tmp_cfg->first_addpkg_fileTmp($data_setup, $rilisCfg);

#    print Dumper $data;

    $allconfig = $data;
    $r_config = $data;
    return $data;
}
# Subroutine for format data config :
# ------------------------------------------------------------------------
sub format_data {
    my %data = (
        'timezone' => 'Asia/Makassar',
        'prepare' => 0,
        'build' => {
            'rilis' => '',
            'gpg' => {
                'alg' => '',
                'name' => '',
                'email' => '',
                'passphrase' => ''
            },
        },
        'bzr' => {
            'url' => '',
        },
        'git' => {
            'url' => ''
        },
        'pkg' => {
            'dirpkg' => '',
        },
    );
    return \%data;
}
# Subroutine for list command :
# ------------------------------------------------------------------------
sub cmd_list {
    my %data = ();

    # Git Command :
    $data{'git'} = {
        'cfg-name' => 'git config --global user.name',
        'cfg-email' => 'git config --global user.email',
        'cfg-credential-cache' => 'git config --global credential.helper cache',
        'cfg-creden-cache-clear' => 'git config --global --unset credential.helper',
        'cfg-list' => 'git config --list',
    };
    # GPG Command :
    $data{'gpg'} = {
        'gen-key' => 'gpg --gen-key'
    };
    return \%data;
}

1;