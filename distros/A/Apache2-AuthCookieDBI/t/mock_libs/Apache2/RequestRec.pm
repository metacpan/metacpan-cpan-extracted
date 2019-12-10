package Apache2::RequestRec;
use strict;
use warnings;

use Apache2::Log::Request;

our $AUTOLOAD;

# Mock library for testing only.

sub new {
    my ( $class, %args ) = @_;
    my $self = \%args;
    bless $self, $class;
    $self->{_error_messages} = [];
    $self->{'_log'} = Apache2::Log::Request->new();
    return $self;
}

sub auth_name {
    my ($self) = @_;
    return $self->{auth_name};
}

sub dir_config {
    my ( $self, $name_of_requested_variable ) = @_;
    my $mock_config = $self->{mock_config};
    return $mock_config->{$name_of_requested_variable};
}

sub log {
    my ($self) = @_;
    return $self->{'_log'};
}

sub uri {
    return 'test_uri';
}

sub user {
    my ( $self, $new_user ) = @_;
    if ($new_user) {
        $self->{'user'} = $new_user;
    }
    return $self->{'user'};
}

sub subprocess_env {
    my ( $self, @args ) = @_;
    if ( @args == 1 ) {
        unless ( ref($self->{'subprocess_env'}) ) {
            $self->{'subprocess_env'} = {};
        }
        return $self->{'subprocess_env'}{$args[0]};
    }
    else {
        $self->{'subprocess_env'} = { @args };
    }
    return $self;
}

# For any other method that gets called we store the arguments in
# an arrayref in the hash that is $self. The key is the nameof the
# method that was called, so if:
#   $r->unknown(1,2,3);
# then we push a ref to the args:  [1,2,3] onto the arrayref at $r->{'unknown'}
#
sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $called_name = $AUTOLOAD;
    if ( !exists $self->{$called_name} ) {
        $self->{$called_name} = [];
    }
    push @{ $self->{$called_name} }, \@args;
    return $self;
}

1;
