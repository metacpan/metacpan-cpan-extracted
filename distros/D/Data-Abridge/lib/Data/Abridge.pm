package Data::Abridge;
BEGIN {
  $Data::Abridge::VERSION = '0.03.01';
}

use strict;
use warnings;

use Exporter qw( import );
use Scalar::Util qw( blessed reftype refaddr );
use overload ();

use Carp;

our @EXPORT_OK = qw(
    abridge_item      abridge_items
    abridge_recursive abridge_items_recursive
);


use constant BLESSED_REGEXP => blessed qr/foo/;
use constant REFTYPE_REGEXP => reftype qr/foo/;

# Munge a thing for nice serialization

# Object     -> {  'Package::Name' => <unblessed copy> };
# Code Ref   -> '\&subname'
#            -> '\&__ANON__'
# Scalar Ref -> { SCALAR => $scalar }
# Glob Ref   -> '\*main:glob'

my %SLOB_DISPATCH = (
    SCALAR  => \&_process_scalar,
    REF     => \&_process_ref,
    HASH    => \&_passthrough,
    ARRAY   => \&_passthrough,
    GLOB    => \&_process_glob,
    CODE    => \&_process_code,
    BLESSED => \&_process_object,
    REGEXP  => \&_process_regexp,
);

my %COPY_DISPATCH = (
    SCALAR  => \&_process_scalar,
    REF     => \&_process_ref,
    HASH    => \&_process_hash,
    ARRAY   => \&_process_array,
    GLOB    => \&_process_glob,
    CODE    => \&_process_code,
    REGEXP  => \&_process_regexp,
);

my %RECURSE_DISPATCH = (
    REF     => \&_recurse_ref,
    HASH    => \&_recurse_hash,
    ARRAY   => \&_recurse_array,
    BLESSED => \&_recurse_object,
);

our $HONOR_STRINGIFY = 1;

our %SEEN;  # Global hash for tracking self-referential structures.
            # Should be localized by entry to recursive abridge functions.
our @PATH;  # Also localized for tracking the current path to any given entry
            # in the abridged structure.  

sub _passthrough    { return $_ }
sub _process_ref    { return { SCALAR => $$_ } }
sub _process_glob   { return { GLOB => '\\'.*$_ } }
sub _process_hash   { return {%$_} }
sub _process_array  { return [@$_] }
sub _process_scalar { return { SCALAR => $$_} }
sub _process_regexp { return { Regexp => "$_" } }

sub _process_object {
    my $obj = $_;

    my $class = blessed $obj;
    return unless defined $class;

    if( $HONOR_STRINGIFY && overload::Method($obj, '""') ) {
        # overloads String ?
        return "$obj";
    }
    else {
        # Shallow Copy
        my $type = _is_Regexp( $obj )
                 ? 'REGEXP'
                 : reftype $obj;

        my $value = exists $COPY_DISPATCH{$type}
                  ? $COPY_DISPATCH{$type}->()
                  : _unsupported_type( $obj );

        return { $class => $value };
    }
}

sub _process_code {
    require B;
    my $cv = B::svref_2object($_);
    $cv->isa('B::CV') or return;

    # bail out if GV is undefined
    $cv->GV->isa('B::SPECIAL') and return;

    my $subname =  join "::", $cv->GV->STASH->NAME, $cv->GV->NAME;
    return {CODE => "\\&$subname"};
}

sub _unsupported_type {
    my $item = shift;
    my $type = reftype $item;

    return "Unsupported type: '$type' for $item";
}

sub _is_Regexp {
    require B;
    my $sv = B::svref_2object($_);
    $sv->isa('B::PVMG') or return;
    my $m = $sv->MAGIC or return;

    return $m->TYPE eq 'r';
}

sub abridge_items {
    return [ map abridge_item($_), @_ ];
}

sub abridge_item {
    my $item = shift;

    my $type = reftype $item;

    return $item unless $type;

    my $blessed = blessed $item;
    if( $blessed ) {
        $type = $blessed eq BLESSED_REGEXP ? 'REGEXP' : 'BLESSED';
    }

    my $slobd = $SLOB_DISPATCH{$type};
   $slobd = \&_unsupported_type unless defined $slobd;;

    return  $slobd->($_) for $item;
}


sub _recurse_ref {
    my $processed_ref = shift;

    my $val = $processed_ref->{SCALAR};

    push @PATH, 'SCALAR';
    $processed_ref->{SCALAR} = _abridge_recursive($val);
    pop @PATH;

    return $processed_ref;
}

sub _recurse_array {
    my $processed_array = shift;

    my @result = map { 
        push @PATH, $_;
        my @a = _abridge_recursive($processed_array->[$_]);
        pop @PATH;
        @a;
    } 0 .. $#$processed_array;

    return \@result;
}

sub _recurse_hash {
    my $processed_hash = shift;

    my %new_hash;
    for my $k ( keys %$processed_hash ) {
        push @PATH, $k;
        $new_hash{$k} = _abridge_recursive( $processed_hash->{$k} );
        pop @PATH;
    }

    return \%new_hash;
}

sub _recurse_object {
    my $processed_object = shift;

    return unless ref $processed_object;
    return unless reftype $processed_object eq 'HASH';

    my ( $key, $value ) = each %$processed_object;
    my $type = reftype $value;
    $type = '' unless defined $type;


    push @PATH, $key;

    $value = $RECURSE_DISPATCH{$type}->( $value )
        if exists $RECURSE_DISPATCH{$type};

    pop @PATH;

    my %new_obj = ( $key => $value );

    return \%new_obj;
}


sub abridge_recursive {
    local %SEEN;
    local @PATH;
    &_abridge_recursive;
}

sub _abridge_recursive {
    my $item = shift;

    my $type = reftype $item;
    $type = 'BLESSED' if blessed $item;
    $type = '' unless defined $type;

    my $repl = abridge_item($item);

    # repl may have become a plain old scalar.
    # Can't recurse that.
    my $repl_type = reftype $repl;
    return $repl unless defined $repl_type;

    if ( exists $RECURSE_DISPATCH{$type} ) {
        my $id = refaddr $item;
        $id = '' unless defined $id;

            return { SEEN => [ @{$SEEN{$id}} ] }
            if exists $SEEN{$id};

        $SEEN{$id} =  [@PATH];
        $repl = $RECURSE_DISPATCH{$type}->($repl);

    }

    return $repl;
}

sub abridge_items_recursive {
    local %SEEN;
    &_abridge_items_recursive;
}

sub _abridge_items_recursive { 
    return _abridge_recursive([@_]); 
}

1;

# ABSTRACT: Simplify data structures for naive serialization.

__END__

=head1 NAME

Data::Abridge

=head1 VERSION

version 0.03.01

Simplify data structures for naive serialization.


=head1 SYNOPSIS

    use Data::Abridge qw( abridge_recursive );
    use JSON;

    my $foo = bless { handle => \*STDIN }, 'SomeObj';

    print encode_json abridge_recursive( $foo );

    local $DATA::Abridge::HONOR_STRINGIFY = undef;

    print encode_json abridge_recursive( $foo );

=head1 DESCRIPTION

Webster's 1913 edition defines abridge as follows:

  A*bridge" (#), v. t.
  1. To make shorter; to shorten in duration; to lessen; to diminish; to
  curtail; as, to abridge labor; to abridge power or rights. The bridegroom

This module exists to simplify the process of serializing data to formats, such as
JSON, which do not support the full richness of perl datatypes.

An abridged data structure will feature only scalars, hashes and arrays.

This module does NOT guarantee round-trip capability.  Abridgement is a lossy process and some information may be lost.


=head1 EXPORTED SYMBOLS

Nothing is exported by default.

The three subroutines in the public API are available for export by request.


=head1 SUBROUTINES

=head2 abridge_item

Abridges the top level of an item.  Deep structures are B<not> modified below
the top structure.  For complete conversion, use C<abridge_recursive>.

Scalars that aren't references, array references and hash references are
unchanged:

    Input         Output
    ------------------------------------------
    'A string'    'A string'
    57            57
    {a=>1, b=>2}  {a=>1, b=>2}
    [1,2,3]       [1,2,3]

Code references are converted to a hash ref that indicates the fully
qualified name of the subroutine pointed to.  Anonymous subroutines are
marked as C<__ANON__>.

    Input         Output
    ------------------------------------------
    \&foo         {CODE => '\&main::foo'}
    sub {0}       {CODE => '\&main::__ANON__'}

Typeglob references are converted to a hash ref that contains the name
of the glob.

    Input         Output
    ------------------------------------------
    \*main::foo   {GLOB => '\*main::foo'}

Scalar references are converted to a hash ref that contains the scalar.

    Input         Output
    ------------------------------------------
    \$foo         {SCALAR => $foo}

Objects are converted to a hash ref that contains the name of the
class and an unblessed copy of the object's underlying data type.

    Input                 Output
    ------------------------------------------
    bless {a=>'b'}, 'Foo' { Foo => {a=>'b'} }
    bless [1,2,3], 'Foo'  { Foo => [1,2,3]  }

Objects that override stringification will be treated as strings,
by default.

    Given:
      package Foo;
      use overload '""' => sub { join ' ', keys %$_[0] };

    Input                 Output              Condition
    ----------------------------------------------------
    bless {a=>'b'}, 'Foo' 'a'                 Default
    bless {a=>'b'}, 'Foo' { Foo => {a=>'b'} } $HONOR_STRINGIFY = undef
    bless {a=>'b'}, 'Foo' 'a'                 $HONOR_STRINGIFY = 1

=head2 abridge_items

Operates as abridge item, but applied to a list.

Takes a list of arguments, applies C<abridge_item> to each, and then returns
an array ref containing the results.

=head2 abridge_recursive

Operates on a single data structure as per C<abridge_item>, but in a top-down recursive mode.

The data structure returned will consist of only abridged data.

Recursive processing adds one more transformation type to the set described above:

    Input              Output
    ------------------------------------------
    Any repeated item  {SEEN => [ 0, 'Path' ]}

This means that any item that appears more than once in a data structure will be replaced with a pointer to the other location.  A hash ref with a single key "SEEN" and a value consisting of an array reference to indicate the path of keys and indexes that must be traversed to find the fully dumped instance.

A reference to the top level data structure will yeild an empty C<[]> path.

A reference to an element in an object or other special item will include the Data::Abridge generated keys in the path C<[ 2, 'SCALAR', 'SomeClass', 'that_attrib', 5 ]>.

=head2 abridge_items_recursive

Operates as C<abridge_recursive>, but applied to a list.

Takes a list of arguments, applies C<abridge_recursive> to each, and then returns
an array ref of the results.

The top level item, in this case, is taken to be the array of items.

=head1 SUPPORT

Please file any bugs through the standard CPAN ticketing system.  At the time of writing this is L<http://rt.cpan.org>.

=head1 LICENSE

This module is licensed under the same terms as Perl.

To be specific, you may choose to use it under any of the licensing terms available for Perl 5.6.0 or newer.

=head1 AUTHOR

Mark Swayne

Copyright 2012

=head1 ACKNOWLEDGEMENTS

Thank you to Marchex L<http://marchex.com> for supporting the development and release of this module.

Special thanks to Tye McQueen for the original idea and his readiness to kibbitz during the development process.

=cut
