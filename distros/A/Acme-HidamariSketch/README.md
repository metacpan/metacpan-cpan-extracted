# NAME

Acme::HidamariSketch - This module of the Hidamalar, by the Hidamalar, for the Hidamalar.

# SYNOPSIS

     use Acme::HidamariSketch;

     # Let's make the Hidamari-world first.
     my $hidamari = Acme::HidamariSketch->new;
    
     # You can see the character information.
     my @characters = $hidamari->characters;

     # You can build a Hidamari-apartment.
     my $apartment = $hidamari->apartment;

     # You can knock on the room.
     my $yuno = $apartment->knock(201);

     # You can change the year.
     $hidamari->year('second');
     $apartment = $hidamari->apartment;

     # You also meet Sae and Hiro.
     my $hiro = $apartment->knock(101);
     my $sae  = $apartment->knock(102);

# DESCRIPTION

Hidamari Sketch is a Japanese manga that are loved by many people.

# METHODS

## new

    my $hidamari = Acme::HidamariSketch->new;

## characters

    my @characters = $hidamari->characters;

## apartment

    my $apartment = $hidamari->apartment;

    my $yuno = $apartment->knock(201);

## year

    my $year = $hidamari->year('second');

# SEE ALSO

- Hidamari Sketch (Wikipedia - ja)

    http://ja.wikipedia.org/wiki/%E3%81%B2%E3%81%A0%E3%81%BE%E3%82%8A%E3%82%B9%E3%82%B1%E3%83%83%E3%83%81

- Hidamari Sketch (Wikipedia - en)

    http://en.wikipedia.org/wiki/Hidamari\_Sketch

- Blog of authorship

    http://ap.sakuraweb.com/

# REFERENCE

- Acme::MorningMusume

    https://github.com/kentaro/perl-acme-morningmusume

- Acme::PrettyCure

    https://github.com/kan/p5-acme-prettycure

- Acme::MilkyHolmes

    https://github.com/tsucchi/p5-Acme-MilkyHolmes

# LICENSE

Copyright (C) akihiro\_0228.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

akihiro\_0228 <nano.universe.0228@gmail.com>
