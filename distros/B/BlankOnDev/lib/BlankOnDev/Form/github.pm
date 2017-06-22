package BlankOnDev::Form::github;
use strict;
use warnings FATAL => 'all';

# Import :
use Term::ReadKey;
use BlankOnDev::Rilis;
use BlankOnDev::command;

# Version :
our $VERSION = '0.1005';

# Subroutine for config github :
# ------------------------------------------------------------------------
sub form_config_github {
    my ($self, $name, $email) = @_;

    # Prepare form :
    my $confirmation;
    my $home_dir = $ENV{"HOME"};
    my $r_gitset;

    # Get Command :
    # ----------------------------------------------------------------
    my $get_cmd = BlankOnDev::command::github();
    my $getGit_cmd = $get_cmd->{'git'};
    my $gitCmd_name = $getGit_cmd->{'cfg-name'};
    my $gitCmd_email = $getGit_cmd->{'cfg-email'};

    # Check file config github :
    if (-e $home_dir.'/.gitconfig') {
        # Form Confirmation :
        print "\n\n";
        print "You want reconfig github ? [y or n] ";
        chomp($confirmation = <STDIN>);
        if ($confirmation eq 'y') {

            if ($name ne '' and $email ne '') {
                system("$gitCmd_name \"$name\"");
                system("$gitCmd_email \"$email\"");
                $r_gitset = 1;
            } else {
                $r_gitset = 0;
                print "git user.name or user.email not enter\n";
                exit 0;
            }
        }
    } else {
        if ($name ne '' and $email ne '') {
            system("$gitCmd_name \"$name\"");
            system("$gitCmd_email \"$email\"");
            $r_gitset = 1;
        } else {
            $r_gitset = 0;
            print "git user.name or user.email not enter\n";
            exit 0;
        }
    }
}
1;