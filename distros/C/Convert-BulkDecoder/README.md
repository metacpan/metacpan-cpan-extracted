# Convert::BulkDecoder

Convert::BulkDecoder provides an easy way to decode binaries from 
email and news articles. It supports uuencoded contents, yencoded
contents and MIME attachments.

For example, to decode a multi-part yencoded article from the
command line:

    perl -MConvert::BulkDecoder \
     -e 'Convert::BulkDecoder->new->decode([<>])' \
       part01.yenc part02.yenc ...

From a program:

    my $cvt = new Convert::BulkDecoder::;
    # Collect the articles into an array ref.
    my $art = [<>];
    # Decode.
    my $res =  $cvt->decode($art);
    die("Failed!") unless $res eq "OK";
    print "Extracted ", $cvt->{size}, " bytes",
          " to file ", $cvt->{file}, "\n";

Note that it doesn't matter if the articles contain uuencoded,
yencoded or MIME encoded data.

An example program 'mfetch' is included to fetch and extract
the contents from news articles:

    mfetch alt.binaries.linux 31544 31542 31541 31543 31545

## INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

## DEPENDENCIES

This module requires these other modules and libraries:

    MIME::Parser (for MIME parsing)
    Digest::MD5 (optional, for digest calculation)

## LIMITATIONS

The parts have to be offered in order.

Only yencoded data can be CRC checked.

## COPYRIGHT AND LICENCE

Copyright 2003,2005 Squirrel Consultancy.

License: Artistic.

