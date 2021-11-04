package Astro::VEX::Parse;

=head1 NAME

Astro::VEX::Parse - VEX (VLBI Experiment Definition) parser module

=cut

use strict;
use warnings;

our $VERSION = '0.001';

use Parse::RecDescent;

use Astro::VEX;
use Astro::VEX::Block;
use Astro::VEX::Comment;
use Astro::VEX::Def;
use Astro::VEX::Link;
use Astro::VEX::Param;
use Astro::VEX::Param::Empty;
use Astro::VEX::Param::Number;
use Astro::VEX::Param::String;
use Astro::VEX::Ref;
use Astro::VEX::Scan;

my $grammar = q{
    vex: header content(s?)
        {new Astro::VEX(version => $item[1], content => $item[2]);}

    header: 'VEX_rev' '=' /\d+\.\d+/ ';'
        {$item[3];}

    content: comment | block

    comment: '*' <skip:''> /.*/
        {new Astro::VEX::Comment($item[3]);}

    block: block_header block_content(s?)
        {new Astro::VEX::Block($item[1], $item[2]);}

    block_header: '$' block_name ';'
        {$item[2];}

    block_content: comment | statement_ref | statement_def | statement_scan | parameter_assignment

    statement_ref: 'ref' reference '=' parameter_values ';'
        {new Astro::VEX::Ref($item[2], $item[4]);}

    statement_def: 'def' identifier ';' def_content(s?) 'enddef' ';'
        {new Astro::VEX::Def($item[2], $item[4]);}

    def_content: comment | statement_ref | parameter_assignment

    statement_scan: 'scan' identifier ';' scan_content(s?) 'endscan' ';'
        {new Astro::VEX::Scan($item[2], $item[4]);}

    scan_content: comment | parameter_assignment

    parameter_assignment: parameter_name '=' parameter_values ';'
        {new Astro::VEX::Param($item[1], $item[3]);}

    parameter_values: parameter_value parameter_values_tail(s?)
        {my $tail = $item[2]->[0]; [$item[1], ref $tail ? @$tail : ()];}

    parameter_values_tail: ':' parameter_values
        {$item[2];}

    parameter_value: parameter_value_link | parameter_value_number_with_unit | parameter_value_number_without_unit | parameter_value_plain | parameter_value_quoted | parameter_value_empty

    block_name: /[!"#$%&'()*+,\\-.\/0-9:<>?\@A-Z\\[\\\\\\]^_`a-z{|}~]+/

    reference: '$' block_name
        {$item[2];}

    parameter_name: ...!/[$&*"]/ /[!"#$%&'()*+,\\-.\/0-9<>?\@A-Z\\[\\\\\\]^_`a-z{|}~]+/

    parameter_value_link: '&' /[!"#$%&'()*+,\\-.\/0-9<>?\@A-Z\\[\\\\\\]^_`a-z{|}~]+/
        {new Astro::VEX::Link($item[2]);}

    parameter_value_plain: ...!/["$&]/ /[!"#$%&'()+,\\-.\/0-9<=>?\@A-Z\\[\\\\\\]^_`a-z{|}~\\n\\t]+/
        {new Astro::VEX::Param::String($item[2] =~ s/[\n\t ]+$//r, 0)}

    parameter_value_quoted: '"' <skip:''> parameter_value_quoted_char(s?) '"'
        {new Astro::VEX::Param::String((join '', @{$item[3]}), 1)}

    parameter_value_quoted_char: parameter_value_quoted_char_plain | parameter_value_quoted_char_escape

    parameter_value_quoted_char_plain: /[ !#$%&'()*+,\\-.\/0-9:;<=>?\@A-Z\\[\\]^_`a-z{|}~\\n\\t]/

    parameter_value_quoted_char_escape: '\\\\' /["'?\\\\]/
        {$item[2]}

    parameter_value_empty: '' .../[:;]/
        {new Astro::VEX::Param::Empty()}

    parameter_value_number_with_unit: parameter_value_number_plain parameter_value_unit .../[:;]/
        {new Astro::VEX::Param::Number($item[1], $item[2])}

    parameter_value_number_without_unit: parameter_value_number_plain .../[:;]/
        {new Astro::VEX::Param::Number($item[1], undef)}

    parameter_value_number_plain: /[-+]?(?:(?:[0-9]+(?:\.[0-9]+)?)|(?:\.[0-9]+))(?:[Ee][-+]?[0-9]+)?/

    parameter_value_unit: parameter_value_unit_angrate | parameter_value_unit_velocity | parameter_value_unit_time | parameter_value_unit_freq | parameter_value_unit_rate | parameter_value_unit_length | parameter_value_unit_angle | parameter_value_unit_flux | parameter_value_unit_bitdens | parameter_value_unit_flsz

    parameter_value_unit_angrate: parameter_value_unit_angle '/' parameter_value_unit_time
        {$item[1] . '/' . $item[3]}
    parameter_value_unit_velocity: parameter_value_unit_length '/' parameter_value_unit_time
        {$item[1] . '/' . $item[3]}

    parameter_value_unit_time: 'psec' | 'nsec' | 'usec' | 'msec' | 'sec' | 'min' | 'hr' | 'yr'
    parameter_value_unit_freq: 'mHz' | 'Hz' | 'kHz' | 'MHz' | 'GHz'
    parameter_value_unit_rate: 'ks/sec' | 'Ms/sec'
    parameter_value_unit_length: 'um' | 'mm' | 'cm' | 'm' | 'km' | 'in' | 'ft'
    parameter_value_unit_angle: 'mdeg' | 'deg' | 'amin' | 'asec' | 'rad'
    parameter_value_unit_flux: 'mJy' | 'Jy'
    parameter_value_unit_bitdens: 'bpi' | 'kbpi'
    parameter_value_unit_flsz: 'MB' | 'GB' | 'TB'

    identifier: /[!"#%'()+,\\-.\/0-9<>?\@A-Z\\[\\\\\\]^_`a-z{|}~]+/

    # Example (not used).
    anychar: /[ !"#$%&'()*+,\\-.\/0-9:;<=>?\@A-Z\\[\\\\\\]^_`a-z{|}~]/
};


sub parse_vex {
    my $cls = shift;
    my $text = shift;

    my $parser = new Parse::RecDescent($grammar)
        or die 'Failed to prepare parser';

    # Parse text as reference so that we are left with whatever didn't match.
    my $result = $parser->vex(\$text);

    chomp $text;
    $text =~ s/^\s//;
    $text =~ s/\s$//;
    die "Failed to parse VEX at: '" . (substr $text, 0, 60) . "'"
        if $text;

    return $result;
}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2021 East Asian Observatory
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA

=cut
