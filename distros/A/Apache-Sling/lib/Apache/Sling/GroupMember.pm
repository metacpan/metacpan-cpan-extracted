#!/usr/bin/perl -w

package Apache::Sling::GroupMember;

use 5.008001;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use JSON;
use Text::CSV;
use Apache::Sling;
use Apache::Sling::GroupUtil;
use Apache::Sling::GroupMemberUtil;
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
    my ( $group, $act_on_group, $add_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupMemberUtil::add_setup(
            $group->{'BaseURL'}, $act_on_group, $add_member
        )
    );
    my $success = Apache::Sling::GroupMemberUtil::add_eval($res);
    my $message = "\"$add_member\" ";
    $message .= ( $success ? 'added' : 'was not added' );
    $message .= " to group \"$act_on_group\"!";
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

                    # Second field must be user:
                    if ( $column_headings[1] !~ /^[Uu][Ss][Ee][Rr]$/msx ) {
                        croak 'Second CSV column must be the user ID, '
                          . 'column heading must be "user". '
                          . 'Found: "'
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
                if ( $csv->parse($_) ) {
                    my @columns      = $csv->fields();
                    my $columns_size = @columns;

           # Check row has same number of columns as there were column headings:
                    if ( $columns_size != $number_of_columns ) {
                        croak
"Found \"$columns_size\" columns. There should have been \"$number_of_columns\".\n"
                          . "Row contents was: $_";
                    }
                    my $act_on_group = $columns[0];
                    my $add_member   = $columns[1];
                    $group->add( $act_on_group, $add_member );
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

#{{{ sub command_line
sub command_line {
    my ( $group_member, @ARGV ) = @_;
    my $sling = Apache::Sling->new;
    my $config = $group_member->config( $sling, @ARGV );
    return $group_member->run( $sling, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $group_member, $sling, @ARGV ) = @_;
    my $group_member_config = $group_member->config_hash( $sling, @ARGV );

    GetOptions(
        $group_member_config, 'auth=s',
        'help|?',              'log|L=s',
        'man|M',               'pass|p=s',
        'threads|t=s',         'url|U=s',
        'user|u=s',            'verbose|v+',
        'add|a=s',             'additions|A=s',
        'delete|d=s',          'exists|e=s',
        'group|g=s',           'view|V'
    ) or $group_member->help();

    return $group_member_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $group_member, $sling, @ARGV ) = @_;
    my $additions;
    my $add;
    my $delete;
    my $exists;
    my $group;
    my $view;

    my %group_member_config = (
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
        'group'     => \$group,
        'view'      => \$view
    );

    return \%group_member_config;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $group, $act_on_group, $exists_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::view_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::view_eval($res);
    my $message;
    if ($success) {
        my $group_info = from_json( ${$res}->content );
        my $is_member  = 0;
        foreach my $member ( @{ $group_info->{'members'} } ) {
            if (   $member eq "/system/userManager/user/$exists_member"
                || $member eq "/system/userManager/group/$exists_member"
                || $member eq "$exists_member" )
            {
                $is_member = 1;
                last;
            }
        }
        $success = $is_member;
        $message =
            "\"$exists_member\" is "
          . ( $is_member ? q{} : 'not ' )
          . "in group \"$act_on_group\"";
    }
    else {
        $message = "Problem viewing group: \"$act_on_group\"";
    }
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub del
sub del {
    my ( $group, $act_on_group, $delete_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupMemberUtil::delete_setup(
            $group->{'BaseURL'}, $act_on_group, $delete_member
        )
    );
    my $success = Apache::Sling::GroupMemberUtil::delete_eval($res);
    my $message = "\"$delete_member\" ";
    $message .= ( $success ? 'deleted' : 'was not deleted' );
    $message .= " from group \"$act_on_group\"!";
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --additions or -A (file)       - file containing list of members to be added to groups.
 --add or -a (member)           - add specified member.
 --auth (type)                  - Specify auth type. If ommitted, default is used.
 --delete or -d (member)        - delete specified group member.
 --exists or -e (member)        - check whether specified member exists in group.
 --group or -g (actOnGroup)     - group to perform membership actions on.
 --help or -?                   - view the script synopsis and options.
 --log or -L (log)              - Log script output to specified log file.
 --man or -M                    - view the full script documentation.
 --pass or -p (password)        - Password of user performing actions.
 --threads or -t (threads)      - Used with -A, defines number of parallel
                                  processes to have running through file.
 --url or -U (URL)              - URL for system being tested against.
 --user or -u (username)        - Name of user to perform any actions as.
 --verbose or -v or -vv or -vvv - Increase verbosity of output.
 --view or -V                   - view members of specified group.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {

    my ($group_member) = @_;

    print <<'EOF';
group membership perl script. Provides a means of managing membership of groups
in sling from the command line.

EOF

    $group_member->help();

    print <<"EOF";
Example Usage

* Authenticate and add a member testuser to the group with id g-test:

 perl $0 -U http://localhost:8080 -g g-test -u admin -p admin -a testuser

* Authenticate and view members of group with id g-test:

 perl $0 -U http://localhost:8080 -g g-test -u admin -p admin -V

* Authenticate and check whether testuser is a member of group with id g-test:

 perl $0 -U http://localhost:8080 -g g-test -u admin -p admin -e testuser 

* Authenticate and remove testuser from being a member of group with id g-test with very verbose output:

 perl $0 -U http://localhost:8080 -g g-test -u admin -p admin -d testuser -vv

EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $group_member, $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No group_member config supplied!';
    }
    $sling->check_forks;
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    my $success = 1;

    if ( $sling->{'Help'} ) { $group_member->help(); }
    elsif ( $sling->{'Man'} )  { $group_member->man(); }
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
                my $group_member =
                  new Apache::Sling::GroupMember( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $group_member->add_from_file( ${ $config->{'additions'} },
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
            $group_member =
              new Apache::Sling::GroupMember( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group_member->check_exists( ${ $config->{'group'} },
                ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $group_member =
              new Apache::Sling::GroupMember( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group_member->add( ${ $config->{'group'} },
                ${ $config->{'add'} } );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $group_member =
              new Apache::Sling::GroupMember( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group_member->del( ${ $config->{'group'} },
                ${ $config->{'delete'} } );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $group_member =
              new Apache::Sling::GroupMember( \$authn, $sling->{'Verbose'},
                $sling->{'Log'} );
            $success = $group_member->view( ${ $config->{'group'} } );
        }
        else {
            $group_member->help();
            return 1;
        }
        Apache::Sling::Print::print_result($group_member);
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
    my $message;
    if ($success) {
        my $group_info     = from_json( ${$res}->content );
        my $number_members = @{ $group_info->{'members'} };
        my $members = "$number_members result(s) for group \"$act_on_group\":";
        foreach my $member ( @{ $group_info->{'members'} } ) {
            $members .= "\n$member";
        }
        $message = "$members";
        $success = $number_members;
    }
    else {

        # HTTP request did not complete successfully!
        $message = "Problem viewing group: \"$act_on_group\"";
    }
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

Add a member to a group.

=head2 add_from_file

Add members to groups based on entries in a file.

=head2 config

Fetch hash of group membership configuration.

=head2 delete

Delete member from a group.

=head2 exists

Check whether a member exists in a group.

=head2 run

Run group membership related actions.

=head2 view

View members of a group.

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
