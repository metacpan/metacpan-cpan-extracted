#!/usr/bin/perl -w

package Apache::Sling::Group;

use 5.008001;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use JSON;
use Text::CSV;
use Apache::Sling;
use Apache::Sling::GroupUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

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
    my $group = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $group, $class;
    return $group;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $group, $message, $response ) = @_;
    $group->{'Message'}  = $message;
    $group->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $group, $act_on_group, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::add_setup(
            $group->{'BaseURL'}, $act_on_group, $properties
        )
    );
    my $success = Apache::Sling::GroupUtil::add_eval($res);
    my $message = "Group: \"$act_on_group\" ";
    $message .= ( $success ? 'added!' : 'was not added!' );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub add_from_file
sub add_from_file {
    my ( $group, $file, $fork_id, $number_of_forks ) = @_;
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

                    # First field must be group:
                    if ( $column_headings[0] !~ /^[Gg][Rr][Oo][Uu][Pp]$/msx ) {
                        croak 'First CSV column must be the group ID, '
                          . 'column heading must be "group". '
                          . 'Found: "'
                          . $column_headings[0] . "\".\n";
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
"Found \"$columns_size\" columns. There should have been \"$number_of_columns\".\n"
                          . "Row contents was: $_";
                    }
                    my $id = $columns[0];
                    for ( my $i = 1 ; $i < $number_of_columns ; $i++ ) {
                        my $heading = $column_headings[$i];
                        my $data    = $columns[$i];
                        my $value   = "$heading=$data";
                        push @properties, $value;
                    }
                    $group->add( $id, \@properties );
                    Apache::Sling::Print::print_result($group);
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
        }
        close $input or croak q{Problem closing input!};
    }
    else {
        croak "Problem opening file: '$file'";
    }
    return 1;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::exists_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::exists_eval($res);
    my $message = "Group \"$act_on_group\" ";
    $message .= ( $success ? 'exists!' : 'does not exist!' );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $group, @ARGV ) = @_;
    my $sling = Apache::Sling->new;
    my $config = $group->config( $sling, @ARGV );
    return $group->run( $sling, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $group, $sling, @ARGV ) = @_;
    my $group_config = $group->config_hash( $sling, @ARGV );

    GetOptions(
        $group_config, 'auth=s',     'help|?',       'log|L=s',
        'man|M',        'pass|p=s',   'threads|t=s',  'url|U=s',
        'user|u=s',     'verbose|v+', 'add|a=s',      'additions|A=s',
        'delete|d=s',   'exists|e=s', 'property|P=s', 'view|V=s'
    ) or $group->help();

    return $group_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $group, $sling, @ARGV ) = @_;
    my $additions;
    my $add;
    my $delete;
    my $exists;
    my @property;
    my $view;

    my %group_config = (
        'auth'      => \$sling->{'Auth'},
        'help'      => \$sling->{'Help'},
        'log'       => \$sling->{'Log'},
        'man'       => \$sling->{'Man'},
        'pass'      => \$sling->{'Pass'},
        'threads'   => \$sling->{'Threads'},
        'url'       => \$sling->{'URL'},
        'user'      => \$sling->{'User'},
        'verbose'   => \$sling->{'Verbose'},
        'add'       => \$add,
        'additions' => \$additions,
        'delete'    => \$delete,
        'exists'    => \$exists,
        'property'  => \@property,
        'view'      => \$view
    );

    return \%group_config;
}

#}}}

#{{{sub del
sub del {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::delete_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::delete_eval($res);
    my $message = "Group: \"$act_on_group\" ";
    $message .= ( $success ? 'deleted!' : 'was not deleted!' );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --additions or -A (file)          - file containing list of groups to be added.
 --add or -a (actOnGroup)          - add specified group.
 --auth (type)                     - Specify auth type. If ommitted, default is used.
 --delete or -d (actOnGroup)       - delete specified group.
 --exists or -e (actOnGroup)       - check whether specified group exists.
 --help or -?                      - view the script synopsis and options.
 --log or -L (log)                 - Log script output to specified log file.
 --man or -M                       - view the full script documentation.
 --pass or -p (password)           - Password of user performing actions.
 --property or -P (property=value) - Specify property to set on group.
 --threads or -t (threads)         - Used with -A, defines number of parallel
                                     processes to have running through file.
 --url or -U (URL)                 - URL for system being tested against.
 --user or -u (username)           - Name of user to perform any actions as.
 --verbose or -v or -vv or -vvv    - Increase verbosity of output.
 --view or -V (actOnGroup)         - view details for specified group in json format.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {

    my ($group) = @_;

    print <<'EOF';
group perl script. Provides a means of managing groups in sling from the
command line. The script also acts as a reference implementation for the Group
perl library.

EOF

    $group->help();

    print <<"EOF";
Example Usage

* Authenticate and add a group with id g-test:

 perl group.pl -U http://localhost:8080 -u admin -p admin -a g-test

* Authenticate and check whether group with id g-test exists:

 perl group.pl -U http://localhost:8080 -u admin -p admin -a g-test

* Authenticate and view details for group with id g-test:

 perl group.pl -U http://localhost:8080 -u admin -p admin -V g-test

* Authenticate and delete group with id g-test:

 perl group.pl -U http://localhost:8080 -u admin -p admin -d g-test

* Authenticate and add a group with id g-test and property p1=v1:

 perl group.pl -U http://localhost:8080 -u admin -p admin -a g-test -P p1=v1

EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $group, $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No group config supplied!';
    }
    $sling->check_forks;
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    my $success = 1;

    if ( $sling->{'Help'} ) { $group->help(); }
    elsif ( $sling->{'Man'} )  { $group->man(); }
    elsif ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding groups from file \"" . ${ $config->{'additions'} } . "\":\n";
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
                my $group =
                  new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $group->add_from_file( ${ $config->{'additions'} },
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
            $group =
              new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group->check_exists( ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $group =
              new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success =
              $group->add( ${ $config->{'add'} }, $config->{'property'} );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $group =
              new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group->del( ${ $config->{'delete'} } );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $group =
              new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group->view( ${ $config->{'view'} } );
        }
        else {
            $group->help();
            return 1;
        }
        Apache::Sling::Print::print_result($group);
    }
    return $success;
}

#}}}

#{{{sub view
sub view {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::view_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::view_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing group: \"$act_on_group\""
    );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::Group - Manipulate Groups in an Apache Sling instance.

=head1 ABSTRACT

group related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a Group Object.

=head2 set_results

Set a suitable message and response for the group object.

=head2 add

Add a new group to the system.

=head2 add_from_file

Add new groups to the system based on definitions in a file.

=head2 config

Fetch hash of group configuration.

=head2 del

Delete a user.

=head2 check_exists

Check whether a group exists.

=head2 run

Run group related actions.

=head2 view

View details for a group

=head1 USAGE

use Apache::Sling::Group;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST group methods

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
