package App::MadEye::Plugin::Notify::Debug;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;
use Data::Dumper;

sub notify :Hook {
    my ($self, $context, $args) = @_;

    warn Dumper($args);
}

1;

