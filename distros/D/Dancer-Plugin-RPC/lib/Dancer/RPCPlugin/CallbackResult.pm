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

sub AUTOLOAD {
    my $self = shift;
    (my $attribute = our $AUTOLOAD) =~ s/.*:://;
    return $self->{$attribute} if exists $self->{$attribute};
    die "Unknown attribute $attribute\n";
}
sub DESTROY { }
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

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
