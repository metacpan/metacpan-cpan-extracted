=pod

=head1 NAME

Class::Mixin - API for aliasing methods to/from other classes

=head1 OVERVIEW

Class::Mixin provides a way to mix methods from one class into another,
such that the target class can use both its methods as well as those
of the source class.

The primary advantage is that the behavior of a class can be modified
to effectively be another class without changing any of the calling
code -- just requires using the new class that mixes into the original.

=head1 SYNOPSIS

  # class1.pm
  package class1;
  sub sub1 { return 11 };
  ...

  # class2.pm
  package class2;
  use Class::Mixin to=> 'class1';
  sub sub2 { return 22 };

  # Original calling code
  use class1;
  print class1->sub1;  # 11
  print class1->can('sub2');  # false

  # Updated calling code
  use class1;
  use class2;	# performs the mixing-in
  print class1->sub1;  # 11
  print class1->can('sub2');  # true
  print class1->sub2;  # 22  <-- note class1 now has the class2 method

=head1 METHODS

=cut

#######################################################
package Class::Mixin;
use strict;

use Symbol ();
use Carp;
use warnings::register;

our $VERSION = '1.00';

my %r = map { $_=> 1 } qw(
	BEGIN
	INIT
	CHECK
	END
	DESTROY
	AUTOLOAD
	ISA
	
	import
	can
	isa
	ISA
	STDIN
	STDOUT
	STDERR
	ARGV
	ARGVOUT
	ENV
	INC
	SIG
);

sub __new {
	return $Class::Mixin::OBJ if defined $Class::Mixin::OBJ;
	$Class::Mixin::OBJ = bless {}, shift;
	return $Class::Mixin::OBJ;
}

=pod

=head2 import

Method used when loading class to import symbols or perform
some function.  In this case we take the calling classes methods
and map them into the class passed in as a parameter.

=over 2

=item Input

=over 2

=item None

=back

=item Output

None

=back

=cut

sub import {
	my $cl = shift;
	return unless @_;
	my $obj = Class::Mixin->__new;
	my $p = { @_ };
	Carp::croak q{Must mixin 'to' or 'from' something} unless exists $p->{to} || exists $p->{from};

	my $class = caller;
	if( exists $p->{to} ){
	  $obj->{mixins}->{ $class   }->{ $p->{to} } ||= [];
	}
	if( exists $p->{from} ){
	  $obj->{mixins}->{ $p->{from} }->{ $class } ||= [];
	}
}

CHECK { resync() }

=pod

=head2 B<Destructor> DESTROY

This modules uses a destructor for un-mixing methods.  This is done in
the case that this module is unloaded for some reason.  It will return
modules to their original states.

=over 2

=item Input

=over 2

=item *

Class::Mixin object

=back

=item Output

=over 2

=item None

=back

=back

=cut

sub DESTROY {
  my $obj = shift;
	foreach my $mixin ( keys %{$obj->{mixins}} ) {
	  foreach my $target ( keys %{$obj->{mixins}->{$mixin}} ) {
	    foreach my $v ( @{ $obj->{mixins}->{$mixin}->{$target} } ){
		no strict 'refs';
		my $m = $v->{'method'};
		my $c = $v->{'class'} . '::';
		my $s = $v->{'symbol'};
		*{ $s } = undef;
		delete ${ $c }{ $m };
		$s = undef;
	    }
	  }
	}
}

=pod

=head2 resync

Function used to process registered 'mixins'.  Typically automatically
called once immediately after program compilation.  Sometimes though you
may want to call it manually if a modules is reloaded.

=over 2

=item Input

=over 2

=item None

=back

=item Output

=over 2

=item None

=back

=back

=cut

sub resync {
	my $obj = Class::Mixin->__new;
	my $class = caller;

	foreach my $mixin ( keys %{$obj->{mixins}} ) {
	  foreach my $target ( keys %{$obj->{mixins}->{$mixin}} ) {

		my $mixinSym = $mixin . '::';
		my $targetSym = $target . '::';

		next if $class ne $mixin && !$class->isa( __PACKAGE__ );

		no strict 'refs';

		foreach my $method ( keys %$mixinSym ) {
			if ( exists $r{ $method } ) {
				warnings::warn "Unable to Mixin method '$method', restricted"
					if warnings::enabled();
			} elsif ( exists ${ $targetSym }{ $method } ) {
				warnings::warn qq{
Unable to Mixin method '$method'
FROM $mixin
TO $target
already defined in $target
} if warnings::enabled();
			} else {
				my $m = Symbol::qualify_to_ref( $method, $mixin );
				my $t = Symbol::qualify_to_ref( $method, $target );
				*{ $t } = *{ $m };

				push @{ $obj->{mixins}->{$mixin}->{$target} }, {
					class=>		$target,
					method=>	$method,
					symbol=>	$t,
				};
			}
		}

	  }
	}
}

1;

__END__

=pod

=head1 AUTHORS

=over 2

=item *

Stathy G. Touloumis <stathy@stathy.com>

=item *

David Westbrook <dwestbrook@gmail.com>

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-class-mixin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Mixin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Mixin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Mixin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Mixin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Mixin>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Mixin>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2008 Stathy G. Touloumis

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

