package Bundle::DateTime::Complete;

$VERSION = '0.15';

1;

__END__

=head1 NAME

Bundle::DateTime::Complete - Bundle with all DateTime related modules

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::DateTime::Complete'>

=head1 CONTENTS

Class::Factory::Util 1.3 - prereq's of DateTime
Params::Validate 0.76
Test::More 0.34
Time::Local 1.04
Pod::Man 1.14

Module::Build

Class::Singleton 1.03 - prereq of DT::TimeZone

DateTime::Locale 0.21 - needed by DateTime 
DateTime::TimeZone 0.38 - needed by DateTime

DateTime

DateTime::Set

DateTime::HiRes

DateTime::Functions

DateTime::Incomplete

DateTime::Util::Calc
DateTime::Util::Astro::Common
DateTime::Util::DayOfWeek

DateTime::Calendar::Coptic 
DateTime::Calendar::Discordian
DateTime::Calendar::FrenchRevolutionary 
DateTime::Calendar::Hebrew
DateTime::Calendar::Hijri
DateTime::Calendar::Japanese::Era
DateTime::Calendar::Julian  -- prereq of Easter
DateTime::Calendar::Christian -- prereq of NameDay
DateTime::Calendar::Mayan 
DateTime::Calendar::Pataphysical

DateTime::Fiction::JRRTolkien::Shire

Math::Round -- prereq of DT::Ev::SolarTerm

DateTime::Event::Recurrence -- prereq of ICal
DateTime::Event::Lunar -- prereq of Chinese
DateTime::Event::SolarTerm -- prereq of Chinese
DateTime::Event::Chinese
DateTime::Event::Cron 
DateTime::Event::Easter 
DateTime::Event::ICal 
DateTime::Event::NameDay 
DateTime::Event::Random
DateTime::Event::Sunrise

DateTime::Format::Strptime -- needed by DT::F::Builder 
DateTime::Format::Builder -- prereq of several other formats
DateTime::Format::Baby 
DateTime::Format::Bork 
DateTime::Format::DateManip 
DateTime::Format::DateParse
DateTime::Format::DB2
DateTime::Format::DBI 
DateTime::Format::Duration
DateTime::Format::Epoch 
DateTime::Format::Excel 
DateTime::Format::HTTP 
DateTime::Format::Human 
DateTime::Format::IBeat 
DateTime::Format::ICal 
DateTime::Format::ISO8601 
DateTime::Format::Mail 
DateTime::Format::MySQL 
DateTime::Format::Pg 
DateTime::Format::Roman 
DateTime::Format::RSS
DateTime::Format::W3CDTF
DateTime::Format::WindowsFileTime

DateTime::TimeZone::Alias
DateTime::TimeZone::LMT

DateTime::Fiscal::Year

DateTime::Calendar::Chinese
DateTime::Calendar::Japanese
DateTime::Format::Japanese

=head1 DESCRIPTION

This bundle contains all modules related to the DateTime project: base
modules, formatters and parsers, calendars and event modules.

If you're not seriously interested in dates, times, calendars, or the
DateTime project, you might be better served by individually installing
the modules you need.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

The best address to send questions or additions to is the datetime
mailing list <datetime@perl.org>.

Bundle::DateTime::Complete is public domain. Note that this does not
cover the individual packages installed by this Bundle; these all are
separately licensed. See the appropriate license files in those
packages.

=head1 SEE ALSO

http://datetime.perl.org/

=cut
