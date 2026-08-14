
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame;
$Context::Singleton::Frame::VERSION = '1.0.9';
use Moo;

use Context::Singleton::Frame::DB;
use Context::Singleton::Exception::Invalid;
use Context::Singleton::Exception::Deduced;
use Context::Singleton::Exception::Nondeducible;
use Context::Singleton::Frame::Deducer::Notifying;

use namespace::clean;

use overload (
	q ("") => sub { ref ($_[0]) . q ([) . $_[0]->depth . q (]) },
	fallback => 1,
);

__PACKAGE__->_generate_frame_class_internals;

has q (_deducer_class)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Deducer::Notifying:: }
	;

has q (_deducer)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->root_frame->_deducer_class->new (frame => $_[0]) }
	=> handles  => [
		q (is_deducible),
	];

has q (db)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->db : $_[0]->db_class->instance }
	;

has q (db_class)
	=> is       => q (ro)
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::DB:: }
	;

has q (depth)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->depth + 1 : 0 }
	;

has q (parent)
	=> is       => q (ro)
	;

has q (root_frame)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->root_frame : $_[0] }
	;

sub _effective_frame {
	my $frame = shift;

	ref ($frame) ? $frame : $frame->current_frame;
}

sub _frame_by_depth {
	my ($frame, $depth) = @_;

	return
		if $depth < 0
		;

	my $distance = $frame->depth - $depth;
	return
		if $distance < 0
		;

	my $found = $frame;

	$found = $found->parent
		while $distance-- > 0
		;

	$found;
}

sub _generate_frame_class_internals {
	my ($class) = @_;

	my $current_frame = [ $class->build_frame ];

	no strict q (refs);
	*{"${class}::_localisable_current_frame"} = sub { $current_frame };
}

sub _throw_deduced {
	my ($frame, $singleton) = @_;

	throw Context::Singleton::Exception::Deduced ($singleton);
}

sub _throw_nondeducible {
	my ($frame, $singleton) = @_;

	throw Context::Singleton::Exception::Nondeducible ($singleton);
}

sub build_frame {
	my ($class, %proclaim) = @_;

	my $frame = ref ($class)
		? $class->new (parent => $class)
		: $class->new
		;

	$frame->proclaim (%proclaim);

	return $frame;
}

sub contrive {
	(&_effective_frame)->db->contrive (@_);
}

sub contrive_class {
	(&_effective_frame)->db->contrive_class (@_);
}

sub current_frame {
	shift->_localisable_current_frame->[0];
}

sub debug {
	my ($frame, @message) = @_;

	my $sub = (caller(1))[3];
	$sub =~ s/^.*://;

	use feature q (say);
	say qq (# [${\ $frame->depth}] $sub ${\ join ' ', @message });
}

sub deduce {
	my ($frame, $singleton, @proclaim) = (&_effective_frame, @_);

	$frame = $frame->new (@proclaim)
		if @proclaim
		;

	$frame->_throw_nondeducible ($singleton)
		unless $frame->try_deduce ($singleton)
		;

	$frame->_deducer->deduce ($singleton);
}

sub frame {
	my ($frame, $code) = (&_effective_frame, @_);

	local $frame->_localisable_current_frame->[0] = $frame->build_frame;

	$code->();
}

sub is_deduced {
	(&_effective_frame)->_deducer->is_deduced (@_);
}

sub load_rules {
	(&_effective_frame)->db->load_rules (@_);
}

sub proclaim {
	my ($frame, @proclaim) = (&_effective_frame, @_);

	return
		unless @proclaim
		;

	my $retval;
	while (@proclaim) {
		my $singleton = shift @proclaim;
		my $value = shift @proclaim;

		$frame->_throw_deduced ($singleton)
			if $frame->is_deduced ($singleton)
			;

		$retval = $frame->_deducer->proclaim ($singleton, $value);
	}

	$retval;
}

sub trigger {
	(&_effective_frame)->db->trigger (@_);
}

sub try_deduce {
	(&_effective_frame)->_deducer->try_deduce (@_);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame - Internal representation of Context::Singleton's frame

=head1 DESCRIPTION

This is internal package.

=head1 EXTENDING FRAME

Each L<Context::Singleton::Frame> (sub)class tracks its own current I<frame>,
so alternate implementations - e.g. selected via
C<< use Context::Singleton { frame_class => q (My::Frame) } >> - don't
interfere with L<Context::Singleton::Frame>'s (or each other's) state.

=head2 _generate_frame_class_internals ()

	package My::Frame;
	use Moo;
	BEGIN { extends q (Context::Singleton::Frame) }
	BEGIN { __PACKAGE__->_generate_frame_class_internals }

Installs a C<_localisable_current_frame> method into the calling class,
backed by its own arrayref slot holding the current I<frame> instance.

C<current_frame ()> and C<frame {}> both resolve C<_localisable_current_frame>
through regular method dispatch, so:

=over

=item *

A class calling C<_generate_frame_class_internals> gets its own current
I<frame>, independent of its parent class.

=item *

A subclass which doesn't call it inherits its parent's
C<_localisable_current_frame> and therefore shares its parent's current
I<frame>.

=back

L<Context::Singleton::Frame> calls C<_generate_frame_class_internals> on
itself when the module is loaded, so it always has its own state, even
before any subclass exists.

An optional frame (or class) to seed the slot with may be passed; it defaults
to the invocant.

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

