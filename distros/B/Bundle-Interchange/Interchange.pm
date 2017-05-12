package Bundle::Interchange;

$VERSION = '1.08';

1;

__END__

=head1 NAME

Bundle::Interchange - A bundle of the modules nice to have for Interchange 5.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Interchange'>

=head1 CONTENTS

Digest::MD5

Digest::SHA

MIME::Base64

MIME::Lite

JSON

URI::URL

HTML::Tagset

HTML::Entities

LWP

LWP::Protocol::https

Parse::RecDescent

OLE::Storage_Lite

Term::ReadKey

Term::ReadLine::Perl

Text::Query

Image::Size

DBI

Safe::Hole

Tie::ShadowHash

Set::Crontab

IO::Scalar

Storable

Spreadsheet::ParseExcel

Spreadsheet::WriteExcel

Net::IP::Match::Regexp

Digest::Bcrypt

Crypt::Random


=head1 DESCRIPTION

This bundle installs the prerequisites for Interchange 5 as well as some
modules that are not strictly necessary.

(Interchange was formerly known as Minivend.)

After installing this bundle, it is recommended that you quit the current
session and then run Interchange's C<makecat> program. That will give you the
benefit of line completion and history.

The core functions of Interchange I<will> run with a stock Perl, but
to use some features of Interchange (like the administrative interface)
you will need these modules.

=over 4

=item Digest::MD5
This module is used to generate unique cache keys. If you don't have it,
then keys will be computed with a checksum that has a very low but not
infinitesimal chance of causing a cache conflict.

=item MIME::Base64

Used for decoding HTTP authorization, also part of Bundle::LWP.

=item Bundle::LWP
Business::UPS, for calculating shipping, requires this. The [get-url ...]
UserTag and most payment gateways also need LWP.

=item Storable
If you have this module session save speed increases by anywhere from 25-60%.
Highly recommended for busy systems. 

=item Business::UPS
Enables lookup of shipping costs directly from www.ups.com.

=item HTML::Parser

The HTML::Entities module, which is part of this package, is used to
parse HTML entities for substitution. URI::URL and HTML::TagSet are
prerequisites.

=item Text::Query

Gives Altavista-style search language with AND, OR, NOT, and NEAR and
full parentheses nesting.

=item Safe::Hole
This helps Interchange deal with the object-creation restrictions
of I<Safe.pm>, used to encourage security.

=item DBI
Most people want to use SQL with Interchange, and this is a requirement.
You will also need the appropriate DBD module, i.e. DBD::mysql to support
B<MySQL>.

=item Spreadsheet::ParseExcel

Allows upload of XLS spreadsheets in UI. IO::Scalar and OLE::Storage_Lite
are prerequisites.

=item Spreadsheet::WriteExcel

Allows creation of XLS spreadsheets for download in UI.

=item Term::ReadLine::Perl

Gives you filename completion and command history in the makecat program.
Not used otherwise.

=item Term::ReadKey

Helps Term::ReadLine::Perl generate completions and editing in makecat.
Not used otherwise.

=item Digest::Bcrypt

Used for strong password encryption.

=item Crypt::Random

Used for strong password encryption.

=back

=head1 AUTHOR

Mike Heins, <mikeh@perusion.net>
