package MinimalApp;
use base 'CGI::Application';
use strict;

use HTML::Template;
use CGI::Session;
use Data::Dumper;

sub cgiapp_init {
    my $self    = shift;
    my $query   = $self->query;
    # get the current session id from the cookie
    my $sid     = $query->cookie( 'CGISESSID' ) || undef;
    my $session = CGI::Session->new("driver:File", $sid, {Directory=>'/tmp'});
    $self->param( 'session' => $session);
    if (!$sid or $sid ne $session->id ) {
       my $cookie = $query->cookie(
          -name    => 'CGISESSID',
          -value   => $session->id,
          -expires => '+1y'
       );
       $self->header_props( -cookie => $cookie );
    }
    $self->login($query->param("lg_nick"), $query->param("lg_pass"));
}

sub login{
    my $self = shift;
    my($nick, $pass) = @_;
    my $session = $self->param('session');
    if(defined $nick and defined $pass){
        if($nick eq $pass){
            # replace this check above with something real ie lookup from a database
            $session->param(profile => {nick => $nick});
            $session->clear('badlogins');
        }else{
            my $badlogins = $session->param('badlogins') || 0;
            $session->param('badlogins' => ++$badlogins);
        }
    }
}

sub setup {
    my $self = shift;
    $self->start_mode('index');
    $self->run_modes(
        'index' => 'index',
        'page1' => 'page1',
        'logout' => 'logout'
    );
    $self->tmpl_path("/Library/Webserver/Documents/tmpls/test/");
}

sub logout{
    my $self = shift;
    my $session = $self->param('session');
    $session->clear('profile');
    return $self->index();
}

sub processtmpl{
# processes the template with parameters gathered from the application object
    my ($self,$tmplname) = @_;
    my $query = $self->query();
    my $template = $self->load_tmpl($tmplname, loop_context_vars => 1,);
    #my $tmplpar = $self->param('tmplpar') || {};
    $template->param(PROFILE => $self->param('session')->param("profile"));
    $template->param(BADLOGINS => $self->param('session')->param("badlogins"));
    $template->param(MYURL => $query->url());
    my $html = $template->output;
    return $html;
}

sub index{
    my $self = shift;
    return $self->processtmpl('index.tmpl');
}

sub page1{
    my $self = shift;
    return $self->processtmpl('page1.tmpl');
}

1;    # Perl requires this at the end of all modules
 
