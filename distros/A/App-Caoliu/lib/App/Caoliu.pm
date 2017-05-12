package App::Caoliu;

# ABSTRACT: a awsome module,suck greate fire wall!
use Mojo::Base "Mojo";
use Mojo::UserAgent;
use Mojo::Log;
use Mojo::Util;
use Mojo::URL;
use Mojo::Collection;
use Mojo::IOLoop;
use File::Basename;
use App::Caoliu::Parser;
use App::Caoliu::Downloader;
use App::Caoliu::Utils 'dumper';
no warnings 'deprecated';
no warnings 'recursion';

our $VERSION = 1.0;

use constant FEEDS => {
    WUMA  => 'http://t66y.com/rss.php?fid=2',
    YOUMA => 'http://t66y.com/rss.php?fid=15',
    OUMEI => 'http://t66y.com/rss.php?fid=4',
};
use constant DOWNLOAD_FILE_TIME => 1200;

has require_md5_path => 0;
has timeout          => 60;
has proxy            => '127.0.0.1:8087';
has log              => sub { Mojo::Log->new };
has category         => sub { [qw( wuma youma donghua oumei)] };
has parser           => sub { App::Caoliu::Parser->new };
has index            => 'http://t66y.com';
has downloader       => sub { App::Caoliu::Downloader->new };
has target           => '.';
has loop             => sub { Mojo::IOLoop->delay };
has parallel_num     => 20;

my @downloaded_files;

sub new {
    my $self = shift->SUPER::new(@_);

    Carp::croak("category args must be arrayref")
      if ref $self->category ne ref [];
    $self->downloader->ua->http_proxy(
        join( '', 'http://sri:secret@', $self->proxy ) )
      if $self->proxy;
    $ENV{LOGGER} = $self->log;

    return $self;
}

sub reap {
    my $self = shift;
    my $category = shift || $self->category;

    return if not scalar @{ $self->category };

    my @download_links;
    my @feeds = map { FEEDS->{ uc $_ } } @{ $self->category };
    $self->log->debug( "show feeds: " . dumper \@feeds );

    # fetch all rmdown_link
    # parallel get post page and download bt files
    $self->_non_blocking_get_torrent(@feeds);
    unless ( Mojo::IOLoop->is_running ) {
        $self->loop->wait;
        $self->log->debug(
            "Downloaded files list:" . dumper [@downloaded_files] );
        return wantarray ? @downloaded_files : scalar(@downloaded_files);
    }
}

sub _non_blocking_get_torrent {
    my ( $self, @feeds ) = @_;

    for my $feed (@feeds) {
        $self->loop->begin;
        $self->downloader->ua->get(
            $feed => sub {
                $self->_process_feed(@_);
            }
        );
    }
}

sub _process_feed {
    my ( $self, $ua, $tx ) = @_;
    my @posts;
    my $processer;

    if ( $tx->success ) {
        my $xml             = $tx->res->body;
        my $post_collection = $self->parser->parse_rss($xml);
        $processer = sub {
            for (@_) {
                $ua->get( $_->{link} => sub { $self->_process_posts(@_) } );
            }
        };
        $processer->( @{$post_collection} );
    }
}

sub _process_posts {
    my ( $self, $ua, $tx ) = @_;
    my $post_hashref;

    if ( $tx->success ) {
        $post_hashref = $self->parser->parse_post( $tx->res->body );
        $post_hashref->{source} = $tx->req->url->to_string;

        if ( my $download_link = $post_hashref->{rmdown_link} ) {

            # set a alarm clock,when async download,perhaps program will block
            # here,and every thread will block...
            eval {
                local $SIG{ALRM} = sub { die "TIMEOUT" };
                alarm DOWNLOAD_FILE_TIME;
                my $retry_times = 3;
                while ($retry_times) {
                    my $file =
                      $self->downloader->download_torrent( $download_link,
                        $self->target, { md5_dir => 0 } );
                    $post_hashref->{bt} = $file;
                    last if $file;
                    if ( $retry_times == 1 ) {
                        sleep 3;
                    }
                    if ( $retry_times == 2 ) {
                        sleep 1;
                    }
                    $retry_times--;
                }
                alarm 0;
            };
            if ( $@ =~ m/TIMEOUT/ ) {
                $self->log->error( "Download file timeout ..... in "
                      . $post_hashref->{rmdown_link} );
            }
            if ($@) { $self->log->error($@); }
        }
        push @downloaded_files, $post_hashref;
    }
}

1;
__END__

=pod

=encoding utf8

=head1 NAME App::Caoliu

=head1 DESCRIPTION

If you are the fans of 1024 bbs,you should know what I did for it.After you learn
this module,you will feel very happy to make communication to 1024 bbs.
OK,I don't want to see any more,just follow me step by step.
Let's rock!!!

=head1 SYNOPSIS
    
    use App::Caoliu;
    use 5.010;
    # reap the torrent from a category
    my $c = App::Caoliu->new( category => ['wuma'],target => '/tmp');
    # set proxy,if you have installed go-agent or some other proxy softwares
    # because the gfw often suck 1024 bbs
    $c->proxy('127.0.0.1:8087');
    
    # when in scalar env ,return the count number of downloaded files        
    say "total downloaded ".scalar($c->reap)." torrent files";
    use App::Caoliu::Utils 'dumper';

    # when under list env,return the file list
    my @reaped = $c->reap;

    # reap only one link;
    my $link = 'http://t66y.com/htm_data/2/1309/956691.html';
    my $post_href =
      $c->parser->parse_post( $c->downloader->ua->get($link)->res->body );
    my $file = $c->downloader->download_torrent( $post_href->{rmdown_link},
        $c->target, { md5_dir => 0 } );
    say "I got the file $file";

    # set log
    $c->log->path('/tmp/xx.log');
    $c->log->level('debug');

    # download image
    my @images = $c->downloader->download_image(
        path => '.',
        imgs => ['http://example.com/xx.jpg','http://example.com/yy.jpg'],
    );
    my $count = $c->downloader->download_image(
        path => '.',
        imgs => ['http://example.com/xx.jpg','http://example.com/yy.jpg'],
    );

=head1 new 
    
create a caoliu object,like as:

    my $caoliu = App::Caoliu->new;

=head1 reap 

reap the file which should be downloaded.

=head1 require_md5_path

set this will make the md5 path:
    
    $caoliu->require_md5_path(1);
    say $caoliu->require_md5_path;

=head1 proxy

set the caoliu proxy address

    $caoliu->proxy('127.0.0.1:8087');
    say $caoliu->proxy;

=head1 downloader

set or get the caoliu downloader object:

    say $caoliu->downloader;
    $caoliu->downloader( App::Caoliu::Downloader->new );

=head1 parser 

set or get the caoliu parser object

    $caoliu->parser;
    $caoliu->parser( App::Caoliu::Parser->new );

=head1 target 

set or get target path

    $caoliu->target('/tmp');
    $caoliu->target;

=head1 category

set or get category 

    $caoliu->category;
    $caoliu->category([qw(wuma youma)]);

=head1 log

set App::caoliu log

    $caoliu->log->debug("hello world");
    $caoliu->log->path('/tmp');
    $caoliu->log->level('debug');

=cut
