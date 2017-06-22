package BlankOnDev::Form;
use strict;
use warnings FATAL => 'all';

# Import :
use Term::ReadKey;
use BlankOnDev::Rilis;
use BlankOnDev::DateTime;

# Version :
our $VERSION = '0.1005';

# Subroutine for form time zone :
# ------------------------------------------------------------------------
sub form_timezone {
    my ($self, $time_zone) = @_;
    # Prepare From TimeZone :
    my $form_timezone;
    my $timezone = $time_zone ? $time_zone : 'Asia/Makassar';
    my $data_timezone = '';
    my $id_timezone = BlankOnDev::DateTime::id_timezone();
    my $tz_long_short = $id_timezone->{'long-short'};
    my $tz_num_short = $id_timezone->{'num-short'};
    my $tz_num_long = $id_timezone->{'num-long'};
    if (exists $tz_long_short->{$timezone}) {
        $timezone = uc $tz_long_short->{$timezone}
    } else {
        $timezone = $timezone;
    }

    print "\n";
    print "List TimeZone : \n";
    print "1. WIB \n";
    print "2. WITA \n";
    print "3. WIT \n";
    if ($timezone ne '') {
        print "Enter your time zone [$timezone] : ";
    } else {
        print "Enter your time zone : ";
    }
    chomp($form_timezone = <STDIN>);
    if ($form_timezone ne '') {
        if ($form_timezone =~ m/^[0-9]$/) {
            $data_timezone = $tz_num_long->{$form_timezone};
        } else {
            $data_timezone = $tz_num_long->{'1'};
        }
    } else {
        $data_timezone = 'Asia/Makassar';
    }
    print "\n";
    print "Active TimeZone : $data_timezone\n";
    return $data_timezone;
}
# Subroutine for form blankon release :
# ------------------------------------------------------------------------
sub form_boi_rilis {
    my ($self) = @_;
    # Prepare Form Rilis :
    my $num_data_rilis;
    my %data = ();
    my $data_rilis = BlankOnDev::Rilis::data();
    my $latest_rilis = $data_rilis->{'latest'}->{'name'};
    my $boi_rilis = $latest_rilis;
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
    print "1. $data_rilis->{'10'}->{'name'}\n";
    print "2. $data_rilis->{'11'}->{'name'}\n";
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

    print "\n";
    print "Rilis Activated : $boi_rilis\n\n";

    $data{'result'} = $status;
    $data{'data'} = $boi_rilis;

    return \%data;
}
# Subroutine for form Name : :
# ------------------------------------------------------------------------
sub form_name {
    my ($self, $name) = @_;
    # Prepare Form :
    my $name_form;
    my $data_name;
    my %data = ();

    # Form_name ;
    print "\n";
    if ($name ne '') {
        print "Enter your name [$name] : ";
    } else {
        print "Enter your name : ";
    }
    chomp($name_form = <STDIN>);
    if ($name_form ne '') {
        $data_name = $name_form;
    } else {
        if ($name eq '') {
            print "your name is empty !!! \n";
            form_name();
        } else {
            $data_name = $name;
        }
    }

    return $data_name;
}
# Subroutine for Email Github :
# ------------------------------------------------------------------------
sub form_email_git {
    my ($self, $email) = @_;
    # Prepare Form :
    my $emailGit_form;
    my $data_emailGit;

    # Form Email Git :
    print "\n";
    if ($email ne '') {
        print "Enter your email address Github Account [$email] : ";
    } else {
        print "Enter your email address Github Account : ";
    }
    chomp($emailGit_form = <STDIN>);
    if ($emailGit_form ne '') {
        if ($emailGit_form =~ m/(.*)\@(.*).(.*)/) {
            $data_emailGit = $emailGit_form;
        } else {
            print "Please enter valid email address !!! \n";
            form_email_git();
        }
    } else {
        if ($email eq '') {
            print "your E-mail Github Account is empty !!! \n";
            form_email_git();
        } else {
            $data_emailGit = $email;
        }
    }
    return $data_emailGit;
}
# Subroutine for Email GnuPG :
# ------------------------------------------------------------------------
sub form_email_gpg {
    my ($self, $email) = @_;
    # Prepare Form :
    my $emailGnuPG_form;
    my $data_emailGnuPG;

    # Form Email GnuPG :
    print "\n";
    if ($email ne '') {
        print "Enter your email address for GnuPG Generate Key [$email] : ";
    } else {
        print "Enter your email address for GnuPG Generate Key : ";
    }
    chomp($emailGnuPG_form = <STDIN>);
    if ($emailGnuPG_form ne '') {
        if ($emailGnuPG_form =~ m/(.*)\@(.*).(.*)/) {
            $data_emailGnuPG = $emailGnuPG_form;
        } else {
            print "Please enter valid email address !!! \n";
            form_email_gpg();
        }
    } else {
        if ($email eq '') {
            print "your enter email is empty !!! \n";
            form_email_gpg();
        } else {
            $data_emailGnuPG = $email;
        }
    }
    return $data_emailGnuPG;
}
# Subroutine for Passphrase GnuPG :
# ------------------------------------------------------------------------
sub form_passphrase_gpg {
    my ($self) = @_;
    # Prepare Form :
    my $passph_form = '';
    my $confirm_again;
    my $data_passph;

    # From Passhphrase :
    print "\n";
    print "Enter Passphrase gpg : ";
    ReadMode('noecho');
    $passph_form = ReadLine(0);
    ReadMode 1;
    if ($passph_form ne '') {
        $data_passph = $passph_form;
    } else {
        print "your enter passphrase gpg is empty !!! \n";
        print "You want to try again ? [y or n] : ";
        chomp($confirm_again = <STDIN>);
        if ($confirm_again eq 'y' or $confirm_again eq 'Y') {
            print "Enter Passphrase gpg : ";
            ReadMode('noecho');
            $passph_form = ReadLine(0);
            ReadMode 1;
        }
    }
    return $passph_form;
}
1;