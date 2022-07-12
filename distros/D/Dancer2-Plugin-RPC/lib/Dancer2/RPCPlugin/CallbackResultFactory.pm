package Dancer2::RPCPlugin::CallbackResultFactory;
use warnings;
use strict;

our $VERSION = '2.00';

use Exporter 'import';
our @EXPORT = qw/ callback_success callback_fail /;

use Params::ValidationCompiler 'validation_for';
use Types::Standard qw/ Int Str /;
use Dancer2::RPCPlugin::CallbackResult::Success;
use Dancer2::RPCPlugin::CallbackResult::Fail;

=head1 NAME

Dancer2::RPCPlugin::CallbackResult - Factory for generating Callback-results.

=head1 SYNOPSIS

    use Dancer2::Plugin::RPC::JSON;
    use Dancer2::RPCPlugin::CallbackResultFactory;
    jsonrpc '/admin' => {
        publish => 'config',
        callback => sub {
            my ($request, $rpc_method) = @_;
            if ($rpc_method =~ qr/^admin\.\w+$/) {
                return callback_success();
            }
            return callback_fail(
                error_code => -32768,
                error_message => "only admin methods allowed: $rpc_method",
            );
        },
    };

=head1 DESCRIPTION

This module exports 2 factory subs: C<callback_success> and C<callback_fail>.

=head2 callback_success()

Allows no arguments.

Returns an instantiated L<Dancer::RPCPlugin::CallbackResult::Success> object.

=cut

sub callback_success {
    die "callback_success() does not have arguments\n" if @_ > 1;
    return Dancer2::RPCPlugin::CallbackResult::Success->new();
}

=head2 callback_fail(%arguments)

Allows these named arguments:

=over

=item error_code => $code

=item error_message => $message

=back

Returns an instantiated L<Dancer::RPCPlugin::CallbackResult::Fail> object.

=cut

sub callback_fail {
    my %data = validation_for(
        params => {
            error_code    => {optional => 0, type => Int},
            error_message => {optional => 0, type => Str},
        }
    )->(@_);
    return Dancer2::RPCPlugin::CallbackResult::Fail->new(%data);
}

1;

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
