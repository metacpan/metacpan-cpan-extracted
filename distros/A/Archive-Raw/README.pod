package Archive::Raw;

use strict;
use warnings;
use Carp;

require XSLoader;
XSLoader::load ('Archive::Raw', $Archive::Raw::VERSION);

use Archive::Raw::DiskWriter;
use Archive::Raw::Entry;
use Archive::Raw::Match;
use Archive::Raw::Reader;

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Archive::Raw::constant not defined" if $constname eq '_constant';
    my ($error, $val) = _constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}


1;

__END__

=for HTML
<a href="https://dev.azure.com/jacquesgermishuys/p5-Archive-Raw">
	<img src="https://dev.azure.com/jacquesgermishuys/p5-Archive-Raw/_apis/build/status/jacquesg.p5-Archive-Raw?branchName=master" alt="Build Status: Azure" align="right" />
</a>
<a href="https://coveralls.io/github/jacquesg/p5-Archive-Raw">
	<img src="https://coveralls.io/repos/github/jacquesg/p5-Archive-Raw/badge.svg?branch=master" alt="Coverage Status" align="right"/>
</a>
=cut

=head1 NAME

Archive::Raw - Perl bindings to the libarchive library

=head1 DESCRIPTION

L<libarchive|https://www.libarchive.org> is a multi-format archive and compression
library.  This module provides Perl bindings to the libarchive API.

B<WARNING>: The API of this module is unstable and may change without warning
(any change will be appropriately documented in the changelog).

=head1 SYNOPSIS

	use Archive::Raw;

	# Extract 'archive.tar.gz' to 'out/'
	my $reader = Archive::Raw::Reader->new();
	$reader->open_filename ('archive.tar.gz');

	my $writer = Archive::Raw::DiskWriter->new (
		Archive::Raw->EXTRACT_TIME | Archive::Raw->EXTRACT_PERM |
		Archive::Raw->EXTRACT_ACL | Archive::Raw->EXTRACT_FFLAGS);

	my $extractPath = "out";
	while (my $entry = $reader->next())
	{
		my $filename = $extractPath.'/'.$entry->pathname;
		$entry->pathname ($filename);
		$writer->write ($entry);
	}

=head1 FUNCTIONS

=head2 libarchive_version( )

Get the libarchive version.

=head1 DOCUMENTATION

=head2 L<Achive::Raw::DiskWriter>

=head2 L<Achive::Raw::Entry>

=head2 L<Achive::Raw::Match>

=head2 L<Achive::Raw::Reader>

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
