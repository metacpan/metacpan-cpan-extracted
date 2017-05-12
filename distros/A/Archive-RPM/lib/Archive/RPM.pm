#############################################################################
#
# Manipulate an RPM archive
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
#
# Copyright (c) 2009, 2010 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Archive::RPM;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::AttributeHelpers;
use MooseX::Types::Path::Class ':all';

use overload '""' => sub { shift->rpm->basename };

use English '-no_match_vars';
use File::Temp 'tempdir';
use Path::Class;
use RPM2 0.67;

use Archive::RPM::ChangeLogEntry;

our $VERSION = '0.07';

with 'MooseX::Traits';
has '+_trait_namespace' => (default => 'Archive::RPM::TraitFor');

# debugging
#use Smart::Comments '###', '####';

around BUILDARGS => sub {
    my ($orig, $self) = (shift, shift);

    # if it's a single non-ref value, assume it's meant for 'rpm'
    return $self->$orig({ rpm => $_[0] }) if @_ == 1 && (!ref $_[0] || ref $_[0] ne 'HASH');
    return $self->$orig(@_);
};

sub BUILD {
    my $self = shift @_;
    my $rpm  = $self->rpm;

    die "$rpm does not exist!\n" unless $rpm->stat;

    return;
}

has rpm => (is => 'ro', isa => File, coerce => 1, required => 1);

sub nvr { (my $nvr = shift->as_nvre) =~ s/^.*://; $nvr }

has _header => (
    is         => 'ro', 
    isa        => 'RPM2::Header', 
    lazy_build => 1,
    
    # http://www.perlmonks.org/?node_id=588315 kick ass!
    handles => qr/^(?!(?s:.*)^(files|changelog|nvr)$)/,
);

sub _build__header { RPM2->open_package(shift->rpm) }

# lazy cheats! :-)
sub nvre      { shift->as_nvre           }
sub is_srpm   { shift->is_source_package }
sub is_source { shift->is_source_package }

has auto_cleanup => (is => 'ro', isa => 'Bool', default => 0);

has extracted_to => (
    is        => 'ro', 
    isa       => Dir, 
    lazy      => 1,
    builder   => '_build_extracted_to',
    predicate => 'has_been_extracted',
);

sub _build_extracted_to {
    my $self = shift @_;
    my $rpm  = $self->rpm->absolute;

    # create a tempdir and extract to it
    #my $dir = dir tempdir('archive.rpm.XXXXXX', CLEANUP => 1, TMPDIR => 1);
    my $dir = dir tempdir(
        'archive.rpm.XXXXXX', 
        CLEANUP => $self->auto_cleanup, 
        TMPDIR  => 1,
    );

    my $opts = '-idum --no-absolute-filenames --quiet';
    system "cd $dir ; rpm2cpio $rpm | cpio $opts";
    die "Error extracting rpm: $CHILD_ERROR" if $CHILD_ERROR;

    return $dir;
}

has _files => (
    metaclass => 'Collection::List',

    is         => 'ro',
    isa        => 'ArrayRef[Path::Class::Entity]',
    lazy_build => 1,

    provides => {
        'empty'     => 'has_files',
        'count'     => 'num_files',
        'map'       => 'map_files',
        'find'      => 'find_file',
        'grep'      => 'grep_files',
        'elements'  => 'files',
        'first'     => 'first_file',
        'last'      => 'last_file',
        'join'      => 'join_files',
    },
);

sub _build__files {
    my $self = shift @_;
    my @files;

    # get all our entries and return
    $self->extracted_to->recurse(callback => sub { push @files, shift });

    shift @files;
    return \@files;
}

has _cl => (
    metaclass => 'Collection::List',

    is         => 'ro', 
    isa        => 'ArrayRef[Archive::RPM::ChangeLogEntry]',
    lazy_build => 1,
    
    provides => {
        'count'     => 'num_changelog_entries',
        'map'       => 'map_changelog_entries',
        'find'      => 'find_changelog_entry',
        'grep'      => 'grep_changelog_entries',
        'elements'  => 'changelog',
        'first'     => 'first_changelog_entry',
        'last'      => 'last_changelog_entry',
        'get'       => 'get_changelog_entry',
    },
);

sub _build__cl { 
    my $self = shift @_;

    my @cls = 
        map { Archive::RPM::ChangeLogEntry->new($_) } 
        $self->_header->changelog
        ;

    return \@cls;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Archive::RPM - Work with a RPM

=head1 SYNOPSIS

	use Archive::RPM;
    my $rpm = Archive::RPM->new('foo-1.2-1.noarch.rpm');

    # RPM2 header functions...

    # other functions...

=head1 DESCRIPTION

Archive::RPM provides a more complete method of accessing an RPM's meta- and
actual data.  We access this information by leveraging L<RPM2> where we can,
and by "exploding" the rpm (with rpm2cpio and cpio) when we need information
we can't get through RPM2.

=head1 TRAITS

This package allows for the application of various "TraitFor" style traits
through the with_traits() function, e.g.:

    Archive::RPM->with_traits('Foo')->new(...);

By default, we look for traits in the "Archive::RPM::TraitsFor" namespace,
though this can be overridden by prepending a "+" to the full package name of
the trait.

=head1 METHODS

An object of this class represents an actual RPM, somewhere on the filesystem.
We provide all the methods L<RPM2::Header> does, as well as additional
functions to manipulate/extract the rpm itself (but not to install).

Right now, our documentation is horrible.  Please see L<RPM2> for the methods
provided by "RPM2::Header", and the source for the other functions we have
defined.  We support all methods provided by RPM2::Header, except the "files"
method (that's handled by other bits).

=over 4

=item B<new('file.rpm') | new(rpm =E<gt> 'file.rpm', ...)>

Creates a new Archive::RPM object.  Note that the rpm parameter is required,
and if it is the only one being passed the "rpm =>" may be omitted.

=over 4

=item B<rpm =E<gt> 'filename'|Path::Class::File>

Required.  Takes either a filename or a Path::Class::File object pointing to the rpm.

=item B<auto_cleanup =E<gt> 0|1>

Default is 1; if the rpm is extracted to the filesystem, purge this
automatically.

=back

=item B<rpm>

Returns a L<Path::Class::File> object representing the rpm we're working with.

=item B<extracted_to>

Returns a L<Path::Class::Dir> object representing where the rpm has been
exploded to.  If the rpm has not been exploded, it will be.

=item B<has_been_extracted>

Returns true if the rpm has been exploded; false if not.

=item B<is_source_package | is_srpm | is_source>

Returns true if this is a source rpm; false if not.

=item B<has_files>

True if this rpm contains any files. (Some, e.g. Fedora's "perl-core" package,
are "meta-packages" and do not deliver files; they simply ensure a given set
of dependencies exist on a system.  Sort of like Task::* CPAN dists.)

=item B<num_files>

Returns the number of files delivered.

=item B<grep_files>

Grep over the array of files; e.g.

    my ($spec) = $srpm->grep_files(sub { /\.spec$/ });

=item B<map_files>

=item B<files>

Returns an array of all the dir/files delievered by the rpm.  Note that these
are returned as Path::Class objects, and we use the directories and files
present on the filesystem after exploding the rpm rather than the list
described by the rpm itself.

=item B<first_file>

=item B<last_file>

=item B<join_files>

=item B<num_changelog_entries>

Returns the total number of changelog entries.

=item B<changelog_entries>

Returns an array of all the changelog entries.

=item B<first_changelog_entry>

Returns the first changelog entry; note that changelogs are stored in reverse
chronological order.  That is, the first changelog entry is the newest entry.

=item B<last_changelog_entry>

Returns the oldest changelog entry.

=item B<get_changelog_entry(Int)>

Get a specific changelog entry.

=item B<map_changelog_entries>

=item B<find_changelog_entry>

=item B<grep_changelog_entries>

=back

=head1 DIAGNOSTICS

We tend to complain and die loudly on any errors.

=head1 SEE ALSO

L<RPM2>

=head1 LIMITATIONS

Our documentation and test suite is clearly lacking, sadly.

We also have to explode the rpm for anything more intense than simply looking
at the header for info.  While this isn't really a _horrible_ thing, it's
annoying to have to, say, explode a 100MB ooffice rpm just to get a count of
how many files there are in it.

We do the "exploding" using external rpm2cpio and cpio binaries.  While we
could have used L<Archive::Cpio> to handle the cpio extraction, it seemed a
touch overkill; as there does not appear to be a Perl library to handle the
"rpm2cpio" part, we may as well use the cpio bin.  (It's not like it's missing
from many systems, anyways.

=head1 BUGS 

All complex software has bugs lurking in it, and this module is no
exception.  If you find a bug please either email me, or (preferred) 
to this package's RT tracker at C<bug-Archive-RPM@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, 2010 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut


# fin..
