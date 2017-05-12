package Data::Type::Digger;

=head1 NAME

Data::Type::Digger - digging types from data structures

=head1 SYNOPSIS

    use Data::Type::Digger;

    my $in_data = { ... };

    my $out_data = dig( $in_data, do_scalar => { uc @_ }  );


=head1 DESCRIPTION

B<dig> helps you to deal with deep data structores.

Instead of other modules this allow more clearly separation of
processing for different types of nodes into different sub's.

This can be useful, if the procesing code is different for different types of nodes,
or if nodes have their own methods to apply or something other like this.

If you looking for more simple and type-independent tool, then you may look on
some similar packages. For example: Data::Rmap, Data::Dmap, Data::Traverse.

Instead, if you need to process something like this:
dig( $in_data, do_my_unique_class => { shift->unique_class_method() }, do_some_other_class => ... );
this module will be more useful.
Also this module provide depth limitation, unblessing and cloning with passing just a simple param

=head1 METHODS

=head2 C<dig>

    Perform recursive digging required types from data structure

    my $out_data = dig( $in_data, %params );

    in_data = source structure, required

    Params: # all param keys are optional
        do_all        => coderef, function called for all nodes
        do_hash       => coderef, function called for all hashref nodes
        do_array      => coderef, function called for all arrayref nodes
        do_scalar     => coderef, function called for all scalar nodes
        do_type       => coderef, function called for all nodes with ref = 'type'
        unbless       => 0 || 1,  turn all blessed objects into simple hashrefs
        clone         => 1,       make all actions on cloned structure and save the source data
        max_deep      => -1, int  -1, undef (not limited) || int (limited to INT) depth of work
        max_deep_cut  => 0 || 1,  save or cut the data deeper then max_deep

    coderef
        assumes two params:
            node - value of current node
            key  - name or index of parent_node (if parent node ref is hash or array)

        returns:
            new value of node


=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Data::Type::Digger

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Type-Digger

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Data-Type-Digger

    CPAN Ratings
        http://cpanratings.perl.org/d/Data-Type-Digger

    Search CPAN
        http://search.cpan.org/dist/Data-Type-Digger/


=head1 AUTHOR

    ANTONC <antonc@cpan.org>

=head1 LICENSE

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

    L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

use v5.14.0;
use Modern::Perl;
use Clone;
use Scalar::Util;
use Exporter 'import';

our $VERSION = '0.06';

our @EXPORT_OK = qw/ dig /;

our %_param;
our $_levels_to_stop;

=head1 FUNCTIONS

=head2 dig($data, %param)

    perform digging data and do some actions on values

=cut

sub dig {
    my ( $data, %param ) = @_;

    die 'no data given' unless $data;

    %_param = %param;

    # cloning data, if required
    if ( $param{clone} ) {
        $data = Clone::clone $data;
    }

    # Countdown levels deep
    $_levels_to_stop = $param{max_deep} || -1;

    _dig( $data );
};


# Working with current node and make recursive call for all subnodes
sub _dig {
    my ( $data, $up_key ) = @_;

    # stop, if max deep reached
    unless ( $_levels_to_stop-- ) {
        $_levels_to_stop++;
        return $_param{max_deep_cut} ? undef : $data;
    };

    # Get a type of value, regardless of any blessing
    my $ref = Scalar::Util::reftype( $data ) // '';

    if ( $ref eq 'ARRAY' ) {
        for ( 0 .. @$data-1 ) {
            $data->[$_] = _dig( $data->[$_], $_ );
        };
    }

    if ( $ref eq 'HASH' ) {
        for ( keys %$data ) {
            $data->{$_} = _dig( $data->{$_}, $_ );
        };
    }

    # Trying to apply something useful for this node
    my @do = map { s/\:+/_/g; 'do_'.lc }
        keys %{{ map { $_ => 1 } $ref, ( ref $data || 'scalar' ), 'all' }};

    for ( @do ) {
        next unless $_param{$_};
        $data = $_param{$_}->( $data, $up_key );
    }

    $_levels_to_stop++;

    # If unblessing not required then do nothing
    return $data  unless $_param{unbless};

    # Unbless reference if we can
    return { %$data }  if $ref eq 'HASH';
    return [ @$data ]  if $ref eq 'ARRAY';

    # Don't know how to unbless this object
    return undef       if ref $data;

    # Just a simple scalar
    return $data;
};

1;
