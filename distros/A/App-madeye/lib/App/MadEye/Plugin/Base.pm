package App::MadEye::Plugin::Base;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;
use App::MadEye::Util qw/get_schema_from_pod/;
use Kwalify ();

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    if (my $schema = get_schema_from_pod($self)) {
        local $SIG{__DIE__} = sub { die "$self: @_" };
        Kwalify::validate($schema, $self->config->{config});
    }

    $self;
}

1;

