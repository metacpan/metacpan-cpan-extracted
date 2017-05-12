package CGI::Application::Plugin::ProtectCSRF;

=pod

=head1 NAME

CGI::Application::Plugin::ProtectCSRF - Plug-in protected from CSRF

=head1 VERSION

1.01

=head1 SYNPSIS

  use Your::App;
  use base qw(CGI::Application);
  use CGI::Application::Plugin::Session; # require!!
  use CGI::Application::Plugin::ProtectCSRF;

  sub input_form : PublishCSRFID {
    my $self = shift;
    do_something();
  }

  sub finish : ProtectCSRF {
    my $self = shift;
    $self->clear_csrf_id;
    do_something();
  }

=head1 DESCRIPTION

CGI::Application::Plugin::ProtectCSRF is C::A::P protected from CSRF.

When CSRF is detected, Forbidden is returned and processing is interrupted.

=cut

use strict;
use base qw(Exporter);
use Carp;
use HTML::TokeParser;
use Digest::SHA1 qw(sha1_hex);
use Attribute::Handlers;

our(
    @EXPORT,
    $CSRF_ERROR_MODE,
    $CSRF_ERROR_STATUS,
    $CSRF_ERROR_TMPL,
    $CSRF_ID,
    $CSRF_ID_LENGTH,
    $CSRF_POST_ONLY,
    $VERSION
);

@EXPORT                 = qw(
                            clear_csrf_id
                            csrf_id
                            protect_csrf_config
                            );

$CSRF_ERROR_MODE        = "_csrf_error";
$CSRF_ERROR_STATUS      = 200;
$CSRF_ERROR_TMPL        = \qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head><title>CSRF ERROR</title></head>
<body>
<h1>CSRF ERROR</h1>
<p>This access is illegal. you don't have permission to access on this server.</p>
</body>
</html>
};
$CSRF_ID                = "_csrf_id";
$CSRF_POST_ONLY         = 0;
$VERSION                = 1.01;

my(%publish_csrf_id_runmodes, %protect_csrf_runmodes);

sub import {

    my $pkg = caller;

# C::A::P::Session method check
    croak("C::A::P::Session module is not load to your app") if !$pkg->can("session");

    $pkg->add_callback("prerun",  \&_publish_csrf_id);
    $pkg->add_callback("prerun",  \&_csrf_forbidden);
    $pkg->add_callback("postrun", \&_add_csrf_id);

    goto &Exporter::import;
}

=pod

=head1 ACTION

=head2 PublishCSRFID

PublishCSRFID is action publishes CSRF ticket. CSRF ticket is published when I
define it as an attribute of runmode method publishing CSRF ticket, and it is saved in session.
If there is form tag in HTML to display after the processing end, as for runmode method to
publish, CSRF ticket is set automatically by hidden field

  # publish CSRF ticket
  sub input_form : PublishCSRFID {
    my $self = shift;
    return <<HTML;
  <form action="foo" method="post">
  <input type="text" name="name">
  <input type="submit" value="submit!">
  <input type="hidden" name="rm" value="finish">
  </form>
  HTML
  }
  
  # display html source
  <form action="foo" method="post">
  <input type="hidden" name="_csrf_id" value="random string" /> <- insert hidden field
  <input type="text" name="name">
  <input type="submit" value="submit!">
  <input type="hidden" name="rm" value="finish">
  </form>

=head2 ProtectCSRF

ProtectCSRF is action to protect from CSRF Attack. If session CSRF ticket does not accord
with query CSRF ticket, application consideres it to be CSRF attack and refuse to access it.
Carry out the processing that you want to perform after having carried out clear_csrf_id method
when access it, and it was admitted.

  sub finish : ProtectCSRF {
    my $self = shift;
    $self->clear_csrf_id; # require! There is not a meaning unless I do it
    do_something();       # The processing that you want to perform (DB processing etc)
  }

=cut

sub CGI::Application::PublishCSRFID : ATTR(BEGIN) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $publish_csrf_id_runmodes{$referent} = 1;
    #$publish_csrf_id_runmodes{*{$symbol}{NAME}} = 1;
}

sub CGI::Application::ProtectCSRF : ATTR(BEGIN) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $protect_csrf_runmodes{$referent} = 1;
}

=pod

=head1 METHOD

=head2 csrf_id

Get ticket for protect CSRF

Example: 

  sub input_form : PublishCSRFID {
    my $self = shift;

    my $csrf_id = $self->csrf_id;
    do_something();
  }

=cut

sub csrf_id {

    my $self = shift;
    return $self->session->param($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id});
}

=head2 protect_csrf_config

Initialize ProtectCSRF

Option:

  csrf_error_status      : CSRF error status code (default: 200)
  csrf_error_mode        : CSRF error runmode name (default: _csrf_error)
  csrf_error_tmpl        : CSRF error display html. scalarref or filepath or filehandle (default: $CSRF_ERROR_TMPL - scalarref)
  csrf_error_tmpl_param  : CSRF error display html parameter (for HTML::Template)
  csrf_id                : CSRF ticket name (default: _csrf_id)
  csrf_post_only         : CSRF protect runmode request method check(default:0  1:POST Only)

Example:

  sub cgiapp_init {
    my $self = shift;
    $self->tmpl_path("/path/to/template");
    $self->protect_csrf_config(
                           csrf_error_status     => 403, # change forbidden
                           csrf_error_tmpl       => "csrf_error.tmpl",
                           csrf_error_tmpl_param => { TITLE => "CSRF ERROR", MESSAGE => "your access is csrf!"},
                           csrf_id               => "ticket_id",
                           csrf_post_only        => 1
                         );
  }

  # csrf_error.tmpl
  <html><head><title><TMPL_VAR NAME=TITLE ESCAPE=HTML></title></head>
  <body>
  <h1>CSRF Error</h1>
  <span style="color: red"><TMPL_VAR NAME=MESSAGE ESCAPE=HTML></span>
  </body>
  </html>

=cut

sub protect_csrf_config {

    my($self, %args) = @_;
    if(ref($self->{__CAP_PROTECT_CSRF_CONFIG}) ne "HASH"){
        $self->{__CAP_PROTECT_CSRF_CONFIG} = {};
    }

    $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_status}     = exists $args{csrf_error_status} ? $args{csrf_error_status} : $CSRF_ERROR_STATUS;
    $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_mode}       = exists $args{csrf_error_mode} ? $args{csrf_error_mode} : $CSRF_ERROR_MODE;
    $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_tmpl}       = exists $args{csrf_error_tmpl} ? $args{csrf_error_tmpl} : $CSRF_ERROR_TMPL;
    $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_tmpl_param} = {};
    $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id}               = exists $args{csrf_id} ? $args{csrf_id} : $CSRF_ID;
    $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_post_only}        = exists $args{csrf_post_only} ? $args{csrf_post_only} : $CSRF_POST_ONLY;

    if(ref($args{csrf_error_tmpl_param}) eq "HASH" && keys %{$args{csrf_error_tmpl_param}}){
        $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_tmpl_param} = $args{csrf_error_tmpl_param};
    }
}

=pod

=head2 clear_csrf_id

Clear csrfid. It is preferable to make it execute after processing ends.

Example : 

  sub cgiapp_init {
    my $self = shift;
    $self->protect_csrf_config;
  }

  sub input {
    my $self = shift;
    do_something(). # input form display..
  }
  
  sub confirm : PublishCSRFID {
    my $self = shift;
    do_something(). # publish csrf_id and input check and confirm display..
  }

  sub complete : ProtectCSRF {
    my $self = shift;
    $self->clear_csrf_id(1); # clear csrf_id for CSRF protect
    do_something();          # DB insert etc..
  }

=cut

sub clear_csrf_id {

    my($self, $fast) = @_;
    $self->session->clear($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id});
    $self->session->flush if $fast;
}

=pod

=head1 CALLBACK

=head2 _publish_csrf_id

prerun callback

=cut

sub _publish_csrf_id {

    my($self, $rm) = @_;
    return if !exists $publish_csrf_id_runmodes{$self->can($rm)};

    if(ref($self->{__CAP_PROTECT_CSRF_CONFIG}) ne "HASH"){
        $self->protect_csrf_config;
    }

    my @words = ('A'..'Z', 'a'..'z', 0..9, '/', '.');
    my $salt = join "", @words[ map { sprintf( "%d", rand(scalar @words) ) } 1..2 ];
    my $csrf_id = sha1_hex($salt . time . $$ . rand(10000));
    $self->session->param($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id}, $csrf_id);
}

=pod

=head2 _csrf_forbidden

prerun callback

=cut

sub _csrf_forbidden {

    my($self, $rm) = @_;
    my $err_flg = 0;

    return if !exists $protect_csrf_runmodes{$self->can($rm)};

    if(ref($self->{__CAP_PROTECT_CSRF_CONFIG}) ne "HASH"){
        $self->protect_csrf_config;
    }

    if($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_post_only} && $ENV{REQUEST_METHOD} ne "POST"){
        $err_flg = 1;
    } else {

        if(
            !$self->query->param($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id}) || 
            !$self->csrf_id                                                     ||
            $self->query->param($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id}) ne $self->csrf_id
        ){
            $err_flg = 1;
        }
    }

    if($err_flg){

        $self->run_modes( $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_mode} => sub {       
     
            my $self = shift;
            $self->header_props( -type => "text/html", -status => $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_status} );

            my $tmpl_obj = $self->load_tmpl($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_tmpl}, die_on_bad_params => 0);
            if(keys %{$self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_tmpl_param}}){
                $tmpl_obj->param(%{$self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_tmpl_param}});
            }
            return $tmpl_obj->output;
        });
        $self->prerun_mode($self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_error_mode});
    }

    return 0;
}


=pod

=head2 _add_csrf_id

postrun callback

=cut

sub _add_csrf_id {

    my($self, $scalarref) = @_;
    my $rm = $self->get_current_runmode;
    my $coderef = $self->can($rm);
    return if !$coderef || !exists $publish_csrf_id_runmodes{$coderef};

    if(ref($self->{__CAP_PROTECT_CSRF_CONFIG}) ne "HASH"){
        $self->protect_csrf_config;
    }

    # my %header = $self->header_props;
    # return if %header && $header{-type} ne "text/html";

    my $body = "";
    my $hidden = sprintf qq{<input type="hidden" name="%s" value="%s" />}, $self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id}, $self->csrf_id;

    my $parser = HTML::TokeParser->new($scalarref);
    while(my $token = $parser->get_token){

# start tag(<form> sniping)
        if($token->[0] eq "S"){
            
            if(lc($token->[1]) eq "form"){
                $body .= $token->[4] . "\n" . $hidden;
            # In the future...
            #}elsif(lc($token->[1]) eq "a"){
            #    
            #   if(exists $token->[2]->{href} && defined $token->[2]->{href}){
            #       my $uri = URI->new($token->[2]->{href});
            #       my %query_form = $uri->query_form;
            #       $query_form{$self->{__CAP_PROTECT_CSRF_CONFIG}->{csrf_id}} = $self->csrf_id;
            #       $uri->query_form(%query_form);
            #       $token->[2]->{href} = $uri->path_query;
            #       my $prop = join " ", (map { $_ . "=\"" . $token->[2]->{$_} . "\"" } keys %{$token->[2]});
            #       $body .= "<" . lc($token->[1]) . " ". $prop . ">";
            #   }else{
            #       $body .= $token->[4];
            #   }

            }else{
                $body .= $token->[4];
            }

# end tag, process instructions
        }elsif($token->[0] =~ /^(E|PI)$/){
            $body .= $token->[2];
            
# text, comment, declaration
        }elsif($token->[0] =~ /^(T|C|D)$/){
            $body .= $token->[1];
        }
    }

    ${$scalarref} = $body;
}

1;

__END__

=head1 CAUTION

It has only the protection function of basic CSRF,and mount other security checks in the application, please.

=head1 SEE ALSO

L<Attribute::Handlers> L<Carp> L<CGI::Application> L<CGI::Application::Plugin::Session> L<Digest::SHA1> L<Exporter> L<HTML::TokeParser> 

=head1 AUTHOR

Akira Horimoto <kurt0027@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 - 2008 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut



