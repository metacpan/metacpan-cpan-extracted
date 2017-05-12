package DBIx::ThinSQL::Drop;
use strict;
use warnings;
use File::ShareDir qw/dist_dir/;
use Path::Tiny;
use DBIx::ThinSQL::Deploy;

our $VERSION = '0.0.48';

sub _doit {
    my $self   = shift;
    my $type   = shift;
    my $driver = $self->{Driver}->{Name};
    my $file   = $self->share_dir->child( 'Drop', $driver, $type . '.sql' );

    return $self->run_file($file) if -f $file;
    Carp::croak "Drop $type for driver $driver is unsupported.";
}

sub DBIx::ThinSQL::db::drop_indexes {
    my $self = shift;
    return _doit( $self, 'indexes' );
}

sub DBIx::ThinSQL::db::drop_functions {
    my $self = shift;
    return _doit( $self, 'functions' );
}

sub DBIx::ThinSQL::db::drop_languages {
    my $self = shift;
    return _doit( $self, 'languages' );
}

sub DBIx::ThinSQL::db::drop_sequences {
    my $self = shift;
    return _doit( $self, 'sequences' );
}

sub DBIx::ThinSQL::db::drop_tables {
    my $self = shift;
    return _doit( $self, 'tables' );
}

sub DBIx::ThinSQL::db::drop_triggers {
    my $self = shift;
    return _doit( $self, 'triggers' );
}

sub DBIx::ThinSQL::db::drop_views {
    my $self = shift;
    return _doit( $self, 'views' );
}

sub DBIx::ThinSQL::db::drop_everything {
    my $self = shift;
    return _doit( $self, 'indexes' ) +
      _doit( $self, 'functions' ) +
      _doit( $self, 'languages' ) +
      _doit( $self, 'sequences' ) +
      _doit( $self, 'tables' ) +
      _doit( $self, 'triggers' ) +
      _doit( $self, 'views' );
}

1;
