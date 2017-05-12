package Class::DBI::Sweet::Topping;

use strict;
use Class::DBI::Sweet;

# Alias
*Class::DBI::Sweet::find = \&Class::DBI::Sweet::search;

sub Class::DBI::Sweet::AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD = $Class::DBI::Sweet::AUTOLOAD;
    my $super_meth = $AUTOLOAD;
    $super_meth =~ s/(?:.*::)?/SUPER::/;
    $AUTOLOAD =~ m/(search|find|page|count|(?:previous|next)_by)_(.*)/
        || return $self->$super_meth(@_);
    my $method = $1 || '';
    my $query = $2 || '';
    return 0 unless $query;
    my @keys = split /_and_/, $query;
    my %con;

    for my $key (@keys) {
        if ($method =~ /_by/) {
            $con{$key} = $self->$key; # previous/next_by conds are from self
        } else {
            $con{$key} = shift || '';
        }
    }

    $method =~ s/(.*)_by/retrieve_$1/; # Convert next_by to retrieve_next

    my $attrs = shift || {};

    return wantarray()
        ? @{[$self->$method( \%con, $attrs )]}
        : $self->$method( \%con, $attrs );
}

1;

__END__

=head1 NAME

    Class::DBI::Sweet::Topping - Topping for Class::DBI::Sweet

=head1 SYNOPSIS

    MyApp::Article->find_title_and_created_on( $title, $created_on );

    MyApp::Article->search_title_and_created_on( $title, $created_on );

    MyApp::Article->count_title_and_created_on( $title, $created_on );

    MyApp::Article->page_title_and_created_on( $title, $created_on );

    MyApp::Article->next_by_created_by( { order_by => 'created_on' } );

    MyApp::Article->previous_by_created_by( { order_by => 'created_on' } );

=head1 DESCRIPTION

Class::DBI::Sweet::Topping provides a convenient AUTOLOAD for search, page,
retrieve_next and retrieve_previous.

=head1 AUTHORS

Christian Hansen <ch@ngmedia.com>

Matt S Trout <mstrout@cpan.org>

Sebastian Riedel <sri@oook.de>

=head1 THANKS TO

Danijel Milicevic, Jesse Sheidlower, Marcus Ramberg, Viljo Marrandi

=head1 SUPPORT

#catalyst on L<irc://irc.perl.org>

L<http://lists.rawmode.org/mailman/listinfo/catalyst>

L<http://lists.rawmode.org/mailman/listinfo/catalyst-dev>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::Sweet>

L<Catalyst>

=cut
