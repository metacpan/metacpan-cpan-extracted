# NAME

Data::Validator::Recursive - recursive data friendly Data::Validator

# SYNOPSIS

    use Data::Validator::Recursive;

    # create a new rule
    my $rule = Data::Validator::Recursive->new(
        foo => 'Str',
        bar => { isa => 'Int' },
        baz => {
            isa  => 'HashRef', # default
            rule => [
                hoge => { isa => 'Str', optional => 1 },
                fuga => 'Int',
            ],
        },
    );

    # input data for validation
    $input = {
        foo => 'hoge',
        bar => 1192,
        baz => {
            hoge => 'kamakura',
            fuga => 1185,
        },
    };

    # do validation
    my $params = $rule->validate($iput) or croak $rule->error->{message};

# DESCRIPTION

Data::Validator::Recursive is recursive data friendly Data::Validator.

You are creates the validation rules contain `NoThrow` as default.

# METHODS

## `new($arg_name => $rule [, ... ]) : Data::Validator::Recursive`

Create a validation rule.

    my $rule = Data::Validator::Recursive->new(
        foo => 'Str',
        bar => { isa => 'Int' },
        baz => {
            rule => [
                hoge => { isa => 'Str', optional => 1 },
                fuga => 'Int',
            ],
        },
    );

_$rule_'s attributes is [Data::Validator](https://metacpan.org/pod/Data::Validator) compatible, And additional attributes as follows:

- `rule => $rule : Array | Hash | Data::Validator::Recursive | Data::Validator`

    You can defined a _$rule_ recursively to _rule_.

    For example:

        my $rule = Data::Validator::Recursive->new(
            foo => {
              rule => [
                  bar => {
                      baz => [
                          rule => ...
                      ],
                  },
              ],
            }
        );

- `with => $extention : Str | Array`

    Applies _$extention_ to this rule.

    See also [Data::Validator](https://metacpan.org/pod/Data::Validator).

## `with(@extentions)` : Data::Validator::Recursive

Applies _@extention_ to this rule.

See also [Data::Validator](https://metacpan.org/pod/Data::Validator).

## `validate(@args) : \%hash | undef`

Validates _@args_ and returns a restricted HASH reference, But return undefined value if there found invalid parameters.

    my $params = $rule->validate(@args) or croak $rule->error->{message};

## `has_errors() : Bool`

Return true if there is an error.

    $rule->validate($params);
    if ($rule->has_errors) {
       ...
    }

## `errors() : \@errors | undef`

Returns last error datum or undefined value.

    my $errors = $rule->errors;
    # $error = [
    #     {
    #         name    => 'xxx',
    #         type    => 'xxx',
    #         message => 'xxx',
    #     },
    #     { ... },
    #     ...
    # ]

## `error() : \%error | undef`

Returns last first error data or undefined value.

    my $error = $rule->error;
    # $error = $rule->errors->[0]

## `clear_errors  : \@errors | undef`

Clear last errors after return last errors or undefined value.

    my $errors = $rule->clear_errors;
    say $rule->has_errors; # 0

# AUTHOR

Yuji Shimada &lt;xaicron {@} GMAIL.COM>

# CONTRIBUTORS

punytan

# COPYRIGHT

Copyright 2013 - Yuji Shimada

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Data::Validator](https://metacpan.org/pod/Data::Validator)
