package Catalyst::Helper::Model::XMLRPC;
use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::XMLRPC - Helper for XMLRPC models

=head1 SYNOPSIS

 script/myapp_create.pl model RemoteService XMLRPC http://webservice.example.com:9000

=head1 DESCRIPTION

Helper for the L<Catalyst> XMLRPC model.

=head1 USAGE

When creating a new XMLRPC model class using this helper, you can
specify much of the configuration and have it filled automatically.
Using the example from the L</SYNOPSIS> section:

=over

=item * C<RemoteService>

The name of the model.  This is also used to determine the filename,
e.g. C<lib/MyApp/Model/RemoteService.pm>.

=item * C<XMLRPC>

The helper to use, i.e. this one.

=item * C<http://webservice.example.com:9000>

The XMLRPC webservice fully qualified domain name (FQDN).  Can also be an
IP address, e.g. C<127.0.0.1>. Followed by the port number, separated by
colons.

=back

=head1 METHODS

=head2 mk_compclass

Makes the XMLRPC model class.

=cut

sub mk_compclass {
    my ($self, $helper, $location) = @_;

    $helper->{location} = $location || '';

    $helper->render_file('modelclass', $helper->{file});

    return 1;
}

=head2 mk_comptest

Makes tests for the XMLRPC model.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;

    $helper->render_file('modeltest', $helper->{test});
}

=head1 SEE ALSO

=over 1

=item * L<Catalyst::Model::XMLRPC>

=item * L<Catalyst::Helper>

=item * L<Catalyst::Manual>

=back

=head1 ACKNOWLEDGEMENTS

=over 1

=item * Daniel Westermann-Clark's module, L<Catalyst::Model::LDAP>, it was my reference.

=back

=head1 AUTHOR

Florian Merges E<lt>fmerges@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use strict;
use warnings;
use base 'Catalyst::Model::XMLRPC';

__PACKAGE__->config(
    location => '[% location %]',
    # For more options take a look at L<RPC::XML::Client>.
);

=head1 NAME

[% class %] - XMLRPC Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

XMLRPC Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');

