package DBIx::Class::AuditAny::Util::ResultMaker;
use strict;
use warnings;

# ABSTRACT: On-the-fly creation of DBIC Result classes

=head1 NAME

DBIx::Class::AuditAny::Util::ResultMaker - On-the-fly creation of DBIC Result classes

=head1 DESCRIPTION

This package provides an easy way to conjurer new DBIC result classes into existence. It
is typically used by L<DBIx::Class::AuditAny::Util::SchemaMaker> and not called directly.

=head1 ATTRIBUTES

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

require Class::MOP::Class;
use DBIx::Class::AuditAny::Util;


=head2 class_name

Required. Full class name of the result class to be created

=cut
has 'class_name', 			is => 'ro', isa => Str, required => 1;

=head2 class_opts

Optional extra params to supply to C<< Class::MOP::Class->create >>

=cut
has 'class_opts', 			is => 'ro', isa => HashRef, default => sub {{}};

=head2 table_name

Required. The name of the table as would be supplied to C<< ->table() >> in the
result class.

=cut
has 'table_name', 			is => 'ro', isa => Str, required => 1;

=head2 columns

Required. ArrayRef of DBIC column definitions suitable as arguments for C<< ->add_columns() >>

=cut
has 'columns', 				is => 'ro', isa => ArrayRef, required => 1;

=head2 call_class_methods

Optional ArrayRef consumed in pairs, with the first value used as a method name, and the
second value an ArrayRef holding the args to supply to the method. Each of these are called
as class methods on the result class. This allows for any other calls to be handled, such as
adding uniq keys, and so on.

=cut
has 'call_class_methods',	is => 'ro', isa => ArrayRef, default => sub {[]};


=head1 METHODS

=head2 initialize

Initialization constructor. Expects the above attrs as a HashRef as they would be passed to
C<new()>. Creates the specified result class and invokes all the setup methods as defined above.

=cut
sub initialize {
	my $self = shift;
	$self = $self->new(@_) unless (ref $self);
	
	my $class = $self->class_name;
	die "class/namespace '$class' already defined!" if (package_exists $class);
	
	Class::MOP::Class->create($class,
		superclasses => [ 'DBIx::Class::Core' ],
		%{ $self->class_opts }
	) or die $@;
	
	$class->table( $self->table_name );
	
	$class->add_columns( @{$self->columns} );
	
	my @call_list = @{$self->call_class_methods};
	while (my $meth = shift @call_list) {
		my $args = shift @call_list;
		$class->$meth(@$args);
	}

	return $class;
}

1;

__END__

=head1 SEE ALSO

=over

=item *

L<DBIx::Class::AuditAny::Util::SchemaMaker>

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