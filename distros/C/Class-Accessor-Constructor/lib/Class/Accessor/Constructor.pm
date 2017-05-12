use 5.008;
use strict;
use warnings;

package Class::Accessor::Constructor;
BEGIN {
  $Class::Accessor::Constructor::VERSION = '1.111590';
}

# ABSTRACT: Constructor generator
use Carp 'cluck';
use parent qw(
  Class::Accessor
  Class::Accessor::Installer
  Data::Inherited
);
use constant NO_DIRTY   => 0;
use constant WITH_DIRTY => 1;

sub mk_singleton_constructor {
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    @args = ('new') unless @args;
    my $singleton;
    for my $name (@args) {
        my $instance_method = "${name}_instance";
        $self->install_accessor(
            name => $name,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${name}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my $self = shift;
                $singleton ||= $self->$instance_method(@_);
            },
        );
        $self->document_accessor(
            name    => $name,
            purpose => <<'EODOC',
Creates and returns a new object. The object will be a singleton, so repeated
calls to the constructor will always return the same object. The constructor
will accept as arguments a list of pairs, from component name to initial
value. For each pair, the named component is initialized by calling the
method of the same name with the given value. If called with a single hash
reference, it is dereferenced and its key/value pairs are set as described
before.
EODOC
            examples => [
                "my \$obj = $class->$name;",
                "my \$obj = $class->$name(\%args);",
            ],
        );
        $class->mk_constructor($instance_method);
    }
    $self;    # for chaining
}

sub mk_constructor {
    my $self = shift;
    $self->_make_constructor(NO_DIRTY, @_);
    $self;    # for chaining
}

sub mk_constructor_with_dirty {
    my $self = shift;
    $self->_make_constructor(WITH_DIRTY, @_);
    $self;    # for chaining
}

sub _make_constructor {
    my ($self, $should_dirty, @args) = @_;
    my $target_class = ref $self || $self;
    @args = ('new') unless @args;

    # We generate a method into package $class which uses methods it needs to
    # inherit from Class::Accessor::Constructor::Base (which in turn inherits
    # from Data::Inherited), so we need to make sure that $class actually
    # inherits from Class::Accessor::Constructor::Base.
    unless (UNIVERSAL::isa($target_class, 'Class::Accessor::Constructor::Base'))
    {
        require Class::Accessor::Constructor::Base;
        no strict 'refs';
        push @{"${target_class}::ISA"}, 'Class::Accessor::Constructor::Base';
    }
    for my $name (@args) {

        # n00bs getting pwned here
        $self->install_accessor(
            name => $name,
            code => sub {
                local $DB::sub = local *__ANON__ = "${target_class}::${name}"
                  if defined &DB::DB;
                my $class = shift;
                my $self;

                # If we're given a reference, don't tie() it. Only tie()
                # completely new objects.
                if (ref $class) {
                    $self = $class;
                } else {
                    my %self = ();
                    tie %self, 'Class::Accessor::Constructor::Base'
                      if $should_dirty;
                    $self = bless \%self, $class;
                    if ($should_dirty) {

                      # set the results of every_list() from here, because
                      # a tied class' STORE() method is given a $self with a ref
                      # of the tied class, not the original class.
                        $self->hygienic(scalar $self->every_list('HYGIENIC'));
                        $self->unhygienic(
                            scalar $self->every_list('UNHYGIENIC'));

                        # Reset dirty flag because setting the above will cause
                        # the dirty flag to be set.
                        $self->clear_dirty;
                    }
                }
                our %cache;
                my %args;

               # The following should be equivalent to
               #
               # my $munger = $cache{MUNGE_CONSTRUCTOR_ARGS}{ref $self} //=
               #     $self->can('MUNGE_CONSTRUCTOR_ARGS');
               #
               # but we want this to run under perl 5.8.8 as well. Can't use ||=
               # with can() because if the object "can't", then can will return
               # undef so it will check again the next time.
                my $munger;
                unless (exists $cache{MUNGE_CONSTRUCTOR_ARGS}{ ref $self }) {
                    $cache{MUNGE_CONSTRUCTOR_ARGS}{ ref $self } =
                      $self->can('MUNGE_CONSTRUCTOR_ARGS');
                }
                $munger = $cache{MUNGE_CONSTRUCTOR_ARGS}{ ref $self };
                if ($munger) {
                    %args = $munger->($self, @_);
                } else {
                    %args =
                      (scalar(@_ == 1) && ref($_[0]) eq 'HASH')
                      ? %{ $_[0] }
                      : @_;
                }

                # Note: DEFAULTS are cached, so they have to be static.
                my $defaults = $cache{DEFAULTS}{ ref $self } ||=
                  [ $self->every_hash('DEFAULTS') ];
                %args = (@$defaults, %args);

              # If a class wants to order some args first, it can define a
              # FIRST_CONSTRUCTOR_ARGS list (will be cumulative over inheritance
              # tree due to NEXT.pm magic)
              # my @first = $self->every_list('FIRST_CONSTRUCTOR_ARGS');
                my $first = $cache{FIRST_CONSTRUCTOR_ARGS}{ ref $self } ||=
                  [ $self->every_list('FIRST_CONSTRUCTOR_ARGS') ];
                my %seen;
                for (@$first, keys %args) {
                    next if $seen{$_}++;
                    my $setter;
                    unless (exists $cache{setter}{$_}{ ref $self }) {
                        $cache{setter}{$_}{ ref $self } = $self->can($_);
                    }
                    $setter = $cache{setter}{$_}{ ref $self };
                    unless ($setter) {
                        my $error = sprintf "%s: no setter method for [%s]\n",
                          ref($self), $_;
                        cluck $error;
                        die $error;
                    }
                    $setter->($self, $args{$_});
                }
                my $init;
                unless (exists $cache{INIT}{ ref $self }) {
                    $cache{INIT}{ ref $self } = $self->can('init');
                }
                $init = $cache{INIT}{ ref $self };
                $self->init(%args) if $init;
                $self;
            },
        );
        $self->document_accessor(
            name    => $name,
            purpose => <<'EODOC',
Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.
EODOC
            examples => [
                "my \$obj = $target_class->$name;",
                "my \$obj = $target_class->$name(\%args);",
            ]
        );
    }
}
1;


__END__
=pod

=head1 NAME

Class::Accessor::Constructor - Constructor generator

=head1 VERSION

version 1.111590

=head1 SYNOPSIS

  package MyClass;
  use base 'Class::Accessor::Constructor';
  __PACKAGE__->mk_constructor;

=head1 DESCRIPTION

This module generates accessors for your class in the same spirit as
L<Class::Accessor> does. While the latter deals with accessors for scalar
values, this module provides accessor makers for rather flexible constructors.

The accessor generators also generate documentation ready to be used with
L<Sub::Documentation>.

=head1 METHODS

=head2 mk_constructor

Takes an array of strings as its argument. If no argument is given, it uses
C<new> as the default. For each string it creates a class constructor which is
quite powerful and flexible. It supports

=over 4

=item C<customizable munging of arguments>

=item C<customizable sorting of arguments>

=item C<inherited default values>

=item C<an optional init() method>

=back

The constructor accepts named arguments - that is, a hash - and will set the
hash values on the accessor methods denoted by the keys. For example,

    package MyClass;
    use base 'Class::Accessor::Constructor';
    __PACKAGE__->mk_constructor;

    package main;
    use MyClass;

    my $o = MyClass->new(foo => 12, bar => [ 1..5 ]);

is the same as

    my $o = MyClass->new;
    $o->foo(12);
    $o->bar([1..5]);

The constructor will also call an C<init()> method, if there is one.

The arguments are munged beforehand - if a single argument is a hashref is
passed in, it is expanded out, the the key/value pairs - whether originally as
a hash ref or a list - may be reordered as typically occurs with perl hashes.

For example:

    package Simple;
    use base 'Class::Accessor::Constructor';

    __PACKAGE__
        ->mk_constructor
        ->mk_accessors(qw(a b));

    use constant DEFAULTS => (a => 7, b => 'default') ;

Somewhere else:

    use Simple;
    my $test1 = Simple->new;                  # now a == 7, b == 'default'
    my $test2 = Simple->new(a => 1);          # now a == 1, b == 'default'
    my $test3 = Simple->new(a => 1, b => 2);  # now a == 1, b == 2

Defaults can be inherited per L<Data::Inherited>'s C<every_hash()>. Example:

    package A;
    use base 'Class::Accessor::Constructor';

    __PACKAGE__->mk_constructor->mk_accessors(qw(a b));

    use constant DEFAULTS => (a => 7, b => 'default');

and

    package B;
    use base 'A';
    use constant DEFAULTS => (a => 23);

then

    use A;
    use B;
    my $test1 = A->new;   # now a ==  7, b == 'default'
    my $test2 = B->new;   # now a == 23, b == 'default'

If a class wants to order some args first, it can define a
C<FIRST_CONSTRUCTOR_ARGS()> list, which will be cumulative over inheritance
tree due to L<Data::Inherited>. C<FIRST_CONSTRUCTOR_ARGS()> should return a
list of argument names that have to come first; if a constructor is called,
those arguments are set first, whereas the other ones are set in an
unspecified order.

Example:

    package Simple;
    use base 'Class::Accessor::Constructor';

    __PACKAGE__->mk_constructor->mk_accessors(qw(b));

    use constant FIRST_CONSTRUCTOR_ARGS => ('b');

    # make 'a' dependent on 'b'
    sub a {
        return $_[0]->{a} if @_ == 1;
        $_[0]->{a} = $_[1] + $_[0]->b;
    }

then

    my $test = Simple->new(a => 1, b => 2);

will set C<b> first, then set C<a> (to 3).

As mentioned, arguments are munged beforehand automatically, but you can also
customize the munging. By default,

    my $test = Simple->new(a => 1, b => 2)

is the same as

    my $test = Simple->new({ a => 1, b => 2 })

Suppose you have a class that has one preferred accessor, and you want to
simplify its usage so that if the constructor is called with a single value,
it is passed to that preferred accessor.

Given that the C<Simple> class defines

    sub MUNGE_CONSTRUCTOR_ARGS {
        my $self = shift;
        return %{ $_[0] }    if @_ == 1 && ref($_[0]) eq 'HASH';
        return (b => @_) if @_ % 2;      # odd number of args
        return @_;
    }

then an object could be constructed like this

    my $test = Simple->new('blah');

which would be munged to be equivalent to

    my $test = Simple->new(b => 'blah');

If you define an C<init()> method, the constructor calls it with the munged
args as the very last thing.

=head2 mk_constructor_with_dirty

Like C<mk_constructor()>, but also keeps track of whether the object has been
modified. This is useful, for example, when you have read the object from a
storage and at the end you want to write it back if it has changed. This
method generated saves you from having to update a dirty-flag in each
accessor. It achieves its purpose by doing a tie() on the blessed hash that is
the object, so there is some performance penalty. But it also works when
someone tries to break encapsulation by accessing hash elements directly
instead of going via the accessors. See L<Class::Accessor::Constructor::Base>
for details.

If you want that behaviour only in a part of your inheritance tree, redefine
the constructor at the appropriate point. For example:

    package Foo;
    use base 'Class::Accessor::Constructor';

    __PACKAGE__->mk_constructor;

    package Bar;
    use base 'Foo';
    __PACKAGE__->mk_constructor_with_dirty;

Now objects of type C<Foo> will not keep a dirty-flag, but objects of type
C<Bar> and its descendants will.

=head2 mk_singleton_constructor

Like C<constructor> but constructs a singleton object.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-Constructor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Class-Accessor-Constructor/>.

The development version lives at L<http://github.com/hanekomu/Class-Accessor-Constructor>
and may be cloned from L<git://github.com/hanekomu/Class-Accessor-Constructor.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

