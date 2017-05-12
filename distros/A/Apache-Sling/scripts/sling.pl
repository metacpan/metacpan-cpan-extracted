#!/usr/bin/perl

use 5.008001;
use strict;
use warnings;
use version; our $VERSION = qv('0.27');
use Carp;
use Pod::Usage;
use Apache::Sling::Authz;
use Apache::Sling::Content;
use Apache::Sling::GroupMember;
use Apache::Sling::Group;
use Apache::Sling::JsonQueryServlet;
use Apache::Sling::LDAPSynch;
use Apache::Sling::User;

# Fail if args are empty or undefined:
if ( !defined $ARGV[0] || $ARGV[0] eq q{} ) {
    croak "Type '$0 help' for usage.";
}

# Give usage info if help or man are requested:
if ( $ARGV[0] =~ /(--){0,1}help/msx ) {
    pod2usage( -exitstatus => 0, -verbose => 1 );
}
elsif ( $ARGV[0] =~ /(--){0,1}man/msx ) {
    pod2usage( -exitstatus => 0, -verbose => 2 );
}

# Run command line programs:
local $0 = "$0 " . $ARGV[0];

my %module_lookup = (
    'authz',              'Apache::Sling::Authz',
    'content',            'Apache::Sling::Content',
    'group_member',       'Apache::Sling::GroupMember',
    'group',              'Apache::Sling::Group',
    'json_query_servlet', 'Apache::Sling::JsonQueryServlet',
    'ldap_synch',         'Apache::Sling::LDAPSynch',
    'user',               'Apache::Sling::User'
);

my $module = $module_lookup{ $ARGV[0] };

if ( !defined $module ) {
    croak "Unknown command: '" . $ARGV[0] . "'\n" . "Type '$0 help' for usage.";
}

$module->command_line(@ARGV);

1;

__END__

#{{{Documentation

=head1 NAME

sling.pl

=head1 SYNOPSIS

sling perl script. Provides a means of manipulating a running sling system
from the command line.

=head1 OPTIONS

Usage: perl sling.pl [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --help or help     - view the script synopsis and options
 --man or man       - view the full script documentation
 authz              - run authz related actions
 content            - run content related actions
 group_member       - run group membership related actions
 group              - run group related actions
 json_query_servlet - run json query servlet related actions
 ldap_synch         - run ldap synchronization related actions
 user               - run user related actions

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl sling.pl --man

=head1 USAGE

=over

=item Output help for this script:

 perl sling.pl help

=item Output fuller help for this script:

 perl sling.pl man

=back

=head1 DESCRIPTION

sling perl script. Provides a means of manipulating a running sling system
from the command line.

=head1 REQUIRED ARGUMENTS

None.

=head1 DIAGNOSTICS

None.

=head1 EXIT STATUS

1 on success, otherwise failure.

=head1 CONFIGURATION

None needed.

=head1 DEPENDENCIES

Carp; Pod::Usage;

=head1 INCOMPATIBILITIES

None known (^_-)

=head1 BUGS AND LIMITATIONS

None known (^_-)

=head1 AUTHOR

Daniel Parry -- daniel@caret.cam.ac.uk

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>

=cut

#}}}
