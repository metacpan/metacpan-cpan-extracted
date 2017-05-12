# ABSTRACT: Manage config YAML files in a simple manner



package App::Basis::Config;
$App::Basis::Config::VERSION = '1.2';
use 5.010;
use warnings;
use strict;
use Moo;
use YAML::XS qw( Load Dump);
use Path::Tiny;
use Try::Tiny;
use App::Basis;



# ----------------------------------------------------------------------------
# the raw config data hash
has raw => (
    is   => 'ro',
    lazy => 1,

    # builder  => '_load',
    init_arg => undef,        # dont allow setting in constructor
    default  => sub { {} },
    writer   => '_set_raw'
);

has filename => (
    is       => 'ro',
    required => 0,
    writer   => '_set_filename'
);

has nostore => (
    is      => 'ro',
    default => sub {0}
);

has die_on_error => (
    is      => 'ro',
    default => sub {0}
);


has has_data => (
    is       => 'ro',
    default  => sub {0},
    init_arg => undef,            # dont allow setting in constructor
    writer   => '_set_has_data'
);


has changed => (
    is       => 'rw',
    default  => sub {0},
    init_arg => undef,     # dont allow setting in constructor
                           # writer   => '_set_changed'
);


has error => (
    is       => 'ro',
    default  => sub {undef},
    init_arg => undef,         # dont allow setting in constructor
    writer   => '_set_error'
);

# ----------------------------------------------------------------------------


sub BUILD {
    my $self = shift;

    $self->_set_error(undef);

    # make sure that the we expand home
    my $fname = fix_filename( $self->filename );

    if ( !$fname ) {
        $fname = $ENV{APP_BASIS_CFG} || fix_filename( "~/." . get_program() . ".cfg" );
    }
    if ( $fname && -f $fname ) {
        $self->_set_filename($fname);

        my $config;
        try {
            $config = Load( path($fname)->slurp_utf8 );
        }
        catch {
            $self->_set_error(
                "Could not read/processs config file $fname. $_");
        };

        # if there was a file to read from and we had an issue then we should
        # report it back to the caller somehow and make sure its seen.
        if ( $self->error ) {
            die $self->error if ( $self->die_on_error );
            warn $self->error;
        }

        # if we loaded some config
        if ( keys %$config ) {
            $self->_set_has_data(1);
            $self->_set_raw($config);
        }
    }
    else {
        $self->_set_error("could not establish a config filename");
        die $self->error if ( $self->die_on_error );
    }
}

# ----------------------------------------------------------------------------


sub store {
    my $self      = shift;
    my $filename  = shift;
    my $need_save = 0;
    my $status    = 0;

    local $YAML::Indent = 4;

    $self->_set_error(undef);
    if ( !$filename ) {
        $filename = $self->filename;
        $need_save = 1 if ( $self->changed );
    }
    else {
        $need_save = 1;
    }

    # only save if we need to
    if ($need_save) {
        if ( $self->nostore ) {
            warn "Attempt to save config file "
                . $self->filename
                . " when nostore has been used";
            return 0;
        }

        # do the save
        my $cfg = $self->raw;
        try {
            # do we need to create the directory to hold the file
            if ( !-d path($filename)->dirname ) {
                path($filename)->dirname->mkpath;
            }
            path($filename)->spew_utf8( Dump($cfg) );
        }
        catch {
            $self->_set_error(
                "Could not save config file " . $self->filename() );
            $status = 0;
        };
        die $self->error if ( $self->error && $self->die_on_error );
        $self->changed(0);
        $status = 1;
    }

    return $status;
}

# ----------------------------------------------------------------------------
# return a ref to a item in the config or undef
# if $value is true then a path will be established and the value stored as the
# final node

sub _split_path {
    my $self = shift;
    my ( $path, $value ) = @_;
    my $done            = 0;
    my $path_separators = '/:\.';

    # remove any leading/trailing path separators
    $path =~ s|^[$path_separators]?(.*)[$path_separators]?$|$1|;

    my $ref = $self->raw;
    my @items = split( /[$path_separators]/, $path );
    try {
        for ( my $i = 0; $i < scalar(@items); $i++ ) {
            my $item = $items[$i];
            if ( $ref->{$item} ) {
                $ref  = $ref->{$item};
                $done = 1;
            }
            else {
                if ($value) {

                    # is this the last thing?
                    if ( ( $i + 1 ) == scalar(@items) ) {

                        # save the value in the last node
                        $ref->{$item} = $value;
                    }
                    else {
                        $ref->{$item} = {};
                    }
                    $ref  = $ref->{$item};
                    $done = 1;
                }
                else {

                    # missed item
                    $done = 0;
                }
            }
        }
    }
    catch {};

    return $done ? $ref : undef;
}

# ----------------------------------------------------------------------------


sub get {
    my $self = shift;
    my $path = shift;

    $self->_set_error(undef);

    my $ref = $self->_split_path($path);

    return $ref;
}

# ----------------------------------------------------------------------------


sub set {
    my $self = shift;
    my ( $path, $value ) = @_;

    $self->_set_error(undef);

    # create the path to the item
    my $ref = $self->_split_path( $path, $value );

    # if we loaded some config
    $self->_set_has_data(1) if ( keys %{ $self->raw() } );

    # something has changed so we may need to save it later
    $self->changed(1);
}

# ----------------------------------------------------------------------------


sub clear {
    my $self = shift;
    my ( $path, $value ) = @_;

    $self->_set_error(undef);

    $self->raw = {};
    $self->_set_has_data(0);

    # something has changed so we may need to save it later
    $self->changed(1);
}

# ----------------------------------------------------------------------------
# make sure we do any cleanup required

END {
}


# ----------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Basis::Config - Manage config YAML files in a simple manner

=head1 VERSION

version 1.2

=head1 SYNOPSIS

  use App::Basis::Config
 
  my $cfg = App::Basis::Config->new( filename => "filename") ;
  # don't allow the store method to run, we don't want our configdata overwritten
  # my $cfg = App::Basis::Config->new( filename => "filename", nostore => 1) ;
  my $data = $cfg->raw ;

  my $name = $cfg->get( 'name') ;
  my $value = $cfg->get('/block/bill/item') ;

  # now test setting
  $cfg->set( 'test1', 123) ;
  $cfg->set( 'test2/test3/test4', 124) ;

  # saving, beware if saving a complex config file, comments will be lost
  # add a filename to save to a new file
  # $cfg->store() ;       # save to the filename used in new()
  $cfg->store( "filename.new") ;

=head1 DESCRIPTION

Carrying on from App:Simple, many apps need a way to get and store simple config data, if you need complex
the use a database!

This module is an extension to App::Basis to manage YAML config files in a simple manner.

=head1 NAME

App::Basis::Config

=head1 Notes

 Be careful using the save option, especially if the config is pulled in from
 many files, it will only write back to a single file

=head1 Public Functions

=over 4

=item raw

retrieve a hashref of the config data, once it has been parsed from YAML

=item has_data

test if there is any data in the config

=item changed

has the config data changed since the last save, or mark it as changed

    if( $data->changed) {
        say "somethings changed"
    }
    # my $data = $cfg->raw ;
    $data->{deep}->{nested}->{item} = 123 ;
    # mark the data as changed
    $data->changed( 1) ;
    # save in the default config file
    $data->store() ;    

B<Parameter>
    flag        optional, used as a getter if flag is missing, otherwise a setter

=item error

access last error generated (just a descriptive string)

=item new

Create a new instance of a config object, read config data from passed filename

B<Parameters>  passed in a HASH
    filename      - name of file to load/save config from
    nostore       - prevent store operation (optional)
    die_on_error  - die if we have any errors

=item store

Saves the config data, will not maintain any comments from the original file.
Will not perform save if no changes have been noted.

B<Parameter>
    filename        name of file to store config to, optional, will use object 
      instanced filename by default

=item get

Retrieve an item of config data. We use a unix style filepath to separate out 
the individual elements.

We can also use ':' and '.' as path sepators, so valid paths are

    /item/name/thing
    item.name.thing
    item:name:thing

The leading separator is not needed and is ignored.

If the path points to a complex config structure, ie array or hash, then that is
the data that will be returned.

B<Parameter>
    filepath        path to item to retrieve

    #get an item from the config data based on a unix style path
    my $value = $cfg->get( '/deep/nested/item') ;

    # this is the same as same as accessing the raw data
    my $data = $cfg->raw ;
    my $value = $data->{deep}->{nested}->{item} ;

=item set

Store an item into the config. 

    # set the value of an item into the config data based on a unix style path
    # this will mark the data as changed
    $cfg->set( '/deep/nested/item', 123) ;

    # same as accessing the raw_data, but this will not mark the data as changed
    # my $data = $cfg->raw ;
    $data->{deep}->{nested}->{item} = 123 ;
    # mark the data as changed, ready for a store operation
    $data->changed( 1) ;

B<Parameter>
    filepath        path to item to retrieve
    item            item to store, can be scalar, hashref or arrayref

=item clear

Clear all the data from the config, mark the config data as changed

=back

=head1 AUTHOR

Kevin Mulholland <moodfarm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kevin Mulholland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
