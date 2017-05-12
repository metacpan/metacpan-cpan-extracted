package Aspect::Library::Singleton;

use strict;
use Aspect::Modular        ();
use Aspect::Advice::Before ();
use Aspect::Pointcut::Call ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Modular';

my %CACHE = ();

sub get_advice {
	my $self = shift;
	Aspect::Advice::Around->new(
		lexical  => $self->lexical,
		pointcut => Aspect::Pointcut::Call->new(shift),
		code     => sub {
			my $class = $_->self;
			$class    = ref $class || $class;
			if ( exists $CACHE{$class} ) {
				$_->return_value($CACHE{$class});
			} else {
				$_->proceed;
				$CACHE{$class} = $_->return_value;
			}
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Singleton - A singleton aspect

=head1 SYNOPSIS

  use Aspect;
  use Aspect::Singleton;
  
  aspect Singleton => 'Foo::new';
  
  my $f1 = Foo->new;
  my $f2 = Foo->new;
  
  # Both $f1 and $f2 refer to the same object

=head1 DESCRIPTION

A reusable aspect that forces singleton behavior on a constructor. The
constructor is defined by a pointcut spec: a string. regexp, or code ref.

It is slightly different from C<Class::Singleton>
(L<http://search.cpan.org/~abw/Class-Singleton/Singleton.pm>):

=over

=item *

No specific name requirement on the constructor for the external
interface, or for the implementation (C<Class::Singleton> requires
clients use C<instance()>, and that subclasses override
C<_new_instance()>). With aspects, you can change the cardinality of
your objects without changing the clients, or the objects themselves.

=item *

No need to inherit from anything- use pointcuts to specify the
constructors you want to memoize. Instead of I<pulling> singleton
behavior from a base class, you are I<pushing> it in, using the aspect.

=item *

No package variable or method is added to the callers namespace

=back

Note that this is just a special case of memoizing.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
