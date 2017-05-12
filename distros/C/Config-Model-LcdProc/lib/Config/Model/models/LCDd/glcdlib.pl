#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Backlight',
      {
        'default' => 'no',
        'description' => 'Backlight if applicable',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Brightness',
      {
        'default' => '50',
        'description' => 'Brightness (in %) if applicable',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CharEncoding',
      {
        'default' => 'iso8859-2',
        'description' => 'character encoding to use',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Contrast',
      {
        'default' => '50',
        'description' => 'Contrast (in %) if applicable',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Driver',
      {
        'description' => 'which graphical display supported by graphlcd-base to use 
(see /etc/graphlcd.conf for possible drivers)',
        'type' => 'leaf',
        'upstream_default' => 'image',
        'value_type' => 'uniline'
      },
      'FontFile',
      {
        'default' => '/usr/share/fonts/corefonts/courbd.ttf',
        'description' => 'path to font file to use',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Invert',
      {
        'default' => 'no',
        'description' => 'invert light/dark pixels',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MinFontFaceSize',
      {
        'default' => '7x12',
        'description' => 'minimum size in pixels in which fonts should be rendered',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PixelShiftX',
      {
        'default' => '0',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PixelShiftY',
      {
        'default' => '2',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ShowBigBorder',
      {
        'default' => 'no',
        'description' => 'border within the usable text area,
for setting up TextResolution and
MinFontFaceSize (if using FT2);
border around the unused area',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ShowDebugFrame',
      {
        'default' => 'no',
        'description' => 'turns on/off 1 pixel thick debugging',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ShowThinBorder',
      {
        'default' => 'yes',
        'description' => 'border around the unused area',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TextResolution',
      {
        'description' => 'text resolution in fixed width characters 
(if it won\'t fit according to available physical pixel resolution
and the minimum available font face size in pixels, then
\'DebugBorder\' will automatically be turned on)',
        'type' => 'leaf',
        'upstream_default' => '16x4',
        'value_type' => 'uniline'
      },
      'UpsideDown',
      {
        'default' => 'no',
        'description' => 'flip image upside down',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UseFT2',
      {
        'default' => 'yes',
        'description' => 'no=use graphlcd bitmap fonts (they have only one size / font file)
yes=use fonts supported by FreeType2 (needs Freetype2 support in
libglcdprocdriver and its dependants)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::glcdlib'
  }
]
;

