package Const::Exporter;

# ABSTRACT: Declare constants for export.

use v5.10.0;

use strict;
use warnings;

our $VERSION = 'v0.4.2';

use Carp;
use Const::Fast;
use Exporter ();
use List::AllUtils '0.10' => qw/ pairs zip /;
use Package::Stash;
use Ref::Util qw/ is_blessed_ref is_arrayref is_coderef is_hashref is_ref /;

# RECOMMEND PREREQ: Package::Stash::XS
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Storable

sub import {
    my $pkg = shift;

    strict->import;
    warnings->import;

    my $caller = caller;
    my $stash  = Package::Stash->new($caller);

    # Create @EXPORT, @EXPORT_OK, %EXPORT_TAGS and import if they
    # don't yet exist.

    my $export = $stash->get_or_add_symbol('@EXPORT');

    my $export_ok = $stash->get_or_add_symbol('@EXPORT_OK');

    my $export_tags = $stash->get_or_add_symbol('%EXPORT_TAGS');

    $stash->add_symbol( '&import', \&Exporter::import )
      unless ( $stash->has_symbol('&import') );

    _add_symbol( $stash, 'const', \&Const::Fast::const );
    _export_symbol( $stash, 'const' );

    foreach my $set ( pairs @_ ) {

        my $tag = $set->key;
        croak "'${tag}' is reserved" if $tag eq 'all';

        my $defs = $set->value;

        croak "An array reference required for tag '${tag}'"
          unless is_arrayref($defs);

        while ( my $item = shift @{$defs} ) {

            for ($item) {

                # Array reference means a list of enumerated symbols

                if ( is_arrayref($_) ) {

                    my @enums = @{$item};
                    my $start = shift @{$defs};

                    my @values = is_arrayref($start) ? @{$start} : ($start);

                    my $last = $values[0] // 0;
                    my $fn = sub { $_[0] + 1 };

                    if ( is_coderef $values[1] ) {
                        $fn = $values[1];
                        $values[1] = undef;
                    }

                    foreach my $pair ( pairs zip @enums, @values ) {
                        my $value = $pair->value // $fn->($last);
                        $last = $value;
                        my $symbol = $pair->key // next;

                        _add_symbol( $stash, $symbol, $value );
                        _export_symbol( $stash, $symbol, $tag );

                    }

                    next;
                }

                # A scalar is a name of a symbol

                if ( !is_ref($_) ) {

                    my $symbol = $item;
                    my $sigil  = _get_sigil($symbol);
                    my $norm =
                      ( $sigil eq '&' ) ? ( $sigil . $symbol ) : $symbol;

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

sub _check_sigil_against_value {
    my ($sigil, $value) = @_;

    return 1 if $sigil eq '@' && is_arrayref($value);
    return 1 if $sigil eq '%' && is_hashref($value);
    return 1 if $sigil eq '&' && is_coderef($value);
    return 1 if $sigil eq '$';

    return 0;
}

sub _add_symbol {
    my ( $stash, $symbol, $value ) = @_;

    my $sigil = _get_sigil($symbol);
    if ( $sigil ne '&' ) {

        if ( is_blessed_ref $value) {

            $stash->add_symbol( $symbol, \$value );
            Const::Fast::_make_readonly( $stash->get_symbol($symbol) => 1 );

        }
        else {

            croak "Invalid type for $symbol"
                unless _check_sigil_against_value($sigil, $value);

            $stash->add_symbol( $symbol, $value );
            Const::Fast::_make_readonly( $stash->get_symbol($symbol) => 1 );
        }

    }
    else {

        $stash->add_symbol( '&' . $symbol,
            is_coderef($value) ? $value : sub { $value } );

    }
}

# Add a symbol to @EXPORT_OK and %EXPORT_TAGS

sub _export_symbol {
    my ( $stash, $symbol, $tag ) = @_;

    my $export_ok   = $stash->get_symbol('@EXPORT_OK');
    my $export_tags = $stash->get_symbol('%EXPORT_TAGS');

    $tag //= 'all';

    $export_tags->{$tag} //= [];

    push @{ $export_tags->{$tag} }, $symbol;
    push @{$export_ok}, $symbol;
}

# Function to get the sigil from a symbol. If no sigil, it assumes
# that it is a function reference.

sub _get_sigil {
    my ($symbol) = @_;
    my ($sigil) = $symbol =~ /^(\W)/;
    return $sigil // '&';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Const::Exporter - Declare constants for export.

=head1 VERSION

version v0.4.2

=head1 SYNOPSIS

Define a constants module:

  package MyApp::Constants;

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

     default => [qw/ foo $bar /]; # exported by default

and use that module:

  package MyApp;

  use MyApp::Constants qw/ $zoo :tag_a /;

  ...

=head2 Dynamically Creating Constants

You may also import a predefined hash of constants for exporting dynamically:

 use Const::Exporter;

 my %myconstants = (
        'foo'  => 1,
        '$bar' => 2,
        '@baz' => [qw/ a b c /],
        '%bo'  => { a => 1 },
 );

 # ... do stuff

 Const::Exporter->import(
      constants => [%myconstants],        # define constants for exporting
      default   => [ keys %myconstants ], # export everything in %myconstants by default
 );

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

=head1 KNOWN ISSUES

=head2 Support for older Perl versions

This module requires Perl v5.10 or newer.

Pull requests to support older versions of Perl are welcome. See
L</SOURCE>.

=head2 Exporting Functions

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

=item L<Const::Fast::Exporter>

This module will export all constants declared in the package's
namespace.

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Const-Exporter>
and may be cloned from L<git://github.com/robrwo/Const-Exporter.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Const-Exporter/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTOR

=for stopwords B. Estrade

B. Estrade <estrabd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
