package Dancer::Plugin::RPC;
use warnings;
use strict;

our $VERSION = '1.04';

1;

=head1 NAME

Dancer::Plugin::RPC - Configure endpoints for XMLRPC and JSONRPC procedures

=head1 DESCRIPTION

This module contains two plugins for L<Dancer>: L<Dancer::Plugin::RPC::XMLRPC>
and L<Dancer::Plugin::RPC::JSONRPC>. They are plugins rather than
Plack::Middleware.

=head2 Dancer::Plugin::RPC::XMLRPC

This plugin exposes the new keyword C<xmlrpc> that is followed by 2 arguments:
the endpoint and the arguments to configure the xmlrpc-calls at this endpoint.

=head2 Dancer::Plugin::RPC::JSONRPC

This plugin exposes the new keyword C<jsonrpc> that is followed by 2 arguments:
the endpoint and the arguments to configure the jsonrpc-calls at this endpoint.

=head2 General arguments to xmlrpc/jsonrpc

The dispatch table is build by endpoint.

=head3 publish => <config|pod|$coderef>

=over

=item publish => B<config>

The dispatch table is build from the YAML-config:

    plugins:
        'RPC::XMLRPC':
            '/endpoint1':
                'Module::Name1':
                    method1: sub1
                    method2: sub2
                'Module::Name2':
                    method3: sub3
            '/endpoint2':
                'Module::Name3':
                    method4: sub4

The B<arguments> argument should be empty for this publishing type.

=item publish => B<pod>

The dispatch table is build by parsing the POD for C<=for xmlrpc> or C<=for jsonrpc>.

    =for xmlrpc <method_name> <sub_name>

The B<arguments> argument must be an Arrayref with module names. The
POD-directive must be in the same file as the code!

=item publish => B<$coderef>

With this publishing type, you will need to build your own dispatch table and return it.

    use Dancer::RPCPlugin::DispatchItem;
    return {
        method1 => dispatch_item(
            package => 'Module::Name1',
            code => Module::Name1->can('sub1'),
        ),
        method2 => dispatch_item(
            package => 'Module::Name1',
            code    => Module::Name1->can('sub2'),
        ),
        method3 => dispatch_item(
            pacakage => 'Module::Name2',
            code     => Module::Name2->can('sub3'),
        ),
    };

=back

=head3 arguments => $list

This argumument is needed for publishing type B<pod> and must be a list of
module names that contain the pod (and code).

=head3 callback => $coderef

The B<callback> argument may contain a C<$coderef> that does additional checks
and should return a L<Dancer::RPCPlugin::CallbackResult> object.

    $callback->($request, $method_name, @method_args);

Returns for success: C<< callback_success() >>

Returns for failure: C<< callback_fail(error_code => $code, error_message => $msg) >>

This is useful for ACL checking.

=head3 code_wrapper => $coderef

The B<code_wrapper> argument can be used to wrap the code (from the dispatch table).

    my $wrapper = sub {
        my $code   = shift;
        my $pkg    = shift;
        my $method = shift;
        my $instance = $pkg->new();
        $instance->$code(@_);
    };

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
