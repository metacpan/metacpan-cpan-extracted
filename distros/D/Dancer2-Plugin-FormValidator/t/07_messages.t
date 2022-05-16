use strict;
use warnings;

use Test::More tests => 1;
use FindBin;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Input;
use Dancer2::Plugin::FormValidator::Validator;
use Dancer2::Plugin::FormValidator::Factory::Messages;

require "$FindBin::Bin/lib/validator.pl";

my $config = Dancer2::Plugin::FormValidator::Config->new(
    config => {
        session => {
            namespace => '_form_validator'
        },
    }
);

my $registry = Dancer2::Plugin::FormValidator::Registry->new;

my $input = Dancer2::Plugin::FormValidator::Input->new(input => {
    email => 'alex@cpan.org',
});

my $profile = Validator->new(profile_hash =>
    {
        name  => [qw(required)],
        email => [qw(required email)],
    }
);

my $validator = Dancer2::Plugin::FormValidator::Validator->new(
    config   => $config,
    registry => $registry,
);

my ($success, $valid, $invalid) = $validator->validate($profile->profile, $input->get);

my $messages_factory = Dancer2::Plugin::FormValidator::Factory::Messages->new(
    config   => $config,
    registry => $registry,
);

my $messages = $messages_factory->build($invalid);

is_deeply(
    $messages,
    {
        name => ['Name is required'],
    },
    'TEST 1: test messages HashRef'
);
