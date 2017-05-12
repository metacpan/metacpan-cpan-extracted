package Const::Exporter;

use v5.10.0;

use strict;
use warnings;

use version; our $VERSION = version->declare('v0.2.4');

use Carp;
use Const::Fast;
use Exporter ();
use Package::Stash;
use Scalar::Util qw/ blessed reftype /;

sub import {
    my $pkg = shift;

    my ($caller) = caller;
    my $stash = Package::Stash->new($caller);

    # Create @EXPORT, @EXPORT_OK, %EXPORT_TAGS and import if they
    # don't yet exist.

    my $export = $stash->get_or_add_symbol('@EXPORT');

    my $export_ok = $stash->get_or_add_symbol('@EXPORT_OK');

    my $export_tags = $stash->get_or_add_symbol('%EXPORT_TAGS');

    $stash->add_symbol( '&import', \&Exporter::import )
        unless ( $stash->has_symbol('&import') );

    while ( my $tag = shift ) {

        croak "'${tag}' is reserved" if $tag eq 'all';

        my $defs = shift;

        croak "An array reference required for tag '${tag}'"
            unless ( ref $defs ) eq 'ARRAY';

        while ( my $item = shift @{$defs} ) {

            for ( ref $item ) {

                # Array reference means a list of enumerated symbols

                if (/^ARRAY$/) {

                    my @enums = @{$item};
                    my $start = shift @{$defs};

                    my @values = ( ref $start ) ? @{$start} : ($start);

                    my $value = 0;

                    while ( my $symbol = shift @enums ) {

                        croak "${symbol} already exists"
                            if ( $stash->has_symbol($symbol) );

                        $value = @values ? ( shift @values ) : ++$value;

                        _add_symbol( $stash, $symbol, $value );
                        _export_symbol( $stash, $symbol, $tag );

                    }

                    next;
                }

                # A scalar is a name of a symbol

                if (/^$/) {

                    my $symbol = $item;
                    my $sigil  = _get_sigil($symbol);
                    my $norm
                        = ( $sigil eq '&' ) ? ( $sigil . $symbol ) : $symbol;

                    # If the symbol is already defined, that we add it
                    # to the exports for that tag and assume no value
                    # is given for it.

                    if ( $stash->has_symbol($norm) ) {

                        my $ref = $stash->get_symbol($norm);

                        # In case symbol is defined as `our`
                        # beforehand, ensure it is readonly.

                        Const::Fast::_make_readonly( $ref => 1 );

                        _export_symbol( $stash, $symbol, $tag );

                        next;

                    }

                    my $value = shift @{$defs};

                    _add_symbol( $stash, $symbol, $value );
                    _export_symbol( $stash, $symbol, $tag );

                    next;
                }

                croak "$_ is not supported";

            }

        }

    }

    # Now ensure @EXPORT, @EXPORT_OK and %EXPORT_TAGS contain unique
    # symbols. This may not matter to Exporter, but we want to ensure
    # the values are 'clean'. It also simplifies testing.

    push @{$export}, @{ $export_tags->{default} } if $export_tags->{default};
    _uniq($export);

    _uniq($export_ok);

    $export_tags->{all} //= [];
    push @{ $export_tags->{all} }, @{$export_ok};

    _uniq( $export_tags->{$_} ) for keys %{$export_tags};
}

# Add a symbol to the stash

sub _add_symbol {
    my ( $stash, $symbol, $value ) = @_;

    my $sigil = _get_sigil($symbol);
    if ( $sigil ne '&' ) {

        if ( blessed $value) {

            $stash->add_symbol( $symbol, \$value );
            Const::Fast::_make_readonly( $stash->get_symbol($symbol) => 1 );

        } else {
            $stash->add_symbol( $symbol, $value );
            Const::Fast::_make_readonly( $stash->get_symbol($symbol) => 1 );
        }

    } else {

        $stash->add_symbol( '&' . $symbol, sub {$value} );

    }
}

# Add a symbol to @EXPORT_OK and %EXPORT_TAGS

sub _export_symbol {
    my ( $stash, $symbol, $tag ) = @_;

    my $export_ok   = $stash->get_symbol('@EXPORT_OK');
    my $export_tags = $stash->get_symbol('%EXPORT_TAGS');

    $export_tags->{$tag} //= [];

    push @{ $export_tags->{$tag} }, $symbol;
    push @{$export_ok}, $symbol;
}

# Function to get the sigil from a symbol. If no sigil, it assumes
# that it is a function reference.

sub _get_sigil {
    my ($symbol) = @_;
    $symbol =~ /^(\W)/;
    return $1 // '&';
}

# Function to convert a sigil into the corresponding reftype.

{
    const my %_reftype => (
        '$' => 'SCALAR',
        '&' => 'CODE',
        '@' => 'ARRAY',
        '%' => 'HASH',
    );

    sub _get_reftype {
        my ($sigil) = @_;
        return $_reftype{$sigil};
    }
}

# Function to take a list reference and prune duplicate elements from
# it.

sub _uniq {
    my ($listref) = @_;
    my %seen;
    while ( my $item = shift @{$listref} ) {
        $seen{$item} = 1;
    }
    push @{$listref}, keys %seen;
}

1;

=head1 NAME

Const::Exporter - Declare constants for export.

=begin readme

=head1 REQUIREMENTS

This module requires Perl v5.10 or newer, and the following non-core
modules:

=over

=item L<Const::Fast>

=item L<Hash::Objectify> (for testing)

=item L<Package::Stash>

=item L<Test::Most> (for testing)

=back

=end readme

=head1 SYNOPSIS

Define a constants module:

  package MyApp::Constants;

  use Const::Fast;

  our $zoo => 1234;

  use Const::Exporter

     tag_a => [                  # use MyApp::Constants /:tag_a/;
        'foo'  => 1,             # exports "foo"
        '$bar' => 2,             # exports "$bar"
        '@baz' => [qw/ a b c /], # exports "@baz"
        '%bo'  => { a => 1 },    # exports "%bo"
     ],

     tag_b => [                  # use MyApp::Constants /:tag_b/;
        'foo',                   # exports "foo" (same as from ":tag_a")
        '$zoo',                  # exports "$zoo" (as defined above)
     ];

  # `use Const::Exporter` can be specified multiple times

  use Const::Exporter

     tag_b => [                 # we can add symbols to ":tab_b"
        'moo' => $bar,          # exports "moo" (same value as "$bar")
     ],

     enums => [

       [qw/ goo gab gub /] => 0, # exports enumerated symbols, from 0..2

     ],

     default => [qw/ fo $bar /]; # exported by default

and use that module:

  package MyApp;

  use MyApp::Constants qw/ $zoo :tag_a /;

  ...

=head1 DESCRIPTION

This module allows you to declare constants that can be exported to
other modules.

=for readme stop

To declare constants, simply group then into export tags:

  package MyApp::Constants;

  use Const::Exporter

    tag_a => [
       'foo' => 1,
       'bar' => 2,
    ],

    tag_b => [
       'baz' => 3,
       'bar',
    ],

    default => [
       'foo',
    ];

Constants in the C<default> tag are exported by default (that is, they
are added to the C<@EXPORTS> array).

When a constant is already defined in a previous tag, then no value is
specified for it. (For example, C<bar> in C<tab_b> above.)  If you do
give a value, L<Const::Exporter> will assume it's another symbol.

Your module can include multiple calls to C<use Const::Exporter>, so
that you can reference constants in other expressions, e.g.

  use Const::Exporter

    tag => [
        '$zero' => 0,
    ];

  use Const::Exporter

    tag => [
        '$one' => 1 + $zero,
    ];

or even something more complex:

  use Const::Exporter

     http_ports => [
        'HTTP'     => 80,
        'HTTP_ALT' => 8080,
        'HTTPS'    => 443,
     ];

  use Const::Exporter

     http_ports => [
        '@HTTP_PORTS' => [ HTTP, HTTP_ALT, HTTPS ],
     ];

Constants can include traditional L<constant> symbols, as well as
scalars, arrays or hashes.

Constants can include values defined elsewhere in the code, e.g.

  our $foo;

  BEGIN {
     $foo = calculate_value_for_constant();
  }

  use Const::Exporter

    tag => [ '$foo' ];

Note that this will make the symbol read-only. You don't need to
explicitly declare it as such.

Enumerated constants are also supported:

  use Const::Exporter

    tag => [

      [qw/ foo bar baz /] => 1,

    ];

will define the symbols C<foo> (1), C<bar> (2) and C<baz> (3).

You can also specify a list of numbers, if you want to skip values:

  use Const::Exporter

    tag => [

      [qw/ foo bar baz /] => [1, 4],

    ];

will define the symbols C<foo> (1), C<bar> (4) and C<baz> (5).

You can even specify string values:

  use Const::Exporter

    tag => [

      [qw/ foo bar baz /] => [qw/ feh meh neh /],

    ];

however, this is equivalent to

  use Const::Exporter

    tag => [
      'foo' => 'feh',
      'bar' => 'meh',
      'baz' => 'neh',
    ];

Objects are also supported,

   use Const::Exporter

    tag => [
      '$foo' => Something->new( 123 ),
    ];

=head2 Mixing POD with Tags

The following code is a syntax error, at least with some versions of
Perl:

  use Const::Exporter

  =head2 a

  =cut

    a => [ foo => 1 ],

  =head2 b

  =cut

    b => [ bar => 2 ];

If you want to mix POD with your declarations, use multiple use lines,
e.g.

  =head2 a

  =cut

  use Const::Exporter
    a => [ foo => 1 ];

  =head2 b

  =cut

  use Const::Exporter
    b => [ bar => 2 ];

=head2 Export Tags

By default, all symbols are exportable (in C<@EXPORT_OK>.)

The C<:default> tag is the same as not specifying any exports.

The C<:all> tag exports all symbols.

=head2 Using as part of a module with exported functions

L<Const::Exporter> is not intended for use with modules that also
export functions.

There are workarounds that you can use, such as getting
L<Const::Exporter> to export your functions, or munging C<@EXPORT>
etc. separately, but these are not supported and changes in the
future my break our code.

=for readme continue

=head1 SEE ALSO

See L<Exporter> for a discussion of export tags.

=head2 Similar Modules

=over

=item L<Exporter::Constants>

This module only allows you to declare function symbol constants, akin
to the L<constant> module, without tags.

=item L<Constant::Exporter>

This module only allows you to declare function symbol constants, akin
to the L<constant> module, although you can specify tags.

=item L<Constant::Export::Lazy>

This module only allows you to declare function symbol constants, akin
to the L<constant> module by defining functions that are only called
as needed.  The interface is rather complex.

=back

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2015 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut

