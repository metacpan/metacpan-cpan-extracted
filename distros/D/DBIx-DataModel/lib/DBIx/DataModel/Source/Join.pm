package DBIx::DataModel::Source::Join;
use warnings;
use strict;
use parent 'DBIx::DataModel::Source';
use mro 'c3';
require 5.008; # for filehandle in memory
use Carp;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

# Support for Storable::{freeze,thaw} : just a stupid blank operation,
# but that will force Storable::thaw to try to reload the join class ... 
# and then we can catch it and generate it on the fly (see @INC below)

sub STORABLE_freeze {
  my ($self, $is_cloning) = @_;

  return if $is_cloning;
  my $copy = {%$self};
  return Storable::freeze($copy);
}

sub STORABLE_thaw {
  my ($self, $is_cloning, $serialized) = @_;

  return if $is_cloning;
  my $copy = Storable::thaw($serialized);
  %$self = %$copy;
}

# Add a coderef handler into @INC, so that when Storable::thaw tries to load
# a join, we take control, generate the Join on the fly, and return
# a fake file to load.

push @INC, sub { # coderef into @INC: see L<perlfunc/require>
  my ($self_coderef, $filename) = @_;

  # did we try to load an AutoJoin ?
  my ($schema, $join) = ($filename =~ m[^(.+?)/AutoJoin/(.+)$])
    or return;

  # is it really an AutoJoin in DBIx::DataModel ?
  $schema =~ s[/][::]g;
  $schema->isa('DBIx::DataModel::Schema')
    or return;

  # OK, this is really our business. Parse the join name into path items, i.e.
  # qw/My::Table <=> path1 => path2 => .../
  $join =~ s/\.pm$//;
  my ($initial_table, @paths) = split /(<?=>)/, $join;
  $initial_table =~ s[/][::]g;

  # ask schema to create the Join
  $schema->metadm->define_join($initial_table, @paths);

  # return a fake filehandle in memory so that "require" is happy
  open my $fh, "<", \"1"; # pseudo-file just containing "1"

  return $fh;
};




1; # End of DBIx::DataModel::Source::Join

__END__

=head1 NAME

DBIx::DataModel::Source::Join - Parent for Join classes


=head1 DESCRIPTION

This is the parent class for all join classes created through

  $schema->Join($classname, ...);

=head1 METHODS

Methods are documented in 
L<DBIx::DataModel::Doc::Reference|DBIx::DataModel::Doc::Reference>.
This module implements no public methods.

=head1 SUPPORT FOR STORABLE

If an instance of a dynamically created join is serialized
through L<Storable/freeze> and then deserialized in
another process through L<Storable/thaw>, then it may
happen that the second process does not know about the 
dynamic join. Therefore this class adds a coderef handler
into C<@INC>, so that it can take control when C<thaw> attempts
to load the class from a file, and recreate the join
dynamically.

