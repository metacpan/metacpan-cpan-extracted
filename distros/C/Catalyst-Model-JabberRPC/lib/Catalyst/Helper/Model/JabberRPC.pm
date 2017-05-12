package Catalyst::Helper::Model::JabberRPC;
use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::JabberRPC - Helper for JabberRPC models

=head1 SYNOPSIS

 script/myapp_create.pl model RemoteService JabberRPC myserver.org user:password jrpc.myserver.org/rpc-server

=head1 DESCRIPTION

Helper for the L<Catalyst> JabberRPC model.

=head1 USAGE

When creating a new JabberRPC model class using this helper, you can
specify much of the configuration and have it filled automatically.
Using the example from the L</SYNOPSIS> section:

=over

=item * C<RemoteService>

The name of the model.  This is also used to determine the filename,
e.g. C<lib/MyApp/Model/RemoteService.pm>.

=item * C<JabberRPC>

The helper to use, i.e. this one.

=item * C<myserver.org>

The same as the B<server> arg. passed to L<Jabber::RPC::Client>.

=item * C<user:password>

The same as the B<identauth> arg. passed to L<Jabber::RPC::Client>.

=item * C<jrpc.myserver.org/rpc-server>

The same as the B<endpoint> arg. passed to L<Jabber::RPC::Client>.

=back

=head1 METHODS

=head2 mk_compclass

Makes the JabberRPC model class.

=cut

sub mk_compclass {
    my ($self, $helper, $server, $identauth, $endpoint) = @_;

    $helper->{server} = $server || '';
    $helper->{identauth} = $identauth || '';
    $helper->{endpoint} = $endpoint || '';

    $helper->render_file('modelclass', $helper->{file});

    return 1;
}

=head2 mk_comptest

Makes tests for the JabberRPC model.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;

    $helper->render_file('modeltest', $helper->{test});
}

=head1 SEE ALSO

=over 1

=item * L<Catalyst::Model::JabberRPC>

=item * L<Catalyst::Helper>

=item * L<Catalyst::Manual>

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
use base 'Catalyst::Model::JabberRPC';

__PACKAGE__->config(
    server => '[% server %]',
    identauth => '[% identauth %]',
    endpoint => '[% endpoint %]',
    # For more options take a look at L<Jabber::RPC::Client>.
);

=head1 NAME

[% class %] - JabberRPC Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

JabberRPC Catalyst model component.

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

