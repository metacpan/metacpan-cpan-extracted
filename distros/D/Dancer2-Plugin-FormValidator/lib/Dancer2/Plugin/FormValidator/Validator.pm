package Dancer2::Plugin::FormValidator::Validator;

use strict;
use warnings;

use Moo;
use Types::Standard qw(InstanceOf);
use namespace::clean;

has config => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Config'],
    required => 1,
);

has registry => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Registry'],
    required => 1,
);

# Apply validators to each fields.
# Collect valid and invalid fields.
sub validate {
    my ($self, $profile, $input)  = @_;

    my $success = 0;
    my %profile = %{ $profile->profile };
    my $is_valid;
    my @valid;
    my @invalid;

    for my $field (keys %profile) {
        $is_valid = 1;
        my @validators = @{ $profile{$field} };

        for my $validator_declaration (@validators) {
            if (my ($name, $params) = $self->_split_validator_declaration($validator_declaration)) {
                my $validator = $self->registry->get($name);

                if (not $validator->validate($field, $input, split(',', $params))) {
                    push @invalid, [ $field, $name, $params ];
                    $is_valid = 0;
                }

                if (!$is_valid && $validator->stop_on_fail) {
                    last;
                }
            }
        }

        if ($is_valid == 1) {
            push @valid, $field;
        }
    }

    if (not @invalid) {
        $success = 1;
    }

    return ($success, \@valid, \@invalid)
}

# Because validator signatures could be validator:params, we need to split it.
sub _split_validator_declaration {
    return ($_[1] =~ /([^:]+):?(.*)/);
}

1;
