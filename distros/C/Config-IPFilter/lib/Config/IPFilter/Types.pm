package Config::IPFilter::Types;
{
    use Moose::Util::TypeConstraints;
    our $MAJOR = 1; our $MINOR = 0; our $DEV = 0; our $VERSION = sprintf('%0d.%02d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);

    # IPv6 packed address
    subtype 'Config::IPFilter::Types::Paddr' => as 'Str' =>
        where { length $_ == 16 } =>
        message { sprintf '%s is not 16 bytes', $_ };
    coerce 'Config::IPFilter::Types::Paddr' => from 'Str' =>
        via { ip2paddr($_) };

    #
    subtype 'Config::IPFilter::Types::Addr' => as 'ArrayRef' =>
        where { $#{$_[0]} == 1 }   => message {'looking for [host, port]'} =>
        where { defined $_[0][0] } => message {'hostname is missing'} =>
        where { defined $_[0][1] } => message {'port is missing'} =>
        where { $_[0][1] =~ m[^\d+$] } => message {'malformed port'};

    # Utility function
    sub ip2paddr {
        my $addr = shift;
        $addr = '::' . $addr unless $addr =~ /:/;
        if ($addr =~ /^(.*:)(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
        {    # mixed hex, dot-quad
            return undef if $2 > 255 || $3 > 255 || $4 > 255 || $5 > 255;
            $addr = sprintf('%s%X%02X:%X%02X', $1, $2, $3, $4, $5)
                ;    # convert to pure hex
        }
        my $c;
        return undef
            if $addr =~ /[^:\da-f]/i ||    # non-hex character
                (($c = $addr) =~ s/::/x/ && $c =~ /(?:x|:):/)
                ||                         # double :: ::?
                $addr =~ /[0-9a-fA-F]{5,}/;    # more than 4 digits
        $c = $addr =~ tr[:][:];                # count the colons
        return undef if $c < 7 && $addr !~ /::/;
        if ($c > 7) {                          # strip leading or trailing ::
            return undef
                unless $addr =~ s|^::|:|
                    || $addr =~ s|::$|:|;
            return undef if --$c > 7;
        }
        $addr =~ s|::|:::| while $c++ < 7;     # expand compressed fields
        $addr .= 0 if $addr =~ m[:$];
        my @hex = split ':', $addr;
        $hex[$_] = hex $hex[$_] || 0 for 0 .. $#hex;
        return pack 'n8', @hex;
    }

    sub paddr2ip ($) {
        return inet_ntoa($_[0]) if length $_[0] == 4;    # ipv4
        return inet_ntoa($1)
            if length $_[0] == 16
                && $_[0] =~ m[^\0{10}\xff{2}(.{4})$];    # ipv4
        return unless length($_[0]) == 16;
        my @hex = (unpack('n8', $_[0]));
        $hex[9] = $hex[7] & 0xff;
        $hex[8] = $hex[7] >> 8;
        $hex[7] = $hex[6] & 0xff;
        $hex[6] >>= 8;
        my $return = sprintf '%X:%X:%X:%X:%X:%X:%D:%D:%D:%D', @hex;
        $return =~ s|(0+:)+|:|x;
        $return =~ s|^0+    ||x;
        $return =~ s|^:+    |::|x;
        $return =~ s|::0+   |::|x;
        $return =~ s|^::(\d+):(\d+):(\d+):(\d+)|$1.$2.$3.$4|x;
        return $return;
    }

    #
    no Moose::Util::TypeConstraints;
}
1;

=pod

=head1 NAME

Config::IPFilter::Types - Moose Types for Config::IPFilter

=head1 Description

Nothing to see here (yet), folks. Keep it movin'.

=head1 Author

=begin :html

L<Sanko Robinson|http://sankorobinson.com/>
<L<sanko@cpan.org|mailto://sanko@cpan.org>> -
L<http://sankorobinson.com/|http://sankorobinson.com/>

CPAN ID: L<SANKO|http://search.cpan.org/~sanko>

=end :html

=begin :text

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=end :text

=head1 License and Legal

Copyright (C) 2010, 2011 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=for rcs $Id: Types.pm 53e0787 2011-02-01 15:34:19Z sanko@cpan.org $

=cut
