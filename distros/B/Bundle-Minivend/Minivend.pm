package Bundle::Minivend;

$VERSION = '4.0';

1;

__END__

=head1 NAME

Bundle::Minivend - A nice to have modules for MiniVend

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Minivend'>

=head1 CONTENTS

MD5

MIME::Base64

Bundle::LWP

Term::ReadKey

Term::ReadLine::Perl

Business::UPS

SQL::Statement

Storable

Safe::Hole

DBI

=head1 DESCRIPTION

This bundle installs the prerequisites for MiniVend as well as some
modules that are not strictly necessary.

After installing this bundle, it is recommended that you quit the current
session and then run MiniVend's C<makecat> program. That will give you the
benefit of line completion and history.

None of the bundled modules are really needed for MiniVend, but
some functions require on them and you will be limited without them.

=over 4

=item MD5
This module is used to generate unique cache keys. If you don't have it,
then keys will be computed with a checksum that has a very low but not
infinitesimal chance of causing a cache conflict.

=item Bundle::LWP
Certain parts of these modules (URI::URL and MIME::Base64) are required
for MiniVend's internal HTTP server. In addition, Data::Dumper makes the
output of session dumps more readable.

=item Storable
If you have this module session save speed increases by anywhere from 25-60%.
Highly recommended for busy systems. 

=item Business::UPS
Enables lookup of shipping costs directly from www.ups.com.

=item SQL::Statement
Enables SQL-style search query statements for MiniVend.

=item Term::ReadKey
Helps Term::ReadLine::Perl generate completions and editing.

=item Term::ReadLine::Perl
Gives you filename completion and command history in the makecat program.
Not used otherwise.

=item DBI
Necessary if you want to use MySQL or some other SQL database.

=head1 AUTHOR

Mike Heins, <mike@minivend.com>
