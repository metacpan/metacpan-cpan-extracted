# IO/File/RecordStream.pm
package IO::File::RecordStream;
our $VERSION = '0.02';

use 5.006;
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use autodie qw(:all);
use Scalar::Util qw(reftype openhandle);

use IO::Lines;

has 'file_name' => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_file_name',
);

has 'file_handle' => (
    is          => 'ro',
    isa         => 'FileHandle',
    builder     => '_build_file_handle',
    lazy        => 1,
);

has 'end_reached' => (
    is          => 'ro',
    default     => 0,
    init_arg    => undef,
    writer      => '_end_reached',          # private writer
);

# A regexp matching the separator line used to separate individual records
has 'match_separator' => (
    is          => 'ro',
    isa         => 'RegexpRef',
    required    => 1,
);

# A code ref that can be passed a ref to the array containing the read
# lines and that makes a new record object from it.
has '_record_factory' => (                  # keep the ref private
    is          => 'ro',
    isa         => 'CodeRef',
    init_arg    => 'record_factory',
    required    => 1,
);

# Allow various calling styles of the constructor:
# new(file_handle): pass file handle to read data from
# new(file_name):   pass file name of file to read data from
# These don't make much sense in this class because other attributes require
# initialization as well, but in a sub-class these may be overwritten and
# calling with only a file name and file handle is convenient.
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    return $class->$orig(@_) unless @_ == 1;  # no special handling

    # Check if we got a file name or handle for multi-record input file.
    if (not reftype $_[0]) {                    # file name given
        my $input_file_name = shift;
        return $class->$orig(file_name => $input_file_name);
    }
    elsif (reftype $_[0] eq reftype \*STDIN) {  # file handle given
        my $input_file_handle = shift;
        return $class->$orig(file_handle => $input_file_handle);
    }
    else {                                      # no file name / handle
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;

    confess 'The value of file_handle does not seem to be an open handle'
        unless openhandle $self->file_handle;

    # If the input file is empty, set end_reached immediately.
    $self->_end_reached(1) if eof $self->file_handle;

    return;
}

# Open file handle from file name if no handle was passed. Die if we cant.
sub _build_file_handle {
    my $self = shift;

    confess 'Cannot build file handle unless a file name was specified'
        unless $self->has_file_name;

    open my $input_file_handle, '<', $self->file_name;
    return $input_file_handle;
}

# Returns chomped lines.
sub _read_next_record {
    my $self = shift;

    my $record_file_handle = $self->file_handle;
    my @record_lines;
    while (<$record_file_handle>) {
        my $line = $_;
        chomp $line;

        if ($line =~ $self->match_separator) {            # end of record
            # Drop separator line and return current collection of lines.
            # Also test if file ends in a separator.
            $self->_end_reached(1) if eof $record_file_handle;
            return \@record_lines
        }
        else {
            # Store lines until end of record
            push @record_lines, $line;
        }
    }

    $self->_end_reached(1);                     # file has been read
    return \@record_lines;
}

# Get the next record from the multi-record file.
sub next {
    my $self = shift;

    # Are there any more entries?
    return if $self->end_reached;

    # Read lines of next record.
    my $record_lines_ref = $self->_read_next_record;

    # Construct record object using factory
    my $record_array_handle = IO::Lines->new($record_lines_ref);
    my $record = $self->_record_factory->($record_array_handle);

    return $record;
}

__PACKAGE__->meta->make_immutable;

1; # End of IO::File::RecordStream

__END__


=pod

=encoding UTF-8

=head1 NAME

IO::File::RecordStream - Read multi-line records from a file.

=head1 SYNOPSIS

    use Bio::RNA::Treekin;

=head1 DESCRIPTION

Auxiliary class to read records consisting of multiple lines, separated by a
separator matching a specified regular expression.

=head1 METHODS

=head2 IO::File::RecordStream->new($file_name, @args)

=head2 IO::File::RecordStream->new($file_handle)

Construct a new record stream from a file name or handle.

=over

=item Mandatory arguments:

=over

=item file_name | file_handle

Name of or handle to file to read data from. Pass either

=item match_separator

Quoted regular expression matching the record separator. The input file is
split at every match.

=item record_factory

A code ref that, when called with an array ref containing the lines of a
single record, parses the data and constructs a record object.

=back

=back

Additionally, the constructor can be called with a single file name or file
handle (without keyword). This requires to override the C<match_separator> and
C<record_factory> attributes to provide default values.

=head2 $stream->next

Returns the next record object. Internally, the input file is read until the
next match of the C<match_separator>. The data is passed on to the
C<record_factory> and the returned record object is returned.

=head2 $stream->file_name

Return the name of the file that this object reads data from. May be C<undef>
if the data was read from a handle. Use predicate C<has_file_name> to query
its presence.

=head2 $stream->has_file_name

Predicate query whether a file name has been used to read the data.

=head2 $stream->file_handle

Handle to the file the data is being read from.

=head2 $stream->end_reached

Query whether the input file was read completely yet.

=head2 $stream->match_separator

Returns the matching expression used to identify the record separator.

=head1 AUTHOR

Felix Kuehnl, C<< <felix@bioinf.uni-leipzig.de> >>


=head1 BUGS

Please report any bugs or feature requests by raising an issue at
L<https://github.com/xileF1337/Bio-RNA-Treekin/issues>.

You can also do so by mailing to C<bug-bio-rna-treekin at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-RNA-Treekin>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::RNA::Treekin


You can also look for information at:

=over 4

=item * Github: the official repository

L<https://github.com/xileF1337/Bio-RNA-Treekin>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-Treekin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-RNA-Treekin>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bio-RNA-Treekin>

=item * Search CPAN

L<https://metacpan.org/release/Bio-RNA-Treekin>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2019-2021 Felix Kühnl.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

# End of IO/File/RecordStream.pm
