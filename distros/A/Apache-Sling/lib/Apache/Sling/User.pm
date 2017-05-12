#!/usr/bin/perl -w

package Apache::Sling::User;

use 5.008001;
use strict;
use warnings;
use Carp;
use Text::CSV;
use Getopt::Long qw(:config bundling);
use Apache::Sling;
use Apache::Sling::Print;
use Apache::Sling::Request;
use Apache::Sling::UserUtil;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = qw(command_line);

our $VERSION = '0.27';

#{{{sub new

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $user = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $user, $class;
    return $user;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $user, $message, $response ) = @_;
    $user->{'Message'}  = $message;
    $user->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $user, $act_on_user, $act_on_pass, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::add_setup(
            $user->{'BaseURL'}, $act_on_user, $act_on_pass, $properties
        )
    );
    my $success = Apache::Sling::UserUtil::add_eval($res);
    my $message = "User: \"$act_on_user\" ";
    $message .= ( $success ? 'added!' : 'was not added!' );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub add_from_file
sub add_from_file {
    my ( $user, $file, $fork_id, $number_of_forks ) = @_;
    $fork_id         = defined $fork_id         ? $fork_id         : 0;
    $number_of_forks = defined $number_of_forks ? $number_of_forks : 1;
    my $csv               = Text::CSV->new();
    my $count             = 0;
    my $number_of_columns = 0;
    my @column_headings;
    if ( !defined $file ) {
        croak 'File to upload from not defined';
    }
    if ( open my ($input), '<', $file ) {
        while (<$input>) {
            if ( $count++ == 0 ) {

                # Parse file column headings first to determine field names:
                if ( $csv->parse($_) ) {
                    @column_headings = $csv->fields();

                    # First field must be site:
                    if ( $column_headings[0] !~ /^[Uu][Ss][Ee][Rr]$/msx ) {
                        croak
'First CSV column must be the user ID, column heading must be "user". Found: "'
                          . $column_headings[0] . "\".\n";
                    }
                    if ( $column_headings[1] !~
                        /^[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]$/msx )
                    {
                        croak
'Second CSV column must be the user password, column heading must be "password". Found: "'
                          . $column_headings[1] . "\".\n";
                    }
                    $number_of_columns = @column_headings;
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
            elsif ( $fork_id == ( $count++ % $number_of_forks ) ) {
                my @properties;
                if ( $csv->parse($_) ) {
                    my @columns      = $csv->fields();
                    my $columns_size = @columns;

           # Check row has same number of columns as there were column headings:
                    if ( $columns_size != $number_of_columns ) {
                        croak
"Found \"$columns_size\" columns. There should have been \"$number_of_columns\".\nRow contents was: $_";
                    }
                    my $id       = $columns[0];
                    my $password = $columns[1];
                    for ( my $i = 2 ; $i < $number_of_columns ; $i++ ) {
                        my $heading = $column_headings[$i];
                        my $data    = $columns[$i];
                        my $value   = "$heading=$data";
                        push @properties, $value;
                    }
                    $user->add( $id, $password, \@properties );
                    Apache::Sling::Print::print_result($user);
                }
                else {
                    croak q{CSV broken, failed to parse line: }
                      . $csv->error_input;
                }
            }
        }
        close $input or croak q{Problem closing input};
    }
    else {
        croak "Problem opening file: '$file'";
    }
    return 1;
}

#}}}

#{{{sub change_password
sub change_password {
    my ( $user, $act_on_user, $act_on_pass, $new_pass, $new_pass_confirm ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::change_password_setup(
            $user->{'BaseURL'}, $act_on_user, $act_on_pass,
            $new_pass,          $new_pass_confirm
        )
    );
    my $success = Apache::Sling::UserUtil::change_password_eval($res);
    my $message = "User: \"$act_on_user\" ";
    $message .= ( $success ? 'password changed!' : 'password not changed!' );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $user, $act_on_user ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::exists_setup(
            $user->{'BaseURL'}, $act_on_user
        )
    );
    my $success = Apache::Sling::UserUtil::exists_eval($res);
    my $message = "User \"$act_on_user\" ";
    $message .= ( $success ? 'exists!' : 'does not exist!' );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $user, @ARGV ) = @_;
    my $sling = Apache::Sling->new;
    my $config = $user->config( $sling, @ARGV );
    return $user->run( $sling, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $user, $sling, @ARGV ) = @_;

    my $user_config = $user->config_hash( $sling, @ARGV );

    GetOptions(
        $user_config,         'auth=s',
        'help|?',              'log|L=s',
        'man|M',               'pass|p=s',
        'threads|t=s',         'url|U=s',
        'user|u=s',            'verbose|v+',
        'add|a=s',             'additions|A=s',
        'change-password|c=s', 'delete|d=s',
        'email|E=s',           'first-name|f=s',
        'exists|e=s',          'last-name|l=s',
        'new-password|n=s',    'password|w=s',
        'property|P=s',        'update=s',
        'view|V=s'
    ) or $user->help();

    return $user_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $user, $sling, @ARGV ) = @_;
    my $password;
    my $additions;
    my $add;
    my $change_password;
    my $delete;
    my $email;
    my $exists;
    my $first_name;
    my $last_name;
    my $new_password;
    my @property;
    my $update;
    my $view;

    my %user_config = (
        'auth'            => \$sling->{'Auth'},
        'help'            => \$sling->{'Help'},
        'log'             => \$sling->{'Log'},
        'man'             => \$sling->{'Man'},
        'pass'            => \$sling->{'Pass'},
        'threads'         => \$sling->{'Threads'},
        'url'             => \$sling->{'URL'},
        'user'            => \$sling->{'User'},
        'verbose'         => \$sling->{'Verbose'},
        'add'             => \$add,
        'additions'       => \$additions,
        'change-password' => \$change_password,
        'delete'          => \$delete,
        'email'           => \$email,
        'exists'          => \$exists,
        'first-name'      => \$first_name,
        'last-name'       => \$last_name,
        'new-password'    => \$new_password,
        'password'        => \$password,
        'property'        => \@property,
        'update'          => \$update,
        'view'            => \$view
    );

    return \%user_config;
}

#}}}

#{{{sub del
sub del {
    my ( $user, $act_on_user ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::delete_setup(
            $user->{'BaseURL'}, $act_on_user
        )
    );
    my $success = Apache::Sling::UserUtil::delete_eval($res);
    my $message = "User: \"$act_on_user\" ";
    $message .= ( $success ? 'deleted!' : 'was not deleted!' );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --add or -a (actOnUser)             - add specified user name.
 --additions or -A (file)            - file containing list of users to be added.
 --auth (type)                       - Specify auth type. If ommitted, default is used.
 --change-password or -c (actOnUser) - change password of specified user name.
 --delete or -d (actOnUser)          - delete specified user name.
 --email or -E (email)               - specify email address property for user.
 --exists or -e (actOnUser)          - check whether specified user exists.
 --first-name or -f (firstName)      - specify first name property for user.
 --help or -?                        - view the script synopsis and options.
 --last-name or -l (lastName)        - specify last name property for user.
 --log or -L (log)                   - Log script output to specified log file.
 --man or -M                         - view the full script documentation.
 --me or -m                          - me returns json representing authenticated user.
 --new-password or -n (newPassword)  - Used with -c, new password to set.
 --password or -w (actOnPass)        - Password of user being actioned.
 --pass or -p (password)             - Password of user performing actions.
 --property or -P (property=value)   - Specify property to set on user.
 --threads or -t (threads)           - Used with -A, defines number of parallel
                                       processes to have running through file.
 --update (actOnUser)                - update specified user name, used with -P.
 --url or -U (URL)                   - URL for system being tested against.
 --user or -u (username)             - Name of user to perform any actions as.
 --verbose or -v or -vv or -vvv      - Increase verbosity of output.
 --view or -V (actOnUser)            - view details for specified user in json format.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {

    my ($user) = @_;

    print <<'EOF';
user perl script. Provides a means of managing users in sling from the command
line. The script also acts as a reference implementation for the User perl
library.

EOF

    $user->help();

    print <<"EOF";
Example Usage

* Add user "testuser" with password "test"

 perl $0 -U http://localhost:8080 -a testuser -w test

* View information about authenticated user "testuser"

 perl $0 -U http://localhost:8080 --me -u testuser -p test

* Authenticate as admin and check whether user "testuser" exists

 perl $0 -U http://localhost:8080 -e testuser -u admin -p admin

* Authenticate and update "testuser" to set property p1=v1

 perl $0 -U http://localhost:8080 --update testuser -P "p1=v1" -u admin -p admin

* Authenticate and delete "testuser"

 perl $0 -U http://localhost:8080 -d testuser -u admin -p admin
EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $user, $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No user config supplied!';
    }
    $sling->check_forks;
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    # Handle the three special case commonly used properties:
    if ( defined ${ $config->{'email'} } ) {
        push @{ $config->{'property'} }, "email=" . ${ $config->{'email'} };
    }
    if ( defined ${ $config->{'first-name'} } ) {
        push @{ $config->{'property'} },
          "firstName=" . ${ $config->{'first-name'} };
    }
    if ( defined ${ $config->{'last-name'} } ) {
        push @{ $config->{'property'} },
          "lastName=" . ${ $config->{'last-name'} };
    }

    my $success = 1;

    if ( $sling->{'Help'} ) { $user->help(); }
    elsif ( $sling->{'Man'} )  { $user->man(); }
    elsif ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding users from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent( $sling->{'Referer'} );
                $authn->login_user();
                my $user =
                  new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $user->add_from_file( ${ $config->{'additions'} },
                    $i, $sling->{'Threads'} );
                exit 0;
            }
            else {
                croak "Could not fork $i!";
            }
        }
        foreach (@childs) { waitpid $_, 0; }
    }
    else {
        $authn->login_user();
        if ( defined ${ $config->{'exists'} } ) {
            $user =
              new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $user->check_exists( ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $user =
              new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $user->add(
                ${ $config->{'add'} },
                ${ $config->{'password'} },
                $config->{'property'}
            );
        }
        elsif ( defined ${ $config->{'update'} } ) {
            $user =
              new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success =
              $user->update( ${ $config->{'update'} }, $config->{'property'} );
        }
        elsif ( defined ${ $config->{'change-password'} } ) {
            $user =
              new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $user->change_password(
                ${ $config->{'change-password'} },
                ${ $config->{'password'} },
                ${ $config->{'new-password'} },
                ${ $config->{'new-password'} }
            );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $user =
              new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $user->del( ${ $config->{'delete'} } );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $user =
              new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $user->view( ${ $config->{'view'} } );
        }
        else {
            $user->help();
            return 1;
        }
        Apache::Sling::Print::print_result($user);
    }
    return $success;
}

#}}}

#{{{sub update
sub update {
    my ( $user, $act_on_user, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::update_setup(
            $user->{'BaseURL'}, $act_on_user, $properties
        )
    );
    my $success = Apache::Sling::UserUtil::update_eval($res);
    my $message = "User: \"$act_on_user\" ";
    $message .= ( $success ? 'updated!' : 'was not updated!' );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view
sub view {
    my ( $user, $act_on_user ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::exists_setup(
            $user->{'BaseURL'}, $act_on_user
        )
    );
    my $success = Apache::Sling::UserUtil::exists_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing user: \"$act_on_user\""
    );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::User - Methods for manipulating users in an Apache Sling system.

=head1 ABSTRACT

user related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a User Agent.

=head2 set_results

Set a suitable message and response for the user object.

=head2 add

Add a new user to the system.

=head2 add_from_file

Add new users to the system based on definitions in a file.

=head2 change_password

Change the password for a user.

=head2 check_exists

Check whether a user exists.

=head2 config

Fetch hash of user configuration.

=head2 del

Delete a user.

=head2 run

Run user related actions.

=head2 update

Update a user's credentials.

=head2 view

View details for a user.

=head1 USAGE

use Apache::Sling::User;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST user methods

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
