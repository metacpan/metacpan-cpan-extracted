package Aion::Meta::RequiresAnyFunction;

use common::sense;

use Aion::Meta::Util qw//;

Aion::Meta::Util::create_getters(qw/pkg name/);

sub new {
    my $cls = shift;
    bless {@_}, ref $cls || $cls;
}

sub compare {
    my ($self, $other) = @_;

   	die "Requires ${\ $self->stringify}" unless ref $other eq 'CODE';
}

sub stringify {
	my ($self) = @_;

   	return "$self->{name} of $self->{pkg}";
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Meta::RequiresAnyFunction - defines any function that must be in the module

=head1 SYNOPSIS

	use Aion::Meta::RequiresAnyFunction;
	
	my $any_function = Aion::Meta::RequiresAnyFunction->new(
		pkg => 'My::Package', name => 'my_function'
	);
	
	$any_function->stringify # => my_function of My::Package

=head1 DESCRIPTION

It is created in C<requires fn1, fn2...> and when initializing the class it is checked that such a function was declared in it using C<sub> or C<has>.

=head1 SUBROUTINES

=head2 new (%args)

Constructor.

=head2 compare ($other)

Checks that C<$other> is a function.

	my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package', name => 'my_function');
	eval { $any_function->compare(undef) }; $@  # ~> Requires my_function of My::Package

=head2 pkg ()

Returns the name of the package in which the function is declared.

	my $any_function = Aion::Meta::RequiresAnyFunction->new(pkg => 'My::Package');
	$any_function->pkg  # => My::Package

=head2 name ()

Returns the name of the function.

	my $any_function = Aion::Meta::RequiresAnyFunction->new(name => 'my_function');
	$any_function->name  # => my_function

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Meta::RequiresAnyFunction module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
