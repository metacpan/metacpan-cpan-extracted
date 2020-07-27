package App::WRT::EntryStore;

use strict;
use warnings;
use 5.10.0;

use File::Find;
use Carp;
use App::WRT::Sort qw(sort_entries);
use App::WRT::Util qw(file_get_contents);

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

=cut

# "Constants"

my $ENTRYTYPE_FILE = 0;
my $ENTRYTYPE_DIR  = 1;
my $ENTRYTYPE_VIRT = 2;

my %SUBENTRY_IGNORE = ('index' => 1);
my $SUBENTRY_EXPR = qr{
  ^
    [[:lower:][:digit:]_-]+
    (
      [.]
      (tgz|zip|tar[.]gz|gz|txt)
    )?
  $
}x;

# What gets considered a renderable entry path:
my $RENDERABLE_EXPR = qr{
  ^
    (
      [[:lower:][:digit:]_\/-]+
    )
  $
}x;

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

  my @entries;
  my %source_files;
  my %entry_properties;
  my %property_entries;
  my %children;

  find(
    sub {
      return unless $File::Find::name =~ m{^ \Q$entry_dir\E / (.*) $}x;

      my $target = $1;

      # Build an ordered array of entries:
      push @entries, $target;

      # Build a hash indicating:
      #   a. that a file exists
      #   b. whether it's a flatfile or a directory
      if (-f $_) {
        $source_files{$target} = $ENTRYTYPE_FILE;
      } elsif (-d $_) {
        $source_files{$target} = $ENTRYTYPE_DIR;
      }

      # Build hashes of all properties of entries, and all entries of properties:
      if ($target =~ m{(.*) / (.*) [.]prop $}x) {
        my ($entry, $property) = ($1, $2);

        $entry_properties{$entry} //= [];
        push @{ $entry_properties{$entry} }, $property;

        $property_entries{$property} //= [];
        push @{ $property_entries{$property} }, $entry;
      }
    },
    $entry_dir
  );

  # Ensure that the entry list for every property is sorted:
  for (keys %property_entries) {
     $property_entries{$_} = [ sort_entries(@{ $property_entries{$_} }) ];
  }

  # Create virtual entries based on tags, _if there's not already a file
  # there_:
  foreach my $prop (keys %property_entries) {
    if ( $prop =~ m/^ tag[.] (.*)$/x ) {
      my $tag = $1;
      $tag =~ s{[.]}{/}g;
      unless (defined $source_files{$tag}) {
        push @entries, $tag;
        $source_files{$tag} = $ENTRYTYPE_VIRT;
      }
    }
  }

  # Stash refs for future use:
  $self->{entries}          = \@entries;
  $self->{source_files}     = \%source_files;
  $self->{property_entries} = \%property_entries;
  $self->{entry_properties} = \%entry_properties;

  $self->generate_date_hashes();
  $self->store_children();

  return $self;
}

=item all()

Returns a list of all source files for the current entry archive (excepting
index files, which are a special case - this part could use some work).

This was originally in App::WRT::Renderer, so there may be some pitfalls here.

=cut

sub all {
  my ($self) = shift;
  return @{ $self->{entries} };
}

=item all_renderable()

Returns a list of all existing source paths which are considered "renderable".

A path should match C<$RENDERABLE_EXPR> and not be an index file.

=cut

sub all_renderable() {
  my ($self) = shift;
  return grep {
    (index($_, '/index', -6) == -1)
    &&
    m/$RENDERABLE_EXPR/
  } @{ $self->{entries} };
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

  croak('No $depth given.')
    unless defined $depth;

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

  my @by_depth = sort_entries(
    grep m{^ $pattern $}x, $self->all()
  );

  # Stash arrayref for future use:
  $self->{by_depth}->{$depth} = \@by_depth;

  return @by_depth;
}

=item all_years(), all_months(), all_days()

Convenience wrappers for dates_by_depth().

=cut

sub all_years  { return $_[0]->dates_by_depth(1); }
sub all_months { return $_[0]->dates_by_depth(2); }
sub all_days   { return $_[0]->dates_by_depth(3); }

=item days_for($month), months_for($year)

Convenience wrappers for extracting days or months in a given month
or year.

=cut

sub days_for {
  my ($self, $container) = @_;
  return grep { m{^ \Q$container\E / }x } $self->all_days();
}

sub months_for {
  my ($self, $year) = @_;
  return grep { m{^ \Q$year\E / }x } $self->all_months();
}

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

=item store_children

Store hashes of arrayrefs which maps parents to their immediate children.

=cut

sub store_children {
  my $self = shift;

  my %child_cache;

  for my $entry ($self->all()) {
    my $dirname = $self->dirname($entry);
    $child_cache{$dirname} //= [ ];
    push @{ $child_cache{$dirname} }, $entry;
  }

  $self->{child_cache} = { %child_cache };
}

=item parent($entry)

Return an entry's parent, or undef if it's at the top level.

=cut

sub parent {
  my $self = shift;
  my ($entry) = @_;

  # Explode unless an entry actually exists in the archives:
  croak("No such entry: $entry") unless $self->is_extant($entry);

  my (@components) = split '/', $entry;
  pop @components;
  if (@components) {
    return join '/', @components;
  }
  return undef;
}

=item children($entry)

Return an entry's (immediate) children, if any.

=cut

sub children {
  my $self = shift;
  my ($entry) = @_;

  # Explode unless an entry actually exists in the archives:
  croak("No such entry: $entry") unless $self->is_extant($entry);

  if (defined $self->{child_cache}{$entry}) {
    return @{ $self->{child_cache}{$entry} };
  }
  return ();
}

=item children_basenames($entry)

Returns an entry's immediate children, but just basenames - not full paths.

=cut

sub children_basenames {
  my $self = shift;
  my ($entry) = @_;

  return map { $self->basename($_) } $self->children($entry);
}

=item get_sub_entries($entry_loc)

Returns "sub entries" based on the C<SUBENTRY_EXPR> regexp.

=cut

sub get_sub_entries {
  my ($self, $entry) = @_;

  # index gets special treatment as the text body of an entry, rather
  # than as a sub-entry:
  my @subs = grep { m/$SUBENTRY_EXPR/ } $self->children_basenames($entry);
  return sort grep { ! $SUBENTRY_IGNORE{$_} } @subs;

  # return grep { ! $SUBENTRY_IGNORE{$_} }
  #        grep { m/$SUBENTRY_EXPR/ }
  #        $self->children_basenames($entry);
}

=item previous($entry)

Return the previous entry at the same depth for the given entry.

=cut

sub previous {
  return $_[0]->{prev_dates}->{ $_[1] };
}

=item next($entry)

Return the next entry at the same depth for the given entry.

=cut

sub next {
  return $_[0]->{next_dates}->{ $_[1] };
}

=item by_prop($property)

Return an array of any entries for the given property.

=cut

sub by_prop {
  my ($self, $property) = @_;

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
  my ($self, $entry) = @_;

  my @props;
  if (defined $self->{entry_properties}{$entry}) {
    @props = @{ $self->{entry_properties}{$entry} };
  }

  return @props;
}

=item has_prop($entry, $prop)

Return 1 if the given entry has the given property.

=cut

sub has_prop {
  my ($self, $entry, $prop) = @_;
  my @props = grep { $_ eq $prop } $self->props_for($entry);
  return (@props == 1);
}

=item prop_value($entry, $prop)

Return the value of given property, if it exists.  Otherwise return undef.

=cut

sub prop_value {
  my ($self, $entry, $prop) = @_;
  if ($self->has_prop($entry, $prop)) {
    return file_get_contents(
      $self->{entry_dir} . '/' . $entry . '/' . $prop . '.prop'
    );
  }
  return undef;
}

=item all_props()

Return an array of all properties.

=cut

sub all_props {
  my $self = shift;
  return sort keys %{ $self->{property_entries} };
}

=item is_extant($entry)

Check if a given entry exists.

=cut

sub is_extant {
  my ($self, $entry) = @_;
  return exists($self->{source_files}{$entry});
}

=item is_dir($entry)

Check if an entry is a directory.

=cut

sub is_dir {
  my ($self, $entry) = @_;
  croak("No such entry: $entry") unless $self->is_extant($entry);
  return ($self->{source_files}{$entry} == $ENTRYTYPE_DIR);
}

=item is_file($entry)

Check if an entry is a flatfile.

=cut

sub is_file {
  my ($self, $entry) = @_;
  croak("No such entry: $entry") unless $self->is_extant($entry);
  return ($self->{source_files}{$entry} == $ENTRYTYPE_FILE);
}

=item is_renderable($entry)

Check if an entry path is, theoretically, renderable.

=cut

sub is_renderable {
  my ($self, $entry) = @_;
  return ($entry =~ $RENDERABLE_EXPR);
}

=item has_index($entry)

Check if an entry contains an index file.

TODO: Should this care about the pathological (?) case where index is a
directory?

=cut

sub has_index {
  my ($self, $entry) = @_;
  croak("No such entry: $entry") unless $self->is_extant($entry);
  return $self->is_extant($entry . '/index');
}

=item basename($entry)

Get a base name (i.e., filename without path) for a given entry.

=cut

sub basename {
  my ($self, $entry) = @_;
  my @parts = split '/', $entry;
  return pop @parts; 
}

=item dirname($entry)

Get a directory name (i.e., directory without filename) for a given entry.

=cut

sub dirname {
  my ($self, $entry) = @_;
  my @parts = split '/', $entry;
  pop @parts; 
  return join '/', @parts;
}

=back

=cut

1;
