package App::Search::BackPAN;

$App::Search::BackPAN::VERSION   = '0.05';
$App::Search::BackPAN::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

App::Search::BackPAN - Command Line Interface for backpan.perl.org.

=head1 VERSION

Version 0.05

=cut

use 5.006;
use strict;
use warnings;
use HTTP::Tiny;

=head1 DESCRIPTION

Happy Birthday CPAN !!!
Released on 26th Oct to celebrate the occasion.

It provides search functionaliy of L<The BackPAN|http://backpan.perl.org>. It
comes with search tool C<search-backpan>.

=head1 SYNOPSIS

    $ search-backpan --pauseid [PAUSE_ID]

For example, if you look for author AAKD.

    $ search-backpan --pauseid AAKD
    http://backpan.perl.org/authors/id/A/AA/AAKD/MultiProcFactory-0.01.tar.gz
    http://backpan.perl.org/authors/id/A/AA/AAKD/MultiProcFactory-0.02.tar.gz
    http://backpan.perl.org/authors/id/A/AA/AAKD/MultiProcFactory-0.03.tar.gz
    http://backpan.perl.org/authors/id/A/AA/AAKD/MultiProcFactory-0.04.tar.gz
    http://backpan.perl.org/authors/id/A/AA/AAKD/XML-Simple-Tree-0.02.tar.gz
    http://backpan.perl.org/authors/id/A/AA/AAKD/XML-Simple-Tree-0.03.tar.gz

=cut

sub new {
    my $self = {};

    $self->{http}              = HTTP::Tiny->new;
    $self->{base_url}          = 'http://backpan.perl.org/authors/id';
    $self->{pause_id}          = undef;
    $self->{first_letter}      = undef;
    $self->{first_two_letters} = undef;
    $self->{distributions}     = [];
    bless $self;

    return $self;
}

=head1 METHODS

=head2 search($pause_id)

As name suggests, it returns the search result for the given C<$pause_id>.

    use strict; use warnings;
    use App::Search::BackPAN;

    my $backpan = App::Search::BackPAN->new;
    my $result  = $backpan->search('AAKD');

    print join "\n", @$result, "\n";

=cut

sub search {
    my ($self, $pause_id) = @_;

    $self->_check_pause_id($pause_id);
    $self->_validate_first_letter;
    $self->_validate_first_two_letters;

    my $authors = $self->_fetch_authors;
    if (keys %$authors) {
        _die($pause_id) unless (exists $authors->{$pause_id});
        $self->_fetch_distributions;
        return $self->_format_distributions;
    }
    else {
        _die($pause_id);
    }
}

#
#
# PRIVATE METHODS

sub _check_pause_id {
    my ($self, $pause_id) = @_;

    die "ERROR: Missing PAUSE ID" unless defined $pause_id;
    die "ERROR: PAUSE ID should be 3 or more characters long." unless (length($pause_id) >= 3);

    $self->{pause_id}          = $pause_id;
    $self->{first_letter}      = substr($pause_id, 0, 1);
    $self->{first_two_letters} = substr($pause_id, 0, 2);
}

sub _validate_first_letter {
    my ($self) = @_;

    my $http     = $self->{http};
    my $base_url = $self->{base_url};
    my $response = $http->get($base_url);
    my $content  = $response->{content};
    foreach my $line (split /\n/,$content) {
        if ($line =~ /href=\"([A-Z])\/\"/) {
            return 1 if ($self->{first_letter} eq $1);
        }
    }

    _die($self->{pause_id});
}

sub _validate_first_two_letters {
    my ($self) = @_;

    my $http         = $self->{http};
    my $base_url     = $self->{base_url};
    my $first_letter = $self->{first_letter};
    my $url          = sprintf("%s/%s", $base_url, $first_letter);

    my $response = $http->get($url);
    my $content  = $response->{content};
    foreach my $line (split /\n/,$content) {
        if ($line =~ /href=\"([A-Z][A-Z])\/\"/) {
            return 1 if ($self->{first_two_letters} eq $1);
        }
    }

    _die($self->{pause_id});
}

sub _fetch_authors {
    my ($self) = @_;

    my $http              = $self->{http};
    my $base_url          = $self->{base_url};
    my $first_letter      = $self->{first_letter};
    my $first_two_letters = $self->{first_two_letters};

    my $url      = sprintf("%s/%s/%s", $base_url, $first_letter, $first_two_letters);
    my $response = $http->get($url);
    my $content  = $response->{content};
    my $authors  = {};
    foreach my $line (split /\n/,$content) {
        if ($line =~ /\<img.*?\<a href=\"([A-Z]+)\/\"\>/) {
            $authors->{$1} = 1;
        }
    }

    return $authors;
}

sub _fetch_distributions {
    my ($self) = @_;

    my $http              = $self->{http};
    my $base_url          = $self->{base_url};
    my $pause_id          = $self->{pause_id};
    my $first_letter      = $self->{first_letter};
    my $first_two_letters = $self->{first_two_letters};

    my $url      = sprintf("%s/%s/%s/%s", $base_url, $first_letter, $first_two_letters, $pause_id);
    my $response = $http->get($url);
    my $content  = $response->{content};
    my $dists    = [];
    foreach my $line (split /\n/,$content) {
        if ($line =~ /\<img.*?\<a href=\"(.*\.gz)\"\>.*<\/a>/) {
            push @$dists, $1;
        }
    }

   $self->{distributions} = $dists;
}

sub _format_distributions {
    my ($self) = @_;

    my $base_url          = $self->{base_url};
    my $pause_id          = $self->{pause_id};
    my $first_letter      = $self->{first_letter};
    my $first_two_letters = $self->{first_two_letters};

    my $result = [];
    foreach my $dist (@{$self->{distributions}}) {
        push @$result, sprintf("%s/%s/%s/%s/%s", $base_url, $first_letter, $first_two_letters, $pause_id, $dist);
    }

    return $result;
}

sub _die {
    my ($pause_id) = @_;

    die "ERROR: PAUSE ID [$pause_id] not found.\n";
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-Search-BackPAN>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-search-backpan at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Search-BackPAN>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Search::BackPAN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Search-BackPAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Search-BackPAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Search-BackPAN>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Search-BackPAN/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of App::Search::BackPAN
