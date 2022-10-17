package Data::Page::Nav;

use strict;
use warnings;
use base 'Data::Page';

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw/number_of_pages/);

sub new {
    my $class = shift;
    my $self  = {
        _first_nav_page => undef,
        _last_nav_page  => undef,
    };
    bless( $self, $class );

    my ( $total_entries, $entries_per_page, $current_page, $number_of_pages ) = @_;
    $self->total_entries( $total_entries       || 0 );
    $self->entries_per_page( $entries_per_page || 10 );
    $self->current_page( $current_page         || 1 );
    $self->number_of_pages( $number_of_pages   || 10 );
    
    return $self;
}

sub pages_nav {
    my $self = shift;
    
    my $total = int(shift || $self->number_of_pages);
    my $rest  = $total % 2;
    my $half  = ($total - $rest) / 2;
    
    $self->{_first_nav_page} = $self->_start_nav($total, $half, $rest);
    $self->{_last_nav_page}  = $self->_end_nav($total, $half);
    
    return wantarray 
         ? ($self->first_nav_page .. $self->last_nav_page)
         : [$self->first_nav_page .. $self->last_nav_page];
}

sub first_nav_page {
    my $self = shift;
    my $number_of_pages = shift;
    
    return shift @{$self->pages_nav($number_of_pages)} 
        if $number_of_pages || !$self->{_first_nav_page};
        
    return $self->{_first_nav_page} if $self->{_first_nav_page};
    
    return;
}

sub last_nav_page {
    my $self = shift;
    my $number_of_pages = shift;
    
    return pop @{$self->pages_nav($number_of_pages)} 
        if $number_of_pages || !$self->{_last_nav_page};
        
    return $self->{_last_nav_page} if $self->{_last_nav_page};
    
    return;    
}

sub _start_nav {
    my ($self, $total, $half, $rest) = @_;
    
    if ($self->current_page > $half) {
        if (($self->current_page + $half) > $self->last_page) {
            if ($self->last_page > $total) {
                return ($self->last_page - $total) + 1;
            }
        } else {
            return ($self->current_page - $half) + ($rest ? 0 : 1);
        }
    }
        
    return 1;
}

sub _end_nav {
    my ($self, $total, $half) = @_;
    
    if ($self->last_page > ($self->current_page + $half)) {
        if ($self->current_page <= $half) {
            if ($self->last_page > $total) {
                return $total;
            }
        } else {
            return $self->current_page + $half;
        }
    }
    
    return $self->last_page; 
}

1;

__END__
 
=encoding utf8
 
=head1 NAME
 
Data::Page::Nav - Module for pages navigation

=head1 SYNOPSIS

    my $page = Data::Page::Nav->new;
    $page->total_entries(110);
    $page->entries_per_page(10);
    $page->current_page(4);
    $page->number_of_pages(5);
    
    # join all pages
    print join '-', $page->pages_nav; # 2-3-4-5-6
    
    # first navigation page 
    print $page->first_nav_page; # 2
    
    # last navigation page 
    print $page->last_nav_page; # 6  
    
Or

    my $total_entries = 110;
    my $entries_per_page = 10;
    my $current_page = 4;
    my $number_of_pages = 5;
    
    my $page = Data::Page::Nav->new(
        $total_entries, 
        $entries_per_page, 
        $current_page, 
        $number_of_pages
    );

    # join all pages
    print join '-', $page->pages_nav; # 2-3-4-5-6

    # first navigation page 
    print $page->first_nav_page; # 2

    # last navigation page 
    print $page->last_nav_page; # 6 
    
=head1 DESCRIPTION

This module simply provides methods for you to create navigation of pages, using as a base the module Data::Page.

=head1 METHODS

=head2 pages_nav

This method returns the numbers in an array or arrayref depending on the context, too it can set the number of pages, but is optional:

    # if the current page is 7
    print join '-', $page->pages_nav;    # 3-4-5-6-7-8-9-10-11-12
    print join '-', $page->pages_nav(3); # 6-7-8
    print join '-', $page->pages_nav(7); # 4-5-6-7-8-9-10

=head2 first_nav_page

This method returns the first value in the list returned by pages_nav, too it can set the number of pages, but is optional:

    # if the current page is 7
    print $page->first_nav_page;    # 3
    print $page->first_nav_page(3); # 6
    print $page->first_nav_page(7); # 4

=head2 last_nav_page

This method returns the last value in the list returned by pages_nav, too it can set the number of pages, but is optional:

    # if the current page is 7
    print $page->last_nav_page;    # 12
    print $page->last_nav_page(3); # 8
    print $page->last_nav_page(7); # 10    
    
=head2 More methods

The other methods are the same as the Data::Page, and you can see them in L<Data::Page#METHODS>

=head1 SEE ALSO
 
L<Data::Page>.
 
=head1 AUTHOR
 
Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut
