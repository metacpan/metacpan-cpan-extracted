package DBIx::Class::AuditAny::AuditContext::Source;
use strict;
use warnings;

# ABSTRACT: Default 'Source' context object class for DBIx::Class::AuditAny

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
extends 'DBIx::Class::AuditAny::AuditContext';

=head1 NAME

DBIx::Class::AuditAny::AuditContext::Source - Default 'Source' context object 
class for DBIx::Class::AuditAny

=head1 DESCRIPTION

This object class represents a change to a source itself, such as its name


=head1 ATTRIBUTES

Docs regarding the API/purpose of the attributes and methods in this class still TBD...

=head2 ResultSource

=head1 METHODS

=head2 primary_columns

=head2 get_pri_key_value

=cut


has 'ResultSource', is => 'ro', required => 1;
has 'source', is => 'ro', lazy => 1, default => sub { (shift)->ResultSource->source_name };
has 'class', is => 'ro', lazy => 1, default => sub { $_[0]->SchemaObj->class($_[0]->source) };
has 'from_name', is => 'ro', lazy => 1, default => sub { (shift)->ResultSource->from };
has 'table_name', is => 'ro', lazy => 1, default => sub { (shift)->class->table };

sub primary_columns { return (shift)->ResultSource->primary_columns }

sub _build_tiedContexts { [] }
sub _build_local_datapoint_data { 
	my $self = shift;
	return { map { $_->name => $_->get_value($self) } $self->get_context_datapoints('source') };
}

has 'pri_key_column', is => 'ro', isa => Maybe[Str], lazy => 1, default => sub { 
	my $self = shift;
	my @cols = $self->primary_columns;
	return undef unless (scalar(@cols) > 0);
	my $sep = $self->primary_key_separator;
	return join($sep,@cols);
};

has 'pri_key_count', is => 'ro', isa => Int, lazy => 1, default => sub { 
	my $self = shift;
	return scalar($self->primary_columns);
};

sub get_pri_key_value {
	my $self = shift;
	my $Row = shift;
	my $num = $self->pri_key_count;
	return undef unless ($num > 0);
	return $self->_ambig_get_column($Row,$self->pri_key_column) if ($num == 1);
	my $sep = $self->primary_key_separator;
	return join($sep, map { $self->_ambig_get_column($Row,$_) } $self->primary_columns );
}

# added as a bridge to be able to "get_column" with either a Row object
# or a simple HashRef via the same syntax (in get_pri_key_value above):
sub _ambig_get_column {
	my $self = shift;
	my $row = shift;
	my $column = shift;
	return ref($row) eq 'HASH' ? $row->{$column} : $row->get_column($column);
}

1;

__END__

=head1 SEE ALSO

=over

=item *

L<DBIx::Class::AuditAny>

=item *

L<DBIx::Class>

=back

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
