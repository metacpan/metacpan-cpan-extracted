## no critic (RequireUseStrict RequireUseWarnings)
package DSL::Tiny::Role;
## critic
# ABSTRACT: A simple yet powerful DSL builder.

use Moo::Role;

use Sub::Exporter -setup => { groups => { install_dsl => \&_dsl_build, } };

use Data::OptList;
use MooX::Types::MooseLike::Base qw(ArrayRef);
use Params::Util qw(_ARRAYLIKE);
use Sub::Exporter::Util qw(curry_method);
{
    $DSL::Tiny::Role::VERSION = '0.001';
}

BEGIN { *install_dsl = \&import; }

has dsl_keywords => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => 'build_dsl_keywords',
);

sub _dsl_build {
    my ( $invocant, $group, $arg, $col ) = @_;

    # if not already an instance, create one.
    my $instance = ref $invocant ? $invocant : $invocant->new();

    # fluff up the keyword specification
    my $keywords = Data::OptList::mkopt_hash( $instance->dsl_keywords,
        { moniker => 'keyword list' }, ['HASH'], );

    my %dsl = map { $_ => $instance->_compile_keyword( $_, $keywords->{$_} ) }
        keys $keywords;

    return \%dsl;
}

sub _compile_keyword {
    my ( $self, $keyword, $args ) = @_;

    # generate code for keyword
    my $code_generator = $args->{as} || curry_method($keyword);
    my $code = $code_generator->( $self, $keyword );

    # generate before code, if any
    # make sure before is an array ref
    # call each generator (if any), save resulting coderefs
    my $before = $args->{before};
    $before = [$before] unless _ARRAYLIKE($before);
    my @before_code = map { $_->($self) } grep { defined $_ } @{$before};

    # generate after code, if any
    my $after = $args->{after};
    $after = [$after] unless _ARRAYLIKE($after);
    my @after_code = map { $_->($self) } grep { defined $_ } @{$after};

    if ( @before_code or @after_code ) {
        my $new_code = sub {
            my @rval;

            $_->(@_) for @before_code;

            # Cribbed from $Class::MOP::Method::Wrapped::_build_wrapped_method
            # not sure that it doesn't have more parens then necessary, but
            # if it works for them...
            (   ( defined wantarray )
                ? (   (wantarray)
                    ? ( @rval = $code->(@_) )
                    : ( $rval[0] = $code->(@_) )
                    )
                : $code->(@_)
            );

            $_->(@_) for @after_code;

            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        };
        return $new_code;
    }

    return $code;
}

1;

__END__

=pod

=head1 NAME

DSL::Tiny::Role - A simple yet powerful DSL builder.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # In e.g. MooseDSL.pm, describe a simple DSL.
    package MooseDSL;

    use Moose;  # or use Moo;

    with qw(DSL::Tiny::Role);

    sub build_dsl_keywords {
        return [
            # keywords will be run through curry_method
            qw(argulator return_self clear_call_log),
        ];
    }

    has call_log => (
        clearer => 'clear_call_log',
        default => sub { [] },
        is      => 'rw',
        lazy    => 1
    );

    sub argulator {
        my $self = shift;
        push @{ $self->call_log }, join "::", @_;
    }

    sub return_self { return $_[0] }

    1;

    ################################################################

    # and then in another file you can use that DSL

    use Test::More;
    use Test::Deep;

    use MooseDSL qw( -install_dsl );

    # peek under the covers, get the instance
    my $dsl = return_self;
    isa_ok( $dsl, 'MooseDSL' );

    # test argument handling, single scalar
    argulator("a scalar");
    cmp_deeply( $dsl->call_log, ['a scalar'], 'scalar arg works' );
    clear_call_log;

    # test argument handling, list of args
    argulator(qw(a list of things));
    cmp_deeply( $dsl->call_log, ['a::list::of::things'], 'list arg works' );
    clear_call_log;

    done_testing;

=head1 DESCRIPTION

I<This is an initial release.  It's all subject to rethinking.  Comments
welcome.>

    every time a language advertises "we make writing dsls easy!" i
    read "i'm going to have to learn a new language for every project"

    Jesse Luehrs (@doyster) 3/8/13, 12:11 PM

Domain-specific languages (DSL's) aid in the efficient expression of
configurations, problems and solutions within a particular domain.  While some
DSL's are built from the ground up with custom lexers, parsers,
etc... (e.g. the Unix build tool "make"), other "internal DSL's" (L<Werner
Schuster|http://www.infoq.com/news/2007/06/dsl-or-not>) are distilled from
existing languages and "speak the language of their domain with an accent"
(L<Piers Cawley|http://www.bofh.org.uk/2007/05/19/domain-agnostic-languages>).

A variety of Perl tools and libraries sport domain specific langagues,
e.g. L<Dancer>, L<Module-CPANfile> and L<Module-Install> and the number of
re-implementations of the underlying plumbing is almost exactly equal to the
number of such modules.  These implementations usually devolve into dirty
tricks (e.g. explicit package stash manipulations) and re-invention of several
wheels.

L<DSL::Tiny> packages the common functionality required to implement an
internal DSL, building on powerful foundations (L<Sub::Exporter>) and effective
techniques (L<Moose> and L<Moo> roles) to allow developers to focus on their
domain-specific issues.  It builds on a flexible mechanism for exporting a set
of subroutines into a package; provides a consistent framework for subroutine
currying; and automates the construction of instances, their association with
DSL fragments and the evaluation of those fragments.

In other words, when I needed to build an internal DSL for a project, I was
shocked at how often the basic brushstrokes had been repeated and how often
these implementations dug down and peeked underneath Perl's stashes.  These
modules are my attempt to provide a reusable solution to the problem via
existing high-leverage tools.

=head1 ATTRIBUTES

=head2 dsl_keywords

Returns an arrayref of dsl keyword info.

It is lazy.  Classes which consume the role are required to supply a builder
named C<_build_dsl_keywords>.

In its canonical form the contents of the array reference are a series of array
references containing keyword_name => { option_hash } pairs, e.g.

  [ [ keyword1 => { as => &generator('method1') } ],
    [ keyword2 => { before => &generator ]
  ]

Generators are as described in the L<Sub::Exporter> documentation.

However, as the contents of this array reference are processed with
Data::OptList there is a great deal of flexibility, e.g.

  [ qw( m1 m2 ), k4 => { as => &generator('some_method' } ]

is equivalent to:

  [ m1 => undef, m2 => undef, k4 => { as => generator('some_method') } ]

Options are optional.  In particular, if no C<as> generator is provided then
the keyword name is presumed to also be the name of a method in the class and
C<Sub::Exporter::Utils::curry_method> will be applied to that method to
generate the coderef for that keyword.  The makes the above equivalent to:

  [ m1 => { as => generator('m1') }, m2 => { as => generator('m2') },
    k4 => { as => generator('some_method') }
  ]

In its simplest form, the keyword arrayref contains a list of method names
relative to class which consumes this role.

  [ qw( m1 m2 ) ]

Supported options include:

=over 4

=item as

=item before

=item after

=back

=head1 METHODS

=head2 import

An import routine generated by Sub::Exporter.

When invoked as a class method (usually via C<use>) with a C<-install_dsl>
argument it will construct a new instance then generate and install a set of
subroutines using the information provided in the instance's C<dsl_keywords>
attribute.

TODO.

=head2 install_dsl

A synonym for the Sub::Exporter generated import method.  Sounds better when
one uses it to install into an instance.

=head2 _dsl_build

Private-ish.  Do you really want to be here?

C<_dsl_build> build's up the set of keywords that L<Sub::Exporter> will
install.

It returns a hashref whose keys are names of keywords and whose values are
coderefs implementing the respective behavior.

It can be invoked on a class (a.k.a. as a class method), usually by C<use>.  If
so, a new instance of the class will be constructed and the various keywords
are curried with respect to that instance.

It can be invoked on a class instance, e.g. via an explicit invocation of
L<import> on an instance.  If so, then that instance is used when constructing
the keywords.

=head2 _compile_keyword

Private, go away.

Generate a sub that implements the keyword, taking care of before's and afters.

=head1 REQUIRES

=head2 build_dsl_keywords

A subroutine, used as the Moo{,se} builder for the L</dsl_keywords> attribute.
It returns an array reference containing information about the methods and
subroutines that implement the keywords in the DSL.

=head1 AUTHOR

George Hartzell <hartzell@alerce.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
