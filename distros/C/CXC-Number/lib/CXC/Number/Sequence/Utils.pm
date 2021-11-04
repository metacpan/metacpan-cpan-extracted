package CXC::Number::Sequence::Utils;

# ABSTRACT: Utilities for CXC::Number::Sequence generators
use strict;
use warnings;

use feature ':5.24';
use experimental 'signatures';

our $VERSION = '0.06';

# ABSTRACT: sequence utilities

use feature 'state';

use Exporter::Shiny qw( buildargs_factory load_class );
use Type::Params qw( compile_named compile_named_oo );
use Types::Standard -types;
use Types::Common::Numeric qw( PositiveInt );

use CXC::Number::Sequence::Failure -all;

use Hash::Wrap 0.11 { -as => 'wrap_attrs_ro', -immutable => 1, -exists => 'has' };
use Hash::Wrap { -as => 'wrap_attrs_rw' };

use namespace::clean;
























































































sub buildargs_factory {

    state $check = compile_named_oo(
        map => HashRef [
            Dict [
                flag => PositiveInt,
                type => InstanceOf[ 'Type::Tiny' ],
            ]
        ],
        build     => Map [ PositiveInt, CodeRef ],
        xvalidate => Optional [ ArrayRef[ Tuple [ PositiveInt, CodeRef ] ] ],
        adjust    => Optional [CodeRef],
    );

    my $arg = $check->( @_ );

    return sub {

        state $check = compile_named(
            map { $_ => $arg->map->{$_}{type} }
              keys $arg->map->%*
        );

        my ( $class, undef ) = ( shift, shift );

        my %attrs = @_ == 1 ? $_[0]->%* : @_;

        # don't touch attributes we don't know about
        my %build_attrs;
        $build_attrs{$_} = delete $attrs{$_}
          foreach grep { exists $arg->map->{$_} } keys %attrs;

        if ( $arg->adjust ) {
            local $_ = \%build_attrs;
            $arg->adjust->();
        }

        my $attrs = $check->( %build_attrs );

        my $attrs_set = 0;
        $attrs_set |= $arg->map->{$_}{flag} for keys %build_attrs;

        my $build = $arg->build->{$attrs_set}
          // parameter_IllegalCombination->throw( "illegal combination of parameters: "
              . join( ', ', sort keys %build_attrs ) );

        if ( $arg->has_xvalidate ) {
            local $_ = wrap_attrs_rw( $attrs );
            foreach my $pair ( $arg->xvalidate->@* ) {
                my ( $key, $validate ) = $pair->@*;
                next unless $key == ( $attrs_set & $key );
                $validate->();
            }
        }

        local $_ = wrap_attrs_ro( $attrs );
        return { %attrs, $build->()->%* };
    };
}









# based on Mojo::Plugin::load_plugin, Mojo::Loader::load_class, Mojo::Util::camelize
sub load_class( $name ) {

  $name =  join '::', map { join('', map {ucfirst lc } split /_/) } split( /-/, $name )
    unless $name =~ /^[A-Z]/;

  for my $class ( "CXC::Number::Sequence::${name}", $name ) {
      eval "require $class; 1" && return $class; ## no critic (BuiltinFunctions::ProhibitStringyEval)

      loadclass_CompileError->throw( "$class had a compile error: $@" )
        unless $@ =~ m|Can't locate \Q@{[ $class =~ s{::}{/}gr . '.pm' ]}|;
  }

  loadclass_NoClass->throw( "unable to find Sequence class matching $name" );
}

#
# This file is part of CXC-Number
#
# This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory CamelCased bitmask
xvalidate

=head1 NAME

CXC::Number::Sequence::Utils - Utilities for CXC::Number::Sequence generators

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 SUBROUTINES

=head2 buildargs_factory

  $sub = buildargs_factory( %args );

Generate a subroutine wrapper for L<Moo/BUILDARGS> for use with L<Moo/around>, e.g.

  around BUILDARGS => buildargs_factory(
      map       => \%ArgMap,
      build     => \%ArgBuild,
      xvalidate => \@ArgsCrossValidate
  );

It takes the following arguments:

=over

=item map => \%hash

This hash maps a parameter name to a L<Type::Tiny> type and a bitmask
flag which uniquely identifies the parameter. The hash keys are the
parameter names, and the values are hashes with elements keys C<type>
(the C<Type::Tiny> type) and C<flag> (an integer bitmask flag).  For
example,

  use enum qw( BITMASK: MIN MAX SOFT_MIN SOFT_MAX NBINS BINW RATIO GROW );

  my %ArgMap = (
     binw     => { type => BinWidth,               flag => BINW },
     max      => { type => Optional [BigNum],      flag => MAX },
     min      => { type => Optional [BigNum],      flag => MIN },
     nbins    => { type => Optional [PositiveInt], flag => NBINS },
     ratio    => { type => Ratio,                  flag => RATIO },
     soft_max => { type => Optional [BigNum],      flag => SOFT_MAX },
     soft_min => { type => Optional [BigNum],      flag => SOFT_MIN },
  );

=item build => \%hash

This hash maps I<combinations> of parameters with subroutines which
return parameters to be returned by L<Moo/BUILDARGS>. The keys are
masks which specify the parameters, and the values are subroutines
which operate on C<$_> (an object with methods named for the
parameters).  For example,

    ( MIN | NBINS | BINW | RATIO ),
    sub {
        my $nbins = $_->nbins;
        if ( $_->binw > 0 ) {
          ...
        }
        ...
        { elements => { } };
    },

=item xvalidate => \@array

This optional argument provides subroutines to cross-validate
parameters. The array elements are themselves arrays with two
elements; the first is a mask which represents the combination of
parameters to test, the second is a subroutine which operates on C<$_>
(an object with methods named for the parameters).  It should
throw if the validation fails.  Validation subroutines are called
in the order presented in the array.

For example, the following entry ensures that the specified minimum
values are less than maximum values:

 [
     MIN | MAX,
     sub {
         parameter_constraint->throw( "min < max\n" ) unless $_->min < $_->max;
     },
 ],

=item adjust => \&sub

This is an optional parameter providing a subroutine which is passed
(via C<$_>) a hash containing the passed build parameters.  It can
adjust them in place as required.

=back

=head2 load_class

  $class_name = load_seq_class( $class_or_submodule );

C<$class_or_submodule> is CamelCased.

=for Pod::Coverage BUILDARGS

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number> or by email
to L<bug-cxc-number@rt.cpan.org|mailto:bug-cxc-number@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number|CXC::Number>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
