package TestApp::Exception;

use overload q{""} => \&as_string;
use overload q{eq} => \&oper_eq;
    # have to overload this since Catalyst does an `eq' comparison

sub new {
  my $class = shift;
  return bless {
    message => 'The sky is falling',
  }, $class;
}

sub as_string {
  return shift->{message};
}

sub oper_eq {
  my ($val1, $val2) = @_;
  return $val1.'' eq $val2.'';
}

1;
