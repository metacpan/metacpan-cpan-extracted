package Dancer2::Plugin::FormValidator::Extension::DBIC::Unique;

use Moo;
use utf8;
use namespace::clean;

with 'Dancer2::Plugin::FormValidator::Role::Validator';

sub message {
    return {
        en => '%s is already exists',
        ru => '%s уже существует',
        de => '%s ist bereits vorhanden',
    };
}

sub validate {
    my ($self, $field, $input, $source, $attribute) = @_;

    if (exists $input->{$field}) {
        my $result = $self->extension->schema->resultset($source)->search(
            {
                $attribute => $input->{$field},
            }
        )->first;

        return $result ? 0 : 1;
    }

    return 1;
}

1;