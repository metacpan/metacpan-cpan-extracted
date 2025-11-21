package Aion::Meta::Subroutine;
# Описывает функцию с сигнатурой

use common::sense;

use Aion::Meta::Util qw//;
use Aion::Types qw/Tuple/;
use Scalar::Util qw//;
use Sub::Util qw//;

Aion::Meta::Util::create_getters(qw/pkg subname signature referent wrapsub/);

sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls;
}

sub wrap_sub {
	my ($self) = @_;

	my ($pkg, $subname, $signature, $referent) = @$self{qw/pkg subname signature referent/};

	my $args_of_meth = "Arguments of method `$subname`";
	my $returns_of_meth = "Returns of method `$subname`";
	my $return_of_meth = "Return of method `$subname`";

	my @signature = @$signature;
	my $ret = pop @signature;

	my ($ret_array, $ret_scalar) = exists $ret->{is_wantarray}? @{$ret->{args}}: (Tuple([$ret]), $ret);

	my $args = Tuple(\@signature);

	my $sub = sub {
		$args->validate(\@_, $args_of_meth);
		wantarray? do {
			my @returns = $referent->(@_);
			$ret_array->validate(\@returns, $returns_of_meth);
			@returns
		}: do {
			my $return = $referent->(@_);
			$ret_scalar->validate($return, $return_of_meth);
			$return
		}
	};

	Sub::Util::set_prototype Sub::Util::prototype($referent), $sub;
	Sub::Util::set_subname Sub::Util::subname($referent), $sub;
	
	*{"$pkg\::$subname"} = $sub if $subname ne '__ANON__';
	
	$self->{wrapsub} = $sub;
	$Aion::META{$pkg}{subroutine}{$subname} = $self;

	my $key = pack 'J', Scalar::Util::refaddr $sub;
	$Aion::Isa{$key} = $self;
	Scalar::Util::weaken $Aion::Isa{$key};
	
	$self
}

sub compare {
	my ($self, $subroutine) = @_;

	die "Requires subroutine ${\$self->name}" unless $subroutine->isa('Aion::Meta::Subroutine');

	my $i = 0;
	my $signature = $subroutine->signature;
	my $fail = 0;

	if(@$signature == @{$self->signature}) {
		for my $type (@{$self->{signature}}) {
			my $other_type = $signature->[$i++];
			$fail = 1, last unless $type eq $other_type;
		}
	} else {
		$fail = 1;
	}

	die "Signature mismatch: ${\$self->stringify} <=> ${\$subroutine->stringify}" if $fail;
}

sub stringify {
	my ($self) = @_;

	my ($pkg, $subname) = @$self{qw/pkg subname/};
	my $signature = join " => ", @{$self->signature};
	return "$subname($signature) of $pkg";
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Meta::Subroutine - describes a function with a signature

=head1 SYNOPSIS

	use Aion::Types qw(Int);
	use Aion::Meta::Subroutine;
	
	my $subroutine = Aion::Meta::Subroutine->new(
		pkg => 'My::Package',
		subname => 'my_subroutine',
		signature => [Int, Int],
		referent => undef,
	);
	
	$subroutine->stringify  # => my_subroutine(Int => Int) of My::Package

=head1 DESCRIPTION

Used to declare the required function in interfaces and abstract classes.
In this case, C<referent ~~ Undef>.

It also creates a wrapper function that checks the signature.

=head1 SUBROUTINES

=head2 new (%args)

Constructor.

=head2 wrap_sub ()

Creates a wrapper function that checks the signature.

=head2 compare ($subroutine)

Checks its (expected) signature against the one declared by the function in the module and throws an exception if the signatures do not match.

=head2 stringify ()

String description of the function.

=head2 pkg ()

Returns the name of the package in which the function is declared.

=head2 subname ()

Returns the name of the function.

=head2 signature ()

Returns the function signature.

=head2 referent ()

Returns a reference to the original function.

=head2 wrapsub ()

Returns a wrapper function that checks the signature.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Meta::Subroutine module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
