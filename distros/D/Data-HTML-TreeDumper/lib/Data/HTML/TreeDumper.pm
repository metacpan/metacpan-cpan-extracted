package Data::HTML::TreeDumper;
use 5.010;
use strict;
use warnings;
use utf8;
use Encode;
use Carp       qw(croak);
use YAML::Syck qw(Load LoadFile Dump DumpFile);
use Ref::Util  qw(is_ref is_scalarref is_arrayref is_hashref);
use Const::Fast;
use HTML::Entities;
use HTML::AutoTag;

use version 0.77; our $VERSION = version->declare("v0.0.4");

$YAML::Syck::ImplicitUnicode = 1;
$YAML::Syck::ImplicitTyping  = 1;
$YAML::Syck::Headless        = 1;

const my %default => (
    ClassKey           => 'trdKey',
    ClassValue         => 'trdValue',
    ClassOrderedList   => 'trdOL',
    ClassUnorderedList => 'trdUL',
    StartOrderedList   => 0,
    MaxDepth           => 32,
);

my $autoTag = HTML::AutoTag->new( encode => 0, sorted => 1 );

#region Class methods

sub new {
    my $class = shift;
    my $args  = {
        %default,
        MaxDepth => 8,
        ( is_hashref( $_[0] ) ? %{ $_[0] } : @_ ),
    };
    my $self = {};
    bless $self, $class;
    $self->ClassKey( $args->{ClassKey} );
    $self->ClassValue( $args->{ClassValue} );
    $self->ClassOrderedList( $args->{ClassOrderedList} );
    $self->ClassUnorderedList( $args->{ClassUnorderedList} );
    $self->StartOrderedList( $args->{StartOrderedList} );
    $self->MaxDepth( $args->{MaxDepth} );
    return $self;
}

#endregion

#region Instance properties

sub ClassKey {
    my $self = shift;
    if (@_) {
        $self->{ClassKey} = shift;
    }
    return $self->{ClassKey};
}

sub ClassValue {
    my $self = shift;
    if (@_) {
        $self->{ClassValue} = shift;
    }
    return $self->{ClassValue};
}

sub ClassOrderedList {
    my $self = shift;
    if (@_) {
        $self->{ClassOrderedList} = shift;
    }
    return $self->{ClassOrderedList};
}

sub ClassUnorderedList {
    my $self = shift;
    if (@_) {
        $self->{ClassUnorderedList} = shift;
    }
    return $self->{ClassUnorderedList};
}

sub StartOrderedList {
    my $self = shift;
    if (@_) {
        $self->{StartOrderedList} = shift;
    }
    return $self->{StartOrderedList};
}

sub MaxDepth {
    my $self = shift;
    if (@_) {
        my $value = shift;
        $self->{MaxDepth}
            = $value < 0                  ? 0
            : $value > $default{MaxDepth} ? $default{MaxDepth}
            :                               $value;
    }
    return $self->{MaxDepth};
}

#endregion

#region Instance methods

sub dump {
    my $self  = shift;
    my $x     = shift // return $self->_dumpRaw('[undef]');
    my $name  = $self->_normalizeName( $x, shift );
    my $depth = shift || 0;
    my $result
        = !is_ref($x)      ? $self->_dumpRaw( $x, $name )
        : is_scalarref($x) ? $self->dump( ${$x}, $name, $depth + 1 )
        : is_arrayref($x)  ? $self->_dumpArray( $x, $name, $depth + 1 )
        : is_hashref($x)   ? $self->_dumpHash( $x, $name, $depth + 1 )
        :                    $self->_dumpRaw( $x, $name );
    return $result;
}

sub _normalizeName {
    my $self = shift;
    my $x    = shift;
    my $name = shift;
    return $name || ref($x) || 'unnamed';
}

sub _dumpRaw {
    my $self  = shift;
    my $x     = shift // '';
    my $name  = $self->_normalizeName( $x, shift );
    my $depth = shift || 0;
    return $autoTag->tag(
        tag   => 'span',
        attr  => { class => $self->ClassValue(), },
        cdata => encode_entities($x),
    );
}

sub _dumpArray {
    my $self  = shift;
    my $x     = shift // '';
    my $name  = $self->_normalizeName( $x, shift );
    my $depth = shift || 0;
    if ( $depth > $self->MaxDepth() ) {
        return $autoTag->tag(
            tag   => 'span',
            attr  => { class => $self->ClassKey(), },
            cdata => encode_entities($name),
            )
            . ': '
            . $autoTag->tag(
            tag   => 'span',
            attr  => { class => $self->ClassValue(), },
            cdata => '[...]',
            );
    }
    my $inner = [ map { { tag => 'li', cdata => $self->dump( $_, undef, $depth ) } } @{$x} ];
    return $autoTag->tag(
        tag   => 'details',
        cdata => [
            {   tag   => 'summary',
                attr  => { class => $self->ClassKey(), },
                cdata => encode_entities($name),
            },
            {   tag   => 'ol',
                attr  => { class => $self->ClassOrderedList(), start => $self->StartOrderedList() },
                cdata => $inner,
            },
        ],
    );
}

sub _dumpHash {
    my $self  = shift;
    my $x     = shift // '';
    my $name  = $self->_normalizeName( $x, shift );
    my $depth = shift || 0;
    if ( $depth > $self->MaxDepth() ) {
        return $autoTag->tag(
            tag   => 'span',
            attr  => { class => $self->ClassKey(), },
            cdata => encode_entities($name),
            )
            . ': '
            . $autoTag->tag(
            tag   => 'span',
            attr  => { class => $self->ClassValue(), },
            cdata => '{...}',
            );
    }
    my $inner = [
        map {
            is_arrayref( $x->{$_} )
                ? { tag => 'li', cdata => $self->_dumpArray( $x->{$_}, $_, $depth + 1 ) }
                : is_hashref( $x->{$_} )
                ? { tag => 'li', cdata => $self->_dumpHash( $x->{$_}, $_, $depth + 1 ) }
                : {
                tag   => 'li',
                cdata => $autoTag->tag(
                    tag   => 'span',
                    attr  => { class => $self->ClassKey(), },
                    cdata => encode_entities($_)
                    )
                    . ': '
                    . $self->dump( $x->{$_}, $_, $depth + 1 )
                }
        } sort( keys( %{$x} ) )
    ];
    return $autoTag->tag(
        tag   => 'details',
        cdata => [
            {   tag   => 'summary',
                attr  => { class => $self->ClassKey(), },
                cdata => encode_entities($name),
            },
            {   tag   => 'ul',
                attr  => { class => $self->ClassUnorderedList(), },
                cdata => $inner,
            },
        ],
    );
}

#endregion

1;

__END__

=encoding utf-8

=head1 NAME

L<Data::HTML::TreeDumper> - dumps perl data as HTML5 open/close tree

=head1 SYNOPSIS

    use Data::HTML::TreeDumper;
    my $td = Data::HTML::TreeDumper->new(
        ClassKey    => 'trdKey',
        ClassValue  => 'trdValue',
        MaxDepth    => 8,
    );
    my $obj = someFunction();
    print $td->dump($obj);

There are L<some samples|https://raw.githack.com/TakeAsh/p-Data-HTML-TreeDumper/master/examples/output/sample1.html>.

=head1 DESCRIPTION

Data::HTML::TreeDumper dumps perl data as HTML5 open/close tree.

=head1 CLASS METHODS

=head2 new([option => value, ...])

Creates a new Data::HTML::TreeDumper instance.
This method can take a list of options.
You can set each options later as the properties of the instance.

=head3 ClassKey, ClassValue, ClassOrderedList, ClassUnorderedList

CSS class names for each items.
OrderedList is for arrays.
UnorderedList is for hashes.

=head3 StartOrderedList

An integer to start counting from for arrays.
Default is 0.

=head3 MaxDepth

Stops following object tree at this level, and show "..." instead.
Default is 8.
Over 32 is not acceptable to prevent memory leak.

=head1 INSTANCE METHODS

=head2 dump($object)

Dumps perl data as a HTML5 open/close tree.

=head1 SOURCE

Source repository is at L<p-Data-HTML-TreeDumper|https://github.com/TakeAsh/p-Data-HTML-TreeDumper> .

=head1 SEE ALSO

=head2 Similar CPAN modules:

L<Data::HTMLDumper>, L<Data::Dumper::HTML>, L<Data::Format::Pretty::HTML>

=head1 LICENSE

Copyright (C) TakeAsh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

L<TakeAsh|https://github.com/TakeAsh/>

=cut
