package App::SpamcupNG::HTMLParse;
use strict;
use warnings;
use HTML::TreeBuilder::XPath 0.14;
use Exporter 'import';
use Carp 'croak';

use App::SpamcupNG::Error::Factory qw(create_error);
use App::SpamcupNG::Warning::Factory qw(create_warning);

our @EXPORT_OK = (
    'find_next_id',       'find_errors',
    'find_warnings',      'find_spam_header',
    'find_best_contacts', 'find_receivers',
    'find_message_age',   'find_header_info'
);

my %regexes = (
    next_id     => qr#^/sc\?id=(\w+)#,
    message_age => qr/^Message\sis\s(\d+)\s(\w+)\sold/
);

our $VERSION = '0.010'; # VERSION

=head1 NAME

App::SpamcupNG::HTMLParse - functions to extract information from Spamcop.net
web pages

=head1 SYNOPSIS

    use App::SpamcupNG::HTMLParse qw(find_next_id find_errors find_warnings find_spam_header find_message_age find_header_info);

=head1 DESCRIPTION

This package export functions that uses XPath to extract specific information
from the spamcop.net HTML pages.

=head1 EXPORTS

Following are all exported functions by this package.

=head2 find_header_info

Finds information from the e-mail header of the received SPAM and returns it.

Returns a hash reference with the following keys:

=over

=item mailer: the X-Mailer header, if available

=item content_type: the Content-Type, if available

=back

There is an attempt to normalize the C<Content-Type> header, by removing extra
spaces and using just the first two entries, also making everything as lower
case.

=cut

sub find_header_info {
    my $content_ref = shift;
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes = $tree->findnodes('/html/body/div[@id="content"]/pre');
    my %info  = (
        mailer       => undef,
        content_type => undef
    );
    my $mailer_regex       = qr/^X-Mailer:/;
    my $content_type_regex = qr/^Content-Type:/;

    foreach my $node (@nodes) {

        foreach my $content ( split( "\n", $node->as_text() ) ) {
            $content =~ s/^\s+//;
            $content =~ s/\s+$//;
            next if ( $content eq '' );

            if ( $content =~ $mailer_regex ) {
                my $wanted = ( split( ':', $content ) )[1];
                $wanted =~ s/^\s+//;
                $info{mailer} = $wanted;
                next;
            }

            if ( $content =~ $content_type_regex ) {
                my $wanted = ( split( ':', $content ) )[1];
                $wanted =~ s/^\s+//;
                my @wanted = split( ';', $wanted );

                if ( scalar(@wanted) > 1 ) {
                    my $encoding = lc( $wanted[0] );
                    my $charset  = lc( $wanted[1] );
                    $charset =~ s/^\s+//;
                    $info{content_type} = join( ';', $encoding, $charset );
                }
                else {
                    chop $wanted if ( substr( $wanted, -1 ) eq ';' );
                    $info{content_type} = $wanted;
                }

                next;
            }

            last if ( $info{mailer} and $info{content_type} );
        }
    }

    return \%info;

}

=head2 find_message_age

Find and return the SPAM message age information.

Returns an array reference, with the zero index as an integer with the age, and
the index 1 as the age unit (possibly "hour");

If nothing is found, returns C<undef>;

=cut

sub find_message_age {
    my $content_ref = shift;
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes = $tree->findnodes('/html/body/child::div[@id="content"]');

    foreach my $node (@nodes) {
        foreach my $content ( $node->content_refs_list ) {
            next unless ( ref($content) eq 'SCALAR' );
            $$content =~ s/^\s+//;
            $$content =~ s/\s+$//;
            next if ( $$content eq '' );

            if ( $$content =~ $regexes{message_age} ) {
                my ( $age, $unit ) = ( $1, $2 );
                chop $unit if ( substr( $unit, -1 ) eq 's' );
                return [ $age, $unit ];
            }
        }
    }

    return undef;
}

=head2 find_next_id

Expects as parameter a scalar reference of the HTML page.

Tries to find the SPAM ID used to identify SPAM reports on spamcop.net webpage.

Returns the ID if found, otherwise C<undef>.

=cut

sub find_next_id {
    my $content_ref = shift;
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes = $tree->findnodes('//strong/a');
    my $next_id;

    foreach my $element (@nodes) {
        if ( $element->as_trimmed_text eq 'Report Now' ) {

            if ( $element->attr('href') =~ $regexes{next_id} ) {
                $next_id = $1;
                my $length   = length($next_id);
                my $expected = 45;
                warn
                    "Unexpected length for SPAM ID: got $length, expected $expected"
                    unless ( $length == $expected );
                last;
            }
        }
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
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes
        = $tree->findnodes('//div[@id="content"]/div[@class="warning"]');
    my @warnings;

    foreach my $node (@nodes) {
        my @all_text;
        push( @all_text, $node->as_trimmed_text );

  # Spamcop page might add other text lines after the div, until the next div.
        foreach my $next ( $node->right() ) {
            if ( ref $next ) {
                next if ( $next->tag eq 'br' );
                last if ( $next->tag eq 'div' );
            }
            else {
                push( @all_text, $next );
            }
        }

        push( @warnings, create_warning( \@all_text ) );
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
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($$content_ref);
    my @nodes = $tree->findnodes('//div[@id="content"]/div[@class="error"]');
    my @errors;

    foreach my $node (@nodes) {
        my @all_text;
        push( @all_text, $node->as_trimmed_text );

        foreach my $next ( $node->right() ) {
            if ( ref $next ) {
                next if ( $next->tag eq 'br' );
                last if ( $next->tag eq 'div' );
            }
            else {
                push( @all_text, $next );
            }
        }

        push( @errors, create_error( \@all_text ) );
    }

    # bounce errors are inside a form
    my $base_xpath = '//form[@action="/mcgi"]';
    @nodes = $tree->findnodes( $base_xpath . '//strong' );

    if (@nodes) {
        if ( $nodes[0]->as_trimmed_text() eq 'Bounce error' ) {
            my @nodes = $tree->findnodes($base_xpath);
            $nodes[0]->parent(undef);
            my @messages;

            foreach my $node ( $nodes[0]->content_list() ) {
                next unless ( ref($node) eq '' );
                push( @messages, $node );
            }

            push( @errors, create_error( \@messages ) );
        }
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
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
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
    my $content_ref = shift;
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $formatted //= 0;
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($content_ref);

    my @nodes    = $tree->findnodes('/html/body/div[5]/p[1]/strong');
    my $expected = 'Please make sure this email IS spam:';
    my $parent   = undef;

    foreach my $node (@nodes) {
        if ( $node->as_trimmed_text eq $expected ) {
            $parent = $node->parent;
            last;
        }
    }

    if ($parent) {
        $parent->parent(undef);
        @nodes = $parent->findnodes('//font');

        if (   ( scalar(@nodes) != 1 )
            or ( ref( $nodes[0] ) ne 'HTML::Element' ) )
        {
            croak 'Unexpected content of SPAM header: ' . Dumper(@nodes);
        }

        my @lines;
        my $header = $nodes[0]->content;

        for ( my $i = 0; $i <= scalar( @{$header} ); $i++ ) {
            if ( ref( $header->[$i] ) eq 'HTML::Element' ) {
                $header->[$i]->parent(undef);

                # just want text here
                next unless $header->[$i]->content;
                my $content = ( $header->[$i]->content )->[0];
                next unless $content;
                next if ( ref($content) );
                $header->[$i] = $content;
            }
            next unless $header->[$i];

            # removing Unicode spaces in place
            $header->[$i] =~ s/^\s++//u;

            if ($formatted) {
                push( @lines, "\t$header->[$i]" );

            }
            else {
                push( @lines, $header->[$i] );

            }
        }
        return \@lines;
    }

    return [];
}

=head2 find_receivers

Expects as parameter a scalar reference of the HTML page.

Tries to find all the receivers of the SPAM report, even if those were not real
e-mail address, only internal identifiers for Spamcop to store statistics.

Returns an array reference, where each item is a string.

=cut

sub find_receivers {
    my $content_ref = shift;
    croak "Must receive an scalar reference as parameter"
        unless ( ref($content_ref) eq 'SCALAR' );
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($content_ref);
    my @nodes = $tree->findnodes('//*[@id="content"]');
    my @receivers;
    my $devnull     = q{/dev/null'ing};
    my $report_sent = 'Spam report id';

    foreach my $node (@nodes) {
        foreach my $inner ( $node->content_list() ) {

            # we just want text nodes, everything else is discarded
            next if ( ref($inner) );
            $inner =~ s/^\s+//;
            $inner =~ s/\s+$//;

            my $result_ref;
            my @parts = split( /\s/, $inner );

  # /dev/null\'ing report for google-abuse-bounces-reports@devnull.spamcop.net
            if ( substr( $inner, 0, length($devnull) ) eq $devnull ) {
                $result_ref = [ ( split( '@', $parts[-1] ) )[0], undef ];
            }

          # Spam report id 7151980235 sent to: dl_security_whois@navercorp.com
            elsif (
                substr( $inner, 0, length($report_sent) ) eq $report_sent )
            {
                $result_ref = [$parts[6], $parts[3]];
            }
            else {
                warn "Unexpected receiver format: $inner";
            }

            push( @receivers, $result_ref );
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
