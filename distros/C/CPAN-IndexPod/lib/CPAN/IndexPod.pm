package CPAN::IndexPod;
use strict;
use warnings;
use File::Find::Rule;
use KinoSearch;
use KinoSearch::InvIndexer;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::QueryParser::QueryParser;
use KinoSearch::Searcher;
use Pod::Simple;
use Pod::Simple::PullParser;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(unpacked kinosearch));

our $VERSION = '0.25';

sub search {
    my ( $self, $query_string ) = @_;

    my $analyzer
        = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en' );

    my $query_parser = KinoSearch::QueryParser::QueryParser->new(
        analyzer       => $analyzer,
        default_field  => 'value',
        default_boolop => 'OR',
    );
    my $searcher = KinoSearch::Searcher->new(
        invindex => $self->kinosearch,
        analyzer => $analyzer,
    );
    my $query = $query_parser->parse($query_string);
    my $hits = $searcher->search( query => $query );
    $hits->seek( 0, 1000 );

    my %scores;
    while ( my $hit = $hits->fetch_hit_hashref ) {
        my $filename = $hit->{key};
        my $score    = $hit->{score};
        $scores{$filename} = $score;
    }

    return sort { $scores{$b} <=> $scores{$a} || $a cmp $b } keys %scores;
}

sub index {
    my $self     = shift;
    my $unpacked = $self->unpacked;

    my $analyzer
        = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en' );
    my $invindexer = KinoSearch::InvIndexer->new(
        invindex => $self->kinosearch,
        create   => 1,
        analyzer => $analyzer,
    );

    $invindexer->spec_field( name => 'key', indexed => 0, vectorized => 0 );
    $invindexer->spec_field( name => 'value', stored => 0, vectorized => 0 );

    chdir($unpacked) || die "Could not chdir to $unpacked: $!";

    my $rule  = File::Find::Rule->new;
    my @files = $rule->file->in(".");

    foreach my $filename (@files) {
        next if $filename =~ /\.svn/;
        eval {
            my $parser;
            $parser = Pod::Simple::PullParser->new;
            $parser->set_source($filename);

            my $title = $parser->get_title;
            return unless $title;

            my $synopsis = $parser->_get_titled_section(
                'SYNOPSIS',
                max_token          => 400,
                max_content_length => 3_000,
                desperate          => 1,
            );

            my $description = $parser->get_description;

            my $doc = $invindexer->new_doc;
            $doc->set_value( key   => $filename );
            $doc->set_value( value => "$title synopsis $description" );
            $invindexer->add_doc($doc);

            #      warn "added $filename => $title synopsis $description";
        };
    }

    $invindexer->finish( optimize => 1 );
}

1;

__END__


=head1 NAME

CPAN::IndexPod - Index the POD from an unpacked CPAN

=head1 SYNOPSIS

  my $i = CPAN::IndexPod->new;
  $i->unpacked("/unpacked/cpan/); # use CPAN::Unpack
  $i->kinosearch("/kino/");   # must be absolute path
  $i->index;

  # Then search with:
  my @files = $i->search("vampire");

=head1 DESCRIPTION

The Comprehensive Perl Archive Network (CPAN) is a very useful
collection of Perl code. It has a whole lot of module
distributions. CPAN::Unpack unpacks CPAN distributions. This module
will analyse the unpacked CPAN, index the Pod it contains, and allow
you to search it.

Right now it allows simplistic searching of NAME, SYNOPSIS and
DESCRIPTION sections and returns a list of filenames.

=head1 METHODS

=head2 new

  my $i = CPAN::IndexPod->new;

=head2 index

  $i->index;

=head2 search

  my @files = $i->search("vampire");

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004-6, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
