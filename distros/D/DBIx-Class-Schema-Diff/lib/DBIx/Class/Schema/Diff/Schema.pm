package DBIx::Class::Schema::Diff::Schema;
use strict;
use warnings;

# ABSTRACT: Simple Diffing of DBIC Schemas
# VERSION

#
# TODO (#2)
#
# The structure/design of this class (+ Source and InfoPacket)
# made more sense before adding the 'SchemaData' feature (#1)
# when these classes were handling both the data extraction from
# DBIC and the diffing tasks of the individual section of data.
# Now the data extraction work is done in SchemaData leaving only
# simple static hashrefs to be dealt with here. These classes should
# probably now be consolidated and generalized. I'm not sure
# how important this is though since everything is already working.
# Later on, if more types of data need to be diffed besides the
# 5 current ones (columns,relationships,constraints,table_name,isa),
# or it is useful to make that more dynamic, such as to be able to
# add more data-points on the fly, then taking the time for 
# refactoring these will make more sense... (2014-04-14 by vanstyn)
# 

use Moo;
with 'DBIx::Class::Schema::Diff::Role::Common';

use Types::Standard qw(:all);
use Module::Runtime;
use Try::Tiny;

use DBIx::Class::Schema::Diff::Source;
use DBIx::Class::Schema::Diff::SchemaData;

has 'old_schema', required => 1, is => 'ro', isa => InstanceOf[
  'DBIx::Class::Schema::Diff::SchemaData'
], coerce => \&_coerce_schema_data;

has 'new_schema', required => 1, is => 'ro', isa => InstanceOf[
  'DBIx::Class::Schema::Diff::SchemaData'
], coerce => \&_coerce_schema_data;


sub all_source_names {
  my $self = shift;
  
  my ($o,$n) = ($self->old_schema,$self->new_schema);
  
  # List of all sources in old, new, or both:
  return uniq($o->sources,$n->sources);
}

has 'sources', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  return { map {
    $_ => DBIx::Class::Schema::Diff::Source->new(
      name         => $_,
      old_source   => scalar try{$self->old_schema->source($_)},
      new_source   => scalar try{$self->new_schema->source($_)},
      _schema_diff => $self,
    )
  } $self->all_source_names };
  
}, init_arg => undef, isa => HashRef;


has 'diff', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  
  # TODO: handle added/deleted/changed at this level, too...
  my $diff = { map {
    $_->diff ? ($_->name => $_->diff) : ()
  } values %{$self->sources} };
  
  return undef unless (keys %$diff > 0); 
  return $diff;
  
}, init_arg => undef, isa => Maybe[HashRef];

sub _schema_diff { (shift) }


1;

__END__

=pod

=head1 NAME

DBIx::Class::Schema::Diff::Schema - internal object class for DBIx::Class::Schema::Diff

=head1 DESCRIPTION

This class is used internally by L<DBIx::Class::Schema::Diff> and is not meant to be called directly. 

Please refer to the main L<DBIx::Class::Schema::Diff> documentation for more info.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
