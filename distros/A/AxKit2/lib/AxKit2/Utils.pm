# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Utils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(
    uri_encode
    uri_decode
    http_date
    xml_escape
    bytelength
    );

sub uri_encode {
    my $uri = shift;

    # TODO: Support Unicode?
    $uri =~ s/([^-\/.\w ])/sprintf('%%%02X', ord $1)/ge;
    $uri =~ tr/ /+/;

    return $uri;
}

sub uri_decode {
    my $uri = shift;
    return '' unless defined $uri;
    $uri =~ s/\+/ /g;
    $uri =~ s/
        %                      # encoded data marker
        (?:                    # followed by either
            ([0-9a-fA-F]{2})   # 2 hex chars
            |                  # or
            u([0-9a-fA-F]{4})  # 'u' then 4 hex chars
        )
        /
        defined($1) ? chr hex($1) : utf8_chr(hex($2))
        /gex;
    return $uri;
}

# borrowed from CGI::Util which I think borrowed it from XML::DOM...
sub utf8_chr ($) {
    my $c = shift(@_);

    if ($c < 0x80) {
        return sprintf("%c", $c);
    } elsif ($c < 0x800) {
        return sprintf("%c%c", 0xc0 | ($c >> 6), 0x80 | ($c & 0x3f));
    } elsif ($c < 0x10000) {
        return sprintf("%c%c%c",
                               0xe0 |  ($c >> 12),
                               0x80 | (($c >>  6) & 0x3f),
                               0x80 | ( $c          & 0x3f));
    } elsif ($c < 0x200000) {
        return sprintf("%c%c%c%c",
                               0xf0 |  ($c >> 18),
                               0x80 | (($c >> 12) & 0x3f),
                               0x80 | (($c >>  6) & 0x3f),
                               0x80 | ( $c          & 0x3f));
    } elsif ($c < 0x4000000) {
        return sprintf("%c%c%c%c%c",
                               0xf8 |  ($c >> 24),
                               0x80 | (($c >> 18) & 0x3f),
                               0x80 | (($c >> 12) & 0x3f),
                               0x80 | (($c >>  6) & 0x3f),
                               0x80 | ( $c          & 0x3f));

    } elsif ($c < 0x80000000) {
        return sprintf("%c%c%c%c%c%c",
                               0xfe |  ($c >> 30),
                               0x80 | (($c >> 24) & 0x3f),
                               0x80 | (($c >> 18) & 0x3f),
                               0x80 | (($c >> 12) & 0x3f),
                               0x80 | (($c >> 6)  & 0x3f),
                               0x80 | ( $c          & 0x3f));
    } else {
        return utf8(0xfffd);
    }
}

sub http_date {
    my $time = shift;
    $time = time unless defined $time;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    my $day   = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')[$wday];
    my $month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$mon];
    return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
                $day, $mday, $month, $year+1900, $hour, $min, $sec);
}

sub xml_escape {
    my $text = shift;
    $text =~ s/\&/\&amp;/g;
    $text =~ s/</\&lt;/g;
    # for use in attributes we do both just in case.
    $text =~ s/"/&quot;/g;
    $text =~ s/'/&apos;/g;
    return $text;
}

sub bytelength {
    use bytes;
    return length($_[0]);
}

1;
