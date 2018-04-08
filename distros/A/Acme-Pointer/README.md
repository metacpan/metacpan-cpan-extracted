# NAME

Acme::Pointer - We can access to data using address as the string

# SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use utf8;
    use feature qw/say/;
    use Data::Dumper;
    use Acme::Pointer;

    my $a = {
        a => 20,
        b => [1,2]
    };
    my $b = "$a";
    say $b;
    print Dumper deref($b);
    say "-" x 10;

    if ($b =~ /[A-Z]+\((.*)\)/) {
        print Dumper pointer($1);
    }

# DESCRIPTION

Acme::Pointer by passing the address as the string to the function, you can access that address.

**THIS MODULE IS UNSAFE. DO NOT USE THIS IN PRODUCT.**

# METHODS

- `deref($ref :Str)`

    You can pass the following string to this function.

        CODE(0x7fd541a84a30)
        HASH(0x7fd541a84a30)
        ARRAY(0x7fd541a84a30)
        SCALAR(0x7fd541a84a30)

    If a character string other than these is passed, undef will be returned.

- `pointer($addr :Str)`

    You can pass the string like "0x7fd541a84a30" to this function.

# LICENSE

Copyright (C) K.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

K <x00.x7f@gmail.com>
