package DBIx::Class::AuditAny::Util::SchemaMaker;
use strict;
use warnings;

# ABSTRACT: On-the-fly creation of DBIC Schema classes

=head1 NAME

DBIx::Class::AuditAny::Util::SchemaMaker - On-the-fly creation of DBIC Schema classes

=head1 DESCRIPTION

This package provides an easy way to conjurer new DBIC schema classes into existence

=head1 ATTRIBUTES

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

#use Moose;
#use MooseX::Types::Moose qw(HashRef ArrayRef Str Bool Maybe Object CodeRef);

require Class::MOP::Class;
use DBIx::Class::AuditAny::Util;
use DBIx::Class::AuditAny::Util::ResultMaker;

=head2 schema_namespace

Required - the class name of the DBIC schema to be created

=cut
has 'schema_namespace', is => 'ro', isa => Str, required => 1;

=head2 class_opts

Optional extra params to supply to C<< Class::MOP::Class->create >>

=cut
has 'class_opts', is => 'ro', isa => HashRef, default => sub {{}};

=head2 results

HashRef of key/value pairs defining the result/sources to be created. The key
is the source name, while the value must be a HashRef to be supplied to the
C<initialize> constructor of L<DBIx::Class::AuditAny::Util::ResultMaker>. The
C<class_name> does not need to be specified here as it is automatically set
according to the C<schema_namespace> and the source name (key value).

=cut
has 'results', is => 'ro', isa => HashRef[HashRef], required => 1;

=head1 METHODS

=head2 initialize

Initialization constructor. Expects the above attrs as a HashRef as they would be passed to
C<new()>. Creates the specified schema and associated result classes on-the-spot.

=cut
sub initialize {
	my $self = shift;
	$self = $self->new(@_) unless (ref $self);
	
	my $class = $self->schema_namespace;
	die "class/namespace '$class' already defined!" if (package_exists $class);
	
	Class::MOP::Class->create($class,
		superclasses => [ 'DBIx::Class::Schema' ],
		%{ $self->class_opts }
	) or die $@;
	
	my @Results = sort keys %{$self->results};
	
	DBIx::Class::AuditAny::Util::ResultMaker->initialize(
		class_name => $class . '::' . $_,
		%{$self->results->{$_}}
	) for (@Results);
		
	$class->load_classes(@Results);
	
	return $class;
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
