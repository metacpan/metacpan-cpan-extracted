package App::GHPT::WorkSubmitter::ChangedFiles;

use App::GHPT::Wrapper::OurMoose;

our $VERSION = '1.000012';

use List::Util 1.44 qw( any uniq );
use App::GHPT::Types qw( ArrayRef HashRef Str );

has [
    qw(
        added_files
        all_files
        deleted_files
        modified_files
        )
] => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    required => 1,
);

has _file_exists_hash => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_file_exists_hash',
);

sub _build_file_exists_hash ($self) {
    return +{ map { $_ => 1 } $self->all_files->@* };
}

sub changed_files ($self) {
    return [ uniq sort $self->added_files->@*, $self->modified_files->@* ];
}

sub changed_files_match ( $self, $regex ) {
    return any { $_ =~ $regex } $self->changed_files->@*;
}

sub changed_files_matching ( $self, $regex ) {
    return grep { $_ =~ $regex } $self->changed_files->@*;
}

sub file_exists ( $self, $path ) {
    return $self->_file_exists_hash->{$path};
}

# this is inefficently written, but it shouldn't really make any difference
# for the number of files we're talking about here
sub file_status ( $self, $path ) {
    return 'A' if any { $_ eq $path } $self->added_files->@*;
    return 'M' if any { $_ eq $path } $self->modified_files->@*;
    return 'D' if any { $_ eq $path } $self->deleted_files->@*;
    return q{ } if $self->file_exists($path);
    return undef;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Contains all the files that were modified or added in a branch

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GHPT::WorkSubmitter::ChangedFiles - Contains all the files that were modified or added in a branch

=head1 VERSION

version 1.000012

=head1 SYNOPSIS

=head1 DESCRIPTION

A class that represents what files were added, modified or deleted in a
branch, as well as what files exist in the branch.

Normally constructed by L<App::GHPT::WorkSubmitter::ChangedFilesFactory>.

=for test_synopsis use v5.20;

    my $factory = App::GHPT::WorkSubmitter::ChangedFilesFactory->new(
        merge_to_branch_name => 'master',
    );

    my $changed_files = $factory->changed_files;

    # print out all modified / added file in this branch
    say for $changed_files->changed_files->@*;

=head1 ATTRIBUTES

=head2 added_files

All files added in this branch.

Arrayref of String. Required.

=head2 modified_files

All files modified in this branch (excluding those that were added in this
branch)

Arrayref of String. Required.

=head2 deleted_files

All files deleted in this branch.

Arrayref of String. Required.

=head2 all_files

All files in this branch (including those created before the branch was
branched.)  i.e. every file that you'd get from a fresh checkout of this
branch.

Arrayref of String. Required.

=head1 METHODS

=head2 $changed->changed_files

All changed files (i.e. all files that were either added or modified in
this branch.)  Returns Arrayref of Strings.

=head2 $changed->changed_files_match( $regex )

Returns true iff any of the changed files filenames match the passed regex

=head2 $changed->changed_files_matching( $regex )

Returns a list of changed files filenames matching the passed regex

=head2 $changed->file_exists( $path )

Does the passed file exist on the branch (i.e. if you were to do a fresh
checkout of this branch would the file be present)

=head2 $changed->file_status( $path )

Returns the file status.  This is either C<A> (added), C<D> (deleted), C<M>
(modified), C< > (exists, not modified) or undef (doesn't exist).

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/App-GHPT/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
