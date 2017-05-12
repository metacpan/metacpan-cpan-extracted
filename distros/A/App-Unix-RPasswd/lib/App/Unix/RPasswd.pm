package App::Unix::RPasswd;

use 5.010000;
use feature ':5.10';
use Moo;
use Parallel::ForkManager;
use App::Unix::RPasswd::Connection;
use App::Unix::RPasswd::SaltedPasswd;

our $VERSION = '0.53';
our $AUTHOR  = 'Claudio Ramirez <nxadm@cpan.org>';

has 'args' => (
    is       => 'ro',
    #isa      => 'HashRef',
    required => 1,
);

has '_connection_obj' => (
    is      => 'ro',
    does    => 'App::Unix::RPasswd::Connection',
    default => sub {
        my $self = shift;
        App::Unix::RPasswd::Connection->new(
            user     => $self->args->{user},
            ssh_args => $self->args->{ssh},
        );
    },
    lazy     => 1,
    init_arg => undef,
);

has '_saltedpasswd_obj' => (
    is      => 'ro',
    does    => 'App::Unix::RPasswd::SaltedPasswd',
    default => sub {
        my $self = shift;
        App::Unix::RPasswd::SaltedPasswd->new( salt => $self->args->{base} );
    },
    lazy     => 1,
    init_arg => undef,
);

sub ask_key {
    my ( $self, $key ) = @_;
    my $ckeys = $key;
    $ckeys =~ s/(\w)(.+)/\U$1\E$2s/;    # key -> Keys
    my @msg =
      ( "Please introduce the $key: ", "\nPlease re-introduce the $key: " );
    my $counter    = 0;
    my $first_time = 1;
    print $msg[$counter];
    my @input;
    system( '/bin/stty', '-echo' );

    while (<STDIN>) {
        chomp;
        $input[$counter] = $_;
        if ( $counter == 1 ) {
            if ( $input[0] eq $input[1] ) { last }
            else {
                say "\n$ckeys are not the same...";
                $counter = 0;
            }
        }
        else { $counter++; $first_time = 0; }

        print $msg[$counter] unless $first_time;
    }
    system '/bin/stty echo';
    say '';
    return $input[0];
}

sub pexec {
    my $self    = shift;
    my @servers = @_;
    state $run++;
    my @errors;

    # Setup forks
    my $pfm = Parallel::ForkManager->new( $self->args->{sessions} );

    # Retrieve status
    $pfm->run_on_finish(
        sub {
            my ( undef, undef, undef, undef, undef, $dataref ) = @_;
            if ( defined $dataref and defined $$dataref ) {
                push @errors, $$dataref;
            }
        }
    );

    for my $server (@servers) {
        if (@servers) {
            $pfm->start() and next;
            my $error;
            if ( defined $self->args->{base} ) {
                $self->args->{password} =
                  $self->_saltedpasswd_obj->generate(
                    $server . $self->args->{date} . $server );
            }

            if ( $self->args->{generate_only} ) {
                say $self->args->{password} . " ($server)";
            }
            else {
                my $msg =
                  ( $self->args->{debug} )
                  ? 'Running on ' 
                  . $server
                  . ' with password \''
                  . $self->args->{password} . '\'...'
                  : "Running on $server...";
                say $msg;
                my $status = eval {
                    local $SIG{ALRM} = sub {
                        say "Timeout exceeded for $server.";
                        die "Timeout exceeded\n";    # NB: \n required
                    };
                    alarm $self->args->{timeout};
                    return $self->_connection_obj->run(
                        $server,
                        $self->args->{password},
                        $self->args->{debug}
                    );
                    alarm 0;
                };
                if ( !$status ) { $error = $server; }
            }
            $pfm->finish( 0, \$error );
        }
    }
    $pfm->wait_all_children;
    say "\nRun $run done.\n";
    return ( scalar @errors and $run <= $self->args->{reruns} )
      ? $self->pexec(@errors)
      : @errors;    # recursive
}

1;
__END__

=pod

=head1 NAME

App::Unix::RPasswd - Change passwords on UNIX and UNIX-like servers on a simple, 
fast (in parallel) and secure (SSH) way.

=head1 VERSION

Version 0.52

=head1 SYNOPSIS

App::Unix::RPasswd is an application for changing passwords on UNIX and 
UNIX-like servers on a simple, fast (in parallel) and secure (SSH) way. 
A salt-based retrievable "random" password generator, tied to the supplied 
server names and date, is included. 
This generated passwords, unique for each server, can be generated and
automatically remotely applied. Because the salt is secret and the correct date
string is required, the password for an specific server can only be regenerated 
by authorized personnel.

Perl 5.10 or higher is required.

The program has two modes. The default mode connects to remote targets and 
changes the password (optional) of the specified user (mandatory) on the 
supplied servers (mandatory). Optional valid parameters for this mode are 
sessions, ssh_args, reruns, timeout and debug. The built-in salted password 
generator can be used to create unique 'random' passwords for each server on 
the fly. In this case date (optional) and base (mandatory) are valid parameters 
for this mode.

The "generate_only" mode is used to (re-) generate salted passwords. In this 
mode only date (optional), base (mandatory), sessions (optional) and one of more 
servers (mandatory) are valid parameters.

From a security point of view, it is strongly advised to supply '-' as the base
salt or password on the command line. The program will then ask interactively 
for the base salt or password. This program requires a ssh-key based remote 
root access.

	Usage:
		rpasswd -u <user> -p <password> <server(s)>
		rpasswd -g -b <base salt> -date <YYYYMMDD> <server(s)>

	Options:
		--generate_only|-g: (re-)generate the salted password.
		--user|-u:          remote user name.
		--password|-p:      new password for remote user.
		--base|-b:          base salt for encryption.
		--date|-d:          date in YYYYMMDD format*.
		--ssh_args|-a:      settings for the ssh client*.
		--reruns|-r:        reruns for failed targets*.
		--sessions|-s:      simultaneous sessions*.
		--timeout|-t:       session timeout*.
		--debug:            prints debug output*.
		--help|-h:          print this help screen.
		--version|-v:       prints the version number.

		*: optional

=head1 PARAMETERS

=head2 generate_only | g

This parameter enables the (re-)generation of salted passwords.

=head2 user | u

This parameter sets the remote user name that will receive a new password.

=head2 password | p

This parameter sets the new password for the remote user. When "-" is supplied 
as argument, the program asks interactively for the password.

=head2 base | b

This parameter sets the base salt for encryption. When "-" is supplied as 
argument, the program asks interactively for the base salt. The salt can be 
between 1 and 8 characters. Longer salts are truncated.

=head2 date | d

This optional parameters sets the date string in a YYYYMMDD format (defaults to 
today).

=head2 ssh_args | a

This optional parameter sets additional settings for the ssh client (man ssh).
If you dont (locally) run the program as root but have root access via 
ssh-keys you need to use --ssh_args "-l root". Quote the argument string.

=head2 reruns | r

This optional parameterre sets the reruns for failed targets (defaults to 0).

=head2 sessions | s

This optional parameter sets the simultaneous sessions (defaults to 5).

=head2 timeout | t

This optional parameter sets the session timeout in seconds (defaults to 20 
seconds). While OpenSSH has the ConnectTimeout (passed as --ssh_args "-OConnectTimeout=<value>")
that provides a similar funcionality, its for on Solaris, SunSSH, has not. This
is a generic implementation that work on both ssh families.

=head2 debug

This parameter prints debug output.

=head2 help | h

This parameter prints this help screen.

=head2 version | v

This parameter prints the version number.

=head1 BUGS

Please report any bugs or feature requests to C<bug-App-Unix-RPasswd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Unix-RPasswd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

This distribution has been tested on GNU/Linux (Debian 6.0 and Ubuntu 10.10) 
running OpenSSH and Solaris 10 running SunSSH.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App-Unix-RPasswd


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Unix-RPasswd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Unix-RPasswd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Unix-RPasswd>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Unix-RPasswd/>

=back

=head1 ACKNOWLEDGEMENTS

The following non-core modules were used:

=over 2

=item * Crypt::PasswdMD5
L<http://search.cpan.org/dist/Crypt-PasswdMD5/>

=item * Expect
L<http://search.cpan.org/dist/Expect/>

=item * List::MoreUtils
L<http://search.cpan.org/dist/List-MoreUtils/>

=item * Moo
L<http://search.cpan.org/dist/Moo/>

=item * Parallel::ForkManager
L<http://search.cpan.org/dist/Parallel-ForkManager/>

=back

=head1 AUTHOR

Claudio Ramirez <nxadm@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Claudio Ramirez.
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
