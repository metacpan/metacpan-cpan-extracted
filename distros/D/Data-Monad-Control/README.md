[![Build Status](https://travis-ci.org/aereal/Data-Monad-Control.svg?branch=master)](https://travis-ci.org/aereal/Data-Monad-Control) [![Coverage Status](https://img.shields.io/coveralls/aereal/Data-Monad-Control/master.svg?style=flat)](https://coveralls.io/r/aereal/Data-Monad-Control?branch=master)
# NAME

Data::Monad::Control - Exception handling with Monad

# SYNOPSIS

    use Data::Monad::Control qw( try );

    my $result = try {
      write_to_file_may_die(...);
    }; # => Data::Monad::Either
    $result->flat_map(sub {
      # ...
    });

# DESCRIPTION

Data::Monad::Control provides some functions to handle exceptions with monad.

# FUNCTIONS

- try($try\_clause: CodeRef); # => Data::Monad::Either

    Takes a function that will die with some exception and runs it.

    Returns a left Either monad contains the exception if some exception caught, otherwise, returns a right Either monad contains the values from the given function.

# LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

aereal <aereal@aereal.org>

# SEE ALSO

[Data::Monad](https://metacpan.org/pod/Data::Monad), [Try::Tiny](https://metacpan.org/pod/Try::Tiny)
