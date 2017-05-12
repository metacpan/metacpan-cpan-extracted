#!/usr/bin/perl -w

package Apache::Sling::JsonQueryServletUtil;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub all_nodes_setup

sub all_nodes_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    return "get $base_url/content.query.json?queryType=xpath&statement=//*";
}

#}}}

#{{{sub all_nodes_eval

sub all_nodes_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::JsonQueryServletUtil - Methods to generate and check HTTP requests required for querying.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
content operations in the system.

=head1 METHODS

=head1 USAGE

use Apache::Sling::JsonQueryServletUtil;

=head1 DESCRIPTION

JsonQueryServletUtil perl library essentially provides the request strings
needed to perform queries against the jackrabbit repository embedded in sling.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=head1 METHODS

=head2 all_nodes_setup

Returns a textual representation of the request needed to return a JSON
representation of all nodes in the system.

=head2 all_nodes_eval

Check result of all_nodes call.

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
