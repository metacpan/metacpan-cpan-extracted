use strict;
use warnings;
use utf8::all;

use Test::More tests => 1;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Input;
use Dancer2::Plugin::FormValidator::Processor;

package Validator {
    use Moo;

    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    has profile_hash => (
        is       => 'ro',
        required => 1,
    );

    sub profile {
        return $_[0]->profile_hash;
    }

    around hook_before => sub {
        my ($orig, $self, $profile, $input) = @_;

        if ($input->{name} eq 'Secret') {
            delete $profile->{surname};
        }

        return $orig->($self, $profile, $input);
    };
}

my $config = Dancer2::Plugin::FormValidator::Config->new(
    config => {
        session  => {
            namespace => '_form_validator'
        },
        messages => {
            language => 'en',
        }
    },
);

my $profile = Validator->new(profile_hash =>
    {
        name    => [ qw(required) ],
        surname => [ qw(required) ],
        email   => [ qw(required email) ],
    }
);

my $registry  = Dancer2::Plugin::FormValidator::Registry->new;

my $input = Dancer2::Plugin::FormValidator::Input->new(input => {
    name   => 'Secret',
    email  => 'alex@cpan.org',
});

my $processor = Dancer2::Plugin::FormValidator::Processor->new(
    input    => $input,
    profile  => $profile,
    config   => $config,
    registry => $registry,
);

# TEST 1.
## Check messages(en) from extensions validator.

is(
    $processor->run->success,
    1,
    'TEST 1: Check hook_before removing required validator'
);
