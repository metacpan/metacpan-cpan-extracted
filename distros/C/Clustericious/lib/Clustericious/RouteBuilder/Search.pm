package Clustericious::RouteBuilder::Search;

use strict;
use warnings;
use Clustericious::Log;

# ABSTRACT: build routes for searching for objects
our $VERSION = '1.27'; # VERSION


use Sub::Exporter -setup => {
    exports => [
        "search" => \&_build_search,
    ],
    collectors => ['defaults'],
};

sub _build_search {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_class") or die "$finder must be able to find_class";
    sub {
        my $self = shift;

        my $items = $self->stash("items") or LOGDIE "no items in request";

        my $manager = $finder->find_class($items) or LOGDIE "no class for $items";
        unless ($manager->can("object_class")) {
            # Allow tables names in addition to plurals
            $manager .= "::Manager";
        }
        $self->parse_autodata;

        my $p = $self->stash->{autodata};

        if (my $mode = $p->{mode}) {
            DEBUG "Called search mode $mode";
            # A search "mode" indicates that we use a pre-canned
            # query stored in the manager class.  This query is 
            # run by calling a method named "search_$mode" on the
            # manager class.  This method should return a count
            # and a resultset (array ref of hashrefs).
            my $method = "search_$mode";
            my $got = $manager->$method($p);
            ERROR "search_$mode did not return count/resultset"
                 unless ref($got) eq 'HASH' && exists($got->{count}) && exists($got->{resultset});
            $self->stash(autodata => $got);
            return;
        }


        #TRACE "searching for $items : ".Dumper($p);

        # maybe restrict, by first calling $manager->normalize_get_objects_args(%$p)

        my $all = delete $p->{query_all};
        # "If the first argument is a hash it is treated as 'query'" -- RDBOM docs
        my @args = $all || exists( $p->{query} ) ? %$p
                 : ( keys %$p > 0 )              ? $p
                 : ();
        TRACE "args are @args";
        push @args, object_class => $manager->object_class;
        my %a = @args;
        if (!$a{limit} && !$a{page}) {
            DEBUG "Adding limit 100 to query";
            push @args, ( limit => 100 );
        } elsif ( ($a{limit} || $a{per_page} || 0) > 1000) {
            WARN "Very large limit : ".($a{limit} || $a{per_page});
        }

        my $count = $manager->get_objects_count( @args );
        my @key = $manager->object_class->meta->primary_key_column_names;
        $self->stash(autodata => {
            count     => $count,
            key       => (@key > 1 ? \@key : $key[0]),
            resultset => [ map $_->as_hash, @{ $manager->get_objects( @args ) } ]
           });
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::RouteBuilder::Search - build routes for searching for objects

=head1 VERSION

version 1.27

=head1 SYNOPSIS

    use My::Object::Class;
    use Clustericious::RouteBuilder;
    use Clustericious::RouteBuilder::Search
            "search",
            "plurals",
            defaults => { manager_finder => "Manager::Finder::Class" },
        ;

    ...

    post => "/:plural/search" => [ plural => [ plurals() ] ] => \&do_create;

=head1 DESCRIPTION

This automates the creation of routes for searching for objects.

Manager::Finder::Class must provide the following methods :

=over 4

=item lookup_class

given the plural of a table, look up the name of the class

=back

The route that is created turns a JSON structure which is input as POST
data into parameters for Rose::DB::Object::Manager::get_objects.

Additionally a "mode" parameters is supported, which just calls a
search_$mode method within the manager class, and returns that
result set to the client.

=head1 SUPER CLASS

none

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
