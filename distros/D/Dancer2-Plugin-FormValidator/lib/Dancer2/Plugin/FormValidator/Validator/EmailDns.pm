package Dancer2::Plugin::FormValidator::Validator::EmailDns;

use Moo;
use utf8;
use Email::Valid;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s is not a valid email',
        ru => '%s не является валидным email адресом',
        de => '%s enthält keine gültige E-Mail-Adresse',
    };
}

sub validate {
    my ($self, $field, $input) = @_;

    if ($self->_field_defined_and_non_empty($field, $input)) {
        return $self->_is_valid_email_and_dns($input->{$field});
    }

    return 1;
}

sub _is_valid_email_and_dns {
    if (my $valid_email = Email::Valid->address(-address => $_[1], -mxcheck => 1 )) {
        return $_[1] eq $valid_email;
    }

    return 0;
}

1;
