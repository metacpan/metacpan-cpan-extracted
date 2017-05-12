package DSL::HTML::STL;
use strict;
use warnings;

use DSL::HTML;
use Scalar::Util qw/reftype/;
use v5.10;

use Carp qw/croak/;
our @CARP_NOT = qw/DSL::HTML DSL::HTML::Template DSL::HTML::Rendering/;

template dl {
    my ($class, $keys, $data) = process_args(@_);
    
    tag dl(class => $class) {
        for my $key ( @$keys ) {
            tag dt { $key }
            tag dd { $data->{$key} }
        }
    }
}

template ol {
    my ($class, $items) = process_args(@_);

    tag ol(class => $class) {
        for my $item (@$items) {
            tag li { $item }
        }
    }
}

template ul {
    my ($class, $items) = process_args(@_);

    tag ul(class => $class) {
        for my $item (@$items) {
            tag li { $item }
        }
    }
}

sub process_args {
    my ($class, $data, $sort, $keys);
    
    for my $arg ( @_ ) {
        my $type = reftype $arg;

        if (!$type) {
            $class //= $arg;
        }
        elsif( $type eq 'HASH' ) {
            $data //= $arg;
        }
        elsif( $type eq 'ARRAY' ) {
            $keys //= $arg;
        }
        elsif( $type eq 'CODE' ) {
            $sort //= $arg;
        }
        else {
            croak "Not sure what to do with '$arg'";
        }
    }

    $data //= {};
    $keys //= [ keys %$data ];
    $keys = [ sort $sort @$keys ] if $sort;

    return ($class || "", $keys, $data);
}

1;

__END__

=head1 NAME

DSL::HTML::STL - Standard Template Library for L<DSL::HTML>.

=head1 DESCRIPTION

Templates. See L<DSL::HTML>.

=head1 WORK IN PROGRESS

This library is still under development, currently it is minimal at best.

=head1 SYNOPSYS

    use DSL::HTML;
    use DSL::HTML::STL qw/ul .../;

    # Create a short HTML doc
    my $html = build_template ul => qw(foo bar baz);

    # Define a template that uses the ul template
    template mydoc {
        my @items = @_;
        ...
        tag h1 { "the list:" }
        include ul => @items;
        ...
    }

    # Create an HTML doc using the 'mydoc' template
    my $html = build_template mydoc => qw(foo bar baz);

=head1 TEMPLATES

=head2 LISTS

All of these create lists of the specified type. All can take 4 types of
arguments, the first of any given type is the only one used, the rest are
ignored.

If a scalar is provided, it is treated as the class attribute.

If an arrayref is provided it is treated as the items to be listed (or to be used
in the <dt> of the <dl>).

If a hashref is provided it is used to find the values for the <dd> in the
<dl>. If no arrayref is provided then the keys of the hashref will be used as
the list items. In 'ul' and 'dl' the values of the hash are ignored. 

If a coderef is provided it is used via C<sort()> to sort the list items by
name.

=over 4

=item ul

    include ul => [qw/a b c d/];

=item ol

    include ol => [qw/a b c d/];

=item dl

All arguments are optional, but without a hashref you have no <dd> values. If
you have no hashref and no arrayref then you get an empty list. 

    include dl => (
        # Our <dd> values
        { foo => 'a foo', bar => 'a bar', ... },

        # Our <dt> values (other keys in the hashref are ignored)
        [ 'foo', 'bar' ],

        # our 'class' attribute
        'my_class other_class ...'

        # How to sort the values
        sub($$) { $_[0] cmp $_[1] },
    );

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

DSL-HTML is free software; Standard perl license (GPL and Artistic).

DSL-HTML is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
