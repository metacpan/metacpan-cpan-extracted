package CPAN::Webserver;
use CPAN::Mirror::Finder;
use Moose;
use LWP::Simple;
use Path::Class;
extends 'CPAN::Mini::Webserver';
our $VERSION = '0.01';

has 'cpan_mirror' => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    default => sub {
        my $finder = CPAN::Mirror::Finder->new;
        return ( $finder->find_all_mirrors )[0];
    }
);

sub to_app {
    my ($self) = @_;

    $self = $self->new unless ref($self);

    $self->after_setup_listener;

    return CGI::Emulate::PSGI->handler(
        sub {
            CGI::initialize_globals();
            my $cgi = CGI->new;
            return $self->handle_request($cgi);
        }
    );
}

around send_http_header => sub {
    my ( $orig, $self, $code, %params ) = @_;

    $params{'-status'} = $code;
    return $self->$orig( $code, %params );
};

# this is a hook that HTTP::Server::Simple calls after setting up the
# listening socket. we use it load the indexes
override after_setup_listener => sub {
    my ( $self, $cache_dir ) = @_;
    my $CPAN = $self->cpan_mirror;

    my %cache_opts = ( ttl => 60 * 60 );
    $cache_opts{directory} = $cache_dir if $cache_dir;
    my $cache = App::Cache->new( \%cache_opts );

    my $directory = $cache->directory;
    $self->directory($directory);

    my $authors_url       = "$CPAN/authors/01mailrc.txt.gz";
    my $authors_filename  = file( $directory, '01mailrc.txt.gz' );
    my $packages_url      = "$CPAN/modules/02packages.details.txt.gz";
    my $packages_filename = file( $directory, '02packages.details.txt.gz' );
    my $whois_url         = "$CPAN/authors/00whois.xml";
    my $whois_filename    = file( $directory, '00whois.xml' );

    $self->mirror_url( $authors_url,  $authors_filename );
    $self->mirror_url( $packages_url, $packages_filename );
    $self->mirror_url( $whois_url,    $whois_filename );

    $self->author_type('Authors');
    my $parse_cpan_authors = $cache->get_code( 'parse_cpan_authors',
        sub { Parse::CPAN::Authors->new( $authors_filename->stringify ) } );

    my $parse_cpan_packages = $cache->get_code( 'parse_cpan_packages',
        sub { Parse::CPAN::Packages->new( $packages_filename->stringify ) } );

    $self->parse_cpan_authors($parse_cpan_authors);
    $self->parse_cpan_packages($parse_cpan_packages);

    my $scratch = dir( $cache->scratch );
    $self->scratch($scratch);

    my $index = CPAN::Mini::Webserver::Index->new;
    $self->index($index);
    $index->create_index( $parse_cpan_authors, $parse_cpan_packages );
};

around list_files => sub {
    my ( $orig, $self, $distribution ) = @_;
    my $CPAN = $self->cpan_mirror;

    #    warn "list_files $distribution";

    my $url = "$CPAN/authors/id/" . $distribution->prefix;
    my $filename
        = file( $self->directory, 'authors', 'id', $distribution->prefix );
    $self->mirror_url( $url, $filename );

    $self->$orig($distribution);
};

override get_file_from_tarball => sub {
    my ( $self, $distribution, $filename ) = @_;
    my $CPAN = $self->cpan_mirror;

    #    warn "get_file_from_tarball: $distribution -> $filename";

    my $url = "$CPAN/authors/id/" . $distribution->prefix;
    my $destination_filename
        = file( $self->directory, 'authors', 'id', $distribution->prefix );
    $self->mirror_url( $url, $destination_filename );

    my $peek = Archive::Peek->new( filename => $destination_filename );
    my $contents = $peek->file($filename);
    return $contents;
};

sub mirror_url {
    my ( $self, $url, $filename ) = @_;
    my $CPAN = $self->cpan_mirror;

    #    warn "mirror $url -> $filename";

    $filename->parent->mkpath;
    my $status = mirror( $url, $filename );
    if ( is_error($status) ) {
        warn "Error fetching $url: $status";
    }
}

1;

__END__
 
=head1 NAME

CPAN::Webserver - Browse and search CPAN locally

=head1 SYNOPSIS

  % cpan_webserver

=head1 DESCRIPTION

This module allows you to browse and search a CPAN mirror. It automatically
tries to find a locally-configured CPAN mirror using L<CPAN::Mirror::Finder>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or
modify it under the same terms as Perl itself.
