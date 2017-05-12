package CGI::Ex::Recipes::Cache;
use utf8;
use warnings;
use strict;
use Carp qw(croak);
use CGI::Ex::Dump qw(debug dex_warn ctrace dex_trace);
use Storable;
our $VERSION = '0.01';

sub new {
    my $class = shift || __PACKAGE__;
    my $args  = shift || {};
    $args->{expires}  ||= time + 3600;#one hour by default
    $args->{cache_hash} ||= {};
    $args->{dbh} || croak 'Please provide a database handle with a `cache` table in the database!';
    return bless {%$args}, $class;
}

#tries first the 'our %CACHE_HASH', then the database.
sub exists {
    my ($self,$key) = @_;
    1 if(exists $self->{cache_hash}{$key});
    0;
}

sub get {
    my ($self,$key) = @_;
    #dex_trace(); #debug $self;
    if(exists $self->{cache_hash}{$key}) {
        return $self->{cache_hash}{$key}{value};
    }
    #warn 'getting $key'.$key.' from database';
    my $row = $self->{dbh}->selectrow_hashref('SELECT * FROM cache WHERE id=?',{},$key) 
        || return undef;
    $self->{cache_hash}{$key} = $row;
    if($self->{cache_hash}{$key}{expires} < time ){
        #warn 'could not $key'.$key.' from database. data expired.';
        return undef;
    }
    return $self->{cache_hash}{$key}{value};
}

sub set {
    if (!$_[2]) { 
        croak 'Please provide a value to be set!';
    }
    #NOTE: compatible only with SQLITE and MySQL
    $_[0]->{dbh}->prepare(
        'REPLACE INTO `cache` (id, value, tstamp, expires) VALUES ( ?,?,?,? )'
    )->execute( $_[1], $_[2], time, ($_[3]?time+$_[3]:$_[0]->{expires}) );
}

sub clear {
    $_[0]->{cache_hash} = {};
    $_[0]->{dbh}->do('DELETE FROM `cache`')
        and $_[0]->{dbh}->do('VACUUM');

}

sub freeze {
    $_[0]->set( 
        $_[1], 
        ref $_[2] ? Storable::nfreeze($_[2]) : $_[2], 
        $_[3] || $_[0]->{expires},
    );
}

sub thaw {
    Storable::thaw( $_[0]->get($_[1]) ) ;
}


1;

__END__

=head1 NAME

CGI::Ex::Recipes::Cache - Naive caching in a database table

=head1 SYNOPSIS

Example from C<CGI::Ex::Recipes::Template::Menu::list_item()>:

    # ... somewhere at the beginning of a method/subroutine which does heavy computations
    if( $out = $app->cache->get($cache_key) ){ return $out; }
    # ... here are your heavy calculations spread accross many lines
    # making database calls generating HTML etc.
    # ... just before the return of the method
    #try cache support
    $app->cache->set($cache_key, $out);
    return $out;

=head1 DESCRIPTION

I found that when I cached in memory some output from CGI::Ex::Recipes::Template::Menu,
the performance under mod_perl jumped from: 

    ...
    Requests per second:    19.42 [#/sec] (mean)
    Time per request:       154.441 [ms] (mean)
    Time per request:       51.480 [ms] (mean, across all concurrent requests)
    Transfer rate:          67.73 [Kbytes/sec] received

to

    ...
    Requests per second:    42.99 [#/sec] (mean)
    Time per request:       69.792 [ms] (mean)
    Time per request:       23.264 [ms] (mean, across all concurrent requests)
    Transfer rate:          151.74 [Kbytes/sec] received

ApacheBench was invoked like this:

    berov@berovi:~> /opt/apache2/bin/ab -c3  -n300 http://localhost:8081/recipes/index.pl

Of cource this is copied and pasted from my shell. Your results will be different.

I searched CPAN and after realizing that there are too many alternatives I
decided to have some fun and write another one -- simple, stupid and naive.

After implementing my naive caching in a database table I have the following results:

    ...
    Requests per second:    58.35 [#/sec] (mean)
    Time per request:       51.418 [ms] (mean)
    Time per request:       17.139 [ms] (mean, across all concurrent requests)
    Transfer rate:          206.74 [Kbytes/sec] received

Not bad, I would say.

NOTE: 

    This module is not necessarily compatible with the L<Cache|Cache> interface nor near complete.

=head1 METHODS

head2 new

The constructor.

    our $cache_obj = CGI::Ex::Recipes::Cache->new(
        {cache_hash =>\%CACHE_HASH, dbh=>$dbh , expires =>3600*24 }
    );
    Arguments(a hashref):
        cache_hash: Applicaton-wide HASH reference.
                    useful only under mod_perl.
        dbh:        A DBI object.
        expires:    Default expiration for cache entries. Default:time + 3600(one hour)
    Returns:    $self - The cache object used in CGI::Ex::Recipes

=head2 exists

    my $bool = $cache->exists('somekey');

Checks for existence of a given key in C<$self-E<gt>{cache_hash}>.
Returns 1 on success, 0 otherwize.

=head2 get

    if( $out = $app->cache->get($cache_key) ){ return $out; }

Returns the value of a cache entry.
First tries to get it from the C<$self-E<gt>{cache_hash}> then tries to find it 
in the databse.
If the entry is not available or is C<expired>, returns C<undef>.

=head2 set

    $app->cache->set($cache_key, $value [,$expires]);

Inserts a cache entry in the C<cache> database table 
and returns the result of the operation.
    
    NOTE:underlying SQL code is currently compatible only with SQLITE and MySQL

The get/set methods DO NOT serialize complex data types. Use freeze/thaw as appropriate.

=head2 clear

Clears all entries from the <cache> table and C<VACUUM>S the database.
This method should be called immediately after you C<INSERT> or C<UPDATE> 
something in the database.

    #... in CGI::Ex::Recipes::Edit::finalize
    $self->append_path('view');
    $self->cache->clear;
    return 1;

It is an 'all or nothing' sollution.

=head2 freeze

    $app->cache->freze($cache_key, $struct [,$expires]);

Identical to 'set', except that c<$struct> may be any complex data type that will be
serialized via Storable.


=head2 thaw

    my $struct = $app->cache->thaw($cache_key);

Identical to 'get', except that it will return a complex data type that was
set via 'freeze'.

=head1 STORING COMPLEX OBJECTS

The set and get methods only allow for working with simple scalar types, 
but if you want to store more complex types they need to be serialized first. 
To assist with this, the freeze and thaw methods are provided.


=head1 TODO

Generalize the underlying SQL code


=head1 SEE ALSO

L<Cache|Cache> L<Cache::Entry|Cache::Entry>

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

