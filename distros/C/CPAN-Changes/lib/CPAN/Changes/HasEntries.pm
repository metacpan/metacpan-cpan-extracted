package CPAN::Changes::HasEntries;
use strict;
use warnings;

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Sub::Quote qw(qsub);
use Types::Standard qw(ArrayRef InstanceOf Str);

use Moo::Role;

my $entry_type = (InstanceOf['CPAN::Changes::Entry'])->plus_coercions(
  Str ,=> qsub q{ CPAN::Changes::Entry->new(text => $_[0]) },
);

has entries => (
  is => 'rw',
  default => sub { [] },
  isa => ArrayRef[$entry_type],
  coerce => 1,
);

sub clone {
  my $self = shift;
  my %attrs = %$self;
  $attrs{entries} = [ map $_->clone, @{$self->entries} ];
  (ref $self)->new(%attrs, @_);
}

sub has_entries {
  my $self = shift;
  !!($self->entries && @{$self->entries});
}

sub find_entry {
  my ($self, $find) = @_;
  return undef
    unless $self->has_entries;
  if (ref $find ne 'Regexp') {
    $find = qr/\A\Q$find\E\z/;
  }
  my ($entry) = grep { $_->text =~ $find } @{ $self->entries };
  return $entry;
}

around serialize => sub {
  my ($orig, $self, %args) = @_;
  my $indents = $args{indents} || [];
  my $styles = $args{styles} || [];
  my $width = $args{width} || 75;
  $indents = [ @{$indents}[1 .. $#$indents], '  '],
  $styles = [ @{$styles}[1 .. $#$styles], '-'],
  my $out = $self->$orig(@_);
  my $entries = $self->entries || [];
  for my $entry ( @$entries ) {
    my $sub = $entry->serialize(
      indents => $indents,
      styles => $styles,
      width => $width - length $indents->[0],
    );
    $sub =~ s/^(.)/$indents->[0]$1/mg;
    $sub .= "\n"
      if $entry->has_entries;
    $out .= $sub;
  }
  $out =~ s/\n\n+\z/\n/;
  return $out;
};

sub add_entry {
  my ($self, @entries) = @_;
  $_ = $entry_type->coerce($_)
    for @entries;
  push @{ $self->entries }, @entries;
  return wantarray ? @entries : $entries[-1];
}

sub remove_entry {
  my ($self, $entry) = @_;
  $entry
    = ref $entry && $entry->isa('CPAN::Changes::Entry') ? $entry
    : $self->find_entry($entry);
  return unless $entry;
  my @entries = grep { $_ != $entry } @{ $self->entries };
  $self->entries(\@entries);
}

require CPAN::Changes::Entry;
1;
__END__

=for Pod::Coverage .*
