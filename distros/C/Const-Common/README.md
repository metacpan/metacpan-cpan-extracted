# NAME

Const::Common - Yet another constant definition module

# SYNOPSIS

    package MyApp::Const;
    use Const::Common (
        BAR => 'BAZ',
        HASH => {
            HOGE => 'hoge',
        },
    );
    __END__

    use MyApp::Const;
    print BAR; # BAZ
    print HASH->{HOGE}; # hoge;
    HASH->{HOGE} = 10;  # ERROR!

# DESCRIPTION

Const::Common is a module to define common constants in your project.

# METHOD

## `$hashref = $class->constants`

## `$array = $class->constant_names`

## `$value = $class->const($const_name)`

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
