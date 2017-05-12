# NAME

Acme::Ikamusume - The invader comes from the bottom of the sea!

# SYNOPSIS

    use utf8;
    use Acme::Ikamusume;

    print Acme::Ikamusume->geso('イカ娘です。あなたもperlで侵略しませんか？');
    # => イカ娘でゲソ。お主もperlで侵略しなイカ？

# DESCRIPTION

Acme::Ikamusume converts Japanese text into like Ikamusume speak.
Ikamusume, meaning "Squid-Girl", she is a cute Japanese comic/manga
character ([http://www.ika-musume.com/](http://www.ika-musume.com/)).

Try this module here: [http://ika.koneta.org/](http://ika.koneta.org/). enjoy!

# METHODS

- $output = Acme::Ikamusume->geso( $input )

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
