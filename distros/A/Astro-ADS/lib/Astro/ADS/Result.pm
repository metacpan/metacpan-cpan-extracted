package Astro::ADS::Result;
$Astro::ADS::Result::VERSION = '1.92';
use Moo;

use Carp;
use Data::Dumper::Concise;
use Mojo::Base -strict; # do we want -signatures
use Mojo::DOM;
use Mojo::File qw( path );
use Mojo::URL;
use Mojo::Util qw( quote );
use PerlX::Maybe;
use Types::Standard qw( Int Str ArrayRef HashRef Bool ); # InstanceOf ConsumerOf

has [qw/q fq fl sort/] => (
    is       => 'rw',
    isa      => Str,
);
has numFound => (
    is       => 'rw',
    isa      => Int->where( '$_ >= 0' ),
);
has numFoundExact => (
    is       => 'rw',
    isa      => Bool,
);
has [qw/start rows/] => (
    is       => 'rw',
    isa      => Int->where( '$_ >= 0' ),
);
has error => (
    is       => 'rw',
    isa      => HashRef[]
);
has docs => (
    is      => 'rw',
    isa     => ArrayRef[],
    #isa     => ArrayRef[ InstanceOf ['Astro::ADS::Paper'] ],
    default => sub { return [] },
);

# if the query failed, the Result has an error
# so warn the user if they try to access other returned attributes
before [qw/numFound numFoundExact start rows docs/] => sub {
   my ($self) = @_;
   if ($self->error ) {
       carp 'Empty Result object: ', $self->error->{message};
   }
};

sub next {
    my ($self, $num) = @_;
    my $next_start = $self->start + $self->rows;

    if ( $next_start > $self->numFound ) {
        carp "No more results for ", $self->q, "\n";
        return;
    }
    elsif ( $num && !($num > 0) ) {
        carp sprintf('Bad value for number of rows: %s. Defaulting to %d', $num, $self->rows);
        $num = 0;
    }

    my $next_search_terms = {
        q     => $self->q,
        start => $next_start,
        maybe fq   => $self->fq,
        maybe fl   => $self->fl,
        maybe rows => ($num || $self->rows),
        maybe sort => $self->sort,
    };
    delete $next_search_terms->{rows}
        if $next_search_terms->{rows} == 10; # don't send default

    return $next_search_terms;
}

sub get_papers {
    my $self = shift;
    return @{$self->docs};
}

#To Be Decided:
#This is a hold over from v1.0 which gets the summary for each document.
#Should we ditch it?
#
#sub summary {
#    my $self = shift;
#    for my $paper ( $self->get_papers ) {
#        $paper->summary;
#    }
#}
#
#sub sizeof {
#    my $self = shift;
#    return $self->numFound; # or should it be $self->rows ?
#}

1;

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::Result - A class for the results of a Search

=head1 VERSION

version 1.92

=head1 SYNOPSIS

    my $search = Astro::ADS::Search->new(...);

    my $result = $search->query();
    my @papers = $result->get_papers();

    my $next_q = $result->next();
    $result    = $ads->query( $next_q );

=head1 DESCRIPTION

The Result class holds the
L<response|https://ui.adsabs.harvard.edu/help/api/api-docs.html#get-/search/query>
from an ADS search query. It will create attributes for all the fields specified
in the C<fl> parameter of the search OR it will hold the error returned by the
L<UserAgent|Astro::ADS>. If an error was returned, any calls to attribute methods
will raise a polite warning that no fields will be available for that object.

By default, a successful search returns up to 10 rows of results. If more exist,
the user iterates through them using the L</"next"> method to generate a search
query updated to start where the previous search left off.

=head1 Methods

=head2 get_papers

This method gets a list of L<Astro::ADS::Paper>s from the last query executed.

=head2 next

Creates a new search query term hashref, suitable for fetching the next N papers
from the ADS. If not given as an argument, the default is 10 rows.
It returns C<undef> if you have already reached the end of the available results.

This takes the values from the response header and updates the start position,
collects the original query C<q> and other params and returns the hashref,
ready for the next C<<$search->query>>.

If given an argument, it takes that as the number of rows to fetch.

=head1 See Also

=over 4

=item * L<Astro::ADS>

=item * L<Astro::ADS::Search>

=item * L<ADS API|https://ui.adsabs.harvard.edu/help/api/>

=item * L<Available fields for Results|https://ui.adsabs.harvard.edu/help/search/comprehensive-solr-term-list>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
