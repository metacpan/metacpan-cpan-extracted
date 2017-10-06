package Dancer::RPCPlugin::DispatchMethodList;
use warnings;
use strict;

use Exporter 'import';
our @EXPORT = ('list_methods');

use Types::Standard qw/ StrMatch ArrayRef /;
use Params::ValidationCompiler 'validation_for';

=head1 NAME

Dancer::RPCPlugin::DispatchMethodList - Class for maintaining a global methodlist.

=head1 SYNOPSIS

    use Dancer::RPCPlugin::DispatchMethodList;
    my $methods = Dancer::RPCPlugin::DispatchMethodList->new();

    $methods->set_partial(
        protocol => <jsonrpc|restrpc|xmlrpc>,
        endpoint => </configured>,
        methods  => [ @method_names ],
    );

    # ....
    my $method_list = $methods->list_methods(protocol => <any|jsonrpc|restrpc|xmlrpc>);

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

=item protocol => <jsonrpc|restrpc|xmlrpc> (required)

=item endpoint => $endpoint                (required)

=item methods => \@method_list

=back

=head3 Responses

    $self

=cut

sub set_partial {
    my $self = shift;
    my %args = validation_for(
        params => {
            protocol => {type => StrMatch[ qr/^(?:json|xml|rest)rpc$/ ], optional => 0},
            endpoint => {type => StrMatch[ qr/^.*$/] , optional => 0},
            methods  => {type => ArrayRef},
        },
    )->(@_);
    $self->{protocols}{$args{protocol}}{$args{endpoint}} = $args{methods};
    return $self;
}

=head2 list_methods(@parameters)

Method that returns information about the dispatch-table.

=head3 Parameters

Positional, list

=over

=item 1. $protocol => undef || <any|jsonrpc|restrpc|xmlrpc>  (optional)

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
    my $self = shift;
    my ($protocol) = validation_for(
        params => [
            {
                type     => StrMatch [qr/^(?:any|(?:json|rest|xml)rpc)$/],
                default  => 'any',
            },
        ],
    )->(@_);

    if ($protocol eq 'any') {
        return $self->{protocols};
    }
    else {
        return $self->{protocols}{$protocol};
    }
}

1;

=head1 COPYRIGHT

(c) MMXVI - Abe Timmerman <abeltje@cpan.org>

=cut
