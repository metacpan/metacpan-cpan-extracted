#!/usr/bin/perl -w

package Apache::Sling::AuthnUtil;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub basic_login_setup
sub basic_login_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    return "get $base_url/system/sling/login?sling:authRequestLogin=1";
}

#}}}

#{{{sub basic_login_eval
sub basic_login_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::AuthnUtil - Methods to generate and check HTTP requests required for authentication.

=head1 ABSTRACT

useful utility functions for general Authn functionality.

=head1 METHODS

=head2 basic_login_setup

Returns a textual representation of the request needed to log the user in to
the system via a basic auth based login.

=head2 basic_login_eval

Verify whether the log in attempt for the user to the system was successful.

=head1 USAGE

use Apache::Sling::AuthnUtil;

=head1 DESCRIPTION

Utility library providing useful utility functions for general Authn functionality.

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
