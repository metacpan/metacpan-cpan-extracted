package CGI::Ex::Recipes::Template::Menu;

use utf8;
use warnings;
use strict;

#use CGI::Ex::Dump qw(debug dex_warn);

our $VERSION = '0.02';


sub load {    # called as Menu->load($context)
    my ( $class, $context ) = @_;

    #we may do other things beside just returning the class name if we need.
    return $class;    # returns 'Menu'
}

sub new {             # called as Menu->new($context)
    my ( $class, $context, @params ) = @_;
    bless {
        _CONTEXT => $context,
        _PARAMS  => $params[0],
        },
        $class;       # returns blessed Menu object
}

sub run {
    my ( $self, @args ) = @_;
    if ( $args[0] == 'default_map' ) {
        return 'hi ';
    }
    return $self->{_CONTEXT}->stash->get('app');
}

#================METHODS CALLABLE FROM OUTSIDE================
#lists only item in the current category $id
sub list_item {
    my $self = shift;
    my $item = shift || die('please provide a recipe item.') . $!;
    my $app  = $self->{app} ||= $self->get('app');
    my $cgix = $app->cgix;
    my $out;
    my $cache_key = 'list_item_' . $item->{id} . ( $app->is_authed ? 1 : '' );
    #try cache support
    if( $out = $app->cache->get($cache_key) ){ return $out; }
    if ( $self->{'recurse_level'} >= $self->{'_PARAMS'}{recurse} ) {
        return $cgix->li( { class => 'recipes', style => 'color:red' },
            'Max recursion reached. ' . 'If you want more: USE menu = Menu(recurse => 10000);' );
    }

    if ( $item->{is_category} ) {
        $self->{'recurse_level'}++;#ТОДО:make it work
        foreach my $list_item (
            @{  $app->recipes(
                    [qw(id pid is_category title)],
                    {   pid => $item->{id},
                        id  => { '!=', $item->{id} },
                    },
                    ['sortorder']
                )
            }
            )
        {
            $out .= $self->list_item($list_item);
        }
        $out = $cgix->li(
            { class => 'recipes' },
            (   $app->is_authed
                ? $cgix->a(
                    {   class => 'delete right',
                        href  => $app->script_name . '/delete/' . $item->{id}
                    },
                    'delete'
                    )
                    . $cgix->a(
                    {   class => 'edit right',
                        href  => $app->script_name . '/edit/' . $item->{id}
                    },
                    'edit'
                    )
                    . $cgix->a(
                    {   class => 'add right',
                        href  => $app->script_name . '/add/' . $item->{id}
                    },
                    'add here'
                    )
                : ''
                )
                . $cgix->a( { href => $app->script_name . '/view/' . $item->{id} }, $item->{title} )
            )
            . ( $out ? $cgix->ul( { class => 'recipes' }, $out ) : '' );
    }
    else {
        $out = $cgix->li(
            { class => 'recipes' },
            (   $app->is_authed
                ? $cgix->a(
                    {   class => 'delete right',
                        href  => $app->script_name . '/delete/' . $item->{id} . '/pid/'. $item->{pid}
                    },
                    'delete'
                    )
                    . $cgix->a(
                    {   class => 'edit right',
                        href  => $app->script_name . '/edit/' . $item->{id}
                    },
                    'edit'
                    )
                    . $cgix->a(
                    {   class => 'add right',
                        href => $app->script_name . '/add/' . $item->{pid} . '/after/' . $item->{id}
                    },
                    'add after'
                    )
                : ''
                )
                . $cgix->a( { href => $app->script_name . '/view/' . $item->{id} }, $item->{title} )
        );
    }
    #try cache support
    $app->cache->set($cache_key, $out);
    return $out;
}


#called in default.tthtml.
#lists all categorie under $id and items within them
sub recipes_map {
    my $self = shift;
    my $id   = shift || 0;    #id from which to start. must be a category id or 0(Top)
    my $out = '';    # we will push HTML here
    $self->{'recurse_level'} = 0;
    my $app = $self->{app} ||= $self->get('app');
    my $cache_key = 'recipes_map_'. $id . ( $app->is_authed ? 1 : '' );
    #try cache support
    if( $out = $app->cache->get($cache_key) ){ return $out; }
    foreach my $item ( @{ $app->recipes( undef, { pid => $id } ) } ) {
        $out .= $self->list_item($item);
    }
    my $cgix = $app->cgix;
    $out = $cgix->ul(
        { class => 'recipes' },
        $cgix->li(
            { class => 'recipes' },
            (   $app->is_authed
                ? $cgix->a(
                    {   class => 'add right',
                        href  => $app->script_name . '/add/'
                    },
                    'add'
                    )
                    . '&nbsp;'
                : ''
            )
            )
            . $out
    );
    #try cache support
    $app->cache->set($cache_key, $out);
    return $out;
}

#====================METHODS USED INTERNALLY==================
#shows controls for add,edit,delete if user is_authed
sub controls {

}

sub context { $_[0]->{_CONTEXT} }
sub stash   { $_[0]->{_CONTEXT}->stash }
sub get     { shift->stash->get(@_) }
sub set     { shift->stash->set(@_) }

1;    # End of CGI::Ex::Recipes::Template::Menu

__END__

=head1 NAME

CGI::Ex::Recipes::Template::Menu - Implements all sorts of menus for the application

=head1 VERSION

Version 0.02


=head1 SYNOPSIS

    [%# in some template altought it may be loaded first in the pre_process.tthtml %]
    [% menu = USE Menu %]
    
    [% menu.recipes_map(0)      %]
    ...


=head1 METHODS

=head2 recipes_map

Called in default.tthtml. Lists all categorie under $id and items within them.

=head2 list_item

Lists an item in the current category $id

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


