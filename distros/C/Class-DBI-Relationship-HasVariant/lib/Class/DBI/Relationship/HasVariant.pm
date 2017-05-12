package Class::DBI::Relationship::HasVariant;

use strict;
use warnings;

use base qw(Class::DBI::Relationship);

=head1 NAME

Class::DBI::Relationship::HasVariant - columns with varying types

=head1 VERSION

version 0.02

 $Id: HasVariant.pm,v 1.3 2004/10/12 16:53:07 rjbs Exp $

=cut

our $VERSION = '0.020';

=head1 SYNOPSIS

Using a class to transform values:

 package Music::Track::Attribute;
 use base qw(Music::DBI);

 Music::Track::Attribute->add_relationship_type(
   has_variant =>
   'Class::DBI::Relationship::HasVariant'
 );

 Music::Track::Attribute->table("trackattributes");

 Music::Track::Attribute->has_variant(
   attr_value => 'Music::Track::Attribute::Transformer',
   inflate => 'inflate',
   deflate => 'deflate'
 );

Using subs (this is a wildly contrived example):

 Boolean::Stored->has_variant(
   boolean => undef,
   deflate => sub {
     return undef if ($_[0] and $_[0] == 0);
     return 1 if $_[0];
     return 0;
   }
 );

=head1 DESCRIPTION

The C<has_a> relationship in Class::DBI works like this:

 __PACKAGE__->has_a($columnname => $class, %options);

The column is inflated into an instance of the named class, using methods from
the options or default methods.  The inflated value must be of class C<$class>,
or an exception is thrown.

The C<has_variant> relationship allows one column to inflate to different
types.  If a class is given, it is not used for type checking, but for finding
a transformation method.

=head2 EXAMPLES

 __PACKAGE__->has_variant(
   variant => 'Variant::Auto',
   inflate => 'inflate',
   deflate => 'deflate'
 );

This example will pass the value of the "variant" column to Variant::Auto's
C<<inflate>> method before returning it, and to its C<<deflate>> method before
storing it.

 __PACKAGE__->has_variant(
   variant => undef,
   inflate => sub {
     return ($_[0] % 2) ? Oddity->new($_[0]) : Normal->new($_[0])
   }
   deflate => sub { $_[0]->isa('Oddity') ? $_[0]->value : $_[0]->number }
 );

The above example will inflate odd numbers to Oddity objects and other values
to Normals.  Oddities are deflated with the C<<value>> methods, and others with
the C<<number>> method.

=cut

sub remap_arguments {
	my $proto = shift;
	my $class = shift;
	$class->_invalid_object_method('has_a()') if ref $class;
	my $column = $class->find_column(+shift)
		or return $class->_croak("has_variant needs a valid column");
	my $a_class = shift;
	my %meths = @_;
	return ($class, $column, $a_class, \%meths);
}

sub triggers {
	my $self = shift;
  
	$self->class->_require_class($self->foreign_class) ## no critic Private
		if $self->foreign_class;

	my $column = $self->accessor;
	return (
		select              => $self->_inflator,
		"after_set_$column" => $self->_inflator,
		deflate_for_create  => $self->_deflator(1),
		deflate_for_update  => $self->_deflator,
	);
}

sub _inflator {
	my $self = shift;
	my $col  = $self->accessor;

	return sub {
		my $self = shift;
		defined(my $value = $self->_attrs($col)) or return;
		my $meta = $self->meta_info(has_variant => $col);
		my ($a_class, %meths) = ($meta->foreign_class, %{ $meta->args });

		my $get_new_value = sub {
			my ($inflator, $value, $transform_class, $obj) = @_;
			my $new_value =
				(ref $inflator eq 'CODE')
				? $inflator->($value, $obj)
				: $transform_class->$inflator($value, $obj);
			return $new_value;
		};

		# If we have a custom inflate ...
		if (exists $meths{'inflate'}) {
			$value = $get_new_value->($meths{'inflate'}, $value, $a_class, $self);
			return $self->_attribute_store($col, $value);
		} else {
			return $value;
		}

		$self->_croak("can't inflate column $col");
	};
}

sub _deflator {
	my ($self, $always) = @_;
	my $col = $self->accessor;

	return sub {
		my $self = shift;
		defined(my $value = $self->_attrs($col)) or return;
		my $meta = $self->meta_info(has_variant => $col);
		my ($a_class, %meths) = ($meta->foreign_class, %{ $meta->args });

		my $deflate_value = sub {
			my ($deflator, $value, $transform_class, $obj) = @_;
			my $new_value =
				(ref $deflator eq 'CODE')
				? $deflator->($value, $obj)
				: $transform_class->$deflator($value, $obj);
			return $new_value;
		};

		if (exists $meths{'deflate'}) {
			my $value = $deflate_value->($meths{'deflate'}, $value, $a_class, $self);
			return $self->_attribute_store($col => $value)
				if ($always or $self->{__Changed}->{$col});
			return;
		}

		$self->_croak("can't deflate column $col");
	};
}

=head1 WARNINGS

My understanding of the Class::DBI internals isn't beyond question, and I
expect that I've done something foolish inside here.  I've tried to compensate
for my naivety with testing, but stupidy may have leaked through.  Feedback is
welcome.

=head1 AUTHOR

Ricardo SIGNES <C<<rjbs@cpan.org>>>

=head2 COPYRIGHT

(C) 2004, Ricardo SIGNES, and released under the same terms as Perl itself.

=cut

1;
