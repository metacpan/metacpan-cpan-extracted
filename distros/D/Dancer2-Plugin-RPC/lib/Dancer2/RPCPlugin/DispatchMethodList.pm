package Dancer2::RPCPlugin::DispatchMethodList;
use Moo;

with qw(
    Dancer2::RPCPlugin::ValidationTemplates
    MooX::Params::CompiledValidators
);

our $VERSION = '2.00';

use Types::Standard qw( HashRef );

=head1 NAME

Dancer2::RPCPlugin::DispatchMethodList - Class for maintaining a global methodlist.

=head1 SYNOPSIS

    use Dancer2::RPCPlugin::DispatchMethodList;
    my $methods = Dancer2::RPCPlugin::DispatchMethodList->new();

    $methods->set_partial(
        protocol => <jsonrpc|restrpc|xmlrpc>,
        endpoint => </configured>,
        methods  => [ @method_names ],
    );

    # Somewhere else
    my $dml = Dancer2::RPCPlugin::DispatchMethodList->new();
    my $methods = $dml->list_methods(<any|jsonrpc|restrpc|xmlrpc>);

=head1 DESCRIPTION

This class implements a singleton that can hold the collection of all method names.

=head2 my $dml = Dancer2::RPCPlugin::DispatchMethodList->new()

=head3 Parameters

None!

=head3 Responses

    $singleton = bless $parameters, $class;

=cut

has protocol => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

my $_singleton;
around new => sub {
    return $_singleton if $_singleton;

    my ($orig, $self) = (shift, shift);
    $_singleton = $self->$orig(@_);
};

=head2 $dml->set_partial(%parameters)

=head3 Parameters

Named, list:

=over

=item protocol => <jsonrpc|restrpc|xmlrpc>

=item endpoint => $endpoint

=item methods => \@method_list

=back

=head3 Responses

    $self

=cut

sub set_partial {
    my $self = shift;
    $self->validate_parameters(
        {
            $self->parameter(protocol => $self->Required, {store => \my $protocol}),
            $self->parameter(endpoint => $self->Required, {store => \my $endpoint}),
            $self->parameter(methods  => $self->Required, {store => \my $methods}),
        },
        { @_ }
    );

    $self->protocol->{$protocol}{$endpoint} = $methods;
    return $self;
}

=head2 $dml->list_methods(@parameters)

Method that returns information about the dispatch-table.

=head3 Parameters

Positional, list:

=over

=item $protocol => undef || <any|jsonrpc|restrpc|xmlrpc>

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
    $self->validate_positional_parameters(
        [ $self->parameter(any_protocol => $self->Optional, {store => \my $protocol}) ],
        [ @_ ]
    );
    if ($protocol eq 'any') {
        return $self->protocol;
    }
    else {
        return $self->protocol->{$protocol};
    }
}

around ValidationTemplates => sub {
    my ($orig, $class) = splice(@_, 0, 2);
    my $templates = $class->$orig(@_);

    use Dancer2::RPCPlugin::PluginNames;
    use Types::Standard qw( StrMatch);

    my $any_plugin = join("|", Dancer2::RPCPlugin::PluginNames->new->names, 'any');
    $templates->{any_plugin} = {
        type    => StrMatch [qr/(?:$any_plugin)/],
        default => 'any'
    };

    return $templates;
};

use namespace::autoclean;
1;

=head1 COPYRIGHT

(c) MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
