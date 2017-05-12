package MyApp::Module::Name;
use base 'CGI::Application';
use HTTP::Exception;

sub setup {
    my $self = shift;
    $self->start_mode('rm1');
    $self->run_modes([qw/
        rm1
        rm2
        rm3
        rm4
        rm5
        local_args_to_new
        throw_http_exception
    /]); 
    $self->error_mode('rethrow_http_exceptions');
}

sub rm1 {
    my $self = shift;
    return 'MyApp::Module::Name->rm1' 
        . ($self->param('hum') ? 'hum=' . $self->param('hum') : '');
 }

sub rm2 {
    my $self = shift;
    return 'MyApp::Module::Name->rm2'
        . ($self->param('hum') ? 'hum=' . $self->param('hum') : '');
}

sub rm3 {
    my $self = shift;
    my $param = $self->param('my_param') || '';
    return "MyApp::Module::Name->rm3 my_param=$param"
        . ($self->param('hum') ? 'hum=' . $self->param('hum') : '');
}

# because of caching, we can't re-use PATH_INFO, so we do this. 
sub rm4 {
    my $self = shift;
    return $self->rm3;
}

sub rm5 {
  my $self = shift;

  my $return="";

  if( $self->param('the_rest') ) {
    $return = 'the_rest=' . $self->param('the_rest');
  }
  else {
    $return = 'dispatch_url_remainder=' . $self->param('dispatch_url_remainder');
  }
  return "MyApp::Module::Name->rm5 $return";
}

sub local_args_to_new {
    my $self = shift;
    return $self->tmpl_path;
}

sub throw_http_exception {
   HTTP::Exception->throw(405, status_message => 'my 405 exception!');
}

sub rethrow_http_exceptions {
    my $self = shift;
    my $e    = shift;

    # Duck-type to see if we have an HTTP::Exception 
    if (defined $e && $e->can('status_method')) {
        die $e;
    }
    # In this case, just die then, too...
    else {
        die $e;
    }

}

1;
