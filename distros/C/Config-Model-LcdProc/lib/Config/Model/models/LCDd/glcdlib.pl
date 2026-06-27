#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023, 2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'class_description' => 'generated from LCDd.conf',
    'description' => {
      'Backlight' => 'Backlight if applicable',
      'Brightness' => 'Brightness (in %) if applicable',
      'CharEncoding' => 'character encoding to use',
      'Contrast' => 'Contrast (in %) if applicable',
      'Driver' => 'which graphical display supported by graphlcd-base to use 
(see /etc/graphlcd.conf for possible drivers)',
      'FontFile' => 'path to font file to use',
      'Invert' => 'invert light/dark pixels',
      'MinFontFaceSize' => 'minimum size in pixels in which fonts should be rendered',
      'ShowBigBorder' => 'border within the usable text area,
for setting up TextResolution and
MinFontFaceSize (if using FT2);
border around the unused area',
      'ShowDebugFrame' => 'turns on/off 1 pixel thick debugging',
      'ShowThinBorder' => 'border around the unused area',
      'TextResolution' => 'text resolution in fixed width characters 
(if it won\'t fit according to available physical pixel resolution
and the minimum available font face size in pixels, then
\'DebugBorder\' will automatically be turned on)',
      'UpsideDown' => 'flip image upside down',
      'UseFT2' => 'no=use graphlcd bitmap fonts (they have only one size / font file)
yes=use fonts supported by FreeType2 (needs Freetype2 support in
libglcdprocdriver and its dependants)'
    },
    'element' => [
      'Backlight',
      {
        'default' => 'no',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Brightness',
      {
        'default' => '50',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CharEncoding',
      {
        'default' => 'iso8859-2',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Contrast',
      {
        'default' => '50',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Driver',
      {
        'type' => 'leaf',
        'upstream_default' => 'image',
        'value_type' => 'uniline'
      },
      'FontFile',
      {
        'default' => '/usr/share/fonts/corefonts/courbd.ttf',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Invert',
      {
        'default' => 'no',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MinFontFaceSize',
      {
        'default' => '7x12',
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
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ShowDebugFrame',
      '*ShowBigBorder',
      'ShowThinBorder',
      {
        'default' => 'yes',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TextResolution',
      {
        'type' => 'leaf',
        'upstream_default' => '16x4',
        'value_type' => 'uniline'
      },
      'UpsideDown',
      {
        'default' => 'no',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UseFT2',
      {
        'default' => 'yes',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::glcdlib'
  }
]
;
