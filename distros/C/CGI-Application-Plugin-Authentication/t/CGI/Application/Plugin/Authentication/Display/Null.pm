package CGI::Application::Plugin::Authentication::Display::Null;
use base CGI::Application::Plugin::Authentication::Display;

sub new {
    my $class = shift;
    my $self = CGI::Application::Plugin::Authentication::Display->new(shift);
    bless $self, $class;
    return $self;
}

1

