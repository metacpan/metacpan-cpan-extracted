use 5.006;    # our
use strict;
use warnings;

package Acme::Data::Dumper::Extensions;

our $VERSION = '0.001000';

# ABSTRACT: Experimental Enhancements to core Data::Dumper

# AUTHORITY

use Data::Dumper ();
use Exporter     ();

my $DD_Defaults;

BEGIN {
    no warnings 'once';
    $DD_Defaults = {
        Bless     => q[bless],
        Deepcopy  => 0,
        Deparse   => 0,
        Freezer   => q[],
        Indent    => 2,
        Maxdepth  => 0,
        Pad       => q[],
        Pair      => q[ => ],
        Purity    => 0,
        Quotekeys => 1,
        Sortkeys  => 0,
        Terse     => 0,
        Toaster   => q[],
        Useperl   => !( grep $_ eq 'Data::Dumper', @DynaLoader::dl_modules ),
        Useqq     => 0,
        Varname   => q[VAR],
    };

    $DD_Defaults->{Sparseseen} = 0    if eval { Data::Dumper->VERSION(2.136) };
    $DD_Defaults->{Maxrecurse} = 1000 if eval { Data::Dumper->VERSION(2.153) };
    $DD_Defaults->{Trailingcomma} = 0 if eval { Data::Dumper->VERSION(2.160) };
}

sub DD_Defaults {
    { %$DD_Defaults }
}

our $_new_with_defaults = sub {
    my ( $self, $user_defaults ) = @_;

    my $instance = $self->new( [] );

    # Initialise with system defaults
    my $instance_defaults = { %{$DD_Defaults} };

    # Validate and overwrite user defaults
    for my $key ( sort keys %{ $user_defaults || {} } ) {
        if ( not exists $DD_Defaults->{$key} ) {
            my $guesskey = ucfirst( lc($key) );
            my $dym =
              exists $DD_Defaults->{$guesskey}
              ? sprintf q[ (did you mean '%s'?)], $guesskey
              : q[];
            die sprintf "Unknown feature '%s'%s", $key, $dym;
        }
        $instance_defaults->{$key} = $user_defaults->{$key};
    }

    # Set all values
    for my $key ( sort keys %{$instance_defaults} ) {

        # Properties that aren't methods are bad?
        my $sub = $instance->can($key);
        die "No setter for feature '$key'" unless $sub;
        $instance->$sub( $instance_defaults->{$key} );
    }
    return $instance;
};

our $_DumpValues = sub {
    my ( $self, $values, $names ) = @_;

    die "Expected array of values to dump" if not defined $values;
    die "Dump values is not an array" unless q[ARRAY] eq ref $values;

    $names = [] unless defined $names;

    my (@out) = $self->Reset()->Names($names)->Values($values)->Dump;
    $self->Reset()->Names( [] )->Values( [] );

    return wantarray ? @out : join q[], @out;
};

our @EXPORT_OK = qw( $_new_with_defaults $_DumpValues );

BEGIN { *import = \&Exporter::import; }

1;

=head1 NAME

Acme::Data::Dumper::Extensions - Experimental Enhancements to core Data::Dumper

=head1 SYNOPSIS

  use Data::Dumper;
  use Acme::Data::Dumper::Extensions qw/$_new_with_defaults/;

  local $Data::Dumper::Indent = 5;

  my $instance = Data::Dumper->$_new_with_defaults({ }); # Indent is still 2!

  $instance =  Data::Dumper->$_new_with_defaults({
    Indent => 4,         # Easier initalizer
  });

=head1 DESCRIPTION

This is just a testing ground for things that I'm suggesting for Data::Dumper.

It will likely be terrible because bolting on features after-the-fact its also
pretty ugly.

But its just a prototype.

For some, it will serve more as a proof-of-concept for various interfaces until
they get accepted into core.

=head1 EXPORTS

=head2 C<$_new_with_defaults>

This is a prototype function for construcing a Data::Dumper instance without
being prone to leak from other people using the global values.

At the time of this writing, if you need perfect consistency from Data::Dumper
in widely used code, you by necessity have to know every version of
Data::Dumper that exists, and know what the default values are of various
arguments, in order to revert them to your "known good" state if 3rd party
code decides to locally change those values for their own purposes.

Getting an instance of a Data::Dumper object before anyone tweaks those values
would also work, but trying to bet on getting loaded and getting an instance
before anyone else does is just foolhardy

Additionally, due to how C<< ->Values >> works, having a global instance of
Data::Dumper can lend itself to a memory leak and you have to take additional
care to make sure you free values passed to it.

=head3 Syntax

The name used here is C<$_new_with_defaults> as this makes it straight forward
to migrate code that uses this once its adopted, without needing to
monkey-patch Data::Dumper itself.

  Data::Dumper->$_new_with_defaults( ... )
  Data::Dumper->new_with_defaults( ... )

=head3 Arguments

  # Using the defaults
  Data::Dumper->$_new_with_defaults()

  # Augmenting the defaults
  Data::Dumper->$_new_with_defaults({ Name => value, Name => value });

The approach I've taken here is to ignore the standard arguments to C<new>,
because it wasn't clear to me how else to organise this with the existing
alternative interfaces.

Given there's an alternative way of passing the dump values, its suggested
to just use those until this part of the design is sorted out:

  Data::Dumper->$_new_with_defaults()->Values([ stuff, to, dump ])->Dump();

Or use the other feature suggested in this module:

  Data::Dumper->$_new_with_defaults()->$_DumpValues([ stuff, to, dump ]);

=head3 Unrecognised Features

I'm still not sure how to handle what happens when somebody passes the name
of a feature which doesn't exist yet, but does in a future version.

Ideally, calling C<$_new_with_defaults()> should give you the same results in
perpetuity ( or at least, from the date this feature gets added )

For now I think the best thing to do is die fatally if a feature that is
requested can't be provided, as that will produce output other than is desired
and violate output consistency as a result.

This will just become a nightmare if somebody ever changes "The Default" for
a I<new> feature wherein, users have to I<< Opt-B<Out> >>, causing an
explosion on older versions where that feature didn't exist.

This should be a hazard to never even consider changing the default behaviour.

=head2 C<$_DumpValues>

This function is a helper that does what people who maintain a long-lived
C<Data::Dumper> instance generally desire: The ability to just set up an
instance, and then call it an arbitrary number of times with arbitrary inputs
and have it act without side effects.

However, the current implementation of Data::Dumper is such that if you have
an instance, you must B<first> store the data in the object, and B<then>
dump it, which introduces fun problems with your data living longer than you
intended it to.

Currently, you also must call C<< ->Reset >> after dumping to reset the
C<Seen> state.

This function is designed to be used atomically. Any pre-existing variable
state (eg: C<Names>, C<Values>, C<Seen> ) should be thouroughly ignored, and
any of those values will be left in a "reset" state after using this function.

It is thus inadvisable to combine use of this function with others.

If you need complex behaviours provided by the more advanced interfaces, its
recommended to use those instead.

=head3 Syntax

  # Dump array of values as a string
  $instance->$_DumpValues( [ values ] );

  # Dump array of values with predefined names
  $instance->$_DumpValues( [ values, ... ], [ names, ... ]);

=head3 Arguments

The first argument (required) must be an C<ArrayRef> of values to dump.

This value will B<ALWAYS> be used instead of any instances of C<Values> passed
earlier. Any values previously passed to C<Values> will be preserved.

The second (optional) argument is an C<ArrayRef> of names to use for values.

If this option is omitted, it will behave as if you'd passed C<[]>.

If this option is present, passed values used instead.
