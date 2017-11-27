package Chloro::Test::User;

use Moose;
use namespace::autoclean;

use Chloro;

use Chloro::ErrorMessage;
use Chloro::Types qw( NonEmptyStr );
use List::AllUtils qw( all );

field username => (
    isa      => NonEmptyStr,
    required => 1,
);

field email_address => (
    isa      => NonEmptyStr,
    required => 1,
);

field password => (
    isa    => NonEmptyStr,
    secure => 1,
);

field password2 => (
    isa    => NonEmptyStr,
    secure => 1,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _validate_form {
    my $self   = shift;
    my $params = shift;

    return $self->_validate_passwords($params),
        $self->_validate_username($params);
}

sub _validate_passwords {
    my $self   = shift;
    my $params = shift;

    return
        if all { !( defined && length ) }
    @{$params}{ 'password', 'password2' };

    {
        ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        no warnings 'uninitialized';
        return if $params->{password} eq $params->{password2};
    }

    return 'The two password fields must match.';
}

sub _validate_username {
    my $self   = shift;
    my $params = shift;

    return unless $params->{username} eq 'Special';

    return Chloro::ErrorMessage->new(
        category => 'missing',
        text     => 'Special is no good.'
    );
}
## use critic

__PACKAGE__->meta()->make_immutable;

1;
