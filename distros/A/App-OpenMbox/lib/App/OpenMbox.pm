package App::OpenMbox;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::OpenMbox - The methods for email management used in OpenMbox.net

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

Here are several methods used by Open Mbox, a free email provider.

    use App::OpenMbox;

    my $om = App::OpenMbox->new();

    # test purpose by providing temp files
    $om->register('/tmp/dove.db','/tmp/user.temp');
    $om->password('/tmp/dove.db','/tmp/pass.temp');

Sample input from user.temp:

    henry SomePassword111
    hello SomePassword222

Sample input from pass.temp:

    henry OldPassword111  NewPassword111
    hello OldPassword222  NewPassword222

You may know that we don't have RDB in the system for email and user management. We do not record any information about users, nor track user's behavior. For registration, user submits his/her username and password to our system, these username/password are stored in a temp file. A perl program reads data from the file, and updates its content to Dovecot's user database, which is pure text DB for email users and encrypted passwords.

To make this program work, you should have Postfix and Dovecot deployed at first. There are many documentation for how to deploy that a system.


=head1 SUBROUTINES/METHODS

=head2 new()

New the instance.

=cut

sub new {
  my $class = shift;
  bless {},$class;
}


=head2 register('/path/to/dove_userdb','/path/to/temp_userfile')

Register users with username and password.

Web CGI writes username and password to a temp file, another perl script reads this file periodically, and updates its content to Dovecot user DB.

=cut

sub register {
  my $self = shift;
  my $dove_userdb = shift;
  my $temp_userfile = shift;

  if (-f $temp_userfile) {
    my %hash;

    open my $fd,$temp_userfile or die $!;
    while(<$fd>) {
      chomp;
      my ($user,$pass) = split;
      $hash{$user} = $pass;
    }
    close $fd;

    open my $fdw,">>",$dove_userdb or die $!;
    for my $key (keys %hash) {
      my $usr = $key . '@openmbox.net';
      my $pwd = $hash{$key};
      my $crypt = `/usr/bin/doveadm pw -p '$pwd'`;
      chomp $crypt;

      print $fdw $usr . ':' . $crypt, "\n";
    }
    close $fdw;

    unlink $temp_userfile;
  }
}


=head2 password('/path/to/dove_userdb','/path/to/temp_passfile')

Update passwords by providing username, old password and new password.

Web CGI writes username and old_password and new_password to a temp file, another perl script reads this file periodically, and updates its content to Dovecot user DB.

=cut

sub password {
  my $self = shift;
  my $dove_userdb = shift;
  my $temp_passfile = shift;
  my %hash;

  if (-f $temp_passfile) {

    open my $fd,$temp_passfile or die $!;
    while(<$fd>) {
      chomp;
      my ($user,$oldpass,$newpass) = split;
      my $mbox = $user . '@openmbox.net';
      my @res = `/usr/bin/doveadm auth test '$mbox' '$oldpass'`;
      if ($? == 0) {
        $hash{$mbox} = $newpass;
      }
    }
    close $fd;

    unlink $temp_passfile;
  }

  if (%hash) {
    my @arr;

    open my $fd,$dove_userdb or die $!;
    while( my $line = <$fd>) {
      my ($u,$p) = split/\:/,$line;

      if (exists $hash{$u}) {

        my $pass = $hash{$u};
        my $crypt = `/usr/bin/doveadm pw -p '$pass'`;
        chomp $crypt;
        push @arr, $u . ':' . $crypt, "\n";

      } else {
        push @arr, $line;
      }
    }
    close $fd;

    open my $fdw,">",$dove_userdb or die $!;
    for (@arr) {
      print $fdw $_;
    }
    close $fdw;
  }
}


=head1 AUTHOR

Henry R, C<< <support at openmbox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-openmbox at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-OpenMbox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::OpenMbox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-OpenMbox>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-OpenMbox>

=item * Search CPAN

L<https://metacpan.org/release/App-OpenMbox>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Henry R.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::OpenMbox
