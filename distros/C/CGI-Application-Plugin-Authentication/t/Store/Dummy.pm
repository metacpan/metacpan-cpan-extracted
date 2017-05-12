package Store::Dummy;

use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authentication::Store);

sub initialize {
    my $self = shift;
    my ($storage) = $self->options;
    $self->{__DUMMY} = $storage || {};
}

sub fetch {
    my $self = shift;
    return (map { $self->{__DUMMY}->{$_}||undef } @_)[0..$#_];
}

sub save {
    my $self = shift;
    my %data = @_;
    foreach my $key (keys %data) {
        $self->{__DUMMY}->{$key} = $data{$key};
    }
    return 1;
}

sub delete {
    my $self = shift;
    delete $self->{__DUMMY}->{$_} foreach @_;
    return 1;
}

1;
