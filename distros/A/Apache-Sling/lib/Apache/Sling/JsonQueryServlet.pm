#!/usr/bin/perl -w

package Apache::Sling::JsonQueryServlet;

use 5.008001;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use Apache::Sling;
use Apache::Sling::JsonQueryServletUtil;
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
    my $json_query_servlet = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $json_query_servlet, $class;
    return $json_query_servlet;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $json_query_servlet, $message, $response ) = @_;
    $json_query_servlet->{'Message'}  = $message;
    $json_query_servlet->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub all_nodes
sub all_nodes {
    my ($json_query_servlet) = @_;
    my $res = Apache::Sling::Request::request(
        \$json_query_servlet,
        Apache::Sling::JsonQueryServletUtil::all_nodes_setup(
            $json_query_servlet->{'BaseURL'}
        )
    );
    my $success = Apache::Sling::JsonQueryServletUtil::all_nodes_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem fetching all nodes"
    );
    $json_query_servlet->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $json_query_servlet, @ARGV ) = @_;
    my $sling = Apache::Sling->new;
    my $config = $json_query_servlet->config( $sling, @ARGV );
    return $json_query_servlet->run( $sling, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $json_query_servlet, $sling, @ARGV ) = @_;

    my $json_query_servlet_config = $json_query_servlet->config_hash( $sling, @ARGV );

    GetOptions(
        $json_query_servlet_config, 'auth=s',
        'help|?',                    'log|L=s',
        'man|M',                     'pass|p=s',
        'threads|t=s',               'url|U=s',
        'user|u=s',                  'verbose|v+',
        'all_nodes|a'
    ) or $json_query_servlet->help();

    return $json_query_servlet_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $json_query_servlet, $sling, @ARGV ) = @_;
    my $all_nodes;

    my %json_query_servlet_config = (
        'auth'      => \$sling->{'Auth'},
        'help'      => \$sling->{'Help'},
        'log'       => \$sling->{'Log'},
        'man'       => \$sling->{'Man'},
        'pass'      => \$sling->{'Pass'},
        'threads'   => \$sling->{'Threads'},
        'url'       => \$sling->{'URL'},
        'user'      => \$sling->{'User'},
        'verbose'   => \$sling->{'Verbose'},
        'all_nodes' => \$all_nodes
    );

    return \%json_query_servlet_config;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --all_nodes or -a                 - Return a JSON representation of all nodes in the system.
 --auth (type)                     - Specify auth type. If ommitted, default is used.
 --help or -?                      - view the script synopsis and options.
 --log or -L (log)                 - Log script output to specified log file.
 --man or -M                       - view the full script documentation.
 --pass or -p (password)           - Password of user performing json queries.
 --threads or -t (threads)         - Used with -A, defines number of parallel
                                     processes to have running through file.
 --url or -U (URL)                 - URL for system being tested against.
 --user or -u (username)           - Name of user to perform queries as.
 --verbose or -v or -vv or -vvv    - Increase verbosity of output.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {

    my ($json_query_servlet) = @_;

    print <<'EOF';
json_query_servlet perl script. Provides a means of querying content in sling
from the command line. The script also acts as a reference implementation for
the JSON Query Servlet perl library.

EOF

    $json_query_servlet->help();

    print <<"EOF";
Example Usage

* Query all nodes in the system:

 perl $0 -U http://localhost:8080 -a -u admin -p admin
EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $json_query_servlet, $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No json query servlet config supplied!';
    }
    $sling->check_forks;
    ${ $config->{'remote'} } =
      Apache::Sling::URL::strip_leading_slash( ${ $config->{'remote'} } );
    ${ $config->{'remote-source'} } = Apache::Sling::URL::strip_leading_slash(
        ${ $config->{'remote-source'} } );

    my $authn = new Apache::Sling::Authn( \$sling );
    $authn->login_user();
    my $success = 1;
    if ( $sling->{'Help'} ) { $json_query_servlet->help(); }
    elsif ( $sling->{'Man'} )  { $json_query_servlet->man(); }
    elsif ( defined ${ $config->{'all_nodes'} } ) {
        $json_query_servlet =
          new Apache::Sling::JsonQueryServlet( \$authn, $sling->{'Verbose'},
            $sling->{'Log'} );
        $success = $json_query_servlet->all_nodes();
    }
    else {
        $json_query_servlet->help();
        return 1;
    }
    Apache::Sling::Print::print_result($json_query_servlet);
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::JsonQueryServlet - Query the JCR layer via the apache sling JSON query servlet.

=head1 ABSTRACT

query related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a JSON Query Servlet object

=head2 set_results

Set a suitable message and response for the json query object.

=head2 all_nodes

Return all nodes in the sling system in JSON format.

=head2 config

Fetch hash of json query servlet configuration.

=head2 run

Run json query server related actions.

=head1 USAGE

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST JSON query servlet methods

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
