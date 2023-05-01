package Dancer::RPCPlugin::CallbackResult;
use v5.10.1;
use warnings;
use strict;

use Exporter 'import';
our @EXPORT = qw/ callback_success callback_fail /;

use Types::Standard qw/ Int Str /;
use Params::ValidationCompiler qw/ validation_for /;

=head1 NAME

Dancer::RPCPlugin::CallbackResult - Factory for generating Callback-results.

=head1 SYNOPSIS

    use Dancer::Plugin::RPC::JSONRPC;
    use Dancer::RPCPlugin::CallbackResult;
    jsonrpc '/admin' => {
        publish => 'config',
        callback => sub {
            my ($request, $rpc_method) = @_;
            if ($rpc_method =~ qr/^admin\.\w+$/) {
                return callback_success();
            }
            else {
                return callback_fail(
                    error_code => -32768,
                    error_message => "only admin methods allowed: $rpc_method",
                );
            }
        },
    };

=head1 DESCRIPTION

=head2 callback_success()

Allows no arguments.

Returns an instantiated L<Dancer::RPCPlugin::CallbackResult::Success> object.

=cut

sub callback_success {
    die "callback_success() does not have arguments\n" if @_ > 1;
    return Dancer::RPCPlugin::CallbackResult::Success->new();
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
            error_code    => { optional => 0, type => Int },
            error_message => { optional => 0, type => Str },
        }
    )->(@_);
    return Dancer::RPCPlugin::CallbackResult::Fail->new(%data);
}

=head2 $cr->success

Returns the value of the C<success> attribute (getter only).

=cut

sub success { $_[0]->{success} }

1;

=head1 PACKAGE

Dancer::RPCPlugin::CallbackResult::Success - Class for success

=head2 new()

Constructor, does not allow any arguments.

=cut

package Dancer::RPCPlugin::CallbackResult::Success;
our @ISA = ('Dancer::RPCPlugin::CallbackResult');
use overload '""' => sub { "success" };

sub new {
    my $class = shift;
    die "No arguments allowed\n" if @_;
    return bless {success => 1}, $class;
}

=head1 PACKAGE

Dancer::RPCPlugin::CallbackResult::Fail - Class for failure

=head2 new()

Constructor, allows named arguments:

=over

=item error_code => $code

=item error_message => $message

=back

=cut

package Dancer::RPCPlugin::CallbackResult::Fail;
our @ISA = ('Dancer::RPCPlugin::CallbackResult');
use overload '""' => sub { "fail ($_[0]->{error_code} => $_[0]->{error_message})" };
use Types::Standard qw/ Int Str /;
use Params::ValidationCompiler 'validation_for';

sub new {
    my $class = shift;
    my %data = validation_for(
        params => {
            error_code    => {type => Int, optional => 0},
            error_message => {type => Str, optional => 0},
        },
    )->(@_);
    return bless {success => 0, %data}, $class;
}

=head2 $cr->error_code

Getter for the C<error_code> attribute.

=cut

sub error_code { return $_[0]->{error_code} }

=head2 $cr->error_message

Getter for the C<error_message> attribute.

=cut

sub error_message { return $_[0]->{error_message} }

=head1 COPYRIGHT

E<copy> MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
