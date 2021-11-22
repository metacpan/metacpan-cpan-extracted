package App::SpamcupNG::HTMLParse;
use strict;
use warnings;
use HTML::TreeBuilder::XPath 0.14;
use Exporter 'import';

our @EXPORT_OK = (
    'find_next_id',       'find_errors',
    'find_warnings',      'find_spam_header',
    'find_best_contacts', 'find_receivers'
);

my %regexes = (
    no_user_id => qr/\>No userid found\</i,
    next_id    => qr/sc\?id\=(.*?)\"\>/i,
    http_500   => qr/500/,
);

our $VERSION = '0.004'; # VERSION

=head1 NAME

App::SpamcupNG::HTMLParse - function to extract information from Spamcop.net
web pages

=head1 SYNOPSIS

    use App::SpamcupNG::HTMLParse qw(find_next_id find_errors find_warnings find_spam_header);

=head1 DESCRIPTION

This package export functions that uses XPath to extract specific information
from the spamcop.net HTML pages.

=head1 EXPORTS

=head2 find_next_id

Expects as parameter a scalar reference of the HTML page.

Tries to find the SPAM ID used to identify SPAM reports on spamcop.net webpage.

Returns the ID if found, otherwise C<undef>.

=cut

# TODO: use XPath instead of regex
sub find_next_id {
    my $content_ref = shift;
    my $next_id;

    if ( $$content_ref =~ $regexes{next_id} ) {
        $next_id = $1;
    }

    return $next_id;
}

=head2 find_warnings

Expects as parameter a scalar reference of the HTML page.

Tries to find all warnings on the HTML, based on CSS classes.

Returns an array reference with all warnings found.

=cut

# TODO: create a single tree instance and check for everything at once
sub find_warnings {
    my $content_ref = shift;
    my $tree        = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes
        = $tree->findnodes('//div[@id="content"]/div[@class="warning"]');
    my @warnings;

    foreach my $node (@nodes) {
        push( @warnings, $node->as_trimmed_text );
    }

    return \@warnings;
}

=head2 find_errors

Expects as parameter a scalar reference of the HTML page.

Tries to find all errors on the HTML, based on CSS classes.

Returns an array reference with all errors found.

=cut

sub find_errors {
    my $content_ref = shift;
    my $tree        = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes = $tree->findnodes('//div[@id="content"]/div[@class="error"]');
    my @errors;

    foreach my $node (@nodes) {
        push( @errors, $node->as_trimmed_text );
    }

    return \@errors;
}

=head2 find_best_contacts

Expects as parameter a scalar reference of the HTML page.

Tries to find all best contacts on the HTML, based on CSS classes.

The best contacts are the e-mail address that Spamcop considers appropriate to
use for SPAM reporting.

Returns an array reference with all best contacts found.

=cut

sub find_best_contacts {
    my $content_ref = shift;
    my $tree        = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($content_ref);
    my @nodes = $tree->findnodes('//div[@id="content"]');

    foreach my $node (@nodes) {
        for my $html_element ( $node->content_list ) {

            # only text
            next if ref($html_element);
            $html_element =~ s/^\s+//;
            if ( index( $html_element, 'Using best contacts' ) == 0 ) {
                my @tokens = split( /\s/, $html_element );
                splice( @tokens, 0, 3 );
                return \@tokens;
            }
        }

    }

    return [];
}

=head2 find_spam_header

Expects as parameter a scalar reference of the HTML page.

You can optionally pass a second parameter that defines if each line should be
prefixed with a tab character. The default value is false.

Tries to find the e-mail header of the SPAM reported.

Returns an array reference with all the lines of the e-mail header found.

=cut

sub find_spam_header {
    my $raw_spam_header = shift;
    my $formatted //= 0;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($raw_spam_header);
    my @nodes = $tree->findnodes_as_strings('//text()');
    my @lines;

    for ( my $i = 0; $i <= scalar(@nodes); $i++ ) {
        next unless $nodes[$i];
        $nodes[$i] =~ s/^\s++//u;

        if ($formatted) {
            push( @lines, "\t$nodes[$i]" );

        }
        else {
            push( @lines, $nodes[$i] );

        }
    }
    return \@lines;
}

=head2 find_receivers

Expects as parameter a scalar reference of the HTML page.

Tries to find all the receivers of the SPAM report, even if those were not real
e-mail address, only internal identifiers for Spamcop to store statistics.

Returns an array reference, where each item is a string.

=cut

sub find_receivers {
    my $content_ref = shift;
    my $tree        = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($content_ref);
    my @nodes = $tree->findnodes('//*[@id="content"]');
    my @receivers;

    foreach my $node (@nodes) {
        foreach my $inner ( $node->content_list() ) {

            # we just want text nodes, everything else is discarded
            next if ( ref($inner) );
            $inner =~ s/^\s+//;
            $inner =~ s/\s+$//;
            push( @receivers, $inner );
        }
    }

    return \@receivers;
}

=head1 SEE ALSO

=over

=item *

L<HTML::TreeBuilder::XPath>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
