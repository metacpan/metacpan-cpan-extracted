# ABSTRACT: a role for creating App::Rssfilter objects from a configuration hash


use strict;
use warnings;

package App::Rssfilter::FromHash;
{
  $App::Rssfilter::FromHash::VERSION = '0.07';
}

use Moo::Role; # test harness uses Test::Routine, which wants a Moose-y role, son no Role::Tiny
use Method::Signatures;
use Scalar::Util qw< blessed >;

requires 'add_feed';
requires 'add_rule';
requires 'add_group';


method from_hash( $config_ref, @config ) {
    if ( 'HASH' ne ref $config_ref ) {
        unshift @config, $config_ref;
        $config_ref = {};
    }
    $self->_from_hash( %{ $config_ref }, @config );
}

method _from_hash( %config ) {
    my $group = $self->new( name => $config{name} );

    map { $group->add_feed( @{ $_ } ) } $self->split_for_ctor( @{ $config{feeds} } );
    map { $group->add_rule( @{ $_ } ) } $self->split_for_ctor( @{ $config{rules} } );

    for my $subgroup ( @{ $config{groups} } ) {
        $group->add_group( $self->_from_hash( %{ $subgroup } ) );
    }

    return $group;
}


method split_for_ctor( @list ) {
    my @results;
    while( @list ) {
        use experimental 'smartmatch';
        use feature 'switch';
        given( shift @list ) {
            when( 'HASH'  eq ref $_ ) { push @results, [ %{ $_ } ] }
            when( 'ARRAY' eq ref $_ ) { push @results, [ @{ $_ } ] }
            # squash 'Argument "foo" isn't numeric in smart match'
            when( '' ne ref $_ )      { push @results, [ $_ ] }
            default                   { push @results, [ $_ => shift @list ] };
        };
    }
    return @results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::FromHash - a role for creating App::Rssfilter objects from a configuration hash

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    {
        package Cool::Name;
        use Role::Tiny::With;
        with 'App::Rssfilter::FromHash';

        sub new { ... }
        sub add_group { ... }
        sub add_feed { ... }
        sub add_rule { ... }
    };


    my $cool_name = Cool::Name->from_hash(
        name => 'some group',
        rules => [
            # add_rule will be called with ...
            keyvalue_pair => 'some value',
            # then ...
            {
                this_hashref => 'of options',
                with_multiple => 'keys and values',
            },
            # and then ...
            $already_constructed_object,
        ],
        feeds => [
            # same as rules above
            # mix elements as you please
            keyword_pair_for_first_feed => 'and value',
            keyword_pair_for_second_feed => 'with different value',
            {
                feed_option1 => 'more key-value pairs',
                feed_option2 => 'which will be passed as arguments',
                feed_option3 => 'for the third call to add_feed',
            },
        ],
        groups => [
            {
                name => 'a subgroup',
                # subgroups can have their own feeds, rules, and subgroups
                feeds => [ ... ],
                rules => [ ... ],
                groups => [ ... ],
            },
            {
                name => 'another subgroup',
                feeds => [ ... ],
                rules => [ ... ],
                groups => [ ... ],
            },
        ],
    );

=head1 DESCRIPTION

This role will extend its receiving class with a L</from_hash> method. It requires that the receiver has C<add_group>, C<add_feed>, and C<add_rule> methods, and accepts a C<name> attribute to its constructor.

=head1 METHODS

=head2 from_hash

    my $receiver_instance = Receiver::Class->from_hash( %config );

Create a new instance of the receiving class (using C<$config{name}> as its name), then walk the hash to create subgroups and add feeds or rules to it (or its subgroups).

The hash may have four elements:

=over 4

=item *

C<name>   - name of this group

=item *

C<groups> - arrayref of hashrefs for subgroups, same schema as the original hash

=item *

C<feeds>  - arrayref of feeds to fetch

=item *

C<rules>  - arrayref of rules to apply

=back

Bare scalars in C<feeds> will be collected into key-value pairs; everything else will be mapped onto the receiver's C<add_feed>. Likewise for C<rules>.

=head2 split_for_ctor

    B<INTERNAL>

    my @arguments_for_ctor_in_arrayrefs = $receiving_instance->split_for_ctor( @args );

Returns the elements of C<@args> partitioned into arrayrefs, whose contents are suitable arguments for a L<Moose>-y constructor. Collects bare scalars in C<@args> with their following element into key-value pairs; arrayrefs & hashrefs are dereferenced; everthing else is taken as-is.

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
