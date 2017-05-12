# NAME - App::WIoZ

App::WIoZ - a perl word cloud generator

# DESCRIPTION

App::WIoZ can create a SVG or PNG image of a word cloud from a simple text file with `word;weight`.

App::WIoZ is an acronym for "Words for Io by Zeus", look for the Correggio painting to watch the cloud.

App::WIoZ is based on `Wordle` strategy and `yawc` perl clone.

Usage:

    my $File = 'words.txt';
    
    my $wioz = App::WIoZ->new(
      font_min => 18, font_max => 64,
      set_font => "DejaVuSans,normal,bold",
      filename => "testoutput",
      basecolor => '226666'); # violet
    
    if (-f $File) {
      my @words = $wioz->read_words($File);
      $wioz->do_layout(@words);
    }
    else {
      $wioz->chg_font("LiberationSans,normal,bold");
      $wioz->update_colors('testoutput.sl.txt');
    }

watch `doc/freq.pl` to create a `words.txt` file.

# STATUS

App::WIoZ is actually a POC to play with Moose, Cairo or Math::PlanePath. 

The use of an Hilbert curve to manage free space is for playing with Math::PlanePath modules.

Performance can be improved in free space matching, or in spiral strategy to find free space.

Max and min font sizes can certainly be computed. 

Feel free to clone this project on GitHub.

# SETTINGS

## height

image height, default to 600

## width

image width, default to 800

## font_min, font_max

required min and max font size

## set_font, chg_font, font

accessors for font name, type and weight

`set_font` : set font in new WIoZ object, default is `'LiberationSans,normal,bold'`

`chg_font` : change font

`font` : read font object

Usage :

    $wioz = App::WIoZ->new( font_min => 18, font_max => 64,
                            set_font => 'DejaVuSans,normal,bold');
        
    
    $fontname = $wioz->font->{font};
    $wioz->chg_font('LiberationSans,normal,bold');
    


## filename

file name output, extension `.png` or `.svg` will be added 

## svg

produce a svg output, default value

set to 0 to write a png

## scale

Scale for the Hilbert Curve granularity default to 10

Higer value produces better speed but more words recovery.

## basecolor

Base color for color theme, default to 882222

# METHODS

## read_words

read words form file : `word;weight`

Usage: 
 my @words = $wioz->read_words($File);

## update_colors

Read words position from file and update colors.

Usage:

    $wioz->update_colors("file.sl.txt");

## do_layout

Compute words position, save result to svg or png image, save in `filename.sl.txt` words positions to update colors.

Usage :
   $wioz->do_layout(@words);

# Git

[https://github.com/yvesago/WIoZ/](https://github.com/yvesago/WIoZ/)

# AUTHORS

Yves Agostini, `<yveago@cpan.org>`

# LICENSE AND COPYRIGHT

Copyright 2013 - Yves Agostini 

This program is free software and may be modified or distributed under the same terms as Perl itself.
