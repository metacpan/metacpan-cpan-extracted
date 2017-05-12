# NAME

Data::Dumper::OneLine - Dumps data as one line string

# SYNOPSIS

    use Data::Dumper::OneLine;

    Dumper(
        {
            foo => {
                bar => {},
            },
        }
    );
    #=> {foo => {bar => {}}}

# LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroki Honda <cside.story@gmail.com>
