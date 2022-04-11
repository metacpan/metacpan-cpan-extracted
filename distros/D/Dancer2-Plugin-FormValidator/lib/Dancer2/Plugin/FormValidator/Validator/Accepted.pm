package Dancer2::Plugin::FormValidator::Validator::Accepted;

use Moo;
use utf8;
use List::Util qw(any);
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s must be accepted',
        ru => '%s должно быть выбрано',
        de => '%s muss markiert sein',
    };
}

around 'stop_on_fail' => sub {
    return 1;
};

sub validate {
    my ($self, $field, $input) = @_;

    if (exists $input->{$field}) {
        return any { $input->{$field} eq $_ } qw(yes on 1);
    }

    return 0;
}

1;
