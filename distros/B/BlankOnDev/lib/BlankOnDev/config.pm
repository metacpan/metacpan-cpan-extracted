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
use BlankOnDev::Rilis;
use BlankOnDev::command;

# Version :
our $VERSION = '0.1005';

# Our vars :
our $gencfg = {};
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
# Subroutine for general config :
# ------------------------------------------------------------------------
sub _general_config {
    # Preare general conig :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_file_cfg = $data_setup->{'prefix_flcfg'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $file_cfg = 'general'.$ext_flcfg;

    # Get current Configure :
    my $curr_timezone = $gencfg->{'timezone'};
    my $curr_rilis = $gencfg->{'rilis'};
    my $curr_name = $gencfg->{'data'}->{'name'};
    my $curr_email_git = $gencfg->{'data'}->{'email-git'};
    my $curr_email_gpg = $gencfg->{'data'}->{'email-gpg'};
    my $curr_passph_gpg = $gencfg->{'data'}->{'passph-gpg'};

    # For Timezone :
    my $data_timezone = BlankOnDev->FORM('timezone', $curr_timezone);

    # Get data release :
    my $data_rilis = BlankOnDev::Rilis::data();
#    my $form_rilis = BlankOnDev->FORM('rilis');
    my $form_rilis = {
        'result' => 1,
        'data' => 'tambora',
    };
    my $boi_rilis;
    if ($form_rilis->{'result'} == 1) {
        $boi_rilis = $form_rilis->{'data'};
    } else {
        $boi_rilis = $data_rilis->{'10'}->{'name'};
    }
    my $data_name = BlankOnDev->FORM('name', $curr_name);
    my $data_email_git = BlankOnDev->FORM('email-git', $curr_email_git);
    my $data_email_gpg = BlankOnDev->FORM('email-gpg', $curr_email_gpg);
    my $data_passph_gpg = BlankOnDev->FORM('passph-gpg', '');
    $data_passph_gpg = enc_ggp_genkey($data_email_gpg, $data_passph_gpg);
    BlankOnDev::Form::github->form_config_github($data_name, $data_email_git);

    my $new_dataCfg = Hash::MultiValue->new();
    $new_dataCfg->add('name' => $data_name);
    $new_dataCfg->add('email-git' => $data_email_git);
    $new_dataCfg->add('email-gpg' => $data_email_gpg);
    $new_dataCfg->add('passph-gpg' => $data_passph_gpg);
    my $result_dataCfg = $new_dataCfg->as_hashref;

    my $new_genCfg = Hash::MultiValue->new();
    $new_genCfg->add('timezone' => $data_timezone);
    $new_genCfg->add('rilis' => $boi_rilis);
    $new_genCfg->add('data' => $result_dataCfg);
    my $result_cfg = $new_genCfg->as_hashref;

    # Save new config :
    BlankOnDev::config::save->save_to_file($file_cfg, $dir_dev, $result_cfg);

    print "\n";
}
# Subroutine for option "gpg-gen-key :
# ------------------------------------------------------------------------
sub _gpg_genkey {
    # Get data Setup :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_flcfg = $data_setup->{'prefix_flcfg'};
    my $file_cfg_ext = $data_setup->{'fileCfg_ext'};

    # Get current general config :
    my $data_gencfg = $gencfg->{'data'};
    my $curr_name = $data_gencfg->{'name'};
    my $curr_emailgit = $data_gencfg->{'email-git'};
    my $curr_emailgpg = $data_gencfg->{'email-gpg'};
    my $curr_passph = $data_gencfg->{'passph-gpg'};
    $curr_passph = dec_gpg_genkey($curr_emailgpg, $curr_passph);
    my $newData_cfg = $data_gencfg;

    # Check File Config :
    my $file_cfg = 'general'.$file_cfg_ext;
    my $loc_file = $dir_dev.$file_cfg;
    $filename_cfg = $file_cfg;
    $dirdev_cfg = $dir_dev;
    print "Filename : $file_cfg\n";
    if (-e $loc_file) {
        # GPG Generate Key :
        gpg_config($curr_name, $curr_emailgpg, $curr_passph);
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
    my $data_gencfg = $gencfg->{'data'};
    my $name_gpg = $data_gencfg->{'name'};
    my $email_gpg = $data_gencfg->{'email-gpg'};
    my $passphrase_gpg = $data_gencfg->{'passph-gpg'};

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
    my $data_gencfg = $gencfg->{'data'};
    my $name_gpg = $data_gencfg->{'name'};
    my $email_gpg = $data_gencfg->{'email-gpg'};
    my $passphrase_gpg = $data_gencfg->{'passph-gpg'};
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

    print Dumper $gencfg;
    # General Configure :
    my $data_cfg = $gencfg->{data};
    my $name_cfg = $data_cfg->{'name'};
    my $email_gpg = $data_cfg->{'email-gpg'};

    # Get Data current Configure :
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
    print "Name : $name_cfg\n";
    print "Email : $email_gpg\n\n";

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
            if ($files[$i] =~ m/general/) {
                printf("%-20s %s", "General Configure ", ": $files[$i]\n");
            }
            if ($files[$i] =~ m/tambora/) {
                printf("%-20s %s", "Tambora ", ": $files[$i]\n");
            }
            if ($files[$i] =~ m/uluwatu/) {
                printf("%-20s %s", "Uluwatu ", ": $files[$i]\n");
            }
        }
        $i++;
    }
    print "\n";
}
# Subroutine for changes rilis active :
# ------------------------------------------------------------------------
sub _rilis {
    # Prepare :
    my $curr_rilis = $gencfg->{'rilis'};

    # Form Rilis :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $file_cfg = 'general'.$ext_flcfg;

    # Action Form :
    my $form_rilis = BlankOnDev->FORM('rilis', $curr_rilis);
    my $boi_rilis;
    if ($form_rilis->{'result'} == 1) {
        $boi_rilis = $form_rilis->{'data'};
    } else {
        $boi_rilis = 'tambora';
    }
    $gencfg->{'rilis'} = $boi_rilis;

    # Save new rilis :
    BlankOnDev::config::save->save_to_file($file_cfg, $dir_dev, $gencfg);
}
# Subroutine for option "config" :
# ------------------------------------------------------------------------
sub config {
    my $confirmation;
    my $gnupg_genkey;
    my $gitname;
    my $gitemail;
    my $r_gitset = 1;
    my $home_dir = $ENV{"HOME"};

    # Get current general config :
    my $curr_timezone = '';
    my $data_gencfg = $gencfg->{'data'};
    my $curr_name = $data_gencfg->{'name'};
    my $curr_emailgit = $data_gencfg->{'email-git'};
    my $curr_emailgpg = $data_gencfg->{'email-gpg'};
    my $curr_passph = $data_gencfg->{'passph-gpg'};
    $curr_passph = dec_gpg_genkey($curr_emailgpg, $curr_passph);
    my $newData_cfg = $data_gencfg;

    # Preare general conig :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $file_cfg = 'general'.$ext_flcfg;

    # Get Command :
    # ----------------------------------------------------------------
    my $get_cmd = BlankOnDev::command::github();
    my $getGit_cmd = $get_cmd->{'git'};
    my $gitCmd_name = $getGit_cmd->{'cfg-name'};
    my $gitCmd_email = $getGit_cmd->{'cfg-email'};
    my $gitCmd_list = $getGit_cmd->{'cfg-list'};

    # For TimeZone :
    # ----------------------------------------------------------------
    $time_zone = BlankOnDev->FORM('timezone', $curr_timezone);

    # For GitHub Configure
    # ------------------------------------------------------------------------
    if (-e $home_dir."/.gitconfig") {
        # Form Confirmation :
        print "You want reconfig github [y/n]:";
        chomp($confirmation = <STDIN>);
        if ($confirmation eq 'y') {

            # Print FORM :
            print "Enter your github fullname [$curr_name] : ";
            chomp($gitname = <STDIN>);
            print "Enter your github email [$curr_emailgit] : ";
            chomp($gitemail = <STDIN>);
            if ($gitname eq '') {
                $gitname = $curr_name;
            }
            if ($gitemail eq '') {
                $gitemail = $curr_emailgit;
            }

            if ($gitname ne '' and $gitemail ne '') {
                system("$gitCmd_name \"$gitname\"");
                system("$gitCmd_email \"$gitemail\"");
                $r_gitset = 1;

                # For Data config :
                $newData_cfg = Hash::MultiValue->new(%{$data_gencfg});
                $newData_cfg->set('name' => $gitname);
                $newData_cfg->set('email-git' => $gitemail);
                $newData_cfg = $newData_cfg->as_hashref;

                # For Save New config :
                my $saveCfg = Hash::MultiValue->new(%{$gencfg});
                $saveCfg->set('data' => $newData_cfg);
                my $result_cfg = $saveCfg->as_hashref;

                # Save new config :
                BlankOnDev::config::save->save_to_file($file_cfg, $dir_dev, $result_cfg);

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

            # For Data config :
            $newData_cfg = Hash::MultiValue->new(%{$data_gencfg});
            $newData_cfg->set('name' => $gitname);
            $newData_cfg->set('email-git' => $gitemail);

            # For Save New config :
            my $saveCfg = Hash::MultiValue->new(%{$gencfg});
            $saveCfg->set('data' => $newData_cfg);
            my $result_cfg = $saveCfg->as_hashref;

            # Save new config :
            BlankOnDev::config::save->save_to_file($file_cfg, $dir_dev, $result_cfg);

        } else {
            $r_gitset = 0;
            print "git user.name or user.email not enter\n";
            exit 0;
        }
    }

    # get List git config :
    system($gitCmd_list);

    # For gpg gen key :
    print "You want GnuPG Generate key [y/n] : ";
    chomp($gnupg_genkey = <STDIN>);
    if ($gnupg_genkey eq 'y') {
        gpg_config($curr_name, $curr_emailgpg, $curr_passph);
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
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $file_cfg = 'general'.$ext_flcfg;

    # Check Rilis Selection :
    if ($gencfg->{'rilis'} eq '') {
#        my $form_rilis = BlankOnDev->FORM('rilis', '');
        my $form_rilis = {
            'result' => 1,
            'data' => 'tambora',
        };
        my $boi_rilis;
        if ($form_rilis->{'result'} == 1) {
            $boi_rilis = $form_rilis->{'data'};
        } else {
            $boi_rilis = 'tambora';
        }
        $rilisCfg = $boi_rilis;
        $gencfg->{'rilis'} = $boi_rilis;

        # Save new rilis :
        BlankOnDev::config::save->save_to_file($file_cfg, $dir_dev, $gencfg);
    } else {
        $rilisCfg = $gencfg->{'rilis'};
    }
}
# Subroutine for Encode passphrase GnuPG Generate Key :
# ------------------------------------------------------------------------
sub enc_ggp_genkey {
    my ($email, $passphrase) = @_;

    my $plan_key = BlankOnDev::enkripsi->getKey_enc($email);
    my $encoder = BlankOnDev::enkripsi->Encoder($passphrase, $plan_key);

    return $encoder;
}
# Subroutine for Decode passphrase GnuPG Generate Key :
# ------------------------------------------------------------------------
sub dec_gpg_genkey {
    my ($email, $passphrase) = @_;

    my $plan_key = BlankOnDev::enkripsi->getKey_enc($email);
    my $decoder = BlankOnDev::enkripsi->Decoder($passphrase, $plan_key);

    return $decoder;
}
# Subroutine for GNUpg configure :
# ------------------------------------------------------------------------
sub gpg_config {
    my ($name, $email, $passph) = @_;
    # Define hash :
    my %data = ();

    # Define scalar for Form :
    my $input_gpg_algo = 1;
    my $gpg_algo = '';
    my $gpg_name = '';
    my $gpg_email = '';
    my $confirm_passph = '';
    my $gpg_passph = '';
    my $gpg_passph_enc = '';

    # Data Setup :
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $file_cfg = 'general'.$ext_flcfg;

    # Get current general config :
    my $data_gencfg = $gencfg->{'data'};

    # Title Form :
    print "\n";
    print "-----" x 15 . "\n";
    print " For GnuPG Generate Key : \n";
    print "-----" x 15 . "\n";
    print "\n";

    if ($input_gpg_algo eq '1') {
        $gpg_algo = 'RSA';
    } elsif ($input_gpg_algo eq '2') {
        $gpg_algo = 'DSA_ELGAMAL'
    } else {
        $gpg_algo = 'DSA_ELGAMAL';
    }

    # Form Name GnuPG generate key :
    print "Enter Name [$name] : ";
    chomp($gpg_name = <STDIN>);
    if ($gpg_name eq '') {
        $gpg_name = $name;
    }

    # Form Email for GnuPG generate key :
    print "Enter E-mail [$email] : ";
    chomp($gpg_email = <STDIN>);
    if ($gpg_email eq '') {
        $gpg_email = $email;
    }

    # From PassPhrase for GnuPG generate key :
    print "\n";
    print "You want to enter different passphrase GnuPG ? [y or n] ";
    chomp($confirm_passph = <STDIN>);
    if ($confirm_passph eq 'y' or $confirm_passph eq 'Y') {
        print "Enter passphrase : ";
        ReadMode('noecho');
        $gpg_passph = ReadLine(0);
        $gpg_passph =~ s/\n//g;
        if ($gpg_passph eq '') {
            $gpg_passph_enc = enc_ggp_genkey($gpg_email, $passph);
            $gpg_passph = $passph;
        } else {
            $gpg_passph_enc = enc_ggp_genkey($gpg_email, $gpg_passph);
        }
        $r_gpgcfg = 1;
        ReadMode 1;
    } else {
        $gpg_passph = $passph;
        $gpg_passph_enc = enc_ggp_genkey($email, $passph);
    }

    # Initialize GnuPG Module :
    my $gpg = GnuPG->new();
    $gpg->gen_key(
#        algo => $gpg_algo,
        name => $gpg_name,
        email => $gpg_email,
        passphrase => $gpg_passph,
    );

    # Place data :
    $data{'gpg'} = {
        'name' => $gpg_name,
        'email' => $gpg_email,
        'passphrase' => $gpg_passph_enc
    };

    # Prepare Configure :
    my $pre_cfg = Hash::MultiValue->new(%{$data_gencfg});
    $pre_cfg->set('passph-gpg' => $gpg_passph_enc);
    my $newData_cfg = $pre_cfg->as_hashref;

    # Merge Configure :
    my $merge_cfg = Hash::MultiValue->new(%{$gencfg});
    $merge_cfg->set('data' => $newData_cfg);
    my $result_cfg = $merge_cfg->as_hashref;

    # Save configure :
    BlankOnDev::config::save->save_to_file($file_cfg, $dir_dev, $result_cfg);

    # Return :
    $gpgCfg = \%data;
    return \%data;
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
# Subroutine for general config :
# ------------------------------------------------------------------------
sub read_gen_cfg {
    my $data = '';
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $tmp_dir = $data_setup->{'dir_tmp'};

    # For General Configure :
    my $file_name = 'general'.$ext_flcfg;
    my $loc_file = $dir_dev.$file_name;

    # For format config :
    my $format_config = format_general_config();

    # For Dir Temp
    unless (-d $tmp_dir) {
        mkdir($tmp_dir);
    }

    # Check Dir config :
    if (-d $dir_dev) {
        # Check File general configure :
        if (-e $loc_file) {
            my $get_cfg = BlankOnDev::Utils::file->read($loc_file);
            my $data_cfg = decode_json($get_cfg);
            $data = $data_cfg;
        } else {
            BlankOnDev::Utils::file->create($file_name, $dir_dev, encode_json($format_config));
            $data = $format_config;
        }
    } else {
        mkdir($dir_dev);
        BlankOnDev::Utils::file->create($file_name, $dir_dev, encode_json($format_config));
        $data = $format_config;
    }

    $gencfg = $data;
}
# Subroutine for read config :
# ------------------------------------------------------------------------
sub read_config_bzr2git {
    my $data = '';
    my $data_setup = data_setup();
    my $dir_dev = $data_setup->{'dir_dev'};
    my $prefix_file_cfg = $data_setup->{'prefix_flcfg'};
    my $ext_flcfg = $data_setup->{'fileCfg_ext'};
    my $pkgs_dir = $data_setup->{'dir_pkg'};
    my $logs_dir = $data_setup->{'dirlogs'};

    # For Release set :
    # ----------------------------------------------------------------
    if (exists $ARGV[0] and $ARGV[0] ne 'config') {
        $gencfg->{'rilis'} = 'tambora' if $gencfg->{'rilis'} eq '';
        $rilisCfg = $gencfg->{'rilis'} if $gencfg->{'rilis'} ne '';
    } else {
        $rilisCfg = $gencfg->{'rilis'};
        $rilisCfg = $gencfg->{'rilis'} if $gencfg->{'rilis'} ne '';
    }

    # For print Rilis :
    print "\n";
    print "Rilis Active : $rilisCfg\n";

    my $file_cfg = $prefix_file_cfg . $rilisCfg. $ext_flcfg;
    my $loc_flcfg = $dir_dev.$file_cfg;
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
    my $format_config = format_bzr2git_config();

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
                $data = $data_allcfg;
            } else {
                $adddt_pkg = Hash::MultiValue->new();
                $adddt_pkg->add('dirpkg' => $dir_pkgrilis);
                $adddt_pkg->add('group' => {});
                $adddt_pkg->add('pkgs' => {});
                $result_adddtPkg = $adddt_pkg->as_hashref;

                my $set_pkgs = Hash::MultiValue->new(%{$format_config});
                $set_pkgs->set('pkg' => $result_adddtPkg);
                my $result_cfg = $set_pkgs->as_hashref;
                $data = $result_cfg
            }
        } else {
            $adddt_pkg = Hash::MultiValue->new();
            $adddt_pkg->add('dirpkg' => $dir_pkgrilis);
            $adddt_pkg->add('group' => {});
            $adddt_pkg->add('pkgs' => {});
            $result_adddtPkg = $adddt_pkg->as_hashref;
            $format_config->{'pkg'} = $result_adddtPkg;

            my $set_pkgs = Hash::MultiValue->new(%{$format_config});
            $set_pkgs->set('pkg' => $result_adddtPkg);
            my $result_cfg = $set_pkgs->as_hashref;
            $data = $result_cfg;

            BlankOnDev::Utils::file->create($file_cfg, $dir_dev, encode_json($result_cfg));
        }
    } else {
        mkdir($dir_data_boidev);
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

    $allconfig = $data;
    $r_config = $data;
    return $data;
}
# Subroutine for format general config :
# ------------------------------------------------------------------------
sub format_general_config {
    my %data = (
        'timezone' => '',
        'rilis' => '',
        'data' => {
            'name' => '',
            'email-git' => '',
            'email-gpg' => '',
            'passph-gpg' => '',
        }
    );
    return \%data;
}
# Subroutine for format data config :
# ------------------------------------------------------------------------
sub format_bzr2git_config {
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
1;