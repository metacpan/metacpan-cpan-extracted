package CPAN::Source;
use warnings;
use strict;
use feature qw(say);
use Try::Tiny;
use URI;
use Mouse;
use Compress::Zlib;
use LWP::UserAgent;
use XML::Simple qw(XMLin);
use Cache::File;
use DateTime;
use DateTime::Format::HTTP;
use CPAN::DistnameInfo;
use YAML::XS;
use JSON::XS;

use CPAN::Source::Dist;
use CPAN::Source::Package;

use constant { DEBUG => $ENV{DEBUG} };

our $VERSION = '0.04';


# options ...

has cache_path => 
    is => 'rw',
    isa => 'Str';

has cache_expiry => 
    is => 'rw';

has cache =>
    is => 'rw';

has mirror =>
    is => 'rw',
    isa => 'Str';

has source_mirror =>
    is => 'rw',
    isa => 'Str',
    default => sub { 'http://cpansearch.perl.org/' };


# data accessors
has authors => 
    is => 'rw',
    isa => 'HashRef';


# dist info from CPAN::DistnameInfo
has dists =>
    is => 'rw',
    isa => 'HashRef',
    default => sub {  +{  } };

has packages => 
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{  } };

has packagelist_meta =>
    is => 'rw',
    isa => 'HashRef';

has modlist => 
    is => 'rw',
    isa => 'HashRef';

has mailrc =>
    is => 'rw',
    isa => 'HashRef';

has stamp => 
    is => 'rw',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my $content = $self->fetch_stamp;
        my ( $ts , $date ) = split /\s/,$content;
        return DateTime->from_epoch( epoch => $ts );
    };

has mirrors =>
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub { 
        my $self = shift;
        return unless $self->mirror;
        # get 07mirror.json
        my $json = $self->fetch_mirrors;
        my $data = decode_json( $json );
        return $data;
    };

sub debug { 
    say "[DEBUG] " ,@_ if DEBUG;
}

sub BUILD {
    my ($self,$args) = @_;
    if( $args->{ cache_path } ) {
        my $cache = Cache::File->new( 
            cache_root => $args->{cache_path},
            default_expires => $args->{cache_expiry} || '3 minutes' );
        $self->cache( $cache );
    }

    $|++ if DEBUG;
}

sub prepare {
    my ($self) = @_;
    $self->prepare_authors;
    $self->prepare_mailrc;
    $self->prepare_package_data;
    $self->prepare_modlist;
}

sub prepare_authors {
    my $self = shift;

    debug "Prepare authors data...";

    my $authors = $self->fetch_whois;

    $self->authors( $authors );
    return $authors;
}

sub prepare_mailrc {
    my $self = shift;
    debug "Prepare mailrc data...";
    my $mailrc_txt = $self->fetch_mailrc;
    $self->mailrc( $self->parse_mailrc( $mailrc_txt ) );
}

sub prepare_package_data {
    my $self = shift;

    debug "Prepare pacakge data...";
    $self->fetch_package_data;
    return { 
        meta => $self->packagelist_meta,
        packages => $self->packages,
    };
}


sub prepare_modlist {
    my $self = shift;
    debug "Prepare modlist data...";
    my $modlist_txt = _decode_gzip( $self->fetch_modlist_data );

    debug "Parsing modlist data...";
    $self->modlist( $self->parse_modlist( $modlist_txt ) );
}

sub recent {
    my ($self,$period) = @_;
    my $json = $self->fetch_recent( $period );
    return decode_json( $json );
}

sub parse_modlist { 
    my ($self,$modlist_data) = @_;

    debug "Building modlist data ...";

    my @lines = split(/\n/,$modlist_data);
    splice @lines,0,10;
    $modlist_data = join "\n", @lines;
    eval $modlist_data;
    return CPAN::Modulelist->data;
}

sub parse_mailrc { 
    my ($self,$mailrc_txt) = @_;

    debug "Parsing mailrc ...";

    my @lines = split /\n/,$mailrc_txt;
    my %result;
    for ( @lines ) {
        my ($abbr,$name,$email) = ( $_ =~ m{^alias\s+(.*?)\s+"(.*?)\s*<(.*?)>"} );
        $result{ $abbr } = { name => $name , email => $email };
    }
    return \%result;
}


sub purge_cache {
    my $self = shift;
    $self->cache->purge;
}

sub fetch_stamp {
    my $self = shift;
    my $content = $self->http_get( $self->mirror . '/modules/02STAMP' );
    return $content;
}

sub fetch_mirrors {
    my $self = shift;
    return $self->http_get( $self->mirror . '/modules/07mirror.json' );
}

sub fetch_mailrc {
    my $self = shift;
    my $gz = $self->http_get( $self->mirror . '/authors/01mailrc.txt.gz');
    return _decode_gzip($gz);
}

sub fetch_package_data {
    my $self = shift;
    my $gz =  $self->http_get( $self->mirror . '/modules/02packages.details.txt.gz' );
    my $content = _decode_gzip($gz);

    debug "Parsing package data...";

    my @lines = split /\n/,$content;

    # File:         02packages.details.txt
    # URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
    # Description:  Package names found in directory $CPAN/authors/id/
    # Columns:      package name, version, path
    # Intended-For: Automated fetch routines, namespace documentation.
    # Written-By:   PAUSE version 1.14
    # Line-Count:   93553
    # Last-Updated: Thu, 08 Sep 2011 13:38:39 GMT

    my $meta = {  };

    # strip meta tags
    my @meta_lines = splice @lines,0,9;
    for( @meta_lines ) {
        next unless $_;
        my ($attr,$val) = m{^(.*?):\s*(.*?)$};
        $meta->{$attr} = $val;

        debug "meta: $attr => $val ";
    }

    $meta->{'URL'} = URI->new( $meta->{'URL'} );
    $meta->{'Line-Count'} = int( $meta->{'Line-Count'} );
    $meta->{'Last-Updated'} = 
          DateTime::Format::HTTP->parse_datetime( $meta->{'Last-Updated'} );

    my $packages = {  };
    my $cnt = 0;
    my $size = scalar @lines;

    debug "Loading CPAN::DistnameInfo ...";

    local $|;

    for ( @lines ) {
        my ($package_name,$version,$path) = split /\s+/;

        printf("\r[% 7d/%d] " , ++$cnt , $size ) if DEBUG;

        $version = undef if $version eq 'undef';

        my $tar_path = $self->mirror . '/authors/id/' . $path;
        my $dist;

        # debug "Processing $package_name from $tar_path...";

        # Which parses informatino from dist path
        my $d = CPAN::DistnameInfo->new( $tar_path );
        if( $d->version ) {
            # register "Foo-Bar" to dists hash...
            $dist = $self->new_dist( $d , $package_name );
            $self->dists->{ $dist->name } = $dist 
                unless $self->dists->{ $dist->name };
        }

        # Moose::Foo => {  ..... }
        $self->packages->{ $package_name } = CPAN::Source::Package->new({
            package   => $package_name,
            version   => $version,
            path      => $tar_path,
            dist      => $dist,
        });
    }

    $self->packagelist_meta( $meta );
}

sub fetch_modlist_data {
    my $self = shift;
    return $self->http_get( $self->mirror . '/modules/03modlist.data.gz' )
}

sub fetch_whois {
    my $self = shift;

    if( $self->cache ) {
        my $c = $self->cache->get('json_00whois.xml');
        return decode_json($c) if $c;
    }

    my $xml = $self->http_get( $self->mirror . '/authors/00whois.xml');

    debug "Parsing authors data...";

    my $authors = XMLin( $xml )->{cpanid};

    # cache this with json
    if( $self->cache ) {
        $self->cache->set('json_00whois.xml', encode_json($authors) );
    }
    return $authors;
}

sub fetch_module_rss { 
    my $self = shift;
    my $rss_xml = $self->http_get( $self->mirror . '/modules/01modules.mtime.rss' );
    return $rss_xml;
}

sub fetch_recent {
    my ($self,$period) = @_;
    $period ||= '1d';

    # http://search.cpan.org/CPAN/RECENT-1M.json
    # http://ftp.nara.wide.ad.jp/pub/CPAN/RECENT-1M.json
    return $self->http_get( $self->mirror . '/RECENT-'. $period .'.json' );
}

sub module_source_path {
    my ($self,$d) = ($_[0], $_[1]);
    return undef unless $d->distvname;
    return ( $self->source_mirror . '/src/' . $d->cpanid . '/' . $d->distvname );
}


sub author {
    my ($self,$pause_id) = @_;
    return $self->authors->{ $pause_id };
}

# return package obj
sub package {
    my ($self,$pkgname) = @_;
    return $self->packages->{ $pkgname };
}

# return dist
sub dist { 
    my ($self,$distname) = @_;
    $distname =~ s/::/-/g;
    return $self->dists->{ $distname };
}

sub http_get { 
    my ($self,$url,$cache_expiry) = @_;

    if( $self->cache ) {
        my $c = $self->cache->get( $url );
        return $c if $c;
    }

    my $content;
    if( -e $url ) {
        debug "Reading file $url ...";
        local $/;
        open FH , '<' , $url;
        $content = <FH>;
        close FH;
    } else {
        debug "Downloading $url ...";
        my $ua = $self->new_ua;
        my $resp = $ua->get($url);
        $content = $resp->content;
    }
    $self->cache->set( $url , $content , $cache_expiry ) if $self->cache;
    return $content;
}


sub new_dist {
    my ($self,$d, $package_name) = @_;
    my %props = $d->properties;
    my $dist = CPAN::Source::Dist->new({
        %props,  # Hash
        name => $props{dist},  # Dist-Name
        version_name => $props{distvname},
        package_name => $package_name,
        source_path => $self->module_source_path($d),
        _parent => $self,
    });
    return $dist;
}

sub new_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    return $ua;
}

sub _decode_gzip {
    return Compress::Zlib::memGunzip( $_[0] );
}

1;
__END__
=pod

=head1 NAME

CPAN::Source - CPAN source list data aggregator.

=head1 DESCRIPTION

L<CPAN::Source> fetch, parse, aggregate all CPAN source list for you.

Currently CPAN::Source supports 4 files from CPAN mirror. (00whois.xml,
contains cpan author information, 01mailrc.txt contains author emails, 
02packages.details.txt contains package information, 03modlist contains distribution status)

L<CPAN::Source> aggregate those data, and information can be easily retrieved.

The distribution info is from L<CPAN::DistnameInfo>.

=head1 SYNOPSIS

    my $source = CPAN::Source->new(  
        cache_path => '.cache',
        cache_expiry => '7 days',
        mirror => 'http://cpan.nctu.edu.tw',
        source_mirror => 'http://cpansearch.perl.org'
    );

    $source->prepare;   # use LWP::UserAgent to fetch all source list files ...

    # 00whois.xml
    # 01mailrc
    # 02packages.details.txt
    # 03modlist

    $source->dists;  # all dist information
    $source->authors;  # all author information

    for my $dist ( @{ $source->dists } ) {

    }

    for my $author ( @{ $source->authors ) {

    }

    for my $package ( @{ $source->packages } ) {

    }

    $source->packages;      # parsed package data from 02packages.details.txt.gz
    $source->modlist;       # parsed package data from 03modlist.data.gz
    $source->mailrc;        # parsed mailrc data  from 01mailrc.txt.gz


    my $dist = $source->dist('Moose');
    my $distname = $dist->name;
    my $distvname = $dist->version_name;
    my $version = $dist->version;  # attributes from CPAN::DistnameInfo
    my $meta_data = $dist->fetch_meta();

    $meta_data->{abstract};
    $meta_data->{version};
    $meta_data->{resources}->{bugtracker};
    $meta_data->{resources}->{repository};

    my $readme = $dist->fetch_readme;
    my $changes = $dist->fetch_changes;


    my $pkg = $source->package( 'Moose' );
    my $pm_content = $pkg->fetch_pm();


    my $mirror_server_timestamp = $source->stamp;  # DateTime object

=head1 ACCESSORS

=for 4

=item authors

Which is a hashref, contains:

    {
        {pauseId} => { ... }
    }

=item package_data

Which is a hashref, contains:

    { 
        meta => { 
            File => ...
            URL => ...
            Description => ...
            Line-Count => ...
            Last-Updated => ...
        },
        packages => { 
            'Foo::Bar' => {
                package   => 'Foo::Bar',
                version   =>  0.01 ,
                path      =>  tar path,
                dist      =>  dist name
            }
            ....
        }
    }

=back

=head1 METHODS

=head2 new( OPTIONS )


=head2 prepare_authors

=head2 prepare_mailrc

=head2 prepare_modlist

Download 03modlist.data.gz and parse it.

=head2 prepare_package_data

Download 02packages.details.gz and parse it.

=head2 module_source_path

Return full-qualified source path. built from source mirror, the default source mirror is L<http://cpansearch.perl.org>.

=head2 mirrors 

Return mirror info from mirror site. (07mirrors.json)

=head2 fetch_whois

=head2 fetch_mailrc

=head2 fetch_package_data

=head2 fetch_modlist_data

=head2 fetch_mirrors

=head2 fetch_module_rss

Return modules rss, from {Mirror}/modules/01modules.mtime.rss

=head2 fetch_recent( $period )

Fetch recent updated modules,

    my $list = $source->fetch_recent( '1d' );
    my $list = $source->fetch_recent( '1M' );

=head2 dist( $name )

return L<CPAN::Source::Dist> object.

=head2 http_get

Use L<LWP::UserAgent> to fetch content.

=head2 new_dist

Convert L<CPAN::DistnameInfo> into L<CPAN::Source::Dist>.

=head2 purge_cache 

Purge cache.

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
