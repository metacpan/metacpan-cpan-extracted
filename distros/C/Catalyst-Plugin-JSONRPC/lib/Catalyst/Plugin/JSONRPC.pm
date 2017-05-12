package Catalyst::Plugin::JSONRPC;

use strict;
our $VERSION = '0.01';

use JSON ();

sub json_rpc {
    my $c = shift;
    my $attrs = @_ > 1 ? {@_} : $_[0];

    my $body    = $c->req->body;
    my $content = do { local $/; <$body> };

    my $req;
    eval { $req = JSON::jsonToObj($content) };
    if ($@ || !$req) {
        $c->log->debug(qq/Invalid JSON-RPC request: "$@"/);
        $c->res->content_type('text/javascript+json');
        $c->res->body(JSON::objToJson({
            result => undef,
            error  => 'Invalid request',
        }));
        return 0;
    }

    my $res = 0;

    my $method = $attrs->{method} || $req->{method};
    if ($method) {
        my $class = $attrs->{class} || caller(0);
        if (my $code = $class->can($method)) {

            my $remote;
            my $attrs = attributes::get($code) || [];
            for my $attr (@$attrs) {
                $remote++ if $attr eq 'Remote';
            }

            if ($remote) {
                $class = $c->components->{$class} || $class;
                my @args = @{ $c->req->args };
                $c->req->args( $req->{params} );
                my $name = ref $class || $class;
                my $action = Catalyst::Action->new(
                    {
                        name      => $method,
                        code      => $code,
                        reverse   => "-> $name->$method",
                        class     => $name,
                        namespace => Catalyst::Utils::class2prefix(
                            $name, $c->config->{case_sensitive}
                        ),
                    }
                );
                $c->state( $c->execute( $class, $action ) );
                $res = $c->state;
                $c->req->args( \@args );
            }
            else {
                $c->log->debug(qq/Method "$method" has no Remote attribute/)
                  if $c->debug;
            }
        }
        else {
            $c->log->debug(qq/Couldn't find JSON-RPC method "$method"/)
              if $c->debug;
        }

    }

    $c->res->content_type('text/javascript+json');
    $c->res->body(JSON::objToJson({
        result => $res,
        error  => undef,
        id     => $req->{id},
    }));

    return $res;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::JSONRPC - Dispatch JSON-RPC methods with Catalyst

=head1 SYNOPSIS

  # include it in plugin list
  use Catalyst qw/JSONRPC/;

  # Public action to redispatch
  sub entrypoint : Global {
      my ( $self, $c ) = @_;
      $c->json_rpc;
  }

  # Methods with Remote attribute in the same class
  sub echo : Remote {
      my ( $self, $c, @args ) = @_;
      return join ' ', @args;
  }

=head1 DESCRIPTION

Catalyst::Plugin::JSONRPC is a Catalyst plugin to add JSON-RPC methods
in your controller class. It uses a same mechanism that XMLRPC plugin
does and actually plays really nicely.

=head2 METHODS

=over 4

=item $c->json_rpc(%attrs)

Call this method from a controller action to set it up as a endpoint
for RPC methods in the same class.

Supported attributes:

=over 8

=item class

name of class to dispatch (defaults to current one)

=item method

method to dispatch to (overrides JSON-RPC method name)

=back

=back

=head2 REMOTE ACTION ATTRIBUTE

This module uses C<Remote> attribute, which indicates that the action
can be dispatched through RPC mechanisms. You can use this C<Remote>
attribute and integrate JSON-RPC and XML-RPC together, for example:

  sub xmlrpc_endpoint : Regexp('^xml-rpc$') {
      my($self, $c) = @_;
      $c->xmlrpc;
  }

  sub jsonrpc_endpoint : Regexp('^json-rpc$') {
      my($self, $c) = @_;
      $c->json_rpc;
  }

  sub add : Remote {
      my($self, $c, $a, $b) = @_;
      return $a + $b;
  }

Now C<add> RPC method can be called either as JSON-RPC or
XML-RPC.

=head1 AUTHOR & LICENSE

Six Apart, Ltd. E<lt>cpan@sixapart.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS

Thanks to Sebastian Riedel for his L<Catalyst::Plugin::XMLRPC>, from
which a lot of code is copied.

=head1 SEE ALSO

L<Catalyst::Plugin::XMLRPC>, C<JSON>, C<JSONRPC>

=cut
