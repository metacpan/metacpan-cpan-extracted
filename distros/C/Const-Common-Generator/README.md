# NAME

Const::Common::Generator - Auto generate constant package of Const::Common

# SYNOPSIS

    use Const::Common::Generator;
    my $pm = Const::Common::Generator->generate(
        package => 'Hoge::Piyo',
        constants => [
            HO => 'GE',
            FU => {
                value => 'GA',
                comment => 'fuga',
            },
            PI => 3.14,
        ],
    ),

# DESCRIPTION

Const::Common::Generator is a module for generating constant package of Const::Common

# METHOD

## `$str = Const::Common::Generator->generate(%opt)`

- `package`
- `constants`

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
