package App::arxiv2bib;

our $VERSION=0.20;

1;

__END__
=head1 NAME

App::arxiv2bib - Extract bibliographic data from the arXiv API

=head1 SYNOPSIS

    arxiv2bib [options] [args]

    arxiv2bib au:author1 AND au:author2 AND ti:title

    arxiv2bib --raw "(au:author1 AND ti:title) OR au:author2"

    arxiv2bib --amsrefs au:author1 OR ti:title

    arxiv2bib --sortBy=relevance --sortOrder=ascending --max_results=20 au:author1 AND au:author2

=head1 DESCRIPTION

The C<script/arxiv2bib> executable provided by the distribution extracts bibliographic information using the L<arXiv API|https://arxiv.org/help/api/user-manual>.

It defaults to the L<BibTeX|http://www.bibtex.org/> format for entries, but can optionally return L<AMSRefs|http://www.ams.org/arc/resources/amsrefs-about.html> entries or just dump raw info (a C<Perl> hash).

=head1 INSTALLATION

Using L<cpanm|https://metacpan.org/dist/App-cpanminus/view/bin/cpanm>: just plain

    $ cpanm App::arxiv2bib

should work once it's been indexed by L<CPAN|https://www.cpan.org/>. For more up-to-date versions clone this repo, C<cd> into it, and then:

    $ cpanm .

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=head1 OPTIONS

    -h | --help         usage examples and a breakdown of options/arguments
         --man          full documentation
    -n | --dry          only dump the the Mojo request object your options have formed
    -v | --verbose      dump the entire Mojo response object you've received

         --amsrefs      return entries in AMSRefs format instead of the BibTeX default
         --raw          dump a hash containing bibliographic info (authors, etc.), unformatted

    -l | --label        a string that will be used as the label of the BibTeX entry in place of the default (which is the arXiv identifier)
                        only really useful if you're interested in one of the entries being returned, since it labels all entries identically

The rest of the options go hand-in-hand with identically-named query parameters in L<the API|https://arxiv.org/help/api/user-manual>, so that will be essential documentation.

    --sortBy            "submittedDate" (default), "relevance" or "lastUpdatedDate"
    --sortOrder         "descending" (default) or "ascending"
    --id_list           comma-separated list of arXiv identifiers, e.g. 2106.16211,2106.16119,2106.15900; defaults to ""
    --start             index of the first displayed entry in the list returned by the search; defaults to 0
    --max_results       maximal number of displayed returned entries; defaults to 200

=head1 ARGUMENTS

The rest of the arguments constitute the C<search_query>, built as described in the L<API docs|https://arxiv.org/help/api/user-manual#query_details>.

The individual lexemes are of the form C<prefix:string>, where the prefix is one of the following (with the second column indicating what the prefix stands for):

    ti    Title
    au    Author
    abs   Abstract
    co    Comment
    jr    Journal Reference
    cat   Subject Category
    rn    Report Number
    id    Id (use id_list instead)
    all   All of the above

The lexemes can be connected by the logical operators C<AND>, C<OR> and C<ANDNOT>. So a script call might look like this:

    arxiv2bib au:author1 AND au:author2 ANDNOT au:author3

That'll search for papers coauthored by C<author1> and C<author2> but I<not> C<author3>. 

You can also group your search terms parenthetically for more sophisticated logical constructs:

    arxiv2bib "(au:author1 AND ti:title1) OR (au:author2 AND ti:title2)"

I had to enclose that in quotes though, because otherwise the shell gets confused.
