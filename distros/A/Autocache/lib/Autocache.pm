package Autocache;

use strict;
use warnings;

our $VERSION = '0.004';
$VERSION = eval $VERSION;

use Autocache::Config;
use Autocache::Request;
use Autocache::Strategy::Store::Memory;
use Autocache::WorkQueue;
use Autocache::Logger qw(get_logger);
use Carp;

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT = qw( autocache );

my $SINGLETON;

sub autocache
{
    my ($name,$args) = @_;
    get_logger()->debug( "autocache $name" );
    my $package = caller;
    __PACKAGE__->singleton->_cache_function( $package, $name, $args );
}

sub singleton
{
    my $class = shift;
    __PACKAGE__->initialise()
        unless $SINGLETON;
    return $SINGLETON;
}

sub initialise
{
    my $class = shift;
    $SINGLETON = $class->new( @_ );
    $SINGLETON->configure;
    my %args = @_;
    Autocache::Logger->initialise(logger => $args{logger})
        if $args{logger};
}

sub new
{
    my ($class,%args) = @_;
    my $config = Autocache::Config->new( $args{filename} );
    my $self =
        {
            config => $config,
            strategy => {},
            default_strategy => undef,
            work_queue => undef,
        };
    bless $self, $class;
    return $self;
}

sub configure
{
    my ($self) = @_;

    foreach my $node ( $self->{config}->get_node( 'strategy' )->children )
    {
        my $name = $node->name;
        my $package = $node->value;
        _use_package( $package );

        my $strategy;

        eval
        {
            $strategy = $package->new( $node );
        };
        if( $@ )
        {
            confess "cannot create strategy $name using package $package - $@";
        }
        $self->{strategy}{$node->name} = $strategy;
    }

    $self->configure_functions( $self->{config}->get_node( 'fn' ) );

    if( $self->{config}->node_exists( 'default_strategy' ) )
    {
        $self->{default_strategy} = $self->get_strategy(
            $self->{config}->get_node( 'default_strategy' )->value );
    }
}

sub configure_functions
{
    my ($self,$node,$namespace) = @_;

    $namespace ||= '';

    if( $node->value )
    {
        get_logger()->debug( "fn: $namespace -> " . $node->value );

        $self->{fn}{$namespace}{strategy} = $node->value;
    }

    foreach my $child ( $node->children )
    {
        $self->configure_functions( $child, $namespace . '::' . $child->name );
    }
}

sub cache_function
{
    my ($self,$name,$args) = @_;
    get_logger()->debug( "cache_function '$name'" );
    my $package = caller;
    $self->_cache_function( $package, $name, $args );
}

sub _cache_function
{
    my ($self,$package,$name,$args) = @_;

    get_logger()->debug( "_cache_function '$name'" );

    # r : cache routine name
    my $r = '::' . $package . '::' . $name;

    # n : cache routine normaliser name
    my $n = '::' . $package . '::_normalise_' . $name;

    # g : generator routine name
    my $g = __PACKAGE__ . '::G' . $r;

    get_logger()->debug( "cache : $r / $g"  );

    no strict 'refs';

    # get generator routine ref
    my $gsub = *{$r}{CODE};

    # see if we have a normaliser
    my $gsub_norm = *{$n}{CODE};

    unless( defined $gsub_norm )
    {
        get_logger()->debug( "no normaliser, using default" );
        $gsub_norm = $self->get_default_normaliser();
    }

    my $rsub = $self->_generate_cached_fn( $r, $gsub_norm, $gsub );

    {
        # avoid "subroutine redefined" warning
        no warnings;
        # setup cached routine for caller
        *{$r} = $rsub;
    }
    1;
}

sub run_work_queue
{
    my($self) = @_;
    get_logger()->debug( "run_work_queue" );
    $self->get_work_queue()->execute();
}

sub get_work_queue
{
    my ($self) = @_;
    get_logger()->debug( "get_work_queue" );
    unless( $self->{work_queue} )
    {
        $self->{work_queue} = Autocache::WorkQueue->new();
    }
    return $self->{work_queue};
}

sub get_strategy_for_fn
{
    my ($self,$name) = @_;
    get_logger()->debug( "get_strategy_for_fn '$name'" );

    return $self->get_default_strategy()
        unless exists $self->{fn}{$name}{strategy};

    return $self->get_strategy( $self->{fn}{$name}{strategy} );
}

sub get_strategy
{
    my ($self,$name) = @_;
    get_logger()->debug( "get_strategy '$name'" );
    confess "cannot find strategy $name"
        unless $self->{strategy}{$name};
    return $self->{strategy}{$name};
}

sub get_default_strategy
{
    my ($self) = @_;
    get_logger()->debug( "get_default_strategy" );
    unless( $self->{default_strategy} )
    {
        $self->{default_strategy} = Autocache::Strategy::Store::Memory->new;
    }
    return $self->{default_strategy};
}

sub get_default_normaliser
{
    my ($self) = @_;
    get_logger()->debug( "get_default_normaliser" );
    return \&_default_normaliser;
}

sub _generate_cached_fn
{
    my ($self,$name,$normaliser,$coderef) = @_;
    get_logger()->debug( "_generate_cached_fn $name" );

    return sub
    {
        get_logger()->debug( "CACHE $name" );
        return unless defined wantarray;
        my $context = wantarray ? 'L' : 'S';

        get_logger()->debug( "calling context: $context" );

        my $request = Autocache::Request->new(
            name => $name,
            normaliser => $normaliser,
            generator => $coderef,
            args => \@_,
            context => $context,
        );

        my $strategy = $self->get_strategy_for_fn( $name );

        my $rec = $strategy->get( $request );

        unless( $rec )
        {
            $rec = $strategy->create( $request );
            $strategy->set( $request, $rec );
        }

        my $value = $rec->value;

        return wantarray ? @$value : $value;
    };
}

sub _default_normaliser
{
    get_logger()->debug( "_default_normaliser" );
    return join ':', @_;
}

sub _use_package
{
    my ($name) = @_;
    get_logger()->debug( "use $name" );
    eval "use $name";
    if( $@ )
    {
        confess $@;
    }
}

1;

__END__

=pod

=head1 NAME

Autocache - An automatic caching framework for Perl.

=head1 SYNOPSIS

    use Autocache;

    autocache 'my_slow_function';

    sub my_slow_function
    {
        ...
    }

=head1 DESCRIPTION

This code came about as the result of attempting to refactor, simplify and
extend the caching used on a rather large website.

It provides a framework for configuring multiple caches at different levels,
process, server, networked and allows you to declaratively configure which
functions have their results cached, and how.

Autocache acts a lot like the Memoize module. You tell it what function you
would like to have cached and if you say nothing else it will go ahead and
cache all calls to that function in-process, you just specify the name of
the function.

In addition to this though Autocache allows you to specify in great detail
how and where function results get cached.

The module uses IoC/dependency injection from a configuration file to setup
a number Strategies. These are the basic building blocks used to determine
how things get cached.

Strategies determine how a cached value should be validated, refreshed, and
even whether or not the value should be stored at all.

The goal here is to make it stupidly simple to start to cache certain
functions, and change where and how those values get cached if you find
they're in the wrong place.

=head1 CONSIDERATIONS

There are a number of considerations when using autocache, or any caching
mechanism.

=head2 PURITY

Any function that is pure should have no trouble being cached.

A pure function being one;

=over

=item

whose value depends soley on the parameters passed to the function and no other global information, state or input from IO or external devices.

=item

generates no side-effects (although, depending on your use, side-effects may be allowable).

=back

If your function does depend on external state then you may or may not be
able to use some form of caching. For example if your function depends on
one of a number of states that may be the current one then you can always
create a new function that does depend on all of that information and make
the current function simply a driver for it.

For example, the function below depends on the state of a global variable C<$mode>.

    autocache 'authorised';

    sub authorised
    {
        my ($user,$resource,$action) = @_;
        if( $mode eq 'normal' )
        {
            ...normal mode code...
        }
        elsif( $mode eq 'strict' )
        {
            ...strict mode code...
        }
        else
        {
            ...all other mode code...
        }
    }

If this function is cached then autocache will cache the value generated for
whatever the C<$mode> variable is set to at the time of the first
invocation, if this function is invoked again later on it may produce
incorrect results since the value of C<$mode> has changed.

We can still gain a speedup through caching but we have to rewrite it
slightly to make sure we're caching a pure function.

    autocache '_authorised_by_mode';

    sub authorised
    {
        my ($user,$resource,$action) = @_;
        return _authorised_by_mode($user,$resource,$action,$mode);
    }

    sub _authorised_by_mode
    {
        my ($user,$resource,$action,$mode) = @_;
        if( $mode eq 'normal' )
        {
            ...normal mode code...
        }
        elsif( $mode eq 'strict' )
        {
            ...strict mode code...
        }
        else
        {
            ...all other mode code...
        }
    }

Now even though the C<authorised> function is still dependant upon the
global C<$mode> variable the new C<_authorised_by_mode> function is entirely
dependant upon it's input parameters and nothing more and it can be cached.

=head2 NORMALISATION

Function results are cached based on the arguments to the function. For
functions whose arguments are position dependant and are simple values
autocache should simply do the right thing.

Two cases where autocache will require help are when the arguments to a
function are provided through a hash, or more complex data structure and when
objects/references are passed around that are equivalent but where the
identities of the references are not.

For example, if a function 'fn' accepts a hash containing one or more
parameters named 'a', 'b', 'c' and 'd' then the following calls are
equivalent but autocache can't tell that.

    fn( 'a', 3, 'd', 4 );

    fn( 'd', 4, 'a', 3 )

To overcome this you can provide a normalisation function that takes the
parameters that are passed to the function and provides a canonical string
version that ensures equivalent calls appear to be the same to autocache.
Obviously care should be taken when designing a normalisation function where
the inputs may be large. (TODO - cookbook for normalisation)

To allow autocache to automatically pick up your normalisation function it
should be named the same as the function it provides normalisation for but
prefixed with '_normalise_'.

For the above function we could use something like this;

    sub _normalise_fn
    {
        my (%hash) = @_;
        return join ':', map { "$_=$hash{$_}" } sort keys %hash;
    }



=head1 CONTEXT

Perl functions are called in one of three contexts.

=over

=item

scalar

=item

list

=item

void

=back

Autocache automatically maintains seperate caches for each of the first two
contexts that functions may be called in. Since it expects functions to be
pure it understands when a function is called in void context and does
nothing at all since the value will not be used.

TODO - add option to merge all contexts into one if the author knows that
the same value is returned in either scalr or list context.

=head1 ARCHITECTURE

Autocache initially split up the process of caching into generating the values and
storing the values.  This has since been unified under the banner of 'strategies'.
There is a 'Store' namespace in 'Strategy', intended to represent strategies
that involve storage.

Strategies may be chained.  Some examples of Strategies are CostBased, Refresh,
Store::Memory and Store::Memcached.

The API for Strategies is not yet completely fixed but you should be able to quite
easily take one of those that already exists and modify it to suit your needs. The
configuration syntax allows you to use any custom classes you like as long as they
can accept the way we perform IoC (sub-optimal right now).

=head1 TODO

Test, test, test.

=head1 BUGS

Loads, and adding more all the time. This code is yet to become stable.

=head1 LICENSE

This module is Copyright (c) 2010 Nigel Rantor. England. All rights
reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Nigel A Rantor - E<lt>wiggly@wiggly.orgE<gt>

Rajit B Singh - E<lt>rajit.b.singh@gmail.comE<gt>

=cut
