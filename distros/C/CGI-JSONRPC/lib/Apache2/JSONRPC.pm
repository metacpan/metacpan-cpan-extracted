#!perl

package Apache2::JSONRPC;

use Apache2::Const qw(
    TAKE1 OR_ALL OK HTTP_BAD_REQUEST SERVER_ERROR M_GET M_POST
);
use Apache2::RequestRec ();
use Apache2::CmdParms ();
use Apache2::RequestIO ();
use Apache2::Directive ();
use Apache2::Log ();
use Apache2::Module ();
use CGI::JSONRPC::Base;

use base qw(CGI::JSONRPC::Base Apache2::Module);

our $VERSION = "0.02";

__PACKAGE__->add([ CookOptions(
    [
        'JSONRPC_Class',
        'Perl class to dispatch JSONRPC calls to.',
    ],
)]);

return 1;


sub CookOptions { return(map { CookOption(@$_) } @_); }

sub CookOption {
    my($option, $help) = @_;
    return +{
        name            =>      $option,
        func            =>      join('::', __PACKAGE__, 'SetOption'),
        args_how        =>      TAKE1,
        req_override    =>      OR_ALL,
        $help ? (errmsg =>      "$option: $help") : (),
    };
}

sub SetOption {
    my($self, $param, $value) = @_;
    $self->{$param->directive->directive} = $value;
}

##

sub apache2_config {
    my ($class, $r) = @_;
    my $dir_config = __PACKAGE__->get_config($r->server, $r->per_dir_config) || {};
    my $srv_config = __PACKAGE__->get_config($r->server) || {};
    my $config = { %$srv_config, %$dir_config };
    $config;
}

sub handler {
    my($class, $r) = @_;
    my $self = $class->new(
        path            =>  $r->uri(),
        path_info       =>  $r->path_info(),
        request         =>  $r
    );

    $self->{path_info} =~ s{^/|/$}{}g;
    $self->{path_info} =~ s{//}{/}g;

    if($r->method_number == M_GET || $r->header_only) {
        $r->content_type("text/javascript");
        $r->print($self->return_javascript);
        return OK;
    } elsif($r->method_number == M_POST) {
        my $json = $self->apache2_read_post($r) or return HTTP_BAD_REQUEST;
        $r->content_type("text/json");
        
        $r->print($self->run_json_request($json));
        return OK;
    } else {
        $r->log_reason("Unsupported method " . $r->method);
        return HTTP_BAD_REQUEST;
    }
}

sub default_dispatcher {
    my $class = shift;
    my $request = Apache2::RequestUtil->request;
    my $config = $class->apache2_config($request);
    return
        $config->{JSONRPC_Class} ||
        $class->SUPER::default_dispatcher($class);
}

sub apache2_read_post {
    my($self, $r) = @_;

    my $length;
    unless($length = $r->headers_in->{'Content-Length'}) {
        $r->log_error("No JSONRPC content sent!");
        return;
    }
    
    my $buffer = "";
    my $actual = $r->read($buffer, $length);
    
    unless($actual == $length) {
        $r->log_error("Expected $length bytes, only got $actual back!");
        return;
    }
    
    return $buffer;
}

=pod

=head1 NAME

Apache2::JSONRPC - mod_perl handler for JSONRPC


=head1 SYNOPSIS

  <Location /json-rpc>
      SetHandler              perl-script
      PerlOptions             +GlobalRequest
      PerlResponseHandler     Apache2::JSONRPC->handler
      JSONRPC_Class           CGI::JSONRPC::Dispatcher
  </Location>

=head1 DESCRIPTION

Apache2::JSONRPC is a subclass of CGI::JSONRPC that provides some
extra bells and whistles in a mod_perl2 environment.

Currently, the main feature is the "JSONRPC_Class" apache2 config
directive, which allows you to define what class to use for
invoking JSONRPC methods. The default is the same as CGI::JSONRPC uses,
L<CGI::JSONRPC::Dispatcher|CGI::JSONRPC::Dispatcher>.

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net> and
David Labatte <buggyd@justanotherperlhacker.com>.

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

The "examples" directory (examples/hello-cgi.html & examples/jsonrpc.cgi),
L<CGI::JSONRPC>.

=cut
