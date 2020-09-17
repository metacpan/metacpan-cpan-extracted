package App::ElasticSearch::Utilities::QueryString;
# ABSTRACT: CLI query string fixer

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use App::ElasticSearch::Utilities qw(:config);
use App::ElasticSearch::Utilities::Query;
use CLI::Helpers qw(:output);
use Module::Pluggable::Object;
use Moo;
use Ref::Util qw(is_arrayref);
use Types::Standard qw(ArrayRef Enum HashRef);

use namespace::autoclean;


my %JOINING  = map { $_ => 1 } qw( AND OR );
my %TRAILING = map { $_ => 1 } qw( AND OR NOT );


has 'context' => (
    is      => 'rw',
    isa     => Enum[qw(query filter)],
    lazy    => 1,
    default => sub { 'query' },
);


has search_path => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub {[]},
);


has default_join => (
    is      => 'rw',
    isa     => Enum[qw(AND OR)],
    default => sub { 'AND' },
);


has plugins => (
    is      => 'ro',
    isa     => ArrayRef,
    builder => '_build_plugins',
    lazy    => 1,
);


has fields_meta => (
    is => 'rw',
    isa => HashRef,
    default => sub { {} },
);


sub expand_query_string {
    my $self = shift;

    my $query  = App::ElasticSearch::Utilities::Query->new(
        fields_meta => $self->fields_meta,
    );
    my @processed = ();
    TOKEN: foreach my $token (@_) {
        foreach my $p (@{ $self->plugins }) {
            my $res = $p->handle_token($token);
            if( defined $res ) {
                push @processed, is_arrayref($res) ? @{$res} : $res;
                next TOKEN;
            }
        }
        push @processed, { query_string => $token };
    }

    debug({color=>"magenta"}, "Processed parts");
    debug_var({color=>"magenta"},\@processed);

    my $context = $self->context eq 'query' ? 'must' : 'filter';
    my $invert=0;
    my @dangling=();
    my @qs=();
    foreach my $part (@processed) {
        if( exists $part->{dangles} ) {
            push @dangling, $part->{query_string};
        }
        elsif( exists $part->{query_string} ) {
            push @qs, @dangling, $part->{query_string};
            @dangling=(),
        }
        elsif( exists $part->{condition} ) {
            my $target = $invert ? 'must_not' : $context;
            $query->add_bool( $target => $part->{condition} );
            @dangling=();
        }
        elsif( exists $part->{nested} ) {
            $query->nested($part->{nested}{query});
            $query->nested_path($part->{nested}{path});
            @dangling=();
        }
        # Carry over the Inversion for instance where we jump out of the QS
        $invert = exists $part->{invert} && $part->{invert};
    }
    if(@qs)  {
        pop   @qs while @qs && exists $TRAILING{$qs[-1]};
        shift @qs while @qs && exists $JOINING{$qs[0]};

        # Ensure there's a joining token, otherwise use our default
        if( @qs > 1 ) {
            my $prev_query = 0;
            my @joined = ();
            foreach my $part ( @qs ) {
                if( $prev_query ) {
                    push @joined, $self->default_join() unless exists $JOINING{$part};
                }
                push @joined, $part;
                # Here we include AND, NOT, OR
                $prev_query = exists $TRAILING{$part} ? 0 : 1;
            }
            @qs = @joined;
        }
    }
    $query->add_bool($context => { query_string => { query => join(' ', @qs) } }) if @qs;

    return $query;
}

# Builder Routines for QS Objects
sub _build_plugins {
    my $self    = shift;
    my $globals = es_globals('plugins');
    my $finder = Module::Pluggable::Object->new(
        search_path => ['App::ElasticSearch::Utilities::QueryString',@{ $self->search_path }],
        except      => [qw(App::ElasticSearch::Utilities::QueryString::Plugin)],
        instantiate => 'new',
    );
    my @plugins;
    foreach my $p ( sort { $a->priority <=> $b->priority || $a->name cmp $b->name }
        $finder->plugins( options => defined $globals ? $globals : {} )
    ) {
        debug(sprintf "Loaded %s with priority:%d", $p->name, $p->priority);
        push @plugins, $p;
    }
    return \@plugins;
}

# Return true
1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString - CLI query string fixer

=head1 VERSION

version 7.8

=head1 SYNOPSIS

This class provides a pluggable architecture to expand query strings on the
command-line into complex Elasticsearch queries.

=head1 ATTRIBUTES

=head2 context

Defaults to 'query', but can also be set to 'filter' so the elements will be
added to the 'must' or 'filter' parameter.

=head2 search_path

An array reference of additional namespaces to search for loading the query string
processing plugins.  Example:

    $qs->search_path([qw(My::Company::QueryString)]);

This will search:

    App::ElasticSearch::Utilities::QueryString::*
    My::Company::QueryString::*

For query processing plugins.

=head2 default_join

When fixing up the query string, if two tokens are found next to eachother
missing a joining token, join using this token.  Can be either C<AND> or C<OR>,
and defaults to C<AND>.

=head2 plugins

Array reference of ordered query string processing plugins, lazily assembled.

=head2 fields_meta

A hash reference with the field data from L<App::ElasticSearch::Utilities::es_index_fields>.

=head1 METHODS

=head2 expand_query_string(@tokens)

This function takes a list of tokens, often from the command line via @ARGV.  Uses
a plugin infrastructure to allow customization.

Returns: L<App::ElasticSearch::Utilities::Query> object

=head1 TOKENS

The token expansion plugins can return undefined, which is basically a noop on the token.
The plugin can return a hash reference, which marks that token as handled and no other plugins
receive that token.  The hash reference may contain:

=over 2

=item query_string

This is the rewritten bits that will be reassembled in to the final query string.

=item condition

This is usually a hash reference representing the condition going into the bool query. For instance:

    { terms => { field => [qw(alice bob charlie)] } }

Or

    { prefix => { user_agent => 'Go ' } }

These conditions will wind up in the B<must> or B<must_not> section of the B<bool> query depending on the
state of the the invert flag.

=item invert

This is used by the bareword "not" to track whether the token invoked a flip from the B<must> to the B<must_not>
state.  After each token is processed, if it didn't set this flag, the flag is reset.

=item dangles

This is used for bare words like "not", "or", and "and" to denote that these terms cannot dangle from the
beginning or end of the query_string.  This allows the final pass of the query_string builder to strip these
words to prevent syntax errors.

=back

=head1 Extended Syntax

The search string is pre-analyzed before being sent to ElasticSearch.  The following plugins
work to manipulate the query string and provide richer, more complete syntax for CLI applications.

=head2 App::ElasticSearch::Utilities::QueryString::AutoEscape

Provide an '=' prefix to a query string parameter to promote that parameter to a C<term> filter.

This allows for exact matches of a field without worrying about escaping Lucene special character filters.

E.g.:

    user_agent:"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Is evaluated into a weird query that doesn't do what you want.   However:

    =user_agent:"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Is translated into:

    { term => { user_agent => "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1" } }

Which provides an exact match to the term in the query.

=head2 App::ElasticSearch::Utilities::QueryString::Barewords

The following barewords are transformed:

    or => OR
    and => AND
    not => NOT

=head2 App::ElasticSearch::Utilities::QueryString::IP

If a field is an IP address uses CIDR Notation, it's expanded to a range query.

    src_ip:10.0/8 => src_ip:[10.0.0.0 TO 10.255.255.255]

=head2 App::ElasticSearch::Utilities::QueryString::Ranges

This plugin translates some special comparison operators so you don't need to
remember them anymore.

Example:

    price:<100

Will translate into a:

    { range: { price: { lt: 100 } } }

And:

    price:>50,<100

Will translate to:

    { range: { price: { gt: 50, lt: 100 } } }

=head3 Supported Operators

B<gt> via E<gt>, B<gte> via E<gt>=, B<lt> via E<lt>, B<lte> via E<lt>=

=head2 App::ElasticSearch::Utilities::QueryString::Underscored

This plugin translates some special underscore surrounded tokens into
the Elasticsearch Query DSL.

Implemented:

=head3 _prefix_

Example query string:

    _prefix_:useragent:'Go '

Translates into:

    { prefix => { useragent => 'Go ' } }

=head2 App::ElasticSearch::Utilities::QueryString::FileExpansion

If the match ends in .dat, .txt, .csv, or .json then we attempt to read a file with that name and OR the condition:

    $ cat test.dat
    50  1.2.3.4
    40  1.2.3.5
    30  1.2.3.6
    20  1.2.3.7

Or

    $ cat test.csv
    50,1.2.3.4
    40,1.2.3.5
    30,1.2.3.6
    20,1.2.3.7

Or

    $ cat test.txt
    1.2.3.4
    1.2.3.5
    1.2.3.6
    1.2.3.7

Or

    $ cat test.json
    { "ip": "1.2.3.4" }
    { "ip": "1.2.3.5" }
    { "ip": "1.2.3.6" }
    { "ip": "1.2.3.7" }

We can source that file:

    src_ip:test.dat      => src_ip:(1.2.3.4 1.2.3.5 1.2.3.6 1.2.3.7)
    src_ip:test.json[ip] => src_ip:(1.2.3.4 1.2.3.5 1.2.3.6 1.2.3.7)

This make it simple to use the --data-file output options and build queries
based off previous queries. For .txt and .dat file, the delimiter for columns
in the file must be either a tab or a null.  For files ending in
.csv, Text::CSV_XS is used to accurate parsing of the file format.  Files
ending in .json are considered to be newline-delimited JSON.

You can also specify the column of the data file to use, the default being the last column or (-1).  Columns are
B<zero-based> indexing. This means the first column is index 0, second is 1, ..  The previous example can be rewritten
as:

    src_ip:test.dat[1]

or:
    src_ip:test.dat[-1]

For newline delimited JSON files, you need to specify the key path you want to extract from the file.  If we have a
JSON source file with:

    { "first": { "second": { "third": [ "bob", "alice" ] } } }
    { "first": { "second": { "third": "ginger" } } }
    { "first": { "second": { "nope":  "fred" } } }

We could search using:

    actor:test.json[first.second.third]

Which would expand to:

    { "terms": { "actor": [ "alice", "bob", "ginger" ] } }

This option will iterate through the whole file and unique the elements of the list.  They will then be transformed into
an appropriate L<terms query|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html>.

=head2 App::ElasticSearch::Utilities::QueryString::Nested

Implement the proposed nested query syntax early.  Example:

    nested_path:"field:match AND string"

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
