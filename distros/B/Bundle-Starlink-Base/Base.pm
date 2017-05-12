package Bundle::Starlink::Base;
use strict;
$VERSION = '0.02';

1;

__END__

=head1 NAME

Bundle::Starlink::Base - A bundle to install modules required to build
Starlink Perl modules.

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::Starlink::Base'

=head1 CONTENTS

ExtUtils::MakeMaker

Getopt::Long

IO::File

Proc::Simple

Tk

Params::Validate

DateTime

Time::Piece

IO::Tee

LWP::Simple

Math::Trig

Pod::Usage

Tk::TextANSIColor

SOAP::Lite

DateTime::Format::ISO8601

Statistics::Descriptive::Discrete

File::SearchPath

Number::Uncertainty

Term::ANSIColor

Text::Balanced

Time::HiRes

Time::Local

Tk::FileDialog

Tk::Pod

Tk::TextANSIColor

Time::Piece

Tk::Zinc

File::SearchPath

Statistics::Descriptive

Date::Manip

Astro::SLA

Astro::Telescope

Astro::Coords

Astro::WaveBand

Astro::Flux

Astro::FITS::Header

Astro::FITS::HdrTrans

Astro::Catalog

=head1 DESCRIPTION

This bundle should be used to obtain the base set of modules required
to install Starlink Perl modules.

=head1 AUTHOR

Brad Cavanagh
