package MyApp;
use Catalyst;

MyApp->setup_plugins([qw/
  CSRFToken
/]);

MyApp->config(
  'Plugin::CSRFToken' => { default_secret=>'changeme', auto_check => 1 }
);

sub sessionid { 23123123123 }

my %session = ();
sub session {
  my $self = shift;
  %session = (%session, @_) if @_;
  return \%session;
}
     
MyApp->setup;
