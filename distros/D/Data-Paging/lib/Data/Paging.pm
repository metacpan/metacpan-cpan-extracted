package Data::Paging;
use common::sense;
use 5.008008;
use UNIVERSAL::require;

our $VERSION = "0.01";

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/collection/],
);
use Carp qw/croak/;
use Data::Paging::Collection;

sub create {
    my ($class, $collection_param, $renderer_name) = @_;
    my $collection = Data::Paging::Collection->new(%$collection_param);
    $collection->renderer($class->_create_renderer($renderer_name)) if $renderer_name;
    $collection;
}

sub _create_renderer {
    my ($class, $renderer_name) = @_;
    my $package = $class->_load_renderer($renderer_name);
    $package->new;
}

sub _load_renderer {
    my ($class, $name) = @_;
    croak "no renderer name" unless $name;

    my $package = $name;
    $package =~ s/\A-/Data::Paging::Renderer::/;
    $package->require or croak "can't load renderer: $package";
    $package;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Paging - pagination helper for view

=head1 SYNOPSIS

    use Data::Paging;
    
    my $paging = Data::Paging->create({
        entries      => $entries,
        total_count  => 100,
        per_page     => 30,
        current_page => 1,
    });
    
    $paging->has_next;    #=> TRUE
    $paging->has_prev;    #=> FALSE
    $paging->prev_page;   #=> 0
    $paging->next_page;   #=> 2
    $paging->begin_count; #=> 30
    $paging->end_count;   #=> 30
    ...
    
    # If you use simple template engine like HTML::Template,
    # you should use Data::Paging with renderer.
    my $paging = Data::Paging->create({
        entries      => $entries,
        total_count  => 100,
        per_page     => 30,
        current_page => 1,
    }, '-NeighborLink');  # NeighborLink is the bundled renderer. You can load renderer like Plack::Middleware.
    
    $paging->render #=> output HASHREF value

=head1 DESCRIPTION

Data::Paging = Data::Page + Data::Page::Navigation + Data::Page::NoTotalEntries

Data::Paging is the helper library for implementation of paging.
Especialy, Data::Paging class is the factory class of Data::Paging::Collection.

Data::Paging::Collection is the accessor of many pagination parameters like Data::Page, and then, that contain other Data::Page's brother features.

In addition, Data::Paging has renderer mechanism. That is convenience feature, when the application use rigid template engine like HTML::Template. Data::Paging bundle two default renderer to create common paging UI, also Data::Paging make application be able to define original renderer and load it as you like.

A point to notice is Data::Paging always has next or prev page number. This feature difference from Data::Page' one. You should use has_next/has_prev method, when check whether next_page/prev_page exist or not.

=head1 LICENSE

Copyright (C) ainame.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ainame E<lt>s.namai.2012@gmail.comE<gt>

=cut
