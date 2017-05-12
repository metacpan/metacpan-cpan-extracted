#!/usr/bin/perl

package Data::Page::Set;

=head1 NAME

Data::Page::Set - Print page indexes

=head1 SYNOPSIS

  use Data::Page;
  use Data::Page::Set;

  my @data      = 0 .. 300;
  my $page      = Data::Page->new( scalar @data, 5, shift );
  my $pageset   = Data::Page::Set->new( $page, 6, {} );

  print $pageset->show;

=head1 DESCRIPTION

=head2 Data::Page::Set->new( $page, $setsize, $showhash );

=head4 Arguments

=over 4

=item C<$page> [Required]

A Data::Page object.

=item C<$setsize> [Required]

The size of the pageset:
If you have a page object with 20 pages,
but you only want to show

B<E<lt>E<lt>> B<E<lt>> B<4> B<5> 6 B<7> B<8> B<E<gt>> B<E<gt>E<gt>>

Then setsize should be 5 because we're only
showing 5 page indexes.

=item C<$showhash>

A hash with zero or more of the following keys,
with a coderef as value wich is executed when we are about to print:

=over 4

=item show_first

link to the first page

=item show_no_first

no link to the first page

=item show_prev

previous page link

=item show_no_prev

no link to the previous

=item show_next

next page link

=item show_no_next

No next page link

=item show_last

Last page link

=item show_no_last

No last page link

=item show_page

A link to another page

=item show_current_page

The current page

=item grepper

Executed in grep { $code->($_) } before the result is joined

=item joiner

Executed and used as the first argument to join

=back

=cut

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.04';

my $code = {
    show_first          => sub { qq(<a href="?page=$_[0]">&lt;&lt;First</a>) },
    show_no_first       => sub { qq() },
    show_prev           => sub { qq(<a href="?page=$_[0]">&lt;Previous</a>) },
    show_no_prev        => sub { qq() },
    show_next           => sub { qq(<a href="?page=$_[0]">&gt;Next</a>) },
    show_no_next        => sub { qq() },
    show_last           => sub { qq(<a href="?page=$_[0]">&gt;&gt;Last</a>) },
    show_no_last        => sub { qq() },
    show_page           => sub { qq(<a href="?page=$_[0]">$_[0]</a>) },
    show_current_page   => sub { qq($_[0]) },
    joiner              => sub { qq(&nbsp;\n) },
    grepper             => sub { length $_[0] },
};

sub new {
    my $class = shift;
    my $pager = shift;
    my $setsize = shift || 10;
    my $show  = shift;

    for my $key ( keys %$code ) {
        $show->{$key} = $code->{$key}
            unless exists $show->{$key}
               and ref $show->{$key} eq 'CODE';
    }

    my $self = bless {
        pager   => $pager,
        show    => $show,
        setsize => $setsize,
    }, $class;

    return $self;
}

sub show {
    my $self    = shift;
    my $show    = shift || $self->{show};
    my $pager   = $self->{pager};

    return  join $show->{joiner}->(),
            grep( { $show->{grepper}->($_) } (
        $self->page_in_set($pager->first_page)
            ? $show->{show_no_first}->($pager->first_page, $pager)
            : $show->{show_first}->($pager->first_page, $pager),
        $pager->current_page == $pager->first_page
            ? $show->{show_no_prev}-> ($pager->previous_page, $pager)
            : $show->{show_prev}->($pager->previous_page, $pager),
        (map
            {
                $_ == $pager->current_page
                    ? $show->{show_current_page}->( $_, $pager )
                    : $show->{show_page}->( $_, $pager )
            } $self->pages_in_set()
        ),
        $pager->current_page == $pager->last_page
            ? $show->{show_no_next}->($pager->next_page, $pager)
            : $show->{show_next}->($pager->next_page, $pager),
        $self->page_in_set($pager->last_page)
            ? $show->{show_no_last}->($pager->last_page, $pager)
            : $show->{show_last}->($pager->last_page, $pager),
    ));
}

sub pages_in_set {
    my $self = shift;

    my $cur     = $self->{pager}->current_page;
    my $len     = $self->{setsize};
    my $first   = $self->{pager}->first_page;
    my $last    = $self->{pager}->last_page;

    my $pre;
    my $post        = sub { $len  - $pre - 1    };
    my $size        = sub { $last - $first      };
    my $first_show  = sub { $cur  - $pre        };
    my $last_show   = sub { $cur  + $post->()   };

    return $first .. $last if $len > $size->();

    $pre = $len % 2 ? int $len / 2 : int( ($len - 1) / 2 );

    $pre = $last_show->()  > $last  ? -$last  + $cur + $len - 1
         : $first_show->() < $first ? -$first + $cur
         : $pre;

    return $first_show->() .. $last_show->();
}

sub page_in_set {
    my $self = shift;
    my $page = shift;

    return scalar grep
        { $_ == $page }
        $self->pages_in_set;
}

sub page_before_view {
    my $self = shift;
    my @in_view = $self->pages_in_set;

    return $in_view[0] - 1;
}

sub page_after_view {
    my $self = shift;
    my @in_view = $self->pages_in_set;

    return $in_view[-1] + 1;
}

=head1 HISTORY

0.02: Previous and next are show when current page
      not is first and last resp.

0.04: perl-5.6.1 compatible, tests added

=head1 TODO

=over 4

=item * Improve joiner/grepper

Joiner and grepper could be replaced with one routine that
constructs the return value.

=item * Generic backend

Data::Page is atm the only pager supported, but we could
do better than that.

=back

=head1 AUTHOR

Berik Visschers <berikv@xs4all.nl>

=head1 COPYRIGHT

Copyright 2005 by Berik Visschers E<lt>berikv@xs4all.nlE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

1
