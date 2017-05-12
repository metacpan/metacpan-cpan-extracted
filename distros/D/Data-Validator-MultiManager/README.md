# NAME

Data::Validator::MultiManager - to manage a multiple validation for Data::Validator

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use Data::Validator::MultiManager;

    my $manager = Data::Validator::MultiManager->new;
    # my $manager = Data::Validator::MultiManager->new('Data::Validator::Recursive');
    $manager->common(
        category => { isa => 'Int' },
    );
    $manager->add(
        collection => {
            id => { isa => 'ArrayRef' },
        },
        entry => {
            id => { isa => 'Int' },
        },
    );

    my $param = {
        category => 1,
        id       => [1,2],
    };

    my $result = $manager->validate($param);

    if (my $e = $result->errors) {
        errors_common($e);
        # $result->invalid is guess to match some validator
        if ($result->invalid eq 'collection') {
            errors_collection($e);
        }
        elsif ($result->invalid eq 'entry') {
            errors_entry($e);
        }
    }
    else {
        if ($result->valid eq 'collection') {
            process_collection($result->value);
        }
        elsif ($result->valid eq 'entry') {
            process_entry($result->value);
        }
    }

# DESCRIPTION

Data::Validator::MultiManager is to manage a multiple validation for Data::Validator.
Add rules to 'NoThrow' and 'NoRestrict' by default.

# Manager's METHOD

## `Data::Validator::MultiManager->new`

## `$manager->common(@rule)`

add common rules.

    $manager->common(
        category => { isa => 'Int' },
    );

## `$manager->add(@rules)`

add new validation rules.

    $manager->add(
        collection => {
            id => { isa => 'ArrayRef' },
        },
        entry => {
            id => { isa => 'Int' },
        },
    );

## `$manager->validate(@input)`

validates @args and return ResultSet.

    my $result = $manager->validate($param);

# ResultSet's METHOD

## `$result->original`

return original parameters(`@input`).

## `$result->valid`

return valid tag.

## `$result->invalid`

return invalid tag.
(using priority and count of errors)

## `$result->values`

return HASH reference after validate with valid tag.

## `$result->error`

return first error with invalid tag.

## `$result->errors`

return all of errors with invalid tag.

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <hixi@cpan.org>
