package BuzzSaw::DataSource; # -*-perl-*-
use strict;
use warnings;

# $Id: DataSource.pm.in 21390 2012-07-18 08:42:25Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21390 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DataSource.pm.in $
# $Date: 2012-07-18 09:42:25 +0100 (Wed, 18 Jul 2012) $

our $VERSION = '0.12.0';

use Digest::SHA ();

use Moose::Role;

use MooseX::Types::Moose qw(Bool);
use BuzzSaw::Types qw(BuzzSawDB BuzzSawParser);

with 'MooseX::Log::Log4perl', 'MooseX::SimpleConfig';

requires 'next_entry', 'reset';

has 'db' => (
  is       => 'rw',
  isa      => BuzzSawDB,
  coerce   => 1,
  required => 1,
  lazy     => 1,
  default  => sub { require BuzzSaw::DB;
                    BuzzSaw::DB->new_with_config() },
);

has 'parser' => (
    is       => 'ro',
    isa      => BuzzSawParser,
    coerce   => 1,
    required => 1,
);

has 'readall' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

no Moose::Role;

sub checksum_file {
  my ( $self, $file ) = @_;

  my $sha = Digest::SHA->new(256);
  $sha->addfile($file);
  return $sha->b64digest;

}

sub checksum_data {
  my ( $self, $data ) = @_;

  return Digest::SHA::sha256_base64($data);
}

1;
__END__

=head1 NAME

BuzzSaw::DataSource - A Moose role which defines the BuzzSaw data source interface

=head1 VERSION

This documentation refers to BuzzSaw::DataSource version 0.12.0

=head1 SYNOPSIS

package BuzzSaw::DataSource::Example;
use Moose;

with 'BuzzSaw::DataSource';

sub next_entry {
  my ($self) = @_;
  ....
  return $line;
}

sub reset {
  my ($self) = @_;
  ....
}

=head1 DESCRIPTION

This is a Moose role which defines the methods which must be
implemented by any BuzzSaw data source class. It also provides a
number of common attributes which all data sources will require. A
data source is literally what the name implies, the class provides a
standard interface to any set of log data. A data source has a parser
associated with it which is known to be capable of parsing the
particular format of data found within this source. Note that this
means that different types of log files (e.g. syslog, postgresql and
apache) must be represented by different resources even though they
are all sets of files. There is no requirement that the data be stored
in files, it would be just as easy to store and retrieve it from a
database. As long as the data source returns data in the same way, one
complete entry at a time, it will work. A BuzzSaw data source is
expected to work like a stream. Each time the next entry is requested
the method should automatically move on until all entries in all
resources are exhausted. For example, the Files data source
automatically moves on from one file to another whenever the
end-of-file is reached.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

The following atributes are common to all classes which implement this
interface.

=over

=item db

This attribute holds a reference to the L<BuzzSaw::DB> object. When
the DataSource object is created you can pass in a string which is
treated as a configuration file name, this is used to create the
BuzzSaw::DB object via the C<new_with_config> class
method. Alternatively, a hash can be given which is used as the set of
parameters with which to create the new BuzzSaw::DB object.

=item parser

This attribute holds a reference to an object of a class which
implements the L<BuzzSaw::Parser> role. If a string is passed in then
it is considered to be a class name in the BuzzSaw::Parser namespace,
short names are allowed, e.g. passing in C<RFC3339> would result in a
new L<BuzzSaw::Parser::RFC3339> object being created.

=item readall

This is a boolean value which controls whether or not all files should
be read. If it is set to C<true> (i.e. a value of 1 - one) then the
code which normally attempts to avoid re-reading previously seen files
will not be used. The default value is C<false> (i.e. a value of 0 -
zero).

=back

=head1 SUBROUTINES/METHODS

Any class which implements this role must provide the following two
methods.

=over

=item $entry = $source->next_entry

This method returns the next entry from the stream of log entries as a
simple string. For example, with the Files data source - which works
through all lines in a set of files - this will return the next line
in the file.

This method should use the L<BuzzSaw::DB> object C<start_processing>
and C<register_log> methods to avoid re-reading sources (unless the
C<readall> attribute is true). It is also expected to begin and end DB
transactions at appropriate times. For example, the Files data source
starts a transaction when a file is opened and ends the transaction
when the file is closed. This is designed to strike a balance between
efficiency and the need to commit regularly to avoid the potential for
data loss.

Note that this method does NOT return a parsed entry, it returns the
simple string which is the next single complete log entry. When the
data source is exhausted it will return the C<undef> value.

=item $source->reset

This method must reset the position of all (if any) internal iterators
to their initial values. This then leaves the data source back at the
original starting position. Note that this does not imply that a
second parsing would be identical to the first (e.g. files may have
disappeared in the meantime).

=back

The following methods are provided as they are commonly useful to most
possible data sources.

=over

=item $sum = $source->checksum_file($file)

This returns a string which is the base-64 encoded SHA-256 digest of
the contents of the specified file.

=item $sum = $source->checksum_data($data)

This returns a string which is the base-64 encoded SHA-256 digest of
the specified data.

=head1 DEPENDENCIES

This module is powered by L<Moose>, it also requires L<MooseX::Types>,
L<MooseX::Log::Log4perl> and L<MooseX::SimpleConfig>.

The L<Digest::SHA> module is also required.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::DataSource::Files>, L<DataSource::Importer>, L<BuzzSaw::DB>, L<BuzzSaw::Parser>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

