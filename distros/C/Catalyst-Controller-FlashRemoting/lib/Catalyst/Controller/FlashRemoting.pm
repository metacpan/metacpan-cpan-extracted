package Catalyst::Controller::FlashRemoting;
use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->mk_accessors(qw/_amf_method/);

our $VERSION = '0.02';

sub new {
    my $self = shift->NEXT::new(@_);
    $self->{_amf_method} = {};

    $self;
}

sub _parse_AMFGateway_attr {
    my ($self, $c, $name, $value) = @_;

    return ActionClass => 'Catalyst::Controller::FlashRemoting::Action::Gateway',
}

sub _parse_AMFMethod_attr {
    my ($self, $c, $name, $value) = @_;

    my $method = $value || $name;
    $self->_amf_method->{ $method } = $self->can($name);

    return 'Private';
}

=head1 NAME

Catalyst::Controller::FlashRemoting - Catalyst controller for Flash Remoting

=head1 SYNOPSIS

    package MyApp::Controller::Gateway;
    use strict;
    use warnings;
    use base qw/Catalyst::Controller::FlashRemoting/;
    
    sub gateway :Path :AMFGateway { }
    
    sub echo :AMFMethod {
        my ($self, $c, $args) = @_;
    
        return $args;
    }
    
    sub sum :AMFMethod('sum') {
        my ($self, $c, $args) = @_;
    
        return $args->[0] + $args->[1];
    }

=head1 DESCRIPTION

Catalyst::Controller::FlashRemoting is a Catalyst controller that provide easy interface for Flash Remoting.

Flash Remoting is RPC subsystem and that use AMF (Action Message Format) as message body format.

=head1 USAGE

At first, you need api gateway (endpoint) controller. Add AMFGateway attribute to catalyst action for that.

    sub gateway :Local :AMFGateway { }

If you write above code in Root controller, then 'http://localhost:3000/gateway' is AMF Gateway url.

To use this gateway, write actionscript3 like this:

    var nc:NecConnection = new NetConnection();
    nc.connect("http://localhost:3000/gateway");

Second, you need create some methods.

    sub echo :AMFMethod {
        my ($self, $c, $args) = @_;
        return $args;
    }
    
    sub sum :AMFMethod('sum') {
        my ($self, $c, $args) = @_;
    
        return $args->[0] + $args->[1];
    }

'echo' is echoback method that just return same object to request, and 'sum' method sum up two arguments and return the result.

To call these methods, write actionscript3 like this:

    nc.call("echo", responder, "foo bar");  // result "foo bar"
    nc.call("sum", responder, 1, 2);        // result 3

responder is actionscript3's Responder object. see flex/flash docs for detail.

=head1 ACTION ATTRIBUTES

=head2 AMFGateway

This attribute makes the controller to act as AMF Gateway. the controller automatically parse AMF request, dispatch amf method (see AMFMethod attribute below), and serialize response and return.

=head2 AMFMethod($method_name)

This attribute makes the controller to act as AMF Method. This is called from AMFGateway, and don't have to be catalyst controller.

$method_name argument is optional. When no $method_name passed, the actual method name is used as amf method name.

=head1 METHODS

=head2 new

=head2 _parse_AMFGateway_attr

=head2 _parse_AMFMethod_attr

=head1 SEE ALSO

L<Data::AMF>, L<Data::AMF::Packet>.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
