package DDG::ZeroClickInfo::Fathead;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: DuckDuckGo server side used ZeroClickInfo Fathead result class
$DDG::ZeroClickInfo::Fathead::VERSION = '1017';
use Moo;
with 'DDG::IsControllable';



sub new_via_output {
    my @line = split( /\t/, $_[0] );

    my @fields = (
        'title',
        'type',
        'redirect',
        'otheruses',
        'categories',
        'references',
        'see_also',
        'further_reading',
        'external_links',
        'disambiguation',
        'image',
        'abstract',
        'source_url');

    # Uses the list of fields to construct a hash with the field
    # names as keys and the corresponding elements in the line as
    # the values
    my %params = map { $_ => shift @line || ''} @fields;

    # Delete undefined parameters so the attributes aren't set and
    # we can use the predicates later.
    foreach (keys %params) {
        delete $params{$_} if $params{$_} eq '';
    }

    return __PACKAGE__->new( %params );
}


has title => (
    is => 'ro',
    predicate => 'has_title',
);



has type => (
    is => 'ro',
    predicate => 'has_type',
);



has redirect => (
    is => 'ro',
    predicate => 'has_redirect',
);



has other_uses => (
    is => 'ro',
    predicate => 'has_other_uses',
);



has categories => (
    is => 'ro',
    predicate => 'has_categories',
);



has references => (
    is => 'ro',
    predicate => 'has_references',
);



has see_also => (
    is => 'ro',
    predicate => 'has_see_also',
);



has further_reading => (
    is => 'ro',
    predicate => 'has_further_reading',
);



has external_links => (
    is => 'ro',
    predicate => 'has_external_links',
);



has disambiguation => (
    is => 'ro',
    predicate => 'has_disambiguation',
);



has image => (
    is => 'ro',
    predicate => 'has_image',
);



has abstract => (
    is => 'ro',
    predicate => 'has_abstract',
);



has source_url => (
    is => 'ro',
    predicate => 'has_source_url',
);

1;

__END__

=pod

=head1 NAME

DDG::ZeroClickInfo::Fathead - DuckDuckGo server side used ZeroClickInfo Fathead result class

=head1 VERSION

version 1017

=head1 SYNOPSIS

    my $zci_fathead = DDG::ZeroClickInfo::Fathead->new(
        title => 'Widget',
        type => 'A',
        categories => 'Products',
        abstract => 'The widget is the staple of any good business.',
        source_url => 'http://widg.et/amazingwidget.jpg',
    );

=head1 DESCRIPTION

This is the extension of the L<WWW::DuckDuckGo::ZeroClickInfo> class, how it
is used on the server side of DuckDuckGo. It adds attributes to the
ZeroClickInfo class which are not required for the "output" part of it.

=head1 ATTRIBUTES

=head2 title

This is the title of the result. This is what the user must search, with the
possible addition of specific trigger words, to trigger this result.

=head2 type

This is the type of result.

A for article (regular ZCI box)
R for redirect
D for disambiguation

=head2 redirect

Only for type 'R' (redirect)

This is the title it should be directed to.

e.g. "Duck Duck Go" -> "DuckDuckGo"

=head2 other_uses

Ignore.

=head2 categories

You can put the article in multiple categories, and category pages will be 
created automatically.

e.g.: http://duckduckgo.com/c/Procedural_programming_languages

You would do: Procedural programming languages\\n

You can have several categories, separated by an escaped newline. Categories 
should generally end with a plural noun.

=head2 references

Ignore.

=head2 see_also

You can reference related topics here, which get turned into links in
the Zero-click Info box. On the perl example, e.g. Perl Data Language,
you would do:

[[Perl Data Language]]

If the link name is different, you could do: 

[[Perl Data Language|PDL]]

=head2 further_reading

Ignore.

=head2 external_links

You can add external links that get put first when this article comes out.
The canonical example is an official site, which looks like:

[$url Official site]\\n

You can have several, separated by an escaped newline, though only a few
will be used. You can also have before and after text or put multiple
links in one like this:

Before text [$url link text] after text [$url2 second link].\\n

=head2 disambiguation

Only for type 'D' (disambiguation)

This is for searches that may benefit from one of many results, but the search
isn't specific enough to tell which the user is looking for. Disambiguations 
are a list of links to more specific searches. The format looks like this:

Search: "example"

*[[this example]], a brief summary\\n*[[that example]], another summary

=head2 image

You can reference an external image that we will download and reformat
for display. You would do:

[[Image:$url]]

=head2 abstract

This is the text in the ZCI box that should concisely explain the topic.

=head2 source_url

This is the full URL for the source. If all the URLs are relative to
the main domain, this can be relative to that domain.

=head1 METHODS

=head2 new_via_output

Takes a line from output.txt, constructs a hash with the input array mapped to
the attributes of this package, and returns a new DDG::ZeroClickInfo::Fathead
object instantiated with that hash.

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
