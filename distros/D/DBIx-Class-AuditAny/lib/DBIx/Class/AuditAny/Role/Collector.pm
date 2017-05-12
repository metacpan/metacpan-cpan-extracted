package DBIx::Class::AuditAny::Role::Collector;
use strict;
use warnings;

# ABSTRACT: Role for all Collector classes

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

DBIx::Class::AuditAny::Role::Collector - Role for all Collector classes

=head1 DESCRIPTION

All classes which need to be able to function as a "Collector" class must consume this
base role.

=head1 REQUIRES

=head2 record_changes

All Collectors must implement a C<record_changes()> method. This is what is called to send
the change/update data into the Collector for further processing and storage.

=cut
requires 'record_changes';

=head1 ATTRIBUTES

=head2 AuditObj

Required. Reference to the main AuditAny object which is sniffing the change data

=cut
has 'AuditObj', is => 'ro', required => 1;

=head2 writes_bound_schema_sources

these are part of the base class because the AuditObj expects all
Collectors to know if a particular tracked source is also a source used
by the collector which would create a deep recursion situation. in other words,
we don't want to try to track changes of the tables that we're using to 
store changes. We rely on the Collector to identify these exclude cases
my setting those source names here

=cut
has 'writes_bound_schema_sources', is => 'ro', isa => ArrayRef[Str], lazy => 1, default => sub {[]};

=head1 METHODS

=head2 has_full_row_stored

This is part of the "init" system for loading existing data. This is going
to be refactored/replaced, but with what is not yet known

=cut
sub has_full_row_stored {
	my $self = shift;
	my $Row = shift;
	
	warn "has_full_row_stored() not implemented - returning false\n";
	
	return 0;
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