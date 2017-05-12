# NAME

Data::Recursive::Encode - Encode/Decode Values In A Structure

# SYNOPSIS

    use Data::Recursive::Encode;

    Data::Recursive::Encode->decode('euc-jp', $data);
    Data::Recursive::Encode->encode('euc-jp', $data);
    Data::Recursive::Encode->decode_utf8($data);
    Data::Recursive::Encode->encode_utf8($data);
    Data::Recursive::Encode->from_to($data, $from_enc, $to_enc[, $check]);

# DESCRIPTION

Data::Recursive::Encode visits each node of a structure, and returns a new
structure with each node's encoding (or similar action). If you ever wished
to do a bulk encode/decode of the contents of a structure, then this
module may help you.

# VALIABLES

- $Data::Recursive::Encode::DO\_NOT\_PROCESS\_NUMERIC\_VALUE

    do not process numeric value.

        use JSON;
        use Data::Recursive::Encode;

        my $data = { int => 1 };

        is encode_json( Data::Recursive::Encode->encode_utf8($data) ); #=> '{"int":"1"}'

        local $Data::Recursive::Encode::DO_NOT_PROCESS_NUMERIC_VALUE = 1;
        is encode_json( Data::Recursive::Encode->encode_utf8($data) ); #=> '{"int":1}'

# METHODS

- decode

        my $ret = Data::Recursive::Encode->decode($encoding, $data, [CHECK]);

    Returns a structure containing nodes which are decoded from the specified
    encoding.

- encode

        my $ret = Data::Recursive::Encode->encode($encoding, $data, [CHECK]);

    Returns a structure containing nodes which are encoded to the specified
    encoding.

- decode\_utf8

        my $ret = Data::Recursive::Encode->decode_utf8($data, [CHECK]);

    Returns a structure containing nodes which have been processed through
    decode\_utf8.

- encode\_utf8

        my $ret = Data::Recursive::Encode->encode_utf8($data);

    Returns a structure containing nodes which have been processed through
    encode\_utf8.

- from\_to

        my $ret = Data::Recursive::Encode->from_to($data, FROM_ENC, TO_ENC[, CHECK]);

    Returns a structure containing nodes which have been processed through
    from\_to.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

gfx

# SEE ALSO

This module is inspired from [Data::Visitor::Encode](https://metacpan.org/pod/Data::Visitor::Encode), but this module depended to too much modules.
I want to use this module in pure-perl, but [Data::Visitor::Encode](https://metacpan.org/pod/Data::Visitor::Encode) depend to XS modules.

[Unicode::RecursiveDowngrade](https://metacpan.org/pod/Unicode::RecursiveDowngrade) does not supports perl5's Unicode way correctly.

# LICENSE

Copyright (C) 2010 Tokuhiro Matsuno All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
