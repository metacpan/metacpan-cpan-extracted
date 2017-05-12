package Class::DBI::Plugin::AccessionSearch;
use strict;
use warnings;
use base qw/Class::DBI::Plugin/;

our $VERSION = '0.02';

sub accession : Plugged {
    my($pkg, $where, $attrs) = @_;

    my $param = {
        pkg   => $pkg,
        where => $where,
        attrs => $attrs,
    };

    bless $param , __PACKAGE__;
}

sub accession_search : Plugged {
    my ($self, $where, $attrs) = @_;

    $where ||= {};
    $attrs ||= {};

    my $our_where = $self->{where} || {};
    my $new_where = { %{$our_where} , %{$where} };

    my $our_atters = $self->{attrs} || {};
    my $new_attrs = { %{$our_atters} , %{$attrs} };

    $self->{where} = $new_where;
    $self->{attrs} = $new_attrs;

    return $self->{pkg}->search_where($new_where,$new_attrs);
}

=head1 NAME

Class::DBI::Plugin::AccessionSearch - easliy add search atters.

=head1 VERSION

This documentation refers to Class::DBI::Plugin::AccessionSearch version 0.02

=head1 SYNOPSIS


    package Your::Data;
    use base 'Class::DBI';
    use Class::DBI::AccessionSearch;

in your script:

    use Your::Data;
    my $d = Your::Data->accession({status => 'ok'});
    $d->accession_search({sex => 'male'});
    $d->accession_search({status => 'ng'});

=head1 Methods

=head2 accession

create Class::DBI::AccessionSearch object.

=head2 accession_search

search_where's wrapper.

=head1 AUTHOR

Atsushi Kobayashi, C<< <nekokak at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-plugin-accessionsearch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-Plugin-AccessionSearch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::DBI::Plugin::AccessionSearch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-DBI-Plugin-AccessionSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-DBI-Plugin-AccessionSearch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-Plugin-AccessionSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-DBI-Plugin-AccessionSearch>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Plugin::AccessionSearch
