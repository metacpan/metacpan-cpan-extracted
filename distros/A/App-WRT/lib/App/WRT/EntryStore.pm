package App::WRT::EntryStore;

use strict;
use warnings;
use 5.10.0;

use File::Find;
use Carp;

=pod

=head1 NAME

App::WRT::EntryStore - model the contents of a wrt repo's entry_dir

=head1 SYNOPSIS

    use App::WRT::EntryStore;
    my $entries = App::WRT::EntryStore->new('./archives');

    my @all = $entries->all();
    my @months = $entries->all_months();
    my @years = $entries->all_years();
    my @days = $entries->all_days();

    # all_* are wrappers for dates_by_depth():
    my @days = $entries->dates_by_depth(
      3 # 1 for years, 2 for months, 3 for days
    );

    my @recent_days = $entries->recent_days(30);
    my @recent_months = $entries->recent_months(12);
    my @recent_years = $entries->recent_years(10);

    # recent_* are wrappers for recent_by_depth():
    my @recent_days $entries->recent_by_depth(
      3, # 1 for years, 2 for months, 3 for days
      30 # count
    );

=head1 METHODS

=over

=item new($class, $entry_dir)

Get a new EntryStore, using a given $entry_dir.

Finds a list of entries for the given directory, and builds data structures
which can be used to index into entries by depth, property, and next/previous
entry.

=cut

sub new {
  my $class = shift;
  my ($entry_dir) = @_;

  my %params = (
    entry_dir => $entry_dir
  );

  my $self = \%params;

  bless $self, $class;

  my @source_files;
  my %entry_properties;
  my %property_entries;
  find(
    sub {
      # We skip index files, because they'll be rendered from the dir path:
      return if /index$/;
      if ($File::Find::name =~ m{^ \Q$entry_dir\E / (.*) $}x) {
        my $target = $1;
        push @source_files, $target;

        # Build hashes of all properties of entries, and all entries of properties:
        if ($target =~ m{(.*) / (.*) [.]prop $}x) {
          my ($entry, $property) = ($1, $2);

          $entry_properties{$entry} = []
            unless defined $entry_properties{$entry};
          push @{ $entry_properties{$entry} }, $property;

          $property_entries{$property} = []
            unless defined $property_entries{$property};
          push @{ $property_entries{$property} }, $entry;
        }
      }
    },
    $entry_dir
  );

  # Stash arrayref for future use:
  $self->{source_files} = \@source_files;
  $self->{property_entries}   = \%property_entries;
  $self->{entry_properties}   = \%entry_properties;

  $self->generate_date_hashes();

  return $self;
}

=item all()

Returns a list of all source files for the current entry archive (excepting
index files, which are a special case - this part could use some work).

This was originally in App::WRT::Renderer, so there may be some pitfalls here.

=cut

sub all {
  my ($self) = shift;
  return @{ $self->{source_files} };
}

=item dates_by_depth($depth)

Returns a sorted list of all date-like entries which are at a specified depth.
Use 1 for years, 2 for months, and 3 for days.

Fairly silly, but entertaining in its perverse way.  all_years(), all_months(),
and all_days() are provided for convenience.

=cut

sub dates_by_depth {
  my ($self) = shift;
  my ($depth) = @_;

  if (! defined $depth) {
    croak('No $depth given.');
  }

  # Check if we already have a value cached:
  return @{ $self->{by_depth}->{$depth} }
    if defined $self->{by_depth}->{$depth};

  # Build a pattern for matching the given depth of date-like entries.  For
  # example, a day would be depth 3, and matched by \d+/\d+/\d+
  my @particles;
  for (my $i = 0; $i < $depth; $i++) {
    push @particles, '\d+';
  }
  my $pattern = join '/', @particles;

  # Sort entries matching the above pattern by converting them to an array with
  # an easily sortable string format as the second value, like [ "2014/1/1",
  # "201400010001" ], sorting these arrayrefs by that value, and then
  # re-mapping them to the original values.
  #
  # See here: https://en.wikipedia.org/wiki/Schwartzian_transform

  my @by_depth = map  { $_->[0] }
                 sort { $a->[1] cmp $b->[1] }
                 map  { [$_, sortable_date_from_entry($_)] }
                 grep m{^ $pattern $}x, @{ $self->{source_files} };

  # Stash arrayref for future use:
  $self->{by_depth}->{$depth} = \@by_depth;

  return @by_depth;
}

sub sortable_date_from_entry {
  my ($entry) = @_;
  my @parts = map { sprintf("%4d", $_) } split '/', $entry;
  return join '', @parts;
}

=item all_years(), all_months(), all_days()

Convenience wrappers for dates_by_depth().

=cut

sub all_years  { return $_[0]->dates_by_depth(1); }
sub all_months { return $_[0]->dates_by_depth(2); }
sub all_days   { return $_[0]->dates_by_depth(3); }

=item recent_by_depth($depth, $entry_count)

Returns the $entry_count most recent dated entries at $depth (1 for year, 2 for
month, 3 for day).  recent_years(), recent_months(), and recent_days() are
provided for convenience.

=cut

sub recent_by_depth {
  my ($self) = shift;
  my ($depth, $entry_count) = @_;

  my @entries;
  for my $entry (reverse $self->dates_by_depth($depth)) {
    last if scalar(@entries) == $entry_count;
    push @entries, $entry;
  }

  return @entries;
}

=item all_years(), all_months(), all_days()

Convenience wrappers for recent_by_depth().

=cut

sub recent_years  { return $_[0]->recent_by_depth(1, $_[1]); }
sub recent_months { return $_[0]->recent_by_depth(2, $_[1]); }
sub recent_days   { return $_[0]->recent_by_depth(3, $_[1]); }

=item generate_date_hashes()

Store hashes which map dated entries to their previous and next entries at the
same depth in the tree.  That is, something like:

    %prev_dates = {
      '2014'     => '2013',
      '2014/1'   => '2013/12'
      '2014/1/1' => '2013/12/30',
      ...
    }

    %next_dates = {
      '2013'       => '2014',
      '2013/12'    => '2014/1',
      '2013/12/30' => '2014/1/1',
      ...
    }

=cut

sub generate_date_hashes {
  my $self = shift;

  my %prev;

  # Depth 1 is years, 2 is months, 3 is days.  Get lists for all:
  for my $depth (1, 2, 3) {
    my @dates = $self->dates_by_depth($depth);

    my $last_seen;
    foreach my $current_date (@dates) {
      if ($last_seen) {
        $prev{$current_date} = $last_seen;
      }
      $last_seen = $current_date;
    }
  }

  $self->{prev_dates} = { %prev };
  $self->{next_dates} = { reverse %prev };
}

=item previous($entry)

Return the previous entry at the same depth for the given entry.

=cut

sub previous {
  return $_[0]->{prev_dates}->{ $_[1] };
}

=item previous($entry)

Return the next entry at the same depth for the given entry.

=cut

sub next {
  return $_[0]->{next_dates}->{ $_[1] };
}

=item by_prop($property)

Return an array of any entries for the given property.

=cut

sub by_prop {
  my $self = shift;
  my ($property) = @_;

  my @entries;
  if (defined $self->{property_entries}{$property}) {
    @entries = @{ $self->{property_entries}{$property} };
  }

  return @entries;
}


=item props_for($entry)

Return an array of any properties for the given entry.

=cut

sub props_for {
  my $self = shift;
  my ($entry) = @_;

  my @props;
  if (defined $self->{entry_properties}{$entry}) {
    @props = @{ $self->{entry_properties}{$entry} };
  }

  return @props;
}

=item all_props()

Return an array of all properties.

=cut

sub all_props {
  my $self = shift;
  return keys %{ $self->{property_entries} };
}

=back

=cut

1;
