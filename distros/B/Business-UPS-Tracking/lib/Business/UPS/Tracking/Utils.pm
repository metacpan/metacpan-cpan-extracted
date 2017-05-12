# ============================================================================
package Business::UPS::Tracking::Utils;
# ============================================================================
use utf8;
use 5.0100;

use strict;
use warnings;

use Try::Tiny;
use Business::UPS::Tracking::Exception;
use Moose::Util::TypeConstraints;
use Business::UPS::Tracking;
use MooseX::Getopt::OptionTypeMap;
use Business::UPS::Tracking::Meta::Attribute::Trait::Printable;
use Encode;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Utils - Utility functions

=head1 SYNOPSIS

 use Business::UPS::Tracking::Utils;
 
=head1 DESCRIPTION

This module provides some basic utility functions for 
L<Business::UPS::Tracking> and defines some Moose type constraints and 
coercions.
 
=head1 FUNCTIONS

=cut

subtype 'Business::UPS::Tracking::Type::XMLDocument' 
    => as class_type('XML::LibXML::Document');

coerce 'Business::UPS::Tracking::Type::XMLDocument' 
    => from 'Str' 
    => via {
        my $xml = $_;
        $xml = decode("iso-8859-1", $xml);
        
        my $parser = XML::LibXML->new(
            #encoding    => 'iso-8859-15'
        );
        return try {
            return $parser->parse_string($xml);
        } catch {
            Business::UPS::Tracking::X::XML->throw(
                error   => $_ || 'Unknown error parsing xml document',
                xml     => $xml,
            );
        }
    };
    
subtype 'Business::UPS::Tracking::Type::Date' 
    => as class_type('DateTime');

subtype 'Business::UPS::Tracking::Type::DateStr' 
    => as 'Str' 
    => where {
        m/^ 
            (19|20)\d\d #year
            (0[1-9]|1[012]) #month
            (3[01]|[12]\d|0[1-9]) #day
        $/x;
    };

coerce 'Business::UPS::Tracking::Type::DateStr' 
    => from 'Business::UPS::Tracking::Type::Date' 
    => via {
        return $_->format_cldr('yyyyMMdd');
    };

subtype 'Business::UPS::Tracking::Type::TrackingNumber'
    => as 'Str'
    => where { 
        my $trackingnumber = $_;
        return 0 
            unless ($trackingnumber =~ m/^1Z(?<tracking>[A-Z0-9]{8}\d{7})(?<checksum>\d)$/); 
        # Checksum check fails because UPS testdata has invalid checksum!
        return 1
            unless $Business::UPS::Tracking::CHECKSUM;
        my $checksum = $+{checksum};
        my $tracking = $+{tracking}; 
        $tracking =~ tr/ABCDEFGHIJKLMNOPQRSTUVWXYZ/23456789012345678901234567/;
        my ($odd,$even,$pos) = (0,0,0);
        foreach (split //,$tracking) {
            $pos ++;
            if ($pos % 2) {
                $odd += $_;
            } else {
                $even += $_;
            }
        }
        $even *= 2;
        my $calculated = $odd + $even;
        $calculated =~ s/^\d+(\d)$/$1/e;
        $calculated = 10 - $calculated
            unless ($calculated == 0);
        return ($checksum == $calculated);
    }
    => message { "Tracking numbers must start withn '1Z', contain 15 additional characters and end with a valid checksum : '$_'" };

subtype 'Business::UPS::Tracking::Type::CountryCode'
    => as 'Str'
    => where { m/^[A-Z]{2}$/ }
    => message { "Must be an uppercase ISO 3166-1 alpha-2 code" };

=head3 parse_date

 $datetime = parse_date($string);

Parses a date string (YYYYMMDD) and returns a L<DateTime> object.

=cut

sub parse_date {
    my $datestr = shift;
    
    return
        unless $datestr
        && $datestr =~ m/^
            (?<year>(19|20)\d\d)
            (?<month>0[1-9]|1[012])
            (?<day>3[01]|[12]\d|0[1-9])
        $/x;
    
    return try {
        DateTime->new(
            year    => $+{year},
            month   => $+{month},
            day     => $+{day},
        );
    } catch {
        Business::UPS::Tracking::X::XML->throw(
            error   => "Invalid date string: ".$_,
            xml     => $datestr,
        );
    };
}

=head3 parse_time

 $datetime = parse_time($string,$datetime);

Parses a time string (HHMMSS) and appends the parsed values to the given
L<DateTime> object

=cut

sub parse_time {
    my ($timestr,$datetime) = @_;
    
    return 
        unless $datetime;
    
    return $datetime
        unless $timestr 
        && $timestr =~ m/^
            (?<hour>\d\d)
            (?<minute>\d\d)
            (?<second>\d\d)
        $/x;
    
   try {
        $datetime->set_hour( $+{hour} );
        $datetime->set_minute( $+{minute} );
        $datetime->set_second( $+{second} );
        return 1;
    } catch {
        Business::UPS::Tracking::X::XML->throw(
            error   => "Invalid time string: ".$_,
            xml     => $timestr,
        );
    }

    return $datetime;
}


=head3 escape_xml

 my $escaped_string = escape_xml($string);

Escapes a string for xml

=cut

sub escape_xml {
    my ($string) = @_;
    
    $string =~ s/&/&amp;/g;
    $string =~ s/</&gt;/g;
    $string =~ s/>/&lt;/g;
    $string =~ s/"/&qout;/g;
    $string =~ s/'/&apos;/g;
    
    return $string;
}

1;
