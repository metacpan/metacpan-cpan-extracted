# NAME

Acme::OnePiece - substitute strings in a file into 'one piece'-ed.

# SYNOPSIS

    use Acme::OnePiece;

    my $one = Acme::OnePiece->new($filename);
    print $one->onepiece;

# DESCRIPTION

Acme::OnePiece is ...

you can get strings concatenated by '-' from a file.

this makes entirely no sense...

# METHODS

## onepice

    print Acme::OnePiece->new($filename)->onepiece;

# LICENSE

Copyright (C) hidehigo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hidehigo <hidehigo@cpan.org>
