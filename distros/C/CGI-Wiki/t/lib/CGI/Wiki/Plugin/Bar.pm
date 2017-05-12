package CGI::Wiki::Plugin::Bar;
use base qw( CGI::Wiki::Plugin );

sub on_register {
    my $self = shift;
    die unless $self->datastore;
}

1;
