package Bundle::InterchangeKitchenSink;

$VERSION = '1.14';

1;

__END__

=head1 NAME

Bundle::InterchangeKitchenSink - A bundle of most all the modules nice to have for Interchange. A lot of stuff.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::InterchangeKitchenSink'>

=head1 CONTENTS

Bundle::Interchange

Archive::Tar

Archive::Zip

Authen::Captcha

Business::UPS

Compress::Zlib

Crypt::SSLeay

Digest::SHA1

HTML::Parser

IO::Stty

IO::Tty

SOAP::Lite

Time::HiRes

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

=item Storable

If you have this module session save speed increases by anywhere from 25-60%.
Highly recommended for busy systems. 

=item Safe::Hole

This helps Interchange deal with the object-creation restrictions
of I<Safe.pm>, used to encourage security.

=item DBI

Most people want to use SQL with Interchange, and this is a requirement.
You will also need the appropriate DBD module, i.e. DBD::mysql to support
B<MySQL>.

=item Term::ReadKey

Helps Term::ReadLine::Perl generate completions and editing for makecat
and other interactive scripts from command line.

=item Term::ReadLine::Perl

Gives you filename completion and command history in the makecat program.
Not used otherwise.

=item MIME::Base64

Provides HTTP services for internal HTTP server and basic authentication.

=item URI::URL

Provides HTTP primitives for internal HTTP server.

=item HTML::Tagset

Required by Bundle::LWP.

=item Bundle::LWP

Certain parts of these modules (URI::URL and MIME::Base64) are required
for Interchange's internal HTTP server. Also, Business::UPS, for calculating
shipping, requires this.

=item Business::UPS

Enables lookup of shipping costs directly from www.ups.com. Requires Bundle::LWP.

=item IO::Scalar

Used for Spreadsheet::*Excel.

=item Parse::RecDescent

Used for Spreadsheet::*Excel.

=item OLE::Storage_Lite

Used for Spreadsheet::*Excel.

=item Image::Size

Optional but recommended for [image ...] tag.

=item Tie::ShadowHash

Needed for pre-fork mode of Interchange, prevents permanent write of configuration.

=item Spreadsheet::ParseExcel

Allows upload of XLS spreadsheets for database import in the UI.

=item Spreadsheet::WriteExcel

Allows output of XLS spreadsheets for database export in the UI.

=item Archive::Tar

Only needed for supplementary UserTag definitions.

=item Archive::Zip

Only needed for supplementary UserTag definitions.

=item Compress::Zlib

Only needed for supplementary UserTag definitions.

=item Crypt::SSLeay

Payment interface links via HTTPS/SSL.

=item SOAP::Lite

Only needed when employing SOAP.

=item Tie::Watch

Allows tied configuration values that execute subroutines on access or set.

=item Time::HiRes

Needed for some Intranet functions.

=item Authen::Captcha

Needed for captcha generation filter.

=item Digest::Bcrypt

Used for strong password encryption.

=item Crypt::Random

Used for strong password encryption.

=back

=head1 AUTHOR

Mike Heins, <mikeh@perusion.net>
