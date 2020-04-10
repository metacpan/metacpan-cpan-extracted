package Data::CSel::WrapStruct;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-09'; # DATE
our $DIST = 'Data-CSel-WrapStruct'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       wrap_struct
                       unwrap_tree
               );

# convenience
use Data::CSel ();
unshift @Data::CSel::CLASS_PREFIXES, __PACKAGE__
    unless grep { $_ eq __PACKAGE__ } @Data::CSel::CLASS_PREFIXES;

sub _wrap {
    my ($data, $parent, $key_in_parent) = @_;
    my $ref = ref($data);
    if (!$ref) {
        return Data::CSel::WrapStruct::Scalar->new($data, $parent, $key_in_parent);
    #} elsif (blessed $data) {
    } elsif ($ref eq 'ARRAY') {
        my $node = Data::CSel::WrapStruct::Array->new($data, $parent);
        $node->children([ map { _wrap($data->[$_], $node, $_) } 0..$#{$data}]);
        return $node;
    } elsif ($ref eq 'HASH') {
        my $node = Data::CSel::WrapStruct::Hash->new($data, $parent);
        my @keys = sort keys %$data;
        $node->_keys(\@keys);
        $node->children([ map { _wrap($data->{$_}, $node, $_) } @keys]);
        return $node;
    } elsif ($ref eq 'SCALAR') {
        return Data::CSel::WrapStruct::ScalarRef->new($data, $parent, undef);
    } elsif ($ref eq 'JSON::PP::Boolean') {
        return Data::CSel::WrapStruct::Scalar->new($$data, $parent, undef);
    } else {
        die "Sorry, currently can't handle ref=$ref";
    }
}

sub wrap_struct {
    my $data = shift;
    _wrap($data, undef, undef);
}

sub unwrap_tree {
    my $tree = shift;

    state $cleaner = do {
        require Data::Clean;
        Data::Clean->new(
            '!recurse_obj' => 1,
            'Data::CSel::WrapStruct::Scalar'    => [call_method=>'value'],
            'Data::CSel::WrapStruct::ScalarRef' => [call_method=>'value'],
            'Data::CSel::WrapStruct::Array'     => [call_method=>'value'],
            'Data::CSel::WrapStruct::Hash'      => [call_method=>'value'],
        );
    };

    $cleaner->clean_in_place($tree);
}

package
    Data::CSel::WrapStruct::Base;

sub new {
    my ($class, $data_ref, $parent, $key_in_parent) = @_;
    bless [$data_ref, $parent, $key_in_parent], $class;
}

sub value {
    my $self = shift;
    if (@_) {
        my ($parent, $key_in_parent) = ($self->[1], $self->[2]);
        my $new_value = shift;
        my $orig_value = $self->[0];
        $self->[0] = $new_value;
        if (defined $key_in_parent) {
            my $ref_parent = ref $parent->[0];
            if ($ref_parent eq 'ARRAY') {
                $parent->[0][$key_in_parent] = $new_value;
            } elsif ($ref_parent eq 'HASH') {
                $parent->[0]{$key_in_parent} = $new_value;
            } else {
                warn "Cannot replace value in parent: not array/hash";
            }
        }
        return $new_value;
    }
    $self->[0];
}

sub remove {
    my $self = shift;
    my ($parent, $key_in_parent) = ($self->[1], $self->[2]);
    if (defined $parent && defined $key_in_parent) {
        my $ref_parent = ref $parent->[0];
        if ($ref_parent eq 'ARRAY') {
            splice @{ $parent->[0] }, $key_in_parent, 1;
            # shift larger indexes by 1
            for my $chld (@{ $parent->children }) {
                $chld->[2]-- if $chld->[2] >= $key_in_parent;
            }
        } elsif ($ref_parent eq 'HASH') {
            delete $parent->[0]{$key_in_parent};
        } else {
            warn "Cannot remove node from parent: not array/hash";
        }
    }
    undef;
}

sub parent {
    $_[0][1];
}

package
    Data::CSel::WrapStruct::Scalar;

our @ISA = qw(Data::CSel::WrapStruct::Base);

sub children {
    [];
}

package
    Data::CSel::WrapStruct::ScalarRef;

our @ISA = qw(Data::CSel::WrapStruct::Base);

sub children {
    [];
}

package
    Data::CSel::WrapStruct::Array;

our @ISA = qw(Data::CSel::WrapStruct::Base);

sub children {
    if (@_ > 1) {
        $_[0][2] = $_[1];
    }
    $_[0][2];
}

sub length {
    scalar @{ $_[0][0] };
}

package
    Data::CSel::WrapStruct::Hash;

our @ISA = qw(Data::CSel::WrapStruct::Base);

sub _keys {
    if (@_ > 1) {
        $_[0][2] = $_[1];
    }
    $_[0][2];
}

sub children {
    if (@_ > 1) {
        $_[0][3] = $_[1];
    }
    $_[0][3];
}

sub length {
    scalar @{ $_[0][2] };
}

sub has_key {
    exists $_[0][0]{$_[1]};
}

sub key {
    $_[0][0]{$_[1]};
}

1;
# ABSTRACT: Wrap data structure into a tree of objects suitable for use with Data::CSel

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CSel::WrapStruct - Wrap data structure into a tree of objects suitable for use with Data::CSel

=head1 VERSION

This document describes version 0.007 of Data::CSel::WrapStruct (from Perl distribution Data-CSel-WrapStruct), released on 2020-04-09.

=head1 SYNOPSIS

 use Data::CSel qw(csel);
 use Data::CSel::WrapStruct qw(wrap_struct unwrap_tree);

 my $data = [
     0,
     1,
     [2, ["two","dua"], {url=>"http://example.com/two.jpg"}, ["even","prime"]],
     3,
     [4, ["four","empat"], {}, ["even"]],
 ];

 my $tree = wrap_struct($data);
 my @nodes = csel(":root > * > *:nth-child(4) > *", $tree);
 my @tags = map { $_->value } @nodes; # -> ("even", "prime", "even")

Scalars are wrapped using C<Data::CSel::WrapStruct::Scalar> class, scalarrefs
are wrapped using C<Data::CSel::WrapStruct::ScalarRef> class, arrays are wrapped
using C<Data::CSel::WrapStruct::Array> class, and hashes are wrapped using
C<Data::CSel::WrapStruct::Hash> class. For convenience, when you load
C<Data::CSel::WrapStruct>, it adds C<Data::CSel::WrapStruct> to
C<@Data::CSel::CLASS_PREFIXES> so you don't have to specify C<<
{class_prefixes=>["Data::CSel::WrapStruct"]} >> C<csel()> option everytime.

 my @hashes = map {$_->value} csel("Hash", $tree);
 # -> ({url=>"http://example.com/two.jpg"}, {})

The wrapper objects provide some methods, e.g.:

 my @empty_hashes = map {$_->value} csel("Hash[length=0]", $tree);
 # -> ({})

 my @hashes_that_have_url_key = map {$_->value} csel("Hash[has_key('url')]", $tree);
 # -> ({url=>"http://example.com/two.jpg"})

 my @larger_scalars = [map {$_->value} csel("Scalar[value >= 3]", $tree)]
 # -> (3, 4)

See L</NODE METHODS>, L</SCALAR NODE METHODS>, L</SCALARREF NODE METHODS>,
L</ARRAY NODE METHODS>, L</HASH NODE METHODS> for more details on the provided
methods.

You can replace the value of nodes using L</value>:

 my @posint_scalar_nodes = csel("Scalar[value > 0]", $tree);
 for (@posint_scalar_nodes) { $_->value( $_->value * 10 ) }
 use Data::Dump;
 dd unwrap_tree($data);
 # => [
 #     0,
 #     10,
 #     [20, ["two","dua"], {url=>"http://example.com/two.jpg"}, ["even","prime"]],
 #     30,
 #     [40, ["four","empat"], {}, ["even"]],
 # ];

=head1 DESCRIPTION

This module provides C<wrap_struct()> which creates a tree of objects from a
generic data structure. You can then perform node selection using
L<Data::CSel>'s C<csel()>.

You can retrieve the original value of data items by calling C<value()> method
on the tree nodes.

=for Pod::Coverage ^(.+)$

=head1 NODE METHODS

=head2 parent

=head2 children

=head2 value

Usage:

 my $val = $node->value; # get node value
 $node->value(1);        # set node value

Get or set node value.

Note that when setting node value, the new node value is not automatically
wrapped for you. If you want to set new node value and expect to select it or
part of it again with C<csel()>, you will have to wrap the new value first with
L</wrap_struct>.

=head2 remove

Usage:

 $node->remove;

Remove node from parent.

=head1 SCALAR NODE METHODS

In addition to methods listed in L</NODE METHODS>, Scalar nodes also have the
following methods.

=head1 SCALARREF NODE METHODS

In addition to methods listed in L</NODE METHODS>, ScalarRef nodes also have the
following methods.

=head1 ARRAY NODE METHODS

In addition to methods listed in L</NODE METHODS>, Array nodes also have the
following methods.

=head2 length

Get array length. Can be used to select an array based on its length, e.g.:

 @nodes = csel('Array[length > 0]');

=head1 HASH NODE METHODS

In addition to methods listed in L</NODE METHODS>, Hash nodes also have the
following methods.

=head2 length

Get the number of keys. Can be used to select a hash based on its number of
keys, e.g.:

 @nodes = csel('Hash[length > 0]');

=head2 has_key

Usage:

 my $bool = $node->has_key("foo");

Check whether hash has a certain key. Can be used to select a hash, e.g.:

 @nodes = csel('Hash[has_key("foo")]');

=head2 key

Usage:

 my $key_val = $node->key("foo");

Get a hash key's value. Can be used to select a hash based on the value of one
of its keys, e.g.:

 @nodes = csel('Hash[key("name") = "lisa"]');

=head1 FUNCTIONS

None exported by default, but exportable.

=head2 wrap_struct

Usage:

 my $tree = wrap_struct($data);

Wrap a data structure into a tree of objects.

Currently cannot handle recursive structure.

=head2 unwrap_tree

Usage:

 my $data = unwrap_tree($wrapped_data);

Unwrap a tree produced by L</wrap_tree> back into unwrapped data structure.

=head1 FAQ

=head2 Changing the node value doesn't work!

 my $data = [0, 1, 2];
 my @nodes = csel("Scalar[value > 0]", wrap_struct($data));
 for (@nodes) { $_->[0] = "x" }
 use Data::Dump;
 dd $data;

still prints C<< [0,1,2] >> instead of C<< [0,'x','x'] >>. Why?

To set node value, you have to use the C<value()> node method with an argument:

 ...
 for (@nodes) { $->value("x") }
 ...

will then print the expected C<< [0,'x','x'] >>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel-WrapStruct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel-WrapStruct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel-WrapStruct>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::CSel>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
