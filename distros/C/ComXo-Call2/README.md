[![Build Status](https://travis-ci.org/binary-com/perl-ComXo-Call2.svg?branch=master)](https://travis-ci.org/binary-com/perl-ComXo-Call2)
[![codecov](https://codecov.io/gh/binary-com/perl-ComXo-Call2/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-ComXo-Call2)

# NAME

ComXo::Call2 - API for the ComXo Call2 service (www.call2.com)

# SYNOPSIS

    use ComXo::Call2;

# DESCRIPTION

ComXo::Call2 is a perl implemention for [http://www.comxo.com/webservices/buttontel.cfm](http://www.comxo.com/webservices/buttontel.cfm)

# METHODS

## new

- account

    required.

- password

    required.

- debug

    enable SOAP trace. default is off.

## InitCall

Initiate A Call

    my $call_id = $call2->InitCall(
        anumber  => $call_to,   # to number
        bnumber  => $call_from, # from number
        alias    => 'alias',    # optional
    ) or die $call2->errstr;

- amessage

    integer - ID of message to play to customer (0=no message, 15=standard message)

- bmessage

    integer - ID of message to play to company (0=no message, 15=standard message)

- anumber

    string, anumber - Customer Phone Number

- bnumber

    string, bnumber - Company Phone Number

- delay

    integer, delay - Delay in Seconds

- alias

    string, alias - Button Alias (A preset alias or your own identifier)

- name

    string, name - Customer's Name

- company

    string, company - Customer's Company

- postcode

    string, postcode - Customer's Post Code

- email

    string, email - Customer's Email Address

- product

    string, product - Product Interest

- url

    string, url - URL of Button

- extra1

    string, extra1 - Additional Information 1

- extra2

    string, extra2 - Additional Information 2

- extra3

    string, extra3 - Additional Information 3

- extra4

    string, extra4 - Additional Information 4

- extra5

    string, extra5 - Additional Information 5

## GetAllCalls

Get All Call Details

    my @calls = $call2->GetAllCalls(
        fromdate => $dt_from,
        todate   => $dt_to
    ) or die $call2->errstr;

Array of arrayref of

Call Reference,Start Time,A Number,B Number,A Clear Reason,B Clear Reason,A Status,B Status,Duration(seconds),
A Country,B Country,Cost,Name,Company,Post Code,Email,Product,URL,Extra1,Extra2,Extra3,Extra4,Extra5,AAnswered,BAnswered

- fromdate

    datetime, fromdate - Date (YYYY-MM-DD HH:MM)

- todate

    datetime, todate - Date (YYYY-MM-DD HH:MM)

## GetCallStatus

Get Call Details

    my $call_status = $call2->GetCallStatus($call_id) or die $call2->errstr;

Arrayref of

Call Reference,Start Time,A Number,B Number,A Clear Reason,B Clear Reason,A Status,B Status,Duration(seconds),
A Country,B Country,Cost,Name,Company,Post Code,Email,Product,URL,Extra1,Extra2,Extra3,Extra4,Extra5,AAnswered,BAnswered

# AUTHOR

Binary.com <fayland@binary.com>

# COPYRIGHT

Copyright 2014- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
