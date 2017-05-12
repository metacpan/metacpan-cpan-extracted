use strict;
use warnings;

package Config::Identity::GitHub;

our $VERSION = '0.0019';

use Config::Identity;
use Carp;

our $STUB = 'github';
sub STUB { defined $_ and return $_ for $ENV{CI_GITHUB_STUB}, $STUB }

sub load {
    my $self = shift;
    return Config::Identity->try_best( $self->STUB );
}

sub check {
    my $self = shift;
    my %identity = @_;
    my @missing;
    defined $identity{$_} && length $identity{$_}
        or push @missing, $_ for qw/ login token /;
    croak "Missing ", join ' and ', @missing if @missing;
}

sub load_check {
    my $self = shift;
    my %identity = $self->load;
    $self->check( %identity );
    return %identity;
}

1;

