package # this is an example for modify_subroutine()/subroutne_modifier().
	Method::Modifiers;

use strict;
use warnings;

our $VERSION = '0.67';

use Exporter qw(import);

our @EXPORT    = qw(before around after);
our @EXPORT_OK = (@EXPORT, qw(add_method_modifier));
our %EXPORT_TAGS = (
	all   => \@EXPORT_OK,
	moose => \@EXPORT,
);

use Data::Util ();

sub _croak{
	require Data::Util::Error;
	goto &Data::Util::Error::croak;
}

sub add_method_modifier{
	my $into     = shift;
	my $type     = shift;
	my $modifier = pop;

	foreach my $name(@_){
		my $method = Data::Util::get_code_ref($into, $name);

		if(!$method || !Data::Util::subroutine_modifier($method)){

			unless($method){
				$method = $into->can($name)
					or _croak(qq{The method '$name' is not found in the inheritance hierarchy for class $into});
			}

			$method = Data::Util::modify_subroutine($method, $type => [$modifier]);

			no warnings 'redefine';
			Data::Util::install_subroutine($into, $name => $method);
		}
		else{ # $method exists and is modified
			Data::Util::subroutine_modifier($method, $type => $modifier);
		}
	}
	return;
}

sub before{
	my $into = caller;
	add_method_modifier($into, before => @_);
}
sub around{
	my $into = caller;
	add_method_modifier($into, around => @_);
}
sub after{
	my $into = caller;
	add_method_modifier($into, after  => @_);
}


1;
__END__

=head1 NAME

Method::Modifiers - Lightweight method modifiers

=head1 SYNOPSIS

	package Foo;
	use warnings;
	use Data::Util qw(:all);
	use Method::Modifiers;

	before old_method =>
		curry \&warnings::warnif, deprecated => q{"old_method" is deprecated, use "new_method" instead};

	my $success = 0;
	after qw(foo bar baz) => sub{ $success++ };

	around foo => sub{
		my $next = shift;
		my $self = shift;

		$self->$next(map{ instance $_, 'Foo' } @_);
	};

=head1 DESCRIPTION

This module is an implementation of C<Class::Method::Modifiers> that
provides C<Moose>-like method modifiers.

This is just a front-end of C<Data::Util::modify_subroutine()> and
C<Data::Util::subroutine_modifier()>

See L<Data::Util> for details.

=head1 INTERFACE

=head2 Default exported functions

=over 4

=item before(method(s) => code)

=item around(method(s) => code)

=item after(method(s) => code)

=back

=head2 Exportable functions

=over 4

=item add_method_modifier(class, modifer_type, method(s), modifier)

=back

=head1 SEE ALSO

L<Data::Util>.

L<Moose>.

L<Class::Method::Modifiers>.

=cut

