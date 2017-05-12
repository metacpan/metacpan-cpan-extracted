package # Hide from PAUSE 
     DBIx::Class::AuditAny::Collector::Code;
use strict;
use warnings;

# ABSTRACT: Coderef collector

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
with 'DBIx::Class::AuditAny::Role::Collector';

=head1 NAME

DBIx::Class::AuditAny::Collector::Code - Simple CodeRef collector class

=head1 DESCRIPTION

Using this collector class you can supply a coderef, and it will receive the
C<record_changes> data as arguments. This allows you to handle the change data
in whatever manner you choose.

=head1 ATTRIBUTES

=head2 collect_coderef

Required. Any valid CodeRef to use to send change data to. Arguments will be
supplied in the same form as C<record_changes()>

=cut

has 'collect_coderef', is => 'ro', isa => CodeRef, required => 1;


=head1 METHODS

=head2 record_changes

=cut
sub record_changes {
	my $self = shift;
	return $self->collect_coderef->(@_);
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
