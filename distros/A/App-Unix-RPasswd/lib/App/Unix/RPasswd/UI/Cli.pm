package App::Unix::RPasswd::UI::Cli;
# This is an internal module of App::Unix::RPasswd

use feature ':5.10';
use Moo;
use List::MoreUtils ('uniq');
use POSIX qw/strftime/;
use Term::ReadKey;

our $VERSION = '0.53';
our $AUTHOR  = 'Claudio Ramirez <nxadm@cpan.org>';

has 'args' => (
    is       => 'ro',
#    isa      => 'HashRef',
    required => 1,
);

has 'defaults' => (
    is       => 'ro',
#    isa      => 'HashRef',
    required => 1,
);

has 'messages' => (
    is       => 'rw',
#    isa      => 'ArrayRef',
    default  => sub { [] },
    reader   => 'get_messages',
    lazy     => 1,
    init_arg => undef,
);

has '_gen_only_options' => (
    is       => 'ro',
#    isa      => 'ArrayRef',
    default  => sub { [ 'base', 'date', 'sessions', 'generate_only', 'servers' ] },
    init_arg => undef,
);

sub check_params {

    # No params
    # Return success (1) or failure (O)
    my ( $self, $servers_ref ) = @_;
    my $status = 1;

    if ( !scalar @{$servers_ref} > 0 ) {
        $status = 0;
        push @{ $self->messages }, 'You need at least one server.';
    }
    return $status if !$status;

    # gen_only mode
    if ( $self->args->{generate_only} ) {
        $status = $self->_check_gen_only;
    }
    else {
        $status = $self->_check_main_mode;
    }
    return $status if !$status;

    # all modes
    $self->args->{ssh} = $self->defaults->{ssh};
    if ( defined $self->args->{ssh_args} ) {
        for my $arg ( split( /\s/, $self->args->{ssh_args} ) )
        {    # string to array
            push @{ $self->args->{ssh} }, $arg;
        }
    }

    if ( defined $self->args->{base} ) {    # Salts are valid for both modes
        if ( $self->args->{date} and $self->args->{date} !~ /^\d{8}$/ ) {
            $status = 0;
            push @{ $self->messages },
              'Supply parameter date in a YYYYMMDD format (e.g. 20101123).';
        }
        elsif ( !defined $self->args->{date} ) {
            $self->args->{date} = strftime "%Y%m%d", localtime;
        }
        if ( $self->args->{base} eq '-' ) {
            $self->args->{base} = $self->_ask_key('base salt');
        }
        
        while ( $self->args->{base} eq '' ) {
            say 'Base salt can not be empty.';
            $self->args->{base} = $self->_ask_key('base salt');
        }

    }
# This is an internal module of App::Unix::RPasswd
    return $status;
}

sub term_line {
    my $self = shift;
    my ($wchar) = GetTerminalSize();
    return "_" x $wchar . "\n";
}

sub show_help {
    my ( $self, $version_bool ) = @_;
    require File::Basename;
    my $program = File::Basename::basename($0);
    say $program . ', version ' . $VERSION . '.';
    return if $version_bool;
    my $reruns = $self->defaults->{runs} + 1;
    say <<"EOL";

Change passwords on UNIX and UNIX-like servers on a simple, fast (in parallel)
and secure (SSH) way. A salt-based retrievable "random" password generator, 
tied to the supplied server names and date, is included.

Usage:
\t$program -u <user> -p <password> <server(s)>
\t$program -g -b <base salt> -date <YYYYMMDD> <server(s)>

Options:
\t--generate_only|-g:\t(re-)generate the salted password.
\t--user|-u:\t\tremote user name.
\t--password|-p:\t\tnew password for remote user.
\t--base|-b:\t\tbase salt for encryption.
\t--date|-d:\t\tdate in YYYYMMDD format (defaults to today)*.
\t--ssh_args|-a:\t\tsettings for the ssh client (man ssh)*.
\t--reruns|-r:\t\treruns for failed targets (defaults to 0)*.
\t--sessions|-s:\t\tsimultaneous sessions (defaults to 5)*.
\t--timeout|-t:\t\tsession timeout (defaults to 20 seconds)*.
\t--debug:\t\tprints debug output*.
\t--help|-h:\t\tprints this help screen.
\t--version|-v:\t\tprints the version number.

\t*: optional

The program has two modes. The default mode connects to remote targets and 
changes the password (optional) of the specified user (mandatory) on the 
supplied servers (mandatory). Optional valid parameters for this mode are 
sessions, ssh_args ("-l root" if you don't the application as root), reruns, 
timeout and debug. The built-in salted password generator can be used to 
create unique 'random' passwords for each server on the fly. In this case 
date (optional) and base (mandatory) are valid parameters for this mode.

The "generate_only" mode is used to (re-) generate salted passwords. In this 
mode only date (optional), base (mandatory), sessions (optional) and one of 
more servers (mandatory) are valid parameters.

From a security point of view, it is strongly advised to supply '-' as the base
salt or password on the command line. The program will then ask interactively 
for the base salt or password. 

$AUTHOR, http://search.cpan.org/dist/App-Unix-RPasswd 
EOL
}

sub _ask_key {
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

sub _check_gen_only {
    my $self   = shift;
    my $status = 1;
    my @gen_options_provided =
      #grep { !( $_ ~~ @{ $self->_gen_only_options } ) }
      grep { !( /^$_$/, @{ $self->_gen_only_options } ) }
      keys %{ $self->args };
    for my $key (@gen_options_provided) {
        if ( defined $self->args->{$key} ) {
            $status = 0;
            push @{ $self->messages },
              "Parameter $key is invalid in this mode.";
        }
    }
    if ( !defined $self->args->{base} ) {
        $status = 0;
        push @{ $self->messages }, 'Parameter base is required in this mode.';
    }
    if ($status) {    # Reruns have no sense in this mode
        $self->args->{reruns} = 0;
    }
    return $status;
}

sub _check_main_mode {
    my $self   = shift;
    my $status = 1;

    if ( !defined $self->args->{user} ) {
        $status = 0;
        push @{ $self->messages }, 'Parameter user is mandatory.';
    }

    if (    !defined $self->args->{password}
        and !defined $self->args->{base} )
    {
        $status = 0;
        push @{ $self->messages }, 'You need to specify password or base.';
    }
    elsif ( defined $self->args->{password}
        and defined $self->args->{base} )
    {
        $status = 0;
        push @{ $self->messages },
          'You need to specify password or base, not both.';
    }
    return $status if !$status;

    if ( defined $self->args->{password} ) {
        if ( $self->args->{date} ) {
            $status = 0;
            push @{ $self->messages },
              'Date is only valid in combination with base.';
        }
        elsif ( $status == 1 and $self->args->{password} eq '-' ) {
            $self->args->{password} = $self->_ask_key('password');
        }
    }

    if ( !defined $self->args->{timeout} ) {
        $self->args->{timeout} = $self->defaults->{timeout};
    }

    if ( defined $self->args->{reruns} ) {
        if ( $self->args->{reruns} > 98 ) {
            $status = 0;
            push @{ $self->messages },
              'Less than 99 retries allowed. Let\'s be raisonable.';
        }
    }
    else { $self->args->{reruns} = 0 }
    return $status;
}

1;
