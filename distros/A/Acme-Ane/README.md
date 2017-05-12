[![Build Status](https://travis-ci.org/Sixeight/Acme-Ane.svg?branch=master)](https://travis-ci.org/Sixeight/Acme-Ane)
# NAME

Acme::Ane - Ane means big sister.

# SYNOPSIS

    use Acme::Ane;

    my $ane = Acme::Ane->new($your_object)
    if ($ane->is_ane) {
      print "$ane is ane\n";
    }

Other way

    use Acme::Ane "ane";

    my $ane = ane $your_object

# DESCRIPTION

Acme::Ane is joke module for Ane lover.

## Exports

The following functions are exported only by request.

    ane

# METHODS

- is\_ane


    Examin that the objec is ane.

# LICENSE

Copyright (C) Tomohiro Nishimura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tomohiro Nishimura <tomohiro68@gmail.com>
