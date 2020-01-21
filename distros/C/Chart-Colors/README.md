# NAME

Chart::Colors - Perl extension to return an endless stream of new distinct RGB colours codes (good for coloring any number of chart lines)

# SYNOPSIS

```perl
    #!/usr/bin/perl -w
      
    use Chart::Colors;

    my $colors = new Chart::Colors();
    my $nextcolor_hex=$colors->Next('hex');     # Get an HTML-Style answer, like F85099 (put a # in front to use in HTML, i.e. #F85099)
    my($r,$g,$b)=$colors->Next('rgb');          # Get red, green, and blue ints separately, like (255,123,88)
    my($h,$s,$v)=$colors->Next('hsv');          # Get hue, saturation, and brightness
```

# DESCRIPTION

This module outputs an infinte sequence of visually distinct different colours.

It is useful for colorizing the lines on charts etc.

## EXAMPLE

```bash
	# perl -MChart::Colors -e '$c=new Chart::Colors(); for(my $i=0;$i<5;$i++) { print "$i\t( " . join(", ",$c->Next()) . " )\n";}; print "#" . $c->Next("hex") . "\n"; print join("|", $c->Next("hsv")) . "\n"; ' 
```
	0       ( 204, 81, 81 )
	1       ( 127, 51, 51 )
	2       ( 81, 204, 204 )
	3       ( 51, 127, 127 )
	4       ( 142, 204, 81 )
	#597f33
	0.75|0.6|0.8

## EXPORT

None by default.

## Notes

## new

Usage is

```perl
    my $colors = new Chart::Colors();
```

## Next

Returns a colour code in hexadecimal ('hex'), red, green, blue ('rgb') or hue, saturation, and brightnes ('hsv') format.

Usage is

```perl
    my $nextcolor_hex = $colors->Next('hex');
```

or

```perl
    my($r,$g,$b)=$colors->Next('rgb');
```

## hsv\_to\_rgb

```perl
    my($r,$g,$b)=$this->hsv_to_rgb($h,$s,$v);
```

# AUTHOR

This module was written by Chris Drake `cdrake@cpan.org`, and based on https://stackoverflow.com/questions/24852345/hsv-to-rgb-color-conversion

# COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
