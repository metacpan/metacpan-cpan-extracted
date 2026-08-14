
use v5.10;
use strict;
use warnings;
use feature q (state);

package Context::Singleton;
$Context::Singleton::VERSION = '1.0.9';
use parent q (Exporter::Tiny);

use Context::Singleton::Frame;

use constant DEFAULT_FRAME_CLASS => Context::Singleton::Frame::;
use constant FRAME_DEPTH         => 2;

our @EXPORT = (
	qw[ contrive        ],
	qw[ contrive_class  ],
	qw[ current_frame   ],
	qw[ deduce          ],
	qw[ frame           ],
	qw[ is_deduced      ],
	qw[ load_rules      ],
	qw[ proclaim        ],
	qw[ trigger         ],
	qw[ try_deduce      ],
);

sub _exported_accessors {
	my ($class, $globals) = @_;
	my $frame_class = $globals->{frame_class} // $class->DEFAULT_FRAME_CLASS;

	state %cache;

	return $cache{$frame_class} //= +{
		contrive        => eval qq (sub { $frame_class->contrive (\@_) }),
		contrive_class  => eval qq (sub { $frame_class->contrive_class (\@_) }),
		current_frame   => eval qq (sub { $frame_class->current_frame }),
		deduce          => eval qq (sub { $frame_class->deduce (\@_) }),
		frame           => eval qq (sub (&) { my \$frame = $frame_class->current_frame; local \$frame->_localisable_current_frame->[0] = \$frame->build_frame; \$_[0]->() }),
		is_deduced      => eval qq (sub { $frame_class->is_deduced (\@_) }),
		load_rules      => eval qq (sub { $frame_class->load_rules (\@_) }),
		proclaim        => eval qq (sub { $frame_class->proclaim (\@_) }),
		trigger         => eval qq (sub { $frame_class->trigger (\@_) }),
		try_deduce      => eval qq (sub { $frame_class->try_deduce (\@_) }),
	};
}

sub _exporter_expand_sub {
	my ($class, $name, $args, $globals) = @_;

	return $name => _exported_accessors ($class, $globals)->{$name};
}

sub _exporter_validate_opts {
	my ($class, $globals) = @_;

	$class->SUPER::_exporter_validate_opts (@_);

	_exported_accessors ($class, $globals)->{load_rules}->(@{ $globals->{load_path} })
		if $globals->{load_path}
		;
}

__PACKAGE__->import;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton - Context specific singleton values

=head1 GLOSSARY

=head2 dependency

I<Singleton> which value is required to build another I<singleton>'s value

=head2 frame

Frame represents hierarchy. It is for data what block is for code.
Resource value is by default cached in the top-most frame providing
all its dependencies.

Cached values are destroyed upon leaving context.

=head2 rule

Rule specifies how to build singleton value

	contrive 'singleton' => ( ... );

There can be multiple rules for building a single I<singleton>.
The one with most relevant dependencies will be used.
When there are more available rules, the first defined will be used.

Refer L<#contrive ()> for more.

=head2 singleton

A value identified by string. Singleton identifier is global.

=head1 DESCRIPTION

=head2 What is a context specific singleton?

As your workflow handles its tasks, granularity become finer and certain
entities behaves like singletons.

As your application evolves, this granularity changes along with data model
and/or data representation.

=head2 How does it differ from the multiton pattern?

Multiton is a set of named singletons (global variables) whereas values
mantained by L<Context::Singleton> are context sensitive.

=head2 Doesn't C<local> already provide similar behaviour?

In addition to C<local> L<Context::Singleton> provides also immutability
in scope assignment and lazy values built on demand.

=head2 When use L<Context::Singleton>?

=over

=item When your application evolves

=item When your application has tests

=item

=head1 EXPORTED FUNCTIONS

L<Context::Singleton> uses L<Exporter::Tiny> to do hard work.

=head2 frame {}

	frame {
		...;
	}

Creates a new I<frame>, calls its argument while preserving list/scalar context,
and passes through returned value.

It doesn't consume any exception.

=head2 proclaim ()

	proclaim singleton => value;
	proclaim singleton_1 => value, singleton_2 => value2;

Define the value of a I<singleton> in the current I<frame>.

When it is already populated it throws an I<Context::Singleton::Exception::Deduced>
exception.

Returns the value of the last I<singleton> from the argument list.

=head2 deduce ()

	my $var = deduce q (singleton);

Returns a I<singleton> value relevant in current frame.

If I<singleton> value is not available, it tries to contrive it using
known rules or looks into parent I<frame>.

=head2 load_path ()

	load_path q (prefix-1), ...;

Evaluate all modules within given module prefix(es).
Every prefix is evaluated only once.

=head2 contrive ()

Defines new I<rule> how to build I<singleton> value

	contrive q (name)
		=> class   => q (Foo::Bar)
		=> deduce  => q (singleton)
		=> builder => q (new)
		=> default => { singleton_1 => q (v1), ... }
		=> dep     => [ q (singleton_2), ... ]
		=> dep     => { param_a => q (singleton_1), ... }
		=> as      => sub { ... }
		=> value   => 10
	;

=over

=item value => constant

	contrive q (http-request-timeout)
		=> value => 900
		;

Simplest rule, just constant value.

=item as => CODEREF

	contrive q (ideal-body-weight-ibw)
		=> dep => [qw[ height gender ]]
		=> as  => sub ($height, $gender) {
			my $kg = 22 * ($heigth->meters - ($gender->is_woman ? 10 : 0)) ** 2;
			Weight->new (kilograms => $height->centimeters - 100);
		};

Defines code used to build singleton value. Dependencies are passed as arguments.

When used in conjuction with C<class> or C<deduce>, their value is passed as first
argument (mimics method call).


=item builder => method_name

	contrive q (height-in-meters)
		=> deduce  => q (height)
		=> builder => q (meters)
		;

	contrive q (db-connection)
		=> class   => q (DBI)
		=> builder => q (connect)
		=> dep     => [qw[ db-dsn db-user db-password db-connection-options ]]
		;

Specifies method name to be applied on C<class> or C<deduce>.
Defaults to C<new>.

=item class => Class::Name

Calls the builder method with dependencies on the given class to build a value.
Automatically creates singleton C<Class::Name> with a rule dynamically loading
given class and returning its name, almost like:

	my $class_name = eval "require Class::Name; 'Class::Name'";
	$class_name->$builder (@deps);

When class I<singleton> is proclaimed class is not autoloaded.

See also: L<#contrive_class ()

=item deduce => singleton

Calls the builder method (with dependencies) on the object available
as a value of the given I<singleton>.

	my $object = deduce q (singleton);
	$object->$builder (@deps);

=item default => { singleton => value, ... }

Default values of dependencies. If used they are treated as deduced in root I<frame>
but are not stored neither cached anywhere.

=item dep

Dependencies required for this rule.

Two forms are recognized at the moment:

=over

=item ARRAYREF

List of required singletons.
Passed as a list to the builder function

=item HASHREF

Hash values are treated as singleton names.
Passed as a list of named parameters to the builder function.

=back

=back

=head2 contrive_class ()

	contrive_class q (Class::Name);

Setup autoload mechanism same as when using C<contrive> with C<class>.

=head1 SUBCLASSING

	package My::Context::Singleton;
	use parent q (Context::Singleton);

	use My::Frame;
	use constant DEFAULT_FRAME_CLASS => My::Frame::;

	__PACKAGE__->import;

A subclass of L<Context::Singleton> can declare a C<DEFAULT_FRAME_CLASS> constant
to specify which L<Context::Singleton::Frame> (sub)class its exported functions
operate on, without requiring every caller to pass C<frame_class> explicitly.

C<frame_class> passed at C<use> time still takes precedence over
C<DEFAULT_FRAME_CLASS>:

	use My::Context::Singleton;                                     # uses My::Frame
	use My::Context::Singleton { frame_class => q (Other::Frame) }; # uses Other::Frame

See L<Context::Singleton::Frame/EXTENDING FRAME> for how to implement a custom
frame class.

=head1 TUTORIAL

See short tutorial L<Context::Singleton::Tutorial>

=head1 REPOSITORY

https://github.com/happy-barney/perl-Context-Singleton

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

L<Context::Singleton> distribution can be distributed and modified
under The Artistic License 2.0.

=cut
