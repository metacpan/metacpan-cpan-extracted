# NAME

Acme::ZeroWidth - Zero-width fingerprinting

# SYNOPSIS

    use Acme::ZeroWidth qw(to_zero_width from_zero_width);

    to_zero_width('vti'); # becomes \x{200b}\x{200c}...

# DESCRIPTION

Acme::ZeroWidth converts any data to zero-width equivalent characters.

# LICENSE

Copyright (C) vti.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

vti <viacheslav.t@gmail.com>
