package CPAN::Changes::Group;
use strict;
use warnings;

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Sub::Quote qw(qsub);
use CPAN::Changes::Entry;

use Moo;

has _entry => (
  is => 'rw',
  handles => {
    is_empty => 'has_entries',
    add_changes => 'add_entry',
  },
  lazy => 1,
  default => qsub q{ CPAN::Changes::Entry->new(text => '') },
  predicate => 1,
);

sub name {
  my $self = shift;
  my $entry = $self->_entry;
  return $entry->can('text') ? $entry->text : '';
}

sub _maybe_entry {
  my $self = shift;
  if ($self->can('changes') == \&changes) {
    return $self->_entry;
  }
  else {
    return CPAN::Changes::Entry->new(
      text => $self->name,
      entries => $self->changes,
    );
  }
}

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
  my $args = $self->$orig(@args);
  if (!$args->{_entry}) {
    $args->{_entry} = CPAN::Changes::Entry->new({
      text => $args->{name} || '',
      entries => $args->{changes} || [],
    });
  }
  $args;
};

sub changes {
  my ($self) = @_;
  return []
    unless $self->_has_entry;
  [ map { $_->text } @{ $self->_entry->entries } ];
}

sub set_changes {
  my ($self, @changes) = @_;
  $self->clear_changes;
  my $entry = $self->_entry;
  for my $change (@changes) {
    $entry->add_entry($change);
  }
  return;
}

sub clear_changes {
  my ($self) = @_;
  my $entry = $self->_entry;
  @{$entry->entries} = ();
  $self->changes;
}

sub serialize {
  my ($self, %args) = @_;
  $args{indents} ||= [' ', ' '];
  $args{styles} ||= ['[]', '-'];
  $self->_maybe_entry->serialize(%args);
}

1;
__END__

=head1 NAME

CPAN::Changes::Group - An entry group in a CPAN Changes file

=head1 SYNOPSIS

  my $group = CPAN::Changes::Group->new(
    name    => 'A change group',
    changes => [
      'A change entry',
      'Another change entry',
    ],
  );

=head1 DESCRIPTION

Represents a group of change entries on a changelog release.  This is a legacy
interface for the and its use is discouraged.

Behind the scenes, this works as a proxy for the real L<CPAN::Changes::Entry>
objects.

=head1 ATTRIBUTES

=head2 name

The name of the change group.

=head1 METHODS

=head2 is_empty

=head2 add_changes

=head2 changes

=head2 set_changes

=head2 clear_changes

=head2 serialize

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes>

=back

=head1 AUTHORS

See L<CPAN::Changes> for authors.

=head1 COPYRIGHT AND LICENSE

See L<CPAN::Changes> for the copyright and license.

=cut
