package Config::MVP::Sequence;
# ABSTRACT: an ordered set of named configuration sections
$Config::MVP::Sequence::VERSION = '2.200012';
use Moose 0.91;

#pod =head1 DESCRIPTION
#pod
#pod A Config::MVP::Sequence is an ordered set of configuration sections, each of
#pod which has a name unique within the sequence.
#pod
#pod For the most part, you can just consult L<Config::MVP> to understand what this
#pod class is and how it's used.
#pod
#pod =cut

use Tie::IxHash;
use Config::MVP::Error;
use Config::MVP::Section;
use Moose::Util::TypeConstraints ();

# This is a private attribute and should not be documented for futzing-with,
# most likely. -- rjbs, 2009-08-09
has sections => (
  isa      => 'HashRef[Config::MVP::Section]',
  reader   => '_sections',
  init_arg => undef,
  default  => sub {
    tie my %section, 'Tie::IxHash';
    return \%section;
  },
);

has assembler => (
  is   => 'ro',
  isa  => Moose::Util::TypeConstraints::class_type('Config::MVP::Assembler'),
  weak_ref => 1,
  predicate => '_assembler_has_been_set',
  reader    => '_assembler',
  writer    => '__set_assembler',
);

sub _set_assembler {
  my ($self, $assembler) = @_;

  Config::MVP::Error->throw("can't alter Config::MVP::Sequence's assembler")
    if $self->assembler;

  $self->__set_assembler($assembler);
}

sub assembler {
  my ($self) = @_;
  return undef unless $self->_assembler_has_been_set;
  my $assembler = $self->_assembler;

  unless (defined $assembler) {
    Config::MVP::Error->throw("can't access sequences's destroyed assembler")
  }

  return $assembler;
}

#pod =attr is_finalized
#pod
#pod This attribute is true if the sequence has been marked finalized, which will
#pod prevent any changes (via methods like C<add_section> or C<delete_section>).  It
#pod can be set with the C<finalize> method.
#pod
#pod =cut

has is_finalized => (
  is  => 'ro',
  isa => 'Bool',
  traits   => [ 'Bool' ],
  init_arg => undef,
  default  => 0,
  handles  => { finalize => 'set' },
);

#pod =method add_section
#pod
#pod   $sequence->add_section($section);
#pod
#pod This method adds the given section to the end of the sequence.  If the sequence
#pod already contains a section with the same name as the new section, an exception
#pod will be raised.
#pod
#pod =cut

sub add_section {
  my ($self, $section) = @_;

  Config::MVP::Error->throw("can't add sections to finalized sequence")
    if $self->is_finalized;

  my $name = $section->name;
  confess "already have a section named $name" if $self->_sections->{ $name };

  $section->_set_sequence($self);

  if (my @names = $self->section_names) {
    my $last_section = $self->section_named( $names[-1] );
    $last_section->finalize unless $last_section->is_finalized;
  }

  $self->_sections->{ $name } = $section;
}

#pod =method delete_section
#pod
#pod   my $deleted_section = $sequence->delete_section( $name );
#pod
#pod This method removes a section from the sequence and returns the removed
#pod section.  If no section existed, the method returns false.
#pod
#pod =cut

sub delete_section {
  my ($self, $name) = @_;

  Config::MVP::Error->throw("can't delete sections from finalized sequence")
    if $self->is_finalized;

  my $sections = $self->_sections;

  return unless exists $sections->{ $name };

  $sections->{ $name }->_clear_sequence;

  return delete $sections->{ $name };
}

#pod =method section_named
#pod
#pod   my $section = $sequence->section_named( $name );
#pod
#pod This method returns the section with the given name, if one exists in the
#pod sequence.  If no such section exists, the method returns false.
#pod
#pod =cut

sub section_named {
  my ($self, $name) = @_;
  my $sections = $self->_sections;

  return unless exists $sections->{ $name };
  return $sections->{ $name };
}

#pod =method section_names
#pod
#pod   my @names = $sequence->section_names;
#pod
#pod This method returns a list of the names of the sections, in order.
#pod
#pod =cut

sub section_names {
  my ($self) = @_;
  return keys %{ $self->_sections };
}

#pod =method sections
#pod
#pod   my @sections = $sequence->sections;
#pod
#pod This method returns the section objects, in order.
#pod
#pod =cut

sub sections {
  my ($self) = @_;
  return values %{ $self->_sections };
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Sequence - an ordered set of named configuration sections

=head1 VERSION

version 2.200012

=head1 DESCRIPTION

A Config::MVP::Sequence is an ordered set of configuration sections, each of
which has a name unique within the sequence.

For the most part, you can just consult L<Config::MVP> to understand what this
class is and how it's used.

=head1 ATTRIBUTES

=head2 is_finalized

This attribute is true if the sequence has been marked finalized, which will
prevent any changes (via methods like C<add_section> or C<delete_section>).  It
can be set with the C<finalize> method.

=head1 METHODS

=head2 add_section

  $sequence->add_section($section);

This method adds the given section to the end of the sequence.  If the sequence
already contains a section with the same name as the new section, an exception
will be raised.

=head2 delete_section

  my $deleted_section = $sequence->delete_section( $name );

This method removes a section from the sequence and returns the removed
section.  If no section existed, the method returns false.

=head2 section_named

  my $section = $sequence->section_named( $name );

This method returns the section with the given name, if one exists in the
sequence.  If no such section exists, the method returns false.

=head2 section_names

  my @names = $sequence->section_names;

This method returns a list of the names of the sections, in order.

=head2 sections

  my @sections = $sequence->sections;

This method returns the section objects, in order.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
