package Dancer::RPCPlugin::DispatchMethodList;
use warnings;
use strict;
use Params::Validate ':all';

use Exporter 'import';
our @EXPORT = ('list_methods');

=head1 NAME

Dancer::RPCPlugin::DispatchMethodList - Class for maintaining a global methodlist.

=head1 SYNOPSIS

    use Dancer::RPCPlugin::DispatchMethodList;
    my $methods = Dancer::RPCPlugin::DispatchMethodList->new();

    $methods->set_partial(
        protocol => <jsonrpc|xmlrpc>,
        endpoint => </configured>,
        methods  => [ @method_names ],
    );

    # ....
    my $methods = list_methods(<any|jsonrpc|xmlrpc>);

=head1 DESCRIPTION

This class implements a singleton that can hold the collection of all method names.

=head2 my $dml = Dancer::RPCPlugin::DispatchMethodList->new()

=head3 Parameters

None!

=head3 Responses

    $singleton = bless $parameters, $class;

=cut

my $singleton;
sub new {
    return $singleton if $singleton;

    my $class = shift;
    $singleton = bless {protocol => {}}, $class;
}

=head2 $dml->set_partial(%parameters)

=head3 Parameters

Named, list:

=over

=item protocol => <jsonrpc|xmlrpc>

=item endpoint => $endpoint

=item methods => \@method_list

=back

=head3 Responses

    $self

=cut

sub set_partial {
    my $self = shift;
    my $args = validate_with(
        params => \@_,
        spec   => {
            protocol => {regex => qr/^(?:json|xml|rest)rpc$/, optional => 0},
            endpoint => {regex => qr/^.*$/, optional => 0},
            methods  => {type => ARRAYREF},
        },
    );
    $self->{protocols}{$args->{protocol}}{$args->{endpoint}} = $args->{methods};
    return $self;
}

=head2 list_methods(@parameters)

This is not a method, but an exported function.

=head3 Parameters

Positional, list:

=over

=item $protocol => undef || <any|jsonrpc|xmlrpc>

=back

=head3 Responses

In case of no C<$protocol>:

    {
        xmlrpc => {
            $endpoint1 => [ list ],
            $endpoint2 => [ list ],
        },
        jsonrpc => {
            $endpoint1 => [ list ],
            $endpoint2 => [ list ],
        },
    }

In case of specified C<$protocol>:

    {
        $endpoint1 => [ list ],
        $endpoint2 => [ list ],
    }

=cut

sub list_methods {
    my ($protocol) = validate_pos(
        @_,
        {default => 'any', regex => qr/^any|jsonrpc|xmlrpc$/, optional => 1}
    );
    if ($protocol eq 'any') {
        return $singleton->{protocols};
    }
    else {
        return $singleton->{protocols}{$protocol};
    }
}

1;

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
