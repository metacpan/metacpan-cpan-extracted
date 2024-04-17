package CXC::Exporter::Util;

# ABSTRACT: Tagged Based Exporting

use v5.22;

use strict;
use warnings;

our $VERSION = '0.07';

use Scalar::Util 'reftype';
use List::Util 1.45 'uniqstr';
use Import::Into;
use experimental 'signatures', 'postderef', 'lexical_subs';

use Exporter 'import';

our %EXPORT_TAGS = (
    default   => [qw( install_EXPORTS  )],
    constants => [qw( install_CONSTANTS )],
    utils     => [qw( install_constant_tag install_constant_func )],
);

our %HOOK;

install_EXPORTS();

my sub _croak {
    require Carp;
    goto \&Carp::croak;
}

my sub _EXPORT_TAGS ( $caller = scalar caller ) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNostrict)
    *${ \"${caller}::EXPORT_TAGS" }{HASH} // \%{ *${ \"${caller}::EXPORT_TAGS" } = {} };
}

my sub _EXPORT_OK ( $caller = scalar caller ) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNostrict)
    *${ \"${caller}::EXPORT_OK" }{ARRAY} // \@{ *${ \"${caller}::EXPORT_OK" } = [] };
}

my sub _EXPORT ( $caller = scalar caller ) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNostrict)
    *${ \"${caller}::EXPORT" }{ARRAY} // \@{ *${ \"${caller}::EXPORT" } = [] };
}

my sub add_constant_to_tag;





























































sub install_EXPORTS {

    my $export_tags = ( reftype( $_[0] )  // q{} ) eq 'HASH' ? shift : undef;
    my $u_opts      = ( reftype( $_[-1] ) // q{} ) eq 'HASH' ? shift : {};

    my %options = (
        overwrite => 0,
        all       => 'auto',
        package   => shift // scalar caller,
        %$u_opts,
    );

    _croak( 'too many arguments to INSTALL_EXPORTS' ) if @_;

    my $package     = delete $options{package};
    my $install_all = delete $options{all};

    # run hooks.
    if ( defined( my $hooks = delete $HOOK{$package}{pre} ) ) {
        $_->() for values $hooks->%*;
    }

    my $EXPORT_TAGS = _EXPORT_TAGS( $package );

    if ( defined $export_tags ) {

        if ( delete $options{overwrite} ) {
            $EXPORT_TAGS->%* = $export_tags->%*;
        }

        else {
            # cheap one layer deep hash merge
            for my $tag ( keys $export_tags->%* ) {
                push( ( $EXPORT_TAGS->{$tag} //= [] )->@*, $export_tags->{$tag}->@* );
            }
        }
    }

    # Exporter::Tiny handles the 'all' tag, as does Sub::Exporter, but
    # I don't know how to detect when the latter is being used.
    $install_all = !$package->isa( 'Exporter::Tiny' )
      if $install_all eq 'auto';

    if ( $install_all ) {
        # Assign the all tag in two steps to avoid the situation
        # where $EXPORT_TAGS->{all} is created with an undefined value
        # before running values on $EXPORT_TAGS->%*;

        my @all = map { $_->@* } values $EXPORT_TAGS->%*;
        $EXPORT_TAGS->{all} //= \@all;
    }

    _EXPORT( $package )->@*    = ( $EXPORT_TAGS->{default} // [] )->@*;
    _EXPORT_OK( $package )->@* = uniqstr map { $_->@* } values $EXPORT_TAGS->%*;
}





























































sub install_CONSTANTS {
    my $package = !defined reftype( $_[-1] ) ? pop : scalar caller;

    for my $spec ( @_ ) {
        my $type = reftype( $spec );

        if ( 'HASH' eq $type ) {
            install_constant_tag( $_, $spec->{$_}, $package ) for keys $spec->%*;
        }

        elsif ( 'ARRAY' eq $type ) {
            my $idx = $spec->@*;
            _croak( 'constant spec passed as array has an odd number of elements' )
              unless 0 == $idx % 2;

            while ( $idx ) {
                my $hash = $spec->[ --$idx ];
                my $id   = $spec->[ --$idx ];
                install_constant_tag( $id, $hash, $package );
            }
        }

        else {
            _croak( 'expect a HashRef or an ArrayRef' );
        }
    }
}



































































































































































































sub install_constant_tag ( $id, $constants, $package = scalar caller ) {

    # caller may specify distinct tag and enumeration function names.
    my ( $tag, $fn_values, $fn_names )
      = 'ARRAY' eq ( reftype( $id ) // q{} )
      ? ( $id->@* )
      : ( lc( $id ), $id );

    $fn_values //= uc( $tag );
    $fn_names  //= $fn_values . '_NAMES';

    my ( @names );
    if ( reftype( $constants ) eq 'HASH' ) {
        @names = keys $constants->%*;
    }
    elsif ( reftype( $constants ) eq 'ARRAY' ) {
        my @copy = $constants->@*;
        while ( my ( $name ) = splice( @copy, 0, 2 ) ) {
            push @names, $name;
        }
        $constants = { $constants->@* };
    }
    else {
        _croak( '$constants argument should be either a hashref or an arrayref' );
    }

    constant->import::into( $package, $constants );

    push( ( _EXPORT_TAGS( $package )->{$tag} //= [] )->@*, @names );

    $HOOK{$package}{pre}{$fn_values} //= sub {
        my $fqdn = join q{::}, $package, $fn_values;
        _croak( "Error: attempt to redefine enumerating function $fqdn" )
          if exists &{$fqdn};
        no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNostrict)
        my @values
          = map { &{"${package}::${_}"} } _EXPORT_TAGS( $package )->{$tag}->@*;
        install_constant_func( $fn_values, \@values, $package );
    };

    $HOOK{$package}{pre}{$fn_names} //= sub {
        my $fqdn = join q{::}, $package, $fn_names;
        _croak( "Error: attempt to redefine enumerating function $fqdn" )
          if exists &{$fqdn};
        add_constant_to_tag( 'constant_name_funcs', $fn_names,
            [ _EXPORT_TAGS( $package )->{$tag}->@* ], $package );

    };

}












































sub install_constant_func ( $tag, $values, $caller = scalar caller ) {
    add_constant_to_tag( 'constant_funcs', $tag, $values, $caller );
}















































sub add_constant_to_tag ( $tag, $name, $values, $caller = scalar caller ) {
    constant->import::into( $caller, $name => $values->@* );
    push( ( _EXPORT_TAGS( $caller )->{$tag} //= [] )->@*, $name );
}

1;

#
# This file is part of CXC-Exporter-Util
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory mistyped

=head1 NAME

CXC::Exporter::Util - Tagged Based Exporting

=head1 VERSION

version 0.07

=head1 SYNOPSIS

In the exporting code:

  package My::Exporter;
  use CXC::Exporter::Util ':all';

  use parent 'Exporter' # or Exporter::Tiny

  # install sets of constants, with automatically generated
  # enumerating functions
  install_CONSTANTS( {
        DETECTORS => {
            ACIS => 'ACIS',
            HRC  => 'HRC',
        },

        AGGREGATES => {
            ALL  => 'all',
            NONE => 'none',
            ANY  => 'any',
        },
    } );

  # install some functions
  install_EXPORTS(
            { fruit => [ 'tomato', 'apple' ],
              nut   => [ 'almond', 'walnut' ],
            } );

In importing code:

  use My::Exporter   # import ...
   ':fruit',         # the 'fruit' functions
   ':detector',      # the 'detector' functions
   'DETECTORS'       # the function enumerating the DETECTORS constants  values
   'DETECTORS_NAMES' # the function enumerating the DETECTORS constants' names
   ;

  # print the DETECTORS constants' values;
  say $_ for DETECTORS;

  # print the DETECTORS constants' names;
  say $_ for DETECTORS_NAMES;

=head1 DESCRIPTION

C<CXC::Exporter::Util> provides I<tag-centric> utilities for modules
which export symbols.  It doesn't provide exporting services; its sole
purpose is to manipulate the data structures used by exporting modules
which follow the API provided by Perl's core L<Exporter> module
(e.g. L<Exporter::Tiny>).

In particular, it treats C<%EXPORT_TAGS> as the definitive source for
information about exportable symbols and uses it to generate
C<@EXPORT_OK> and C<@EXPORT>.  Consolidation of symbol information in
one place avoids errors of omission.

=head2 Exporting Symbols

At it simplest, the exporting module calls L</install_EXPORTS> with a
hash specifying tags and their symbols sets, e.g.,

  package My::Exporter;
  use CXC::Exporter::Util;

  use parent 'Exporter'; # or your favorite compatible exporter

  install_EXPORTS(
            { fruit => [ 'tomato', 'apple' ],
              nut   => [ 'almond', 'walnut' ],
            } );

  sub tomato {...}
  sub apple  {...}
  sub almond {...}
  sub walnut {...}

An importing module could use this via

  use My::ExportingModule ':fruit'; # import tomato, apple
  use My::ExportingModule ':nut';   # import almond, walnut
  use My::ExportingModule ':all';   # import tomato, apple,
                                    #        almond, walnut,

For more complicated setups, C<%EXPORT_TAGS> may be specified first:

  package My::ExportingModule;
  use CXC::Exporter::Util;

  use parent 'Exporter';
  our %EXPORT_TAGS = ( tag => [ 'Symbol1', 'Symbol2' ] );
  install_EXPORTS;

C<install_EXPORTS> may be called multiple times

=head2 Exporting Constants

C<CXC::Exporter::Util> provides additional support for creating,
organizing and installing constants via L</install_CONSTANTS>.
Constants are created via Perl's L<constant> pragma.

L</install_CONSTANTS> is passed sets of constants grouped by tags,
e.g.:

  install_CONSTANTS( {
        DETECTORS => {
            ACIS => 'ACIS',
            HRC  => 'HRC',
        },

        AGGREGATES => {
            ALL  => 'all',
            NONE => 'none',
            ANY  => 'any',
        },
   });

   # A call to install_EXPORTS (with or without arguments) must follow
   # install_CONSTANTS;
   install_EXPORTS;

This results in the definition of

=over

=item *

the constant functions, i.e.,

  ACIS HRC ALL NONE ANY

returning their specified values,

=item *

functions enumerating the constants' values, i.e.

  DETECTORS -> ( 'ACIS', 'HRC' )
  AGGGREGATES -> ( 'all', 'none', 'any' )

=item *

functions enumerating the constants' names, i.e.

  DETECTORS_NAMES -> ( 'ACIS', 'HRC' )
  AGGGREGATES_NAMES -> ( 'ALL', 'NONE', 'ANY' )

=back

The enumerating functions are useful for generating enumerated types
via e.g. L<Type::Tiny>:

  Enum[ DETECTORS ]

or iterating:

  say $_ for DETECTORS;

C<install_CONSTANTS> may be called multiple times. If the constants
are used later in the module for other purposes, constant definition
should be done in a L<BEGIN> block:

  BEGIN {
      install_CONSTANTS( {
          CCD => {nCCDColumns  => 1024, minCCDColumn => 0,},
      } );
  }

  install_CONSTANTS( {
      CCD => {
          maxCCDColumn => minCCDColumn + nCCDColumns - 1,
      } }
  );

  install_EXPORTS;

For more complex situations, the lower level L</install_constant_tag>
and L</install_constant_func> routines may be useful.

=head1 SUBROUTINES

=head2 install_EXPORTS

  install_EXPORTS( [\%export_tags], [$package], [\%options]  );

Populate C<$package>'s C<@EXPORT> and C<@EXPORT_OK> arrays based upon
C<%EXPORT_TAGS> and C<%export_tags>.

If not specified,  C<$package> defaults to the caller's package.

Available Options:

=over

=item overwrite => [Boolean]

If the C<overwrite> option is true, the contents of C<%export_tags>
will overwrite C<%EXPORT_TAGS> in C<$package>, otherwise
C<%export_tags> is merged into C<%EXPORT_TAGS>.

Note that overwriting will remove the tags and symbols installed into
C<%EXPORT_TAGS> by previous calls to L</install_CONSTANTS>.

This defaults to false.

=item package => [Package Name]

This provides another means of indicating which package to install into.
Setting this overrides the optional C<$package> argument.

=item all => [Boolean | 'auto' ]

This determines whether L</install_EXPORTS> creates an C<all> tag
based on the contents of C<%EXPORT_TAGS> in C<$package>.  Some exporters, such as
L<Exporter::Tiny> and L<Sub::Exporter> automatically handle the C<all>
tag, but Perl's default L<Exporter> does not.

If set to C<auto> (the default), it will install the C<all> tag if
C<$package> is I<not> a subclass of L<Exporter::Tiny>.

(At present I don't know how to determine if L<Sub::Exporter> is used).

=back

This routine does the following in C<$package> based upon
C<%EXPORT_TAGS> in C<$package>:

=over

=item *

Install the symbols specified via the C<$EXPORT_TAGS{default}> tag into C<@EXPORT>.

=item *

Install all of the symbols in C<%EXPORT_TAGS> into C<@EXPORT_OK>.

=back

=head2 install_CONSTANTS

  install_CONSTANTS( @specs, ?$package  );

Create sets of constants and make them available for export in
C<$package>.

If not specified,  C<$package> defaults to the caller's package.

The passed C<@specs> arguments are either hashrefs or arrayrefs and
contain one or more set specifications.  A set specification
consists of a unique identifier and a list of name-value pairs,
specified either as a hash or an array.  For example,

  @spec = ( { $id1 => \%set1, $id2 => \@set2 },
            [ $id3 => \%set3, $id4 => \@set4 ],
          );

The identifier is used to create an export tag for the set, as
well as to name enumerating functions returning constant's names and values.
The individual C<$id>, C<$set> pairs are passed to L</install_constant_tag>;
see that function for more information on how the identifiers are used.

A call to L</install_EXPORTS> I<must> be made after the last call to
C<install_CONSTANTS> or

=over

=item *

The constants won't be added to the exports.

=item *

The enumerating functions won't be created.

=back

L</install_CONSTANTS> may be called more than once to add symbols to a tag,
but don't split those calls across a call to L</install_EXPORTS>.

In other words,

  # DON'T DO THIS, IT'LL THROW
  install_CONSTANTS( { Foo => { bar => 1 } } );
  install_EXPORTS;
  install_CONSTANTS( { Foo => { baz => 1 } } );
  install_EXPORTS;

  # DO THIS
  install_CONSTANTS( { Foo => { bar => 1 } } );
  install_CONSTANTS( { Foo => { baz => 1 } } );
  install_EXPORTS;

Each call to L</install_EXPORTS> installs the enumerating functions for
sets modified since the last call to it, and each enumerating function
can only be added once.

=head2 install_constant_tag

Create and install constant functions for a set of constants.  Called either
as

=over

=item install_constant_tag( \@names, $constants, [$package] )

where B<@names> contains

  $tag,
  $fn_values, # optional name of function returning constants' values
  $fn_names,  # optional name of function returning constants' names

and, if not specified,

  $fn_values //= uc($tag);
  $fn_names //= $fn_values . '_NAMES';

=item install_constant_tag( $fn_values, $constants, [$package] )

where

  $tag = lc($fn_values);
  $fn_names = $fn_values . '_NAMES';

=back

where

=over

=item B<$tag>

is the name of the tag representing the set of constants

=item C<$fn_values>

is the name of the function which will return a list of the constants' values

=item C<$fn_names>

is the name of the function which will return a list of the constants' names

=item C<$constants>

specifies the constants' names and values, as
either a hashref or an arrayref containing I<name> - I<value> pairs.

=item C<$package>

is the name of the package (the eventual exporter) into
which the constants will be installed. It defaults to the package of
the caller.

=back

L</install_constant_tag> will

=over

=item 1

use Perl's L<constant> pragma to create a function named I<name>
returning I<value> for each I<name>-I<value> pair in C<$constants>.

The functions are installed in C<$package> and their names appended to
the symbols in C<%EXPORT_TAGS> with export tag C<$tag>.  If C<$constants>
is an arrayref they are appended in the ordered specified in the array,
otherwise they are appended in random order.

=item 2

Add a hook so that the next time L</install_EXPORTS> is called, Perl's
L<constant> pragma will be used to create

=over

=item *

an enumerating function named C<$fn_values> which returns a list of
the I<values> of the constants associated with C<$tag>, in the order
they were added to C<$EXPORT_TAGS{$tag}>.

=item *

an enumerating function named C<$fn_names> which returns a list of
the I<names> of the constants associated with C<$tag>, in the order
they were added to C<$EXPORT_TAGS{$tag}>.

=back

These enumerating functions are added to the symbols in
C<%EXPORT_TAGS> tagged with C<contant_funcs>.

Just as you shouldn't interleave calls to L</install_CONSTANTS> for a
single tag with calls to L</install_EXPORTS>, don't interleave calls
to L</install_constant_tag> with calls to L</install_EXPORTS>.

=back

For example, after

  $id = 'AGGREGATES';
  $constants = { ALL => 'all', NONE => 'none', ANY => 'any' };
  install_constant_tag( $id, $constants );
  install_EXPORTS:

=over

=item 1

The constant functions, C<ALL>, C<NONE>, C<ANY> will be created and
installed in the calling package.

A new element will be added to C<%EXPORT_TAGS> with an export tag of C<aggregates>.

  $EXPORT_TAGS{aggregates} = [ 'ALL', 'NONE', 'ANY ];

=item 2

A function named C<AGGREGATES> will be created and installed in the
calling package. C<AGGREGATES> will return the values

  'all', 'none', 'any'

(in a random order, as C<$constants> is a hashref).

C<AGGREGATES> will be added to the symbols tagged by C<constant_funcs> in C<%EXPORT_TAGS>

=item 3

A function named C<AGGREGATES_NAMES> will be created and installed in the
calling package. C<AGGREGATES_NAMES> will return the values

  'ALL', 'NONE', 'ANY'

(in a random order, as C<$constants> is a hashref).

C<AGGREGATES_NAMES> will be added to the symbols tagged by C<constant_name_funcs> in C<%EXPORT_TAGS>

=back

After this, a package importing from C<$package> can

=over

=item * import the constant functions C<ALL>, C<NONE>, C<ANY> via the C<aggregate> tag:

   use Package ':aggregate';

=item * import the enumerating function C<AGGREGATES> directly, via

  use Package 'AGGREGATES';

=item * import C<AGGREGATES> via the C<constant_funcs> tag:

  use Package ':constant_funcs';

=back

As mentioned above, if the first argument to L</install_constant_tag> is an
arrayref, C<$tag>, C<$fn_values>, and C<$fn_names> may be specified directly. For example,

  $id = [ 'Critters', 'Animals', 'Animal_names' ];
  $constants = { HORSE => 'horse', GOAT   => 'goat' };
  install_constant_tag( $id, $constants );

will create the export tag C<Critters> for the C<GOAT> and C<HORSE>
constant functions, an enumerating function called C<Animals> returning

  ( 'horse', 'goat' )

and  a function called C<Animal_names> returning

  ( 'HORSE', 'GOAT')

C<install_constant_tag> uses L</install_constant_func> to create and install
the constant functions which return the constant values.

Because of when enumerating functions are created, all enumerating functions
associated with a set will return all of the set's values, regardless of when
the function was specified.  For example,

  install_constant_tag( 'TAG', { HIGH => 'high' }  );
  install_constant_tag( [ 'TAG', 'ATAG' ], { LOW => 'low' } );

will create functions C<TAG> and C<ATAG> which both return C<high>, C<low>.

=head2 install_constant_func( $name, \@values, $caller )

This routine does the following in C<$package>, which defaults to the
caller's package.

=over

=item 1

Create a constant subroutine named C<$name> which returns C<@values>;

=item 2

Adds C<$name> to the C<constant_funcs> tag in C<%EXPORT_TAGS>.

=back

For example, after calling

  install_constant_func( 'AGGREGATES', [ 'all', 'none', 'any' ]  );

=over

=item 1

The function C<AGGREGATES> will return C<all>, C<none>, C<any>.

=item 2

A package importing from C<$package> can import the C<AGGREGATE>
constant function via the C<constant_funcs> tag:

  use Package ':constant_funcs';

or directly

  use Package 'AGGREGATES';

=back

=begin idocs

=sub add_constant_to_tag( $tag, $name, \@values, $caller )

This routine does the following in C<$package>, which defaults to the
caller's package.

=over

=item 1

Create a constant subroutine named C<$name> which returns C<@values>;

=item 2

Adds C<$name> to the C<$tag> tag in C<%EXPORT_TAGS>.

=back

For example, after calling

  add_constant_to_tag( 'constant_name_funcs', 'AGGREGATES', [ 'all', 'none', 'any' ]  );
=over

=item 1

The function C<AGGREGATES> will return C<all>, C<none>, C<any>.

=item 2

A package importing from C<$package> can import the C<AGGREGATE>
constant function via the C<constant_name_funcs> tag:

  use Package ':constant__name_funcs';

or directly

  use Package 'AGGREGATES';
=back

=end idocs

=head1 BUGS

No attempt is made to complain if enumerating functions' names clash
with constant function names.

=head1 EXAMPLES

=over

=item Alternate constant generation modules.

To use an alternate constant generation function bypass
L</install_CONSTANTS> and load things manually.

For example,  using L<enum>:

  package My::Exporter;

  use CXC::Exporter::Util ':all';

  our @DaysOfWeek;
  BEGIN{ @DaysOfWeek = qw( Sun Mon Tue Wed Thu Fri Sat ) }
  use enum @DaysOfWeek;
  use constant DaysOfWeek => map { &$_ } @DaysOfWeek;
  install_EXPORTS( { days_of_week => \@DaysOfWeek,
                     constant_funcs => [ 'DaysOfWeek' ],
                    });

and then

  use My::Exporter -days_of_week;

  say Sun | Mon;

=item Using a constant in the exporting module

When a constant is used in an exporting module (to create another constant, for example),
it's tempting to do something like this:

  # DON'T DO THIS
  %CCD = ( minCCDColumn => 0, nCCDColumns = 1024 );
  $CCD{maxCCDColumn} = $CCD{minCCDColumn} + $CCD{nCCDColumns} - 1;
  install_CONSTANTS( { CCD => \%CCD } );
  install_EXPORTS;

Not only is this noisy code, if the hash keys are mistyped, there's an
error, which is exactly what constants are supposed to avoid.

Instead, create an initial set of constants in a BEGIN block, which
will make them available for the rest of the code:

  BEGIN {
      install_CONSTANTS( {
          CCD => {nCCDColumns  => 1024, minCCDColumn => 0,},
      } );
  }

  install_CONSTANTS( {
      CCD => {
          maxCCDColumn => minCCDColumn + nCCDColumns - 1,
      } }
  );

  install_EXPORTS;

A bit more verbose, but it uses the generated constant functions and
avoids errors.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-exporter-util@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Exporter-Util>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-exporter-util

and may be cloned from

  https://gitlab.com/djerius/cxc-exporter-util.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Exporter|Exporter>

=item *

L<Exporter::Tiny|Exporter::Tiny>

=item *

L<Exporter::Almighty|Exporter::Almighty>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
