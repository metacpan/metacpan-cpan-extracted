package Dancer::RPCPlugin::DispatchItem;
use v5.10.1;
use warnings;
use strict;

our $VERSION = '0.10';

use Exporter 'import';
our @EXPORT = qw/ dispatch_item /;

use Params::Validate ':all';

=head1 NAME

Dancer::RPCPlugin::DispatchItem - Small object to handle dispatch-table items

=head1 SYNOPSIS

    use Dancer::RPCPlugin::DispatchItem;
    use Dancer::Plugin::RPC::JSONRPC;
    jsonrpc '/json' => {
        publish => sub {
            return {
                'system.ping' => dispatch_item(
                    code    => MyProject::Module1->can('sub1'),
                    package => 'Myproject::Module1',
                ),
            };
        },
    };

=head1 EXPORT

=head2 dispatch_item(%arguments)

=head3 Arguments

Named:

=over

=item code => $code_ref [Required]

=item package => $package [Optional]

=back

=head1 DESCRIPTION

=head2 Dancer::RPCPlugin::DispatchItem->new(%arguments)

=head3 Arguments

Named:

=over

=item code => $code_ref [Required]

=item package => $package [Optional]

=back

=head2 $di->code

Getter for the C<code> attibute.

=head2 $di->package

Getter for the C<package> attribute

=cut

sub new {
    my $class = shift;
    my $self = validate_with(
        params => \@_,
        spec => {
            code    => {optional => 0},
            package => {optional => 1},
        },
        allow_extra => 0,
    );
    return bless $self, $class;
}
sub code    { $_[0]->{code} }
sub package { $_[0]->{package} // '' }

sub dispatch_item {
    my %args = validate_with(
        params => \@_,
        spec => {
            code    => {optional => 0},
            package => {optional => 1},
        },
        allow_extra => 0,
    );
    return Dancer::RPCPlugin::DispatchItem->new(%args);
}

1;

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abetim@cpan.org>

=cut
