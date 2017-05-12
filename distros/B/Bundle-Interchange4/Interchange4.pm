package Bundle::Interchange4;

$VERSION = '0.07';

1;

__END__

=head1 NAME

Bundle::Interchange4 - A bundle of the modules nice to have for Interchange 4.

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Interchange4'>

=head1 CONTENTS

Digest::MD5

MIME::Base64

URI::URL

HTML::Tagset

Bundle::LWP

Parse::RecDescent

OLE::Storage_Lite

Term::ReadKey

Term::ReadLine::Perl

Image::Size

DBI

Safe::Hole

Tie::ShadowHash

Business::UPS

IO::Scalar

SQL::Statement::Hash

Storable

Bundle::LWP

Spreadsheet::ParseExcel

Spreadsheet::WriteExcel

=head1 DESCRIPTION

This bundle installs the prerequisites for Interchange as well as some
modules that are not strictly necessary.

(Interchange was formerly known as Minivend.)

After installing this bundle, it is recommended that you quit the current
session and then run Interchange's C<makecat> program. That will give you the
benefit of line completion and history.

The core functions of Interchange I<will> run with a stock Perl, but
to use some features of Interchange (like the administrative interface)
you will need these modules.

=over 4

=item MD5
This module is used to generate unique cache keys. If you don't have it,
then keys will be computed with a checksum that has a very low but not
infinitesimal chance of causing a cache conflict.

=item Bundle::LWP
Certain parts of these modules (URI::URL and MIME::Base64) are required
for Interchange's internal HTTP server. Also, Business::UPS, for calculating
shipping, requires this.

=item Storable
If you have this module session save speed increases by anywhere from 25-60%.
Highly recommended for busy systems. 

=item Business::UPS
Enables lookup of shipping costs directly from www.ups.com.

=item SQL::Statement
Enables SQL-style search query statements for Interchange.

=item Safe::Hole
This helps Interchange deal with the object-creation restrictions
of I<Safe.pm>, used to encourage security.

=item DBI
Most people want to use SQL with Interchange, and this is a requirement.
You will also need the appropriate DBD module, i.e. DBD::mysql to support
B<MySQL>.

=item Term::ReadKey
Helps Term::ReadLine::Perl generate completions and editing.

=item Term::ReadLine::Perl
Gives you filename completion and command history in the makecat program.
Not used otherwise.


=head1 AUTHOR

Mike Heins, <heins@akopia.com>
