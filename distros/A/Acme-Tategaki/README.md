# NAME

Acme::Tategaki - This Module makes a text vertically.

# SYNOPSIS

    $ perl -MAcme::Tategaki -MEncode -e 'print encode_utf8 tategaki(decode_utf8 "お前は、すでに、死んでいる。"), "\n";'
    死　す　お
    ん　で　前
    で　に　は
    い　︑　︑
    る　　　　
    ︒　　　　

    $ perl -MAcme::Tategaki -MEncode -e 'print encode_utf8 tategaki_one_line(decode_utf8 "お前は、すでに、死んでいる。"), "\n";'
    お
    前
    は
    ︑
    す
    で
    に
    ︑
    死
    ん
    で
    い
    る
    ︒
=head1 DESCRIPTION

Acme::Tategaki makes a text vertically.

# AUTHOR

Kazuhiro Homma <kazuph@cpan.org>

# DEPENDENCIES

[Array::Transpose](http://search.cpan.org/perldoc?Array::Transpose), [Array::Transpose::Ragged](http://search.cpan.org/perldoc?Array::Transpose::Ragged)

# SEE ALSO

[flippy](https://rubygems.org/gems/flippy)

# LICENSE

Copyright (C) Kazuhiro Homma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
