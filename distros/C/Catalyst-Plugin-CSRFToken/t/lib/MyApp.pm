package MyApp;
use Catalyst;

MyApp->setup_plugins([qw/
  CSRFToken
/]);

MyApp->config(
  'Plugin::CSRFToken' => {
    'session_key' => '_csrf_token2',
    'form_id_param_key' => 'csrf_form_id2',
    'token_param_key' => 'csrf_token2',
    'max_age' => 8888,
    'default_secret' => 'begin',
    'auto_check' => 1,
  }
);

my %session = ();
sub session {
  my $self = shift;
  %session = (%session, @_) if @_;
  return \%session;
}
     
MyApp->setup;
