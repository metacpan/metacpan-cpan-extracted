package Catalyst::Model::Lucy;
{
  $Catalyst::Model::Lucy::VERSION = '0.001';
}
use Moo;
use FindBin;
use File::Spec;
use Lucy::Search::IndexSearcher;
use Lucy::Plan::Schema;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Plan::FullTextType;
use namespace::clean;

extends 'Catalyst::Model';
# ABSTRACT: A model for Lucy

has create_index => (
    is => 'rw',
    default => sub { 0 },);

has index_path => (
    is => 'ro',
    default => sub { return File::Spec->catfile("$FindBin::Bin","index") }, );

has index_searcher => (
    builder => '_index_searcher_builder',
    is => 'ro',
    handles => { hits => 'hits' },
    lazy => 1,);

has indexer => (
    builder => '_indexer_builder',
    is => 'ro',
    lazy => 1,);

has language => (
    is => 'rw',
    required => 1,
    default => sub { return 'en' },);

has num_wanted => (
    is => 'rw',
    default => sub { return 10 },);

has schema => (
    builder => '_schema_builder',
    is => 'ro',
    lazy => 1,);

has schema_params => (
    is => 'ro',);

has truncate_index => (
    is => 'rw',
    default => sub { 0 },);

sub _indexer_builder {
    my $self = shift;

    my $indexer = Lucy::Index::Indexer->new(
        index => $self->index_path,
        schema => $self->schema,
        create => $self->create_index,
        truncate => $self->truncate_index,
    );
    return $indexer;
}

sub _index_searcher_builder {
    my $self = shift;
    return Lucy::Search::IndexSearcher->new(
        index => $self->index_path,
    );
}

sub _schema_builder {
    my $self = shift;
    my $schema = Lucy::Plan::Schema->new;
    if ( $self->schema_params ) {
        my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
            language => $self->language
        );
        my $default_type = Lucy::Plan::FullTextType->new(
            analyzer => $polyanalyzer,
        );
        for my $param ( @{$self->schema_params} ) {
            $schema->spec_field(
                name => $param->{name}, 
                type => $param->{type} || $default_type);
        }

    }

    return $schema;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catalyst::Model::Lucy

=head1 SYNOPSIS

    # 1. Setup the Model
    package MyCatApplication::Model::Lucy;
    use base qw(Catalyst::Model::Lucy);

    my $other_type = Lucy::Plan::FullTextType->new(
        analyzer => Lucy::Analysis::PolyAnalyzer->new( language => 'en' )
    );

    __PACKAGE__->config(
        index_path     => File::Spec->catfile($FindBin::Bin,'index/path/'),
        num_wanted     => 20,
        language       => 'en',
        create_index   => 1,   # Optional
        truncate_index => 1,   # Optional
        schema_params  => [    # Optional schema params
                              { name => 'title' },   # defaults to Lucy::Plan::FullTextType
                              { name => 'desc', type => $other_type }
                          ]
    );


    # 2. Use in a controller
    my $results = $c->model('Lucy')->hits( query => 'foo' );
    while ( my $hit = $results->next ) {
        print $hit->{title},"\n";
    }



=head1 DESCRIPTION

This is a catalyst model for Apache L<Lucy>. 

=head1 ATTRIBUTES

=head2 create_index( 1|0 )

Sets the create_index flag to either 1 or 0 when initializing
L<Lucy::Index::Indexer>. Default value is 0.

=head2 index_path( $path )

Specifies the path to the index. The default path is $FindBin::Bin/index.

=head2 index_searcher

This is L<Lucy::Search::IndexSearcher>

=head2 indexer

This is L<Lucy::Index::Indexer>

=head2 language( $lang )

This is the index language, the default value is en.

=head2 num_wanted($num)

This is the number of hits the index_searcher will return. This is for
pagination.

=head2 schema

Accessor to L<Lucy::Plan::Schema>

=head2 schema_params( $array_ref )

Used when the indexer is initialized. The values of this are used to define
any custom scheme for index creation. See <Lucy::Plan::Schema>

=head2 truncate_index( 1|0 )

Sets the truncate flag to either 1 or 0 when initializing
L<Lucy::Index::Indexer>. Default value is 0.

=head1 METHODS

=head1 AUTHOR

Logan Bell L<email:logie@cpan.org>

=head1 SEE ALSO

L<Lucy>, L<Catalyst::Model>

=head1 COPYRIGHT & LICENSE

Copyright 2012, Logan Bell L<email:logie@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__END__
