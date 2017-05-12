###########################################
package Cache::Historical;
###########################################
use strict;
use warnings;
use Rose::DB::Object::Loader;
use File::Basename;
use File::Path;
use Log::Log4perl qw(:easy);
use DBI;
use DateTime::Format::Strptime;

our $VERSION = "0.05";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my($home)     = glob "~";
    my $default_cache_dir = "$home/.cache-historical";

    my $self = {
        sqlite_file => "$default_cache_dir/cache-historical.dat",
        %options,
    };

    my $cache_dir = dirname( $self->{sqlite_file} );

    if(! -d $cache_dir ) {
        mkpath [ $cache_dir ] or
            die "Cannot mktree $cache_dir ($!)";
    }

    bless $self, $class;

    $self->{dsn} = "dbi:SQLite:dbname=$self->{sqlite_file}";

    if(! -f $self->{sqlite_file}) {
        $self->db_init();
    }

    my $loader =
    Rose::DB::Object::Loader->new(
        db_dsn        => $self->{dsn},
        db_options    => { AutoCommit => 1, RaiseError => 1 },
        class_prefix  => 'Cache::Historical',
        with_managers => 1,
    );

    $loader->make_classes();

    $self->{loader} = $loader;

    return $self;
}

###########################################
sub make_modules {
###########################################
    my($self, @options) = @_;

    DEBUG "Making modules in @options";
    $self->{loader}->make_modules( @options );
}

###########################################
sub dbh {
###########################################
    my($self) = @_;

    if(! $self->{dbh} ) {
        $self->{dbh} = DBI->connect($self->{dsn}, "", "");
    }

    return $self->{dbh};
}

###########################################
sub db_init {
###########################################
    my($self) = @_;

    my $dbh = $self->dbh();

    DEBUG "Creating new SQLite db $self->{sqlite_file}";

    $dbh->do(<<'EOT');
CREATE TABLE vals (
  id       INTEGER PRIMARY KEY,
  date     DATETIME,
  upd_time DATETIME,
  key      TEXT,
  value    TEXT,
  UNIQUE(date, key)
);
EOT

    $dbh->do(<<'EOT');
CREATE INDEX vals_date_idx ON vals(date);
EOT

    $dbh->do(<<'EOT');
CREATE INDEX vals_key_idx ON vals(key);
EOT

    return 1;
}

###########################################
sub set {
###########################################
    my($self, $dt, $key, $value) = @_;

    DEBUG "Setting $dt $key => $value";

    my $r = Cache::Historical::Val->new();
    $r->key( $key );
    $r->date( $dt );
    $r->upd_time( DateTime->now() );
    $r->load( speculative => 1 );
    $r->value( $value );
    $r->save();
}

###########################################
sub get {
###########################################
    my($self, $dt, $key, $interpolate) = @_;

    my @date_query = (date => $dt);
    @date_query = (date => {le => $dt}) if $interpolate;

    my $values = Cache::Historical::Val::Manager->get_vals(
        query => [
          @date_query,
          key   => $key,
        ],
        sort_by  => "date DESC",
        limit => 1,
    );

    if(@$values) {
        my $value = $values->[0]->value();
        DEBUG "Getting $dt $key => $value";
        return $value;
    }

    return undef;
}

###########################################
sub keys {
###########################################
    my($self) = @_;

    my @keys;
    my $keys = Cache::Historical::Val::Manager->get_vals(
        distinct => 1,
        select   => [ 'key' ],
    );

    for(@$keys) {
        push @keys, $_->key();
    }

    return @keys;
}

###########################################
sub values {
###########################################
    my($self, $key) = @_;

    my @values = ();
    my @key = ();
    @key = (key => $key) if defined $key;

    my $values = Cache::Historical::Val::Manager->get_vals(
        query => [ @key ],
        sort_by => ['date'],
    );

    for(@$values) {
        push @values, [$_->date(), $_->value()];
    }

    return @values;
}

###########################################
sub last_update {
###########################################
    my($self, $key) = @_;

    my @key = ();
    @key = (key => $key) if defined $key;

    my $values = Cache::Historical::Val::Manager->get_vals(
        query => [ @key ],
        sort_by => ['upd_time DESC'],
        limit   => 1,
    );

    if(@$values) {
        my $date = $values->[0]->upd_time();
        return $date;
    }

    return undef;
}

###########################################
sub since_last_update {
###########################################
    my($self, $key) = @_;

    my $date = $self->last_update($key);

    if(defined $date) {
        return DateTime->now() - $date;
    }

    return undef;
}

###########################################
sub get_interpolated {
###########################################
    my($self, $dtp, $key) = @_;

    return $self->get($dtp, $key, 1);
}

my $date_fmt = DateTime::Format::Strptime->new(
                  pattern => "%Y-%m-%d %H:%M:%S");

###########################################
sub time_range {
###########################################
    my($self, $key) = @_;

    my $dbh = $self->dbh();

    my($from, $to) = $dbh->selectrow_array(
       "SELECT MIN(date), MAX(date) FROM vals WHERE key = " .
       $dbh->quote( $key ));

    $from = $date_fmt->parse_datetime( $from );
    $to   = $date_fmt->parse_datetime( $to );

    return($from, $to);
}

###########################################
sub clear {
###########################################
    my($self, $key) = @_;

    my @params = (all => 1);

    if(defined $key) {
        @params = ("where" => [ key => $key ]);
    }

    my $values = Cache::Historical::Val::Manager->delete_vals( @params );
}

1;

__END__

=head1 NAME

Cache::Historical - Cache historical values

=head1 SYNOPSIS

    use Cache::Historical;

    my $cache = Cache::Historical->new();
 
       # Set a key's value on a specific date
    $cache->set( $dt, $key, $value );

       # Get a key's value on a specific date
    my $value = $cache->get( $dt, $key ); 

       # Same as 'get', but if we don't have a value at $dt, but we 
       # do have values for dates < $dt, return the previous 
       # historic value. 
    $cache->get_interpolated( $dt, $key );

=head1 DESCRIPTION

Cache::Historical caches historical values by key and date. If you have
something like historical stock quotes, for example

    2008-01-02 msft 35.22
    2008-01-03 msft 35.37
    2008-01-04 msft 34.38
    2008-01-07 msft 34.61

then you can store them in Cache::Historical like

    my $cache = Cache::Historical->new();

    my $fmt = DateTime::Format::Strptime->new(
                  pattern => "%Y-%m-%d");

    $cache->set( $fmt->parse_datetime("2008-01-02"), "msft", 35.22 );
    $cache->set( $fmt->parse_datetime("2008-01-03"), "msft", 35.37 );
    $cache->set( $fmt->parse_datetime("2008-01-04"), "msft", 34.38 );
    $cache->set( $fmt->parse_datetime("2008-01-07"), "msft", 34.61 );

and retrieve them later by date:

    my $dt = $fmt->parse_datetime("2008-01-03");

      # Returns 35.37
    my $value = $cache->get( $dt, "msft" );

Even if there's no value available for a given date, but there are historical 
values that predate the requested date, C<get_interpolated()> will return
the next best historical value:

    my $dt = $fmt->parse_datetime("2008-01-06");

      # Returns undef, no value available for 2008-01-06
    my $value = $cache->get( $dt, "msft" );

      # Returns 34.48, the value for 2008-01-04, instead.
    $value = $cache->get_interpolated( $dt, "msft" );

=head2 Methods

=over 4

=item new()

Creates the object. Takes the SQLite file to put the date into as
an additional parameter:

    my $cache = Cache::Historical->new(
        sqlite_file => "/tmp/mydata.dat",
    );

The SQLite file defaults to 

    $HOME/.cache-historical/cache-historical.dat

so if you have multiple caches, you need to use different
SQLite files.

=item time_range()

       # List the time range for which we have values for $key
    my($from, $to) = $cache->time_range( $key );

=item keys()

       # List all keys
    my @keys = $cache->keys();

=item values()

       # List all the values we have for $key, sorted by date
       # ([$dt, $value], [$dt, $value], ...)
    my @results = $cache->values( $key );

=item clear()

       # Remove all values for a specific key
    $cache->clear( $key );

       # Clear the entire cache
    $cache->clear();

=item last_update()

       # Return a DateTime object of the last update of a given key
    my $when = $cache->last_update( $key );

=item since_last_update()

       # Return a DateTime::Duration object since the time of the last
       # update of a given key.
    my $since = $cache->since_last_update( $key );

=back

=head1 LEGALESE

Copyright 2007-2011 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <cpan@perlmeister.com>
