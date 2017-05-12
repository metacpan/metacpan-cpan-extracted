package Catalyst::Helper::Controller::DBIC::API::REST;

use Class::Load;
use namespace::autoclean;

use strict;
use warnings;

use FindBin;
use File::Spec;
use Path::Tiny;
use List::Util;

use lib "$FindBin::Bin/../lib";

BEGIN {

    our $VERSION = '0.09'; # VERSION
}

=head1 NAME

Catalyst::Helper::Controller::DBIC::API::REST

=encoding UTF-8

=head1 SYNOPSIS

    $ catalyst.pl MyApp
    $ cd MyApp
    $ script/myapp_create.pl controller API::REST DBIC::API::REST \
        MyApp::Schema MyApp::Model::DB


    ...

    package MyApp::Controller::API::REST::Producer;

    use strict;
    use warnings;
    use base qw/MyApp::ControllerBase::REST/;
    use JSON::XS;

    __PACKAGE__->config(
        action             =>  { setup => {
                                    PathPart => 'producer',
                                    Chained => '/api/rest/rest_base' }
                                }, # define parent chain action and partpath
        class              =>  'DB::Producer',        # DBIC result class
        create_requires    =>  [qw/name/],            # columns required
                                                      # to create
        create_allows      =>  [qw//],                # additional non-required
                                                      # columns that
                                                      # create allows
        update_allows      =>  [qw/name/],            # columns that
                                                      # update allows
        list_returns       =>  [qw/producerid name/], # columns that
                                                      # list returns

        list_prefetch_allows => [ # every possible prefetch param allowed
            [qw/cd_to_producer/], { 'cd_to_producer' => [qw//] },
            [qw/tags/],           { 'tags'           => [qw//] },
            [qw/tracks/],         { 'tracks'         => [qw//] },
        ],

        list_ordered_by         => [ qw/producerid/ ],
                                    # order of generated list
        list_search_exposes     => [ qw/producerid name/ ],
                                    # columns that can be searched on via list
    );

=head1 DESCRIPTION

  This creates REST controllers according to the specifications at
  L<Catalyst::Controller::DBIC::API> and L<Catalyst::Controller::DBIC::API::REST>
  for all the classes in your Catalyst app.

  It creates the following files:

    MyApp/lib/MyApp/Controller/API.pm
    MyApp/lib/MyApp/Controller/API/REST.pm
    MyApp/lib/MyApp/Controller/API/REST/*
    MyApp/lib/MyApp/ControllerBase/REST.pm

  Individual class controllers are under MyApp/lib/MyApp/Controller/API/REST/*.

=head2 CONFIGURATION

    The idea is to make configuration as painless and as automatic as possible, so most
    of the work has been done for you.

    There are 8 __PACKAGE__->config(...) options for L<Catalyst::Controller::DBIC::API/CONFIGURATION>.
    Here are the defaults.

=head2 create_requires

    All non-nullable columns that are (1) not autoincrementing,
    (2) don't have a default value, are neither (3) nextvals,
    (4) sequences, nor (5) timestamps.

=head2 create_allows

    All nullable columns that are (1) not autoincrementing,
    (2) don't have a default value, are neither (3) nextvals,
    (4) sequences, nor (5) timestamps.

=head2 update_allows

    The union of create_requires and create_allows.

=head2 list_returns

    Every column in the class.

=head2 list_prefetch

    Nothing is prefetched by default.

=head2 list_prefetch_allows

    (1) An arrayref consisting of the name of each of the class's
    has_many relationships, accompanied by (2) a hashref keyed on
    the name of that relationship, whose values are the names of
    its has_many's, e.g., in the "Producer" controller above, a
    Producer has many cd_to_producers, many tags, and many tracks.
    None of those classes have any has_many's:

    list_prefetch_allows    =>  [
        [qw/cd_to_producer/], { 'cd_to_producer'  => [qw//] },
        [qw/tags/],           { 'tags'            => [qw//] },
        [qw/tracks/],         { 'tracks'          => [qw//] },
    ],

=head2 list_ordered_by

    The primary key.

=head2 list_search_exposes

    (1) An arrayref consisting of the name of each column in the class,
    and (2) a hashref keyed on the name of each of the class's has many
    relationships, the values of which are all the columns in the
    corresponding class, e.g.,

    list_search_exposes => [
        qw/cdid artist title year/,
        { 'cd_to_producer' => [qw/cd producer/] },
        { 'tags'           => [qw/tagid cd tag/] },
        { 'tracks'         => [qw/trackid cd position title last_updated_on/] },
    ],    # columns that can be searched on via list

=head1 CONTROLLERBASE

    Following the advice in L<Catalyst::Controller::DBIC::API/EXTENDING>, this
    module creates an intermediate class between your controllers and
    L<Catalyst::Controller::DBIC::API::REST>.  It contains one method, create,
    which serializes object information and stores it in the stash, which is
    not the default behavior.

=head1 METHODS

=head2 mk_compclass

    This is the meat of the helper. It writes the directory structure if it is
    not in place, API.pm, REST.pm, the controllerbase, and the result class
    controllers. It replaces $helper->{} values as it goes through, rendering
    the files for each.

=over

=back

=head1 AUTHOR

Amiri Barksdale E<lt>amiri@roosterpirates.comE<gt>

=head1 CONTRIBUTORS

Franck Cuny (lumberjaph) <franck@lumberjaph.net>

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

Chris Weyl (RsrchBoy) <cweyl@alumni.drew.edu>

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub mk_compclass {
    my ( $self, $helper, $schema_class, $model, @extra_options ) = @_;
    my %extra_options = map {split /=/} @extra_options;

    $schema_class ||= $helper->{app} . '::Schema';
    $model        ||= $helper->{app} . '::Model::DB';

    ( my $model_base = $model ) =~ s/^.*::Model:://;

    $helper->{script} = File::Spec->catdir( $helper->{dir}, 'script' ) if $helper->{dir};
    $helper->{appprefix} = Catalyst::Utils::appprefix( $helper->{name} );
    my @path_to_name = split( /::/, $helper->{name} );

    ## Connect to schema for class info
    Class::Load::load_class($schema_class);
    my $schema = $schema_class->connect;

    my $path_app = File::Spec->catdir( $FindBin::Bin, "..", "lib",
        split( /::/, $helper->{app} ) );

    ## Make api base
    my $api_file
        = File::Spec->catfile( $path_app, $helper->{type}, "API.pm" );

    ( my $api_path = $api_file ) =~ s/\.pm$//;
    $helper->mk_dir($api_path);
    $helper->render_file( 'apibase', $api_file );
    $helper->{test} = $helper->next_test('API');
    $helper->_mk_comptest;

    ## Make rest base
    my $rest_file
        = File::Spec->catfile( $path_app, $helper->{type}, "API", "REST.pm" );

    ( my $rest_path = $rest_file ) =~ s/\.pm$//;
    $helper->mk_dir($rest_path);
    $helper->render_file( 'restbase', $rest_file );
    $helper->{test} = $helper->next_test('API_REST');
    $helper->_mk_comptest;

    ## Make controller base
    my $base_file
        = File::Spec->catfile( $path_app, "ControllerBase", "REST.pm" );

    $helper->mk_dir( File::Spec->catdir( $path_app, "ControllerBase" ) );
    $helper->render_file( 'controllerbase', $base_file );
    $helper->{test} = $helper->next_test('controller_base');
    $helper->_mk_comptest;

    $helper->mk_dir( File::Spec->catdir( $path_app, $helper->{type}, @path_to_name ));

    ## Make result class controllers
    for my $source ( $schema->sources ) {
        my ( $class, $result_class );
        my $file
            = File::Spec->catfile( $path_app, $helper->{type}, @path_to_name,
            split(/::/, $source . ".pm") );
        Path::Tiny::path($file)->parent()->mkpath;
        $class
            = $helper->{app} . "::"
            . $helper->{type}
            . "::" . join("::", @path_to_name) ."::"
            . $source;

        #$result_class = $helper->{app} . "::Model::DB::" . $source;
        $result_class = $model_base . '::' . $source;

        ### Declare config vars
        my @create_requires;
        my @create_allows;
        my @update_allows;
        my @list_prefetch;
        my @list_search_exposes = my @list_returns
            = $schema->source($source)->columns;

        ### HAIRY RELATIONSHIPS STUFF
        my @sub_list_search_exposes = my @list_prefetch_allows
            = _return_has_many_list(
            $schema->source($source)->_relationships );
        @list_prefetch_allows = map {
            my $ref = $_;
            qq|[qw/$ref->[0]/], { |
                . qq| '$ref->[0]' => [qw/|
                . join(
                ' ',
                map { $_->[0] } _return_has_many_list(
                    $schema->source( $ref->[1] )->_relationships
                )
                ) . qq|/] },\n\t\t|;
        } @list_prefetch_allows;

        @sub_list_search_exposes = map {
            my $ref = $_;
            qq|{ '$ref->[0]' => [qw/|
                . join( ' ', $schema->source( $ref->[1] )->columns )
                . qq|/] },\n\t\t|;
        } @sub_list_search_exposes;
        ### END HAIRY RELATIONSHIP STUFF

        my @list_ordered_by = $schema->source($source)->primary_columns;

        ### Prepare hash of column info for this class, so we can extract config
        my %source_col_info
            = map { $_, $schema->source($source)->column_info($_) }
            $schema->source($source)->columns;
        for my $k ( sort keys %source_col_info ) {
            no warnings qw/uninitialized/;
            if (( !$source_col_info{$k}->{'is_auto_increment'} )
                && !(
                    $source_col_info{$k}->{'default_value'}
                    =~ /(nextval|sequence|timestamp)/
                )
                )
            {

                ### Extract create required
                push @create_requires, $k
                    if !$source_col_info{$k}->{'is_nullable'};

                ### Extract create_allowed
                push @create_allows, $k
                    if $source_col_info{$k}->{'is_nullable'};
            }
            else { }
            @update_allows = ( @create_requires, @create_allows );
        }

        $helper->{package}        = $class;
        $helper->{class} = $model_base . '::' . $source;
        if (defined $extra_options{'result_class'}) {
            $helper->{result_class} = $extra_options{'result_class'};
        }
        $helper->{path_class_name} = join("/", (map {lc} @path_to_name[ 2 .. (scalar @path_to_name - 1)]), split(/::|\./, $schema->source_registrations->{$source}->name));
        $helper->{class_name}
            = List::Util::first {1;} reverse split(/::/, $schema->source_registrations->{$source}->name);
        $helper->{file}                = $file;
        $helper->{create_requires}     = join( ' ', @create_requires );
        $helper->{create_allows}       = join( ' ', @create_allows );
        $helper->{list_returns}        = join( ' ', @list_returns );
        $helper->{list_search_exposes} = join( ' ', @list_search_exposes );
        $helper->{sub_list_search_exposes}
            = join( '', @sub_list_search_exposes );
        $helper->{update_allows}        = join( ' ', @update_allows );
        $helper->{list_prefetch_allows} = join( '',  @list_prefetch_allows )
            if scalar @list_prefetch_allows > 0;
        $helper->{list_prefetch}
            = join( ', ', map {qq|'$_->[0]'|} @list_prefetch )
            if scalar @list_prefetch > 0;
        $helper->{list_ordered_by} = join( ' ', @list_ordered_by );
        $helper->render_file( 'compclass', $file );
        $helper->{test} = $helper->next_test($source);
        $helper->_mk_comptest;
    }
}

sub _return_has_many_list {
    my ($relationships) = @_;
    return
        grep { $relationships->{ $_->[0] }->{attrs}->{accessor} =~ /multi/ }
        map { [ $_, $relationships->{$_}->{source} ] }
        sort keys %$relationships;
}

1;

__DATA__

=begin pod_to_ignore

__apibase__
package [% app %]::Controller::API;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

sub api_base : Chained('/') PathPart('api') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

1;

__restbase__
package [% app %]::Controller::API::REST;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

sub rest_base : Chained('/api/api_base') PathPart('rest') CaptureArgs(0) {
    my ($self, $c) = @_;
}

1;
__controllerbase__
package [% app %]::ControllerBase::REST;

use strict;
use warnings;

use parent qw/Catalyst::Controller::DBIC::API::REST/;

sub create :Private {
my ($self, $c) = @_;
$self->next::method($c);
    if ($c->stash->{created_object}) {
        %{$c->stash->{response}->{new_object}} = $c->stash->{created_object}->get_columns;
    }
}

1;
__compclass__
package [% package %];

use strict;
use warnings;
use JSON::XS;

use parent qw/[% app %]::ControllerBase::REST/;

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => '[% path_class_name  %]', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  '[% class %]',
[% IF result_class %]
    result_class            =>  '[% result_class %]',
[% END %]
    # Columns required to create
    create_requires         =>  [qw/[% create_requires %]/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw/[% create_allows %]/],
    # Columns that update allows
    update_allows           =>  [qw/[% update_allows %]/],
    # Columns that list returns
    list_returns            =>  [qw/[% list_returns %]/],
[% IF list_prefetch %]
    # relationships prefetched by default
    list_prefetch           =>  [[% list_prefetch %]],
[% END %]
[% IF list_prefetch_allows %]
    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [% list_prefetch_allows %]
    ],
[% END %]
    # Order of generated list
    list_ordered_by         => [qw/[% list_ordered_by %]/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/[% list_search_exposes %]/,
        [% sub_list_search_exposes %]
    ],);

=head1 NAME

[% PACKAGE %] - REST Controller for [% schema_class %]

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class [% class_name %]

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE

[% license %]

=cut

1;
