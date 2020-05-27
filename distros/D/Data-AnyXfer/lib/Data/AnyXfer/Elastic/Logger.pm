package Data::AnyXfer::Elastic::Logger;

use Moose;

use namespace::autoclean;

use Log::Dispatch;
use Log::Dispatch::FileRotate;
use Log::Dispatch::Screen;

use Carp qw( croak );
use Path::Class;
use Path::Class::Dir;
use Scalar::Util  ();
use Sys::Hostname ();

use Data::AnyXfer::JSON;
use DateTime ();

use constant methods => qw/
    debug   info
    notice  warning
    error   critical
    alert   emergency
    /;

_generate_methods();

=head1 NAME

Data::AnyXfer::Elastic::Logger

=head1 SYNOPSIS


    my $logger = Data::AnyXfer::Elastic::Logger->new(
        dir     => 'Str|Path::Class::Dir',    # optional
        options => {                          # optional
           screen       => {},
           file_rotate  => {},
        },
        screen  => 0,                         # false by default
        file    => 1,                         # true by default
    );


    # alias = employees
    my $datafile1 = Datafile->new( file => 'employees.datafile' );

    # by default will log to ../elasticsearch/logs/dd-mm-yyyy/employees
    $logger->debug(
        index_info => $datafile1,
        text       => 'Blah Blah Blah!',
        content    => \@errors
    );


    # alias = interiors
    my $datafile2 = Datafile->new( file => 'interiors.datafile' );

    # by default will log to ../elasticsearch/logs/dd-mm-yyyy/interiors
    $logger->critical(
        index_info => $datafile2,
        text => 'Oops! Something went wrong!',
        content => Search::Elasticsearch::Error::Request->new;
    );

=head1 DESCRIPTION

This module is based of Log::Dispatch to log Elasticsearch events and errors.

=head1 ATTRIBUTES

=head2 destination

Defines the directory location of logging. Defaults to
C<CWD>/logs/yyyy-mm-dd/I<alias_name>.

=cut

has destination => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return Cwd::getcwd();
    },
);

=head2 file

Log to file. Defaults to true.

=cut

has file => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

=head2 screen

Log to screen. Defaults to false.

=cut

has screen => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head2 options

These define the options for C<Log::Dispatch::Screen> and C<Log::Dispatch::Screen>
please refer to their documentation. Note that for FileRotate the arguement
filename will be overwritten.

Must be in the format:

    {
        screen => { Log::Dispatch::Screen options }
        file_rotate => { Log::Dispatch::FileRotate options }
    }

=cut

has options => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_options',
);

sub _build_options {
    return {

        screen => {
            min_level => 'debug',
            name      => 'screen',
            newline   => 1,
        },

        file_rotate => {
            DatePattern => 'yyyy-MM-dd',
            min_level   => 'debug',
            mode        => 'append',
            name        => 'file_rotate',
            newline     => 1,
            TZ          => 'GMT0BST'
        },
    };
}

# PRIVATE ATTRIBUTES

# Cache for storing Log::Dispatch objects

has _cache => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

# JSON decoder/encoder

has _coder => (
    is       => 'ro',
    isa      => 'Data::AnyXfer::JSON',
    init_arg => undef,
    default => sub { Data::AnyXfer::JSON->new->pretty(1)->allow_nonref(1); }
);



=head1 METHODS

=head2 Logging:

    my %args = ( index_info => $df, text => '', content => $struct );

    $logger->debug( %args );
    $logger->info( %args );
    $logger->notice( %args );
    $logger->warning( %args );
    $logger->error( %args );
    $logger->critical( %args );
    $logger->alert( %args );
    $logger->emergency( %args );

All logging methods have the arguements: index_info, text and content. Content
can be either a perl data structure or a C<Search::Elasticsearch::Error::Request>
object.

=cut

sub _log {
    my ( $self, %args ) = @_;

    my $object = $args{index_info};
    my $client = $args{client};
    my $level  = $args{level};
    my $text   = $args{text};

    # we will be calling methods on index_info later on - these methods are
    # implemented so long as ..Role::IndexInfo is consumed

    my $role = 'Data::AnyXfer::Elastic::Role::IndexInfo';
    unless ( $object->does($role) ) {
        croak
            'The index_info arguement must be a object that consumes Data::AnyXfer::Elastic::Role::IndexInfo';
    }

    my $json;
    my $logger = $self->_fetch_logger($object);
    if ( my $content = $args{content} ) {

        # convert Search::Elasticsearch::Error (assumed) to
        # json, we are only really interested in the field 'text' so
        # it is referenced directly. Otherwise we assume it is a
        # hash/array structure

        if ( Scalar::Util::blessed $content
            && $content->isa('Search::Elasticsearch::Error') )
        {
            $json = $self->_coder->encode( $content->{text} );
        } else {
            $json = $self->_coder->encode($content);
        }
        $json =~ s/\s+/ /g;
    }

    # add client information prefix to message
    # if an es client was supplied
    if ($client) {
        $args{text} = sprintf '(%s/%s) %s',
            $client->transport->cxn_pool->cxns_str =~ s{http://|(:[0-9]$)}{}r,
            "$$\@" . Sys::Hostname::hostname(),
            $args{text};
    }

    # constructs mesage:
    my $prefix
        = DateTime->now->strftime('%F %H:%M:%S ') . '- [ ' . uc($level) . ' ] - ';

    my $message = $prefix . $args{text} . ( $json ? " :: ${json}" : '' );
    $logger->log( level => $level, message => $message );

    # add trailing log line after json output
    if ($json) {
        $logger->log( level => $level, message => $prefix . '.' );
    }

    return 1;
}

#
# add methods to class
#

sub _generate_methods {
    my $meta = __PACKAGE__->meta;

    for my $method (methods) {
        $meta->add_method(
            $method => sub {
                my ( $self, %args ) = @_;
                $self->_log( %args, level => $method );
            }
        );
    }
}

#
# fetch logger from cache or create a new one
#

sub _fetch_logger {
    my ( $self, $object ) = @_;

    my $key = $object->index;

    return $self->_cache->{$key} if $self->_cache->{$key};

    # create logger
    my $logger = Log::Dispatch->new;

    $logger->add( $self->_screen_log($object) ) if $self->screen;
    $logger->add( $self->_file_log($object) )   if $self->file;

    # add to cache
    $self->_cache->{$key} = $logger;

    return $logger;
}

#
# A Log::Dispatch::Screen object
#

sub _screen_log {
    return Log::Dispatch::Screen->new( %{ $_[0]->options->{screen} } );
}

#
# A Log::Dispatch::FileRotate object to specific file
#

sub _file_log {
    my ( $self, $object ) = @_;

    # create file and directory
    my $dir = Path::Class::dir( $self->destination );

    my $file = $dir->file( $object->alias . '.log' );
    $dir->mkpath;

    # add to options
    my %options = %{ $self->options->{file_rotate} };
    $options{filename} = $file->stringify;

    return Log::Dispatch::FileRotate->new(%options);
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
