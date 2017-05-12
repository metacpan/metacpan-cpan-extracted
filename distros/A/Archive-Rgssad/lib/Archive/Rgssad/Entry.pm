package Archive::Rgssad::Entry;

use 5.010;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Archive::Rgssad::Entry - A (path, data) pair in rgssad archive.

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

    use Archive::Rgssad::Entry;

    # create a new entry
    my $entry = Archive::Rgssad::Entry->new($path, $data);

    # update path and data
    $entry->path($new_path);
    $entry->data($new_data);

    # save the entry to file
    open FH, '>', $entry->path;
    print FH $entry->data;
    close FH;

=head1 DESCRIPTION

Each entry in rgssad archive is simply a (path, data) pair.

=head2 Constructor

=over 4

=item new([$path [, $data]])

Create a new entry.

=back

=cut

sub new {
  my $class = shift;
  my $self = {
    path => $_[0] // '',
    data => $_[1] // ''
  };
  bless $self, $class;
  return $self;
}

=head2 Accessors

=over 4

=item path([$new_path])

Return the path of the entry. If $new_path is given, set the path to $new_path and return it.

=cut

sub path {
  my $self = shift;
  $self->{path} = shift if @_;
  return $self->{path};
}

=item data([$new_data])

Return the data of the entry. If $new_data is given, set the data to $new_data and return it.

=cut

sub data {
  my $self = shift;
  $self->{data} = shift if @_;
  return $self->{data};
}

=back

=head1 AUTHOR

Zejun Wu, C<< <watashi at watashi.ws> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::Rgssad::Entry


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/watashi/perl-archive-rgssad>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zejun Wu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Archive::Rgssad::Entry
