package App::Caoliu::Downloader;

# ABSTRACT: caoliu download tool
use Mojo::Base 'Mojo';
use Carp;
use Mojo::UserAgent;
use Mojo::Util;
use File::Spec;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Mojo::IOLoop;
use Mojo::Collection;
use Mojo::Log;
use Time::HiRes qw(sleep);
use App::Caoliu::Utils qw(abs_file dumper);

# defined constant var
sub RM_DOWNLOAD_PHP () { 'http://www.rmdown.com/download.php' }

has ua => sub { Mojo::UserAgent->new->max_redirects(5) };
has timeout => 60;
has rmdown  => 'http://www.rmdown.com';
has proxy   => '127.0.0.1:8087';
has agent =>
'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.802.30 Safari/535.1 SE 2.X MetaSr 1.0';
has log => sub { Mojo::Log->new };

sub download_torrent {
    my ( $self, $url, $path, $attr ) = @_;
    my $require_md5_path = $attr->{md5_dir};

    Carp::croak("please input the torrent url link") unless $url;
    Carp::croak("path not exists: $path") unless -e $path;

    return unless $url =~ m{rmdown};

    my $headers = {
        User_Agent   => $self->agent,
        Referer      => $url,
        Origin       => $self->rmdown,
        Content_Type => 'form-data',
    };
    my $post_form = {};

    # get refvalue and reffvalue for post_form
    my $ua = Mojo::UserAgent->new( max_redirects => 5 );
    my $tx = $ua->get( $url => $headers );
    if ( my $res = $tx->success ) {
        my $html = $res->body;
        if ( $html =~ m/(<INPUT.+?name=['"]?ref['"]?.*?>)/gi ) {
            my $tmp = $1;
            $post_form->{ref} = $1
              if ( $tmp =~ m/(?<=value=)["']?([^\s>'"]+)/gi );
        }
        if ( $html =~ m/(<INPUT.+?name=['"]?ref['"]?.*?>)/gi ) {
            my $tmp = $1;
            $post_form->{reff} = $1
              if ( $tmp =~ m/(?<=value=)["']?([^\s>'"]+)/gi );
        }
    }
    else {
        $self->log->error("get reffvalue failed,check ....");
        return;
    }

    # construct post_from and submit post request to rmdownload
    # download file here, and return filename md5
    $post_form->{submit} = 'download';
    $self->log->debug(
        "send http_reqeust to rmdown with form" . dumper($post_form) );
    $tx = $ua->post( +RM_DOWNLOAD_PHP, $headers => form => $post_form );
    if ( $tx->success ) {
        $self->log->debug("post rmdownload link successful!");

        #if ( $tx->res->headers->content_disposition =~
        my $cd = $tx->res->headers->content_disposition;
        return unless $cd;
        if ( $cd =~ m/(?<=filename=)["']?([^\s>'"]+)/gi ) {
            my $tmpfile = $1;
            $self->log->debug("get tmpfile name => $tmpfile");
            my ($hash_md5) = fileparse( $tmpfile, qr/\.[^.]*/ );
            my $file_path =
              $require_md5_path
              ? File::Spec->catfile( $path, $hash_md5, $tmpfile )
              : File::Spec->catfile( $path, $tmpfile );
            if ( -e $file_path ) {
                $self->log->debug("this path:$file_path is exists ,next....");
                return $file_path;
            }
            else {
                make_path dirname($file_path);
                $self->log->debug( "make_path => " . dirname($file_path) );
                return
                  unless $tx->res->content->asset->move_to($file_path);
                return $file_path;
            }
        }
    }
    else {
        $self->log->error( "download failed,return response" . $tx->res->body );
    }

    return;
}

sub move_file {
    my ( $self, $ua, $url, $target ) = @_;

    my $retry_times = 3;
    while ($retry_times) {
        my $tx = $ua->get($url);
        if ( $tx->success ) {
            $tx->res->content->asset->move_to($target);
            last;
        }
        if ( $retry_times == 2 ) {
            sleep(1.5);
        }
        if ( $retry_times == 1 ) {
            sleep(0.5);
        }
        $retry_times--;
    }
    return 1;
}

sub download_image {
    my ( $self, %arg ) = @_;
    my $path           = delete $arg{path};
    my $img_collection = delete $arg{imgs};

    my $ua    = Mojo::UserAgent->new;
    my $delay = Mojo::IOLoop->delay;
    for my $img ( $img_collection->each ) {
        my $img_path = File::Spec->catfile( $path, ( split( '/', $img ) )[-1] );
        unless ( -e $img_path ) {
            my $end = $delay->begin;
            $self->ua->get(
                $img => sub {
                    my ( $ua, $tx ) = @_;
                    $tx->res->content->asset->move_to($img_path);
                    $self->log->debug("Download img : $img_path");
                }
            );
            $end->();
        }
    }
    $delay->wait unless Mojo::IOLoop->is_running;
}

sub parallel_get {
    my ( $self, $cb ) = ( shift, pop );
    my @urls = @_;

    return unless @urls;

    # Blocking parallel requests (does not work inside a running event loop)
    my $delay = Mojo::IOLoop->delay;
    for my $url (@urls) {
        my $end = $delay->begin;
        $self->ua->get(
            $url => sub {
                my ( $ua, $tx ) = @_;
                eval {
                    if ( my $res = $tx->success ) {
                        $end->send( $cb->( $res->body ) );
                    }
                    else {
                        $self->log->error("parallel get url => $_ failed");
                    }
                };
                $end->();
            }
        );
    }
    return Mojo::Collection->new( $delay->wait );
}

1;
