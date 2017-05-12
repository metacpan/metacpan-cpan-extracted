use strict;
use warnings;

package Config::Identity::PAUSE;

our $VERSION = '0.0019';

use Config::Identity;
use Carp;

our $STUB = 'pause';
sub STUB { defined $_ and return $_ for $ENV{CI_PAUSE_STUB}, $STUB }

sub load {
    my $self = shift;
    my %identity =  Config::Identity->try_best( $self->STUB );
    $identity{user} = $identity{username} if exists $identity{username} && ! exists $identity{user};
    $identity{username} = $identity{user} if exists $identity{user} && ! exists $identity{username};
    return %identity;
}

sub check {
    my $self = shift;
    my %identity = @_;
    my @missing;
    defined $identity{$_} && length $identity{$_}
        or push @missing, $_ for qw/ user password /;
    croak "Missing ", join ' and ', @missing if @missing;
}

sub load_check {
    my $self = shift;
    my %identity = $self->load;
    $self->check( %identity );
    return %identity;
}

1;
