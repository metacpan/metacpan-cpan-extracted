package DBIx::Class::Schema::Diff::InfoPacket;
use strict;
use warnings;

use Moo;
with 'DBIx::Class::Schema::Diff::Role::Common';

use Types::Standard qw(:all);

has 'name', required => 1, is => 'ro', isa => Str;
has 'old_info', required => 1, is => 'ro', isa => Maybe[HashRef];
has 'new_info', required => 1, is => 'ro', isa => Maybe[HashRef];

has '_source_diff', required => 1, is => 'ro', isa => InstanceOf[
  'DBIx::Class::Schema::Diff::Source'
];

has 'added', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  defined $self->new_info && ! defined $self->old_info
}, init_arg => undef, isa => Bool;

has 'deleted', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  defined $self->old_info && ! defined $self->new_info
}, init_arg => undef, isa => Bool;


has 'diff', is => 'ro', lazy => 1, default => sub { 
  my $self = shift;
  
  # There is no reason to diff in the case of added/deleted:
  return { _event => 'added'   } if ($self->added);
  return { _event => 'deleted' } if ($self->deleted);
  
  my ($o,$n) = ($self->old_info,$self->new_info);
  my $diff = $self->_info_diff($o,$n) or return undef;
  
  return { _event => 'changed', diff => $diff };
  
}, init_arg => undef, isa => Maybe[HashRef];


sub _schema_diff { (shift)->_source_diff->_schema_diff }

1;

__END__

=pod

=head1 NAME

DBIx::Class::Schema::Diff::InfoPacket - internal object class for DBIx::Class::Schema::Diff

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
