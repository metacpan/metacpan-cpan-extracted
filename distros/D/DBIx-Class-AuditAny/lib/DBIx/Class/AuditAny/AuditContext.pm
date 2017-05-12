package # Hide from PAUSE 
     DBIx::Class::AuditAny::AuditContext;
use strict;
use warnings;

# ABSTRACT: Base class for context objects in DBIx::Class::AuditAny

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

DBIx::Class::AuditAny::AuditContext - Base class for context objects in DBIx::Class::AuditAny

=head1 DESCRIPTION

This class is used internally and typically does not need to be called directly

=head1 ATTRIBUTES

=head2 AuditObj

Required. Reference to the Auditor object (L<DBIx::Class::AuditAny>).

=cut
has 'AuditObj', is => 'ro', isa => InstanceOf['DBIx::Class::AuditAny'], required => 1;

=head2 tiedContexts

Used internally

=cut
has 'tiedContexts', is => 'lazy', isa => ArrayRef[Object];#, lazy_build => 1;

=head2 local_datapoint_data

Used internally

=cut
has 'local_datapoint_data', is => 'lazy', isa => HashRef;#, lazy_build => 1;

sub _build_tiedContexts { die "Virtual method" }
sub _build_local_datapoint_data { die "Virtual method" }


=head1 METHODS

=head2 get_datapoint_value

=cut
sub get_datapoint_value {
	my $self = shift;
	my $name = shift;
	my @Contexts = ($self,@{$self->tiedContexts},$self->AuditObj);
	foreach my $Context (@Contexts) {
		return $Context->local_datapoint_data->{$name} 
			if (exists $Context->local_datapoint_data->{$name});
	}
	die "Unknown datapoint '$name'";
}

=head2 get_datapoints_data

=cut
sub get_datapoints_data {
	my $self = shift;
	my @names = (ref($_[0]) eq 'ARRAY') ? @{ $_[0] } : @_; # <-- arg as array or arrayref
	return { map { $_ => $self->get_datapoint_value($_) } @names };
}


=head2 SchemaObj

=cut
sub SchemaObj { (shift)->AuditObj->schema };


=head2 schema

=cut
sub schema { ref (shift)->AuditObj->schema };


=head2 primary_key_separator

=cut
sub primary_key_separator { (shift)->AuditObj->primary_key_separator };


=head2 get_context_datapoints

=cut
sub get_context_datapoints { (shift)->AuditObj->get_context_datapoints(@_) };


=head2 get_context_datapoint_names

=cut
sub get_context_datapoint_names { (shift)->AuditObj->get_context_datapoint_names(@_) };


=head2 get_dt

=cut
sub get_dt { (shift)->AuditObj->get_dt(@_) };

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
