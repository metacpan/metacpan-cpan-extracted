package Dancer::RPCPlugin::CallbackResult;
use v5.10.1;
use warnings;
use strict;

use Params::Validate ':all';

use Exporter 'import';
our @EXPORT = qw/ callback_success callback_fail /;

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
    validate_with(params => \@_, spec => {}, allow_extra => 0); # no args!
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
    my %data = validate_with(
        params => \@_,
        spec   => {
            error_code    => {regex => qr/^[+-]?\d+$/, optional => 0},
            error_message => {optional => 0},
        },
        allow_extra => 0,
    );
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
use Params::Validate ':all';
sub new {
    my $class = shift;
    validate_with(params => \@_, spec => {}, allow_extra => 0); # no args!
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
use Params::Validate ':all';
sub new {
    my $class = shift;
    my %data = validate_with(
        params => \@_,
        spec   => {
            error_code    => {regex => qr/^[+-]?\d+$/, optional => 0},
            error_message => {optional => 0},
        },
        allow_extra => 0,
    );
    return bless {success => 0, %data}, $class;
}

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
