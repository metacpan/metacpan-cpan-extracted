package Clustericious::RouteBuilder::CRUD;

use strict;
use warnings;
use Clustericious::Log;
use Data::Dumper;

# ABSTRACT: build crud routes easily
our $VERSION = '1.27'; # VERSION 


use Sub::Exporter -setup => {
    exports => [
        "create" => \&_build_create,
        "read"   => \&_build_read,
        "update" => \&_build_update,
        "delete" => \&_build_delete,
        "list"   => \&_build_list,
    ],
    collectors => ['defaults'],
};

sub _build_create {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_class") or die "$finder must be able to find_class";
    return sub {
        my $self  = shift;
        $self->app->log->info("called do_create");
        my $table = $self->stash->{table};
        TRACE "create $table";
        $self->parse_autodata;
        my $object_class = $finder->find_class($table);
        TRACE "data : ".Dumper($self->stash("autodata"));
        my $object = $object_class->new(%{$self->stash->{autodata}});
        if ($self->param("skip_existing") && $object->load(speculative => 1)) {
            DEBUG "Found existing $table, not saving";
            $self->stash(autodata => { text => "skipped" });
            return;
        }
        $object->save or LOGDIE( $object->errors );
        $object->load or LOGDIE "Could not reload object : ".$object->errors;
        $self->stash(autodata => $object->as_hash);
    };
}

sub _build_read {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};
        TRACE "read $table (@keys)";
        my $obj   = $finder->find_object($table,@keys)
            or return $self->reply->not_found( join '/',$table,@keys );
        $self->app->log->debug("Viewing $table @keys");

        $self->stash(autodata => $obj->as_hash);

    };
}

sub _build_delete {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};
        TRACE "delete $table (@keys)";
        my $obj   = $finder->find_object($table,@keys)
            or return $self->reply->not_found( join '/',$table,@keys );
        $self->app->log->debug("Deleting $table @keys");

        $obj->delete or LOGDIE($obj->errors);
        $self->stash->{text} = "ok";
    }
}

sub _build_update {
    my ($class, $name, $arg, $defaults) = @_;

    my $finder = $arg->{finder} || $defaults->{defaults}{finder}
                 || die "no finder defined";

    $finder->can("find_object") or die "$finder must be able to find_object";

    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};

        my $obj = $finder->find_object($table, @keys)
            or return $self->reply->not_found( join '/',$table,@keys );

        TRACE "Updating $table @keys";
        $self->parse_autodata;

        my $pkeys = $obj->meta->primary_key_column_names;
        my $ukeys = $obj->meta->unique_keys_column_names;
        my $columns = $obj->meta->column_names;
        my $nested = $obj->nested_tables;

        while (my ($key, $value) = each %{$self->stash->{autodata}})
        {
            next if grep { $key eq $_ } @$pkeys, @$ukeys; # Skip key fields

            LOGDIE("Can't update $key in $table (only @$columns, @$nested)")
                unless grep { $key eq $_ } @$columns, @$nested;

            TRACE "Setting $key to $value for $table @keys";
            $obj->$key($value) or LOGDIE($obj->errors);
        }

        $obj->save or LOGDIE($obj->errors);

        $self->stash->{autodata} = $obj->as_hash;
    };
}

sub _build_list {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash('table');
        my $params = $self->stash('params');

        # Use http range header for limit and offset.
        my %range;
        if (my $range = $self->req->headers->range) {
            my ($items) = $range =~ /^items=(.*)$/;
            my ($first,$last) = $items =~ /^(\d+)-(\d+)$/;
            if (defined($first) && defined($last))  {
                %range = ( offset => $first - 1, limit => ($last-$first+1) );
            } else {
                WARN "Unrecognized range header : $range";
                %range = (limit => 10);
            }
        } else {
            %range = (limit => 10);
        }

        $self->app->log->debug("Listing $table");
        my $object_class = $finder->find_class($table)
            or return $self->reply->not_found( $table );
        my $pkey = $object_class->meta->primary_key;
        my $manager = $object_class . '::Manager';

        my $objectlist = $manager->get_objects(
                             object_class => $object_class,
                             select => [ $pkey->columns ],
                             sort_by => [ $pkey->columns ],
                             %range);

        # Return total count in "content-range".
        my $count = $manager->get_objects_count( object_class => $object_class );
        $self->res->headers->content_range(
            sprintf( "items %d-%d/%d",
                ( 1 + ($range{offset} || 0)),
                ( ($range{offset} || 0) + @$objectlist ),
                $count )
        );

        my @l;

        foreach my $obj (@$objectlist) {
            push(@l, join('/', map { $obj->$_ } $pkey->columns ));
        }

        $self->stash(autodata => \@l);
        $self->res->code(206); # "Partial content"
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::RouteBuilder::CRUD - build crud routes easily

=head1 VERSION

version 1.27

=head1 SYNOPSIS

    use My::Object::Class;
    use Clustericious::RouteBuilder;
    use Clustericious::RouteBuilder::CRUD
            "create" => { -as => "do_create" },
            "read"   => { -as => "do_read"   },
            "delete" => { -as => "do_delete" },
            "update" => { -as => "do_update" },
            "list"   => { -as => "do_list"   },
            defaults => { finder => "My::Finder::Class" },
        ;

    ...

    post => "/:table" => \&do_create;

=head1 DESCRIPTION

This package provides some handy subroutines for building CRUD
routes in your clustericious application.

The class referenced by "finder" must have methods named
find_class and find_object.

The objects returned by find_object must have a method named as_hash.

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
