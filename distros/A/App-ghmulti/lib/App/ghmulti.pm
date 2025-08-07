package App::ghmulti;

use 5.010;
use strict;
use warnings;

use Carp;

use GitHub::Config::SSH::UserData qw(get_user_data_from_ssh_cfg);
use Git::RemoteURL::Parse qw(parse_git_remote_url);


use Getopt::Std;
# If set to true, exit script after processing --help or --version flags
$Getopt::Std::STANDARD_HELP_VERSION = 1;

use Pod::Usage;

our $VERSION = '0.02';


sub run {
  my %opts;
  getopts('cu', \%opts ) or pod2usage(2);

  usr_error("Too many options") if keys(%opts) > 1;

  if ($opts{u}) {
    my $url = @ARGV ? shift(@ARGV) : get_remote_url();
    usr_error("Too many arguments @ARGV") if @ARGV;
    print (get_ssh_url($url), "\n");
  } elsif ($opts{c}) {
    usr_error("Missing URL") if !@ARGV;
    usr_error("Too many arguments") if @ARGV > 2;
    clone_repo(@ARGV);
  } else {
    usr_error("Too many arguments") if @ARGV;
    config_existing_repo();
  }
}


#
# clone_repo GITHUB_REPO, DIR
# clone_repo GITHUB_REPO
#
# Clones GITHUB_REPO and configures the local clone with the data from ‘~/.ssh/config’.
#
sub clone_repo {
  my ($url, $dir) = @_;
  exit_with_msg("You are in a git repo", 1) if in_git_repo();
  my ($uname, $repo) = get_data_from_gh_url($url);
  $dir //= $repo;
  my $user_data = get_user_data_from_ssh_cfg($uname);
  run_cmd("git clone " . get_ssh_url($url) . " $dir");
  chdir($dir);
  config_user_data($user_data);
  chdir("..");
}


#
# config_existing_repo
#
# Configures the current git repo with the data from ‘~/.ssh/config’. If the
# remote url is already in 'git@github-...' the function prints a message and
# does nothing.
#
sub config_existing_repo {
  my $url = get_remote_url();
  exit_with_msg("Remote URL is already 'git\@github-' format") if ($url =~ /^git\@github-/);
  my ($uname, undef) = get_data_from_gh_url($url);
  my $user_data = get_user_data_from_ssh_cfg($uname);
  run_cmd("git remote set-url origin " . get_ssh_url($url));
  config_user_data($user_data);
}



#
# get_ssh_url GITHUB_URL
#
# Changes GITHUB_URL in our 'git\@github-...' format and returns the result.
#
sub get_ssh_url {
  my $url = shift;
  return $url if ($url =~ /^git\@github-/);
  my ($uname, $repo) = get_data_from_gh_url($url);
  return "git\@github-$uname:$uname/$repo.git";
}


#
# get_data_from_gh_url GITHUB_URL
#
# Returns a two-element list containing user name and repo taken from GITHUB_URL.
#
sub get_data_from_gh_url {
  my $url = shift;
  my $data = parse_git_remote_url($url) // croak("$url: unrecognized URL");
  croak("$data->{service}: non-github service. Not supported.") if $data->{service} ne 'github';
  return ($data->{user}, $data->{repo});
}


#
# in_git_repo
#
# Returns a boolean that flags if you are in a git repo.
#
sub in_git_repo {
  `git status 2>&1`;
  return $? == 0;
}


#
# get_remote_url
#
# Returns the remote url. If you are not in a git repo, the sub terminates
# with an error message.
#
sub get_remote_url {
  exit_with_msg("Not in a git repo", 1) unless in_git_repo();
  my $url = `git remote get-url origin`;
  if ($?) {
    die("Failed to execute get-url");
  }
  chomp($url);
  return $url;
}


#
# config_user_data UDATA
#
# Locally configures user.email and user.name.
# UDATA is a reference to a hash containing 'email' and 'full_name'.
#
sub config_user_data {
  my ($udata) = @_;
  run_cmd("git config user.email \"$udata->{email}\"");
  run_cmd("git config user.name \"$udata->{full_name}\"");
}

# ---

#
# exit_with_msg MSG, EXIT_VALUE
# exit_with_msg MSG
#
# Prints MSG and exits with value EXIT_VALUE (default: 0).
# For EXIT_VALUE != 0 the message is printed to STDERR.
#
sub exit_with_msg {
  my ($msg, $exit_value) = @_;
  $exit_value //= 0;
  my $hndl = $exit_value ? *STDERR : *STDOUT;
  $msg .= "\n" if substr($msg, -1) ne "\n";
  print $hndl ($msg);
  exit $exit_value;
}


#
# run_cmd CMD ECHO
# run_cmd CMD
#
# Executes CMD.
#
# If ECHO is a true value, then CMD is also printed to STDOUT. Default is true (1).
#
sub run_cmd {
  my ($cmd, $echo) = @_;
  $echo //= 1;
  chomp($cmd);
  print("Running: $cmd\n") if $echo;
  system($cmd) == 0 or croak("Failed running  $cmd");
}


sub usr_error {
  pod2usage(-verbose => 1, -message => "$0: $_[0]\n", -output  => \*STDERR, -exitval => 1);
}



# ----------- functions for Getopt::Std, must be in main namespace ---------------------

#
# Print help text, see docu of Getopt::Std.
#
#sub HELP_MESSAGE {
sub main::HELP_MESSAGE {
  pod2usage(-exitval => 0, -verbose => 2);
}

#
# Print version info, see docu of Getopt::Std.
#
sub main::VERSION_MESSAGE {
  print("$0: $VERSION\n");
}


1;


__END__


=pod


=head1 NAME

App::ghmulti - Helps when using multiple Github accounts with SSH keys.


=head1 VERSION

Version 0.02


=head1 SYNOPSIS

    use App::ghmulti;

    App::ghmulti->run();

or

   {
     local @ARGV = @my_args;
     App::ghmulti->run();
   }


=head1 DESCRIPTION

Please read the documentation in the L<ghmulti> program. for more information

B<Note>: this module uses the B<git> command line tool, so B<git> must be
installed and available via C<PATH>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-app-ghmulti at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ghmulti>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

L<ghmulti>,
L<Git::RemoteURL::Parse>,
L<GitHub::Config::SSH::UserData>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ghmulti


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ghmulti>

=item * Search CPAN

L<https://metacpan.org/release/App-ghmulti>

=item * GitHub Repository

L<https://github.com/klaus-rindfrey/perl-app-ghmulti>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Oanh Nguyen (oanhnn) for publishing this gist:
L<https://gist.github.com/oanhnn/80a89405ab9023894df7>, and to everyone who
contributed in the comments.


=head1 AUTHOR

Klaus Rindfrey, C<< <klausrin at cpan.org.eu> >>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Klaus Rindfrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
