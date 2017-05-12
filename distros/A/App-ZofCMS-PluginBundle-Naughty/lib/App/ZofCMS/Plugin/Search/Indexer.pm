package App::ZofCMS::Plugin::Search::Indexer;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use Search::Indexer;

sub _key { 'plug_search_indexer' }
sub _defaults {
    return (
        dir         => 'index_files',
        cell        => 'd',
        key         => 'search_indexer',
        obj_args    => [],
        exact_match => 0,
        # add   => {},
        # remove => [],
        # search => '' || [],
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    return
        unless defined $conf->{add}
            or defined $conf->{remove}
            or defined $conf->{search};

    my $ix = Search::Indexer->new(
        dir => $conf->{dir},
        (
            writeMode => ( defined $conf->{add} or defined $conf->{remove} )
                      ? 1 : 0
        ),
        @{ $conf->{obj_args} || [] }
    );

    if ( defined $conf->{remove} ) {
        $conf->{remove} = [ $conf->{remove} ]
            unless ref $conf->{remove};

        if ( ref $conf->{remove} eq 'HASH' ) {
            for ( keys %{ $conf->{remove} || {} } ) {
                $ix->remove( $_, $conf->{remove}{ $_ } );
            }
        }
        else {
            for ( @{ $conf->{remove} || [] } ) {
                $ix->remove( $_ );
            }
        }
    }

    for ( keys %{ $conf->{add} || {} } ) {
        $ix->add( $_, $conf->{add}{ $_ } );
    }

    if ( defined $conf->{search} ) {
        do_search( $conf, $t, $ix );
    }
}

sub do_search {
    my ( $conf, $t, $ix ) = @_;
    my $search = $conf->{search};

    if ( ref $search ) {
        for ( @$search ) {
            push @{ $t->{ $conf->{cell} }{ $conf->{key} } },
                $ix->search( $_, $conf->{exact_match} );
        }
    }
    else {
        $t->{ $conf->{cell} }{ $conf->{key} } = $ix->search( $search, $conf->{exact_match} );
    }
}

1;
__END__

=encoding utf8

=for stopwords subref

=head1 NAME

App::ZofCMS::Plugin::Search::Indexer - plugin that incorporates Search::Indexer module's functionality

=head1 SYNOPSIS

    plugins => [ qw/Search::Indexer/ ],
    plug_search_indexer => {
        # most of these values are optional
        dir         => 'index_files',
        cell        => 'd',
        key         => 'search_indexer',
        obj_args    => [],
        exact_match => 0,
        add   => { id1 => 'text to index', },
        remove => [ qw/id1 id2 id3/ ],
        search => 'foo bar baz',
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that incorporates (partial) L<Search::Indexer>
functionality in a form of ZofCMS plugin. In other words, plugin allows one to create a
search index from a bunch of data and later on perform search on that index. See
docs for L<Search::Indexer> for more details.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template> as well as familiar with L<Search::Indexer>, at least lightly.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/Search::Indexer/ ],

You need to add the plugin into the list of plugins to execute.

=head2 C<plug_search_indexer>

    plug_search_indexer => {
        # most of these values are optional
        dir         => 'index_files',
        cell        => 'd',
        key         => 'search_indexer',
        obj_args    => [],
        exact_match => 0,
        add   => { id1 => 'text to index', },
        remove => [ qw/id1 id2 id3/ ],
        search => 'foo bar baz',
    },

    plug_search_indexer => sub {
        my ( $t, $q, $conf ) = @_;
        return {
            add   => { id1 => 'text to index', },
        };
    },

B<Mandatory>. The C<plug_search_indexer> first-level key can be specified in either ZofCMS
Template or Main Config File (or both). Its value can be either a subref or a hashref; if the
value is a subref it will be evaluated and it must return a hashref (or undef/empty list). This
hashref will be treated as if you directly assigned it to C<plug_search_indexer> key. The
C<@_> of that subref will contain the following C<$t, $q, $conf> where C<$t> is ZofCMS
Template hashref, C<$q> is a hashref of query parameters and C<$conf> is L<App::ZofCMS::Config>
object. Possible keys/values of C<plug_search_indexer> hashref are as follows:

=head3 C<dir>

    dir         => 'index_files',

B<Optional>. Specifies the directory where index files are located. Corresponds to C<dir>
argument of L<Search::Indexer> C<new()> method. B<Defaults to:> C<index_files> (and is relative
to C<index.pl> file).

=head3 C<obj_args>

    obj_args    => [],

B<Optional>. Takes an arrayref as a value, this arrayref will be directly dereferenced into
L<Search::Indexer>'s constructor (C<new()> method). The C<writeMode> argument will be set
by the plugin to a true value if C<add> or C<remove> keys (see below) are set. The C<dir>
argument will be derived from plugin's C<dir> key. The arrayref will be dereferenced I<after>
the C<dir> and C<writeMode> arguments, thus you can use C<obj_args> to override them.
See documentation for L<Search::Indexer> for possible values that you can set in
C<obj_args>. B<Defaults to:> C<[]> (empty arrayref).

=head3 C<cell>

    cell => 'd',

B<Optional>. Specifies first-level ZofCMS Template key into which to put search results (when
search
is performed). See C<key> argument below. B<Defaults to:> C<d>

=head3 C<key>

    key => 'search_indexer',

B<Optional>. Specifies the name of the key inside C<cell> first-level key into which to put search results (when search
is performed). See C<cell> argument below. Basically, if C<cell> is set to C<d> and
C<key> is set to C<search_indexer> then search results will be stored in
C<< $t->{d}{search_indexer} >> where C<$t> is ZofCMS Template hashref. B<Defaults to:>
C<search_indexer>

=head3 C<exact_match>

    exact_match => 0,

B<Optional>. Takes either true or false values. Will be given as second parameter to
L<Search::Indexer>'s C<search()> method; thus if it is set to true all the search words without
prefix will have C<+> added to them. B<Defaults to:> C<0>

=head3 C<add>

    add   => {
        id1 => 'text to index',
        id2 => 'other text to index',
    },

B<Optional>. When specified, instructs the plugin to add stuff into index. Takes a hashref
as a value where keys are IDs and values are text to index under those IDs.

=head3 C<remove>

    remove => [ qw/id1 id2 id3/ ],

    remove => {
        id1     => 'containing text',
        id2     => 'other containing text'
    },

B<Optional>. Takes either a hashref or an arrayref as a value. Elements of the arrayref would
be IDs of records to remove from the index. You'd use the hashref form when C<positions>
argument in C<obj_args> arrayref would be set to a false value (by default it's true); when
that's the case, the keys of hashref would be IDs and values would be corresponding texts.
See C<remove()> method and C<positions> argument to C<new()> method in L<Search::Indexer>

=head3 C<search>

    search => 'foo bar baz',

B<Optional>. Takes a string as a value. This string will be given to
L<Search::Indexer>'s C<search()> method as a first argument, i.e. the text for which to search.
The return value will be the same as return value of L<Search::Indexer>'s C<search()> method
and it will be assigned to C<< $t->{ <cell> }{ <key> } >> where C<$t> is ZofCMS Template
hashref and C<< <cell> >> and C<< <key> >> are C<cell> and C<key> plugin's arguments
respectively.

=head1 SEE ALSO

L<App::ZofCMS>, L<Search::Indexer>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS-PluginBundle-Naughty at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut