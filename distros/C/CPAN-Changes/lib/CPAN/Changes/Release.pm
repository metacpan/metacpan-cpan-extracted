package CPAN::Changes::Release;
use strict;
use warnings;

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Moo;

with 'CPAN::Changes::HasEntries';

has version => (is => 'rw');
has date    => (is => 'rw');
has note    => (is => 'rw');
has line    => (is => 'ro');

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  if (my $changes = delete $args->{changes}) {
    if ($args->{entries}) {
      die "Mixing back-compat interface with new interface not allowed";
    }
    $args->{entries} = [];
    for my $group (sort keys %$changes) {
      my @entries = @{$changes->{$group}};

      if ($group eq '') {
        push @{$args->{entries}}, @entries;
      }
      else {
        my $entry = CPAN::Changes::Entry->new(
          text => $group,
          entries => \@entries,
        );
        push @{$args->{entries}}, $entry;
      }
    }
  }
  $args;
};

sub serialize {
  my ($self, %args) = @_;
  my $indents = $args{indents} || ['', ' ', ''];
  my $styles = $args{styles} || ['', '[]'];
  my $width = $args{width} || 75;

  my $out = $indents->[0] . $styles->[0] . $self->version;
  if ($self->date || $self->note) {
    $out .= ' ' . join ' ', (grep { defined } $self->date, $self->note);
  }
  $out . "\n";
}

around serialize => sub {
  my ($orig, $self, %args) = @_;
  $args{indents} ||= ['', ' ', ''];
  $args{styles} ||= ['', '[]'];
  $args{width} ||= 75;
  if (my $sort = $args{group_sort}) {
    my $entries = $self->_sorted_groups($sort);
    $self = $self->clone(entries => $entries);
  }
  $self->$orig(%args);
};

sub changes {
  my ($self, $group) = @_;
  if (defined $group) {
    return $self->get_group($group)->changes;
  }
  else {
    return { map { $_ => $self->get_group($_)->changes } $self->groups };
  }
}

sub add_changes {
  my $self = shift;
  my %opts;
  if (@_ > 1 && ref $_[0] eq 'HASH') {
    %opts = %{ +shift };
  }
  $self->get_group($opts{group} || '')->add_changes(@_);
}

sub set_changes {
  my $self = shift;
  my %opts;
  if (@_ > 1 && ref $_[0] eq 'HASH') {
    %opts = %{ +shift };
  }
  $self->get_group($opts{group} || '')->set_changes(@_);
}

sub clear_changes {
  $_[0]->entries([]);
}

sub groups {
  my ($self, %args) = @_;
  my $sort = $args{sort} || sub { sort @_ };
  my %groups;
  for my $entry ( @{ $self->entries } ) {
    if ($entry->has_entries) {
      $groups{$entry->text}++;
    }
    else {
      $groups{''}++;
    }
  }
  return $sort->(keys %groups);
}

sub add_group {
  my ($self, @groups) = @_;
  push @{ $self->entries }, map { CPAN::Changes::Entry->new(text => $_) } @groups;
}

sub delete_group {
  my ($self, @groups) = @_;
  my @entries = @{ $self->entries };
  for my $name (@groups) {
    @entries = grep { $_->text ne $name } @entries;
  }
  $self->entries(\@entries);
}

# this is nonsense, but try to emulate.  if nothing has entries, then there
# are no "groups", so leave everything.
sub delete_empty_groups {
  my ($self) = @_;
  my @entries = grep { $_->has_entries } @{ $self->entries };
  return
    if !@entries;
  $self->entries(\@entries);
}

sub get_group {
  my ($self, $name) = @_;
  require CPAN::Changes::Group;
  if (defined $name && length $name) {
    my ($entry) = grep { $_->text eq $name } @{ $self->entries };
    $entry ||= $self->add_entry($name);
    return CPAN::Changes::Group->new(_entry => $entry);
  }
  else {
    return CPAN::Changes::Group->new(_entry => $self);
  }
}

sub attach_group {
  my ($self, $group) = @_;
  my $entry = $group->_maybe_entry;
  my $text = $entry->text;
  my $entries = $self->entries;
  if ($text eq '') {
    $self->add_entry( @{ $entry->entries } );
  }
  elsif (my ($found) = grep { $_->text eq $text } @$entries) {
    $found->add_entry( @{ $entry->entries } );
  }
  else {
    $self->add_entry( $entry );
  }
}

sub group_values {
  my ($self, @groups) = @_;
  return map { $self->get_group($_) } $self->groups(@groups);
}

sub _sorted_groups {
  my ($self, $sort_function) = @_;
  my @groups = grep { $_->has_entries } @{ $self->entries };
  my @bare = grep { !$_->has_entries } @{ $self->entries };
  return \@bare
    if !@groups;

  my %entries = map { $_->text => [$_] } @groups;
  $entries{''} = \@bare
    if @bare;
  my @sorted = $sort_function->(keys %entries);
  return [ map { @{ $entries{$_} || [] } } @sorted ];
}

1;
__END__

=head1 NAME

CPAN::Changes::Release - A release in a CPAN Changes file

=head1 SYNOPSIS

  my $release = CPAN::Changes::Release->new(
    version => '0.01',
    date    => '2015-07-20',
  );

  $release->add_entry('This is a change');

=head1 DESCRIPTION

A changelog is made up of one or more releases. This object provides access to
all of the key data that embodies a release including the version number, date
of release, and all of the changelog information lines.

=head1 ATTRIBUTES

=head2 version

The version number of the release.

=head2 date

The date for the release.

=head2 note

The note attached to the release.

=head2 entries

An array ref of L<entries|CPAN::Changes::Entry> in the release.

=head2 line

The line number that the release starts at.

=head1 METHODS

=head2 serialize

Returns the changes entry for the release in string form.

=head2 clone

Returns a new release object with the same data. Can be given any attributes to
set them differently in the new object.

=head2 has_entries

Returns true if there are changes entries in this release.

=head2 find_entry

Accepts a string or a regex, returns a matching entry object.

=head2 add_entry

Adds a changes entry. Accepts a changes entry object or a string.

=head2 remove_entry

Given a string or a changes entry object, removes the entry from the release.

=head1 LEGACY METHODS

=head2 changes

=head2 add_changes

=head2 set_changes

=head2 clear_changes

=head2 groups

=head2 add_group

=head2 delete_group

=head2 delete_empty_groups

=head2 get_group

=head2 attach_group

=head2 group_values

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes>

=back

=head1 AUTHORS

See L<CPAN::Changes> for authors.

=head1 COPYRIGHT AND LICENSE

See L<CPAN::Changes> for the copyright and license.

=cut
