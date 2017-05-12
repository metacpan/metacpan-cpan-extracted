# NAME

Acme::Samurai - Speak like a Samurai

# SYNOPSIS

    use utf8;
    use Acme::Samurai;

    Acme::Samurai->gozaru("私、侍です"); # => "それがし、侍でござる"

# DESCRIPTION

Translates Japanese to 時代劇
([http://en.wikipedia.org/wiki/Jidaigeki](http://en.wikipedia.org/wiki/Jidaigeki)) speak.

Test form: [http://samurai.koneta.org/](http://samurai.koneta.org/)

# METHODS

- gozaru( $text )

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# SPECIAL THANKS

kazina, this module started from てきすたー dictionary.
[http://kazina.com/texter/index.html](http://kazina.com/texter/index.html)

and Hiroko Nagashima, Shin Yamauchi for addition samurai vocabulary.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
