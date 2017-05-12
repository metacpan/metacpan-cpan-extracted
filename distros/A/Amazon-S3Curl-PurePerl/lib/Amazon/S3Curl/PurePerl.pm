package Amazon::S3Curl::PurePerl;

#ABSTRACT: Amazon::S3Curl::PurePerl - Pure Perl s3 helper/downloader.
use strict;
use warnings;

use Module::Runtime qw[ require_module ];

our $VERSION = "0.054";
$VERSION = eval $VERSION;

#For instances when you want to use s3, but don't want to install anything. ( and you have curl )
#Amazon S3 Authentication Tool for Curl
#Copyright 2006-2010 Amazon.com, Inc. or its affiliates. All Rights Reserved.
use Moo;
use POSIX;
use File::Spec;
use Log::Contextual qw[ :log :dlog set_logger ];
use Log::Contextual::SimpleLogger;
use Digest::SHA::PurePerl;
use MIME::Base64 qw(encode_base64);
use IPC::System::Simple qw[ capture ];
my $DIGEST_HMAC;
BEGIN {
    eval {
        require_module("Digest::HMAC");
        $DIGEST_HMAC = "Digest::HMAC";
    };
    if ($@) {    #They dont have Digest::HMAC, use our packaged alternative
        $DIGEST_HMAC = "Amazon::S3Curl::PurePerl::Digest::HMAC";
        require_module($DIGEST_HMAC);
    }
};


set_logger(
    Log::Contextual::SimpleLogger->new(
        {
            levels_upto => 'debug'
        } ) );


has curl => (
    is      => 'ro',
    default => sub { 'curl' }    #maybe your curl isnt in PATH?
);

for (
    qw[
    aws_access_key
    aws_secret_key
    ] )
{
    has $_ => (
        is       => 'ro',
        required => 1,
    );

}

has url => (
    is => 'ro',
    required => 1,
    isa => sub {
        $_[0] =~ m|^/| or die "$_[0] is not a relative url. Should be /bucketname/file"
      },
);

has local_file => (
    is => 'ro',
    required => 0,
    predicate => 1,
);

has static_http_date => (
    is => 'ro',
    required => 0,
);

has s3_scheme_host_url => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $env_var = $ENV{AMAZON_S3CURL_PUREPERL_SCHEME_HOST};
        return $env_var if defined $env_var;
        return 'https://s3.amazonaws.com'
    }
);

sub http_date {
    POSIX::strftime( "%a, %d %b %Y %H:%M:%S +0000", gmtime );
}

sub _req {
    my ( $self, $method, $url ) = @_;
    die "method required" unless $method;
    $url ||= $self->url;
    my $to_sign  = $url;
    my $resource = sprintf( "%s%s" , $self->s3_scheme_host_url, $url );
    my $keyId       = $self->aws_access_key;
    my $httpDate    = $self->static_http_date || $self->http_date;
    my $contentMD5  = "";
    my $contentType = "";
    my $xamzHeadersToSign = "";
    my $stringToSign      = join( "\n" =>
          ( $method, $contentMD5, $contentType, $httpDate, "$xamzHeadersToSign$to_sign" ) );
    my $hmac =
      $DIGEST_HMAC->new( $self->aws_secret_key, "Digest::SHA::PurePerl",
        64 );
    $hmac->add($stringToSign);
    my $signature = encode_base64( $hmac->digest, "" );
    return [
        $self->curl,
        -H => "Date: $httpDate",
        -H => "Authorization: AWS $keyId:$signature",
        -H => "content-type: $contentType",
        "-L",
        "-f",
        $resource,
    ];
}




sub download_cmd {
    my ($self) = @_;
    my $args = $self->_req('GET');
    push @$args, ( "-o", $self->local_file );
    return $args;
}

sub upload_cmd {
    my ($self) = @_;
    my $url = $self->url;
    #trailing slash for upload means curl will plop on the filename at the end, ruining the hash signature.
    if ( $url =~ m|/$| ) {
        my $file_name = ( File::Spec->splitpath( $self->local_file ) )[-1];
        $url .= $file_name;
    }
    my $args = $self->_req('PUT',$url);
    splice( @$args, $#$args, 0, "-T", $self->local_file );
    return $args;
}

sub delete_cmd {
    my $args = shift->_req('DELETE');
    splice( @$args, $#$args, 0, qw[ -X DELETE ] );
    return $args;
}

sub head_cmd {
    my $args = shift->_req('HEAD');
    splice( @$args, $#$args, 0, qw[ -I -X HEAD ] );
    return $args;
}

sub url_exists {
    my $self = shift;
    my @args = grep { !/-f/ } @{ $self->head_cmd }; #take out fail mode, want to parse and look for the 404.
    log_info { "running " . join( " ", @_ ) } @args;
    my @output = capture( @args );
    die "no output received!" unless @output;
    return 1 if $output[0] =~ /200 OK/;
    return 0 if $output[0] =~ /404 Not Found/;
    die "url_exists did not find a 200 or 404: $output[0]";
}

sub _exec {
    my($self,$method) = @_;
    my $meth = $method."_cmd";
    die "cannot $meth" unless $self->can($meth);
    my $args = $self->$meth;
    log_info { "running " . join( " ", @_ ) } @$args;
    capture(@$args);
    return 1;
}

sub download {
    return shift->_exec("download");
}

sub upload {
    return shift->_exec("upload");
}

sub delete {
    return shift->_exec("delete");
}

sub head {
    return shift->_exec("head");
}

sub _local_file_required {
    my $method = shift;
    sub {
        die "parameter local_file required for $method"
          unless shift->local_file;
    };
}

before download => _local_file_required('download');
before upload => _local_file_required('upload');
1;
__END__

=head1 NAME

Amazon::S3Curl::PurePerl - Pure Perl s3 helper/downloader.

=head1 VERSION

version 0.054

=head1 DESCRIPTION

This software is designed to run in low dependency situations.
You need curl, and you need perl ( If you are on linux, you probably have perl whether you know it or not ).

Maybe you're bootstrapping a system from s3,
or downloading software to a host where you can't/don't want to install anything.

=head1 SYNOPSIS

    my $s3curl = Amazon::S3Curl::PurePerl->new({
            aws_access_key => $ENV{AWS_ACCESS_KEY},
            aws_secret_key => $ENV{AWS_SECRET_KEY},
            local_file     => "/tmp/myapp.tgz",
            url            => "/mybootstrap-files/myapp.tgz"
    });
    $s3curl->download;

Using L<Object::Remote>:

    use Object::Remote;
    my $conn = Object::Remote->connect("webserver-3");

    my $s3_downloader = Amazon::S3Curl::PurePerl->new::on(
        $conn,
        {
            aws_access_key => $ENV{AWS_ACCESS_KEY},
            aws_secret_key => $ENV{AWS_SECRET_KEY},
            local_file     => "/tmp/myapp.tgz",
            url            => "/mybootstrap-files/myapp.tgz"
        } );

    $s3_downloader->download;

=head1 PARAMETERS

=over

=item aws_access_key ( required )

=item aws_secret_key ( required )

=item url ( required )

This is the (url to download|upload to|delete).
It should be a relative path with the bucket name, and whatever pseudopaths you want.

For upload:
Left with a trailing slash, it'll DWYM, curl style.

=item local_file

This is the (path to download to|file to upload).

=back


=head1 METHODS

=head2 new

Constructor, provided by Moo.


=head2 download

    $s3curl->download;

download url to local_file.

=head2 upload

    $s3curl->upload;

Upload local_file to url.

=head2 delete

    $s3curl->delete;

Delete url.

=head2 delete_cmd

=head2 download_cmd

=head2 upload_cmd

Just get the command to execute in the form of an arrayref, don't actually execute it:

    my $cmd = $s3curl->download_cmd;
    system(@$cmd);

=head2 url_exists

Check to see if a given url returns a 404 or 200. return 1 if 200, return 0 if 404, die otherwise.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AUTHOR AND CONTRIBUTORS

This distribution was
adapted by Samuel Kaufman L<skaufman@cpan.org> from the L<Amazon S3 Authentication Tool for Curl|http://aws.amazon.com/code/128>

   Amazon S3 Authentication Tool for Curl
   Copyright 2006-2010 Amazon.com, Inc. or its affiliates. All Rights Reserved.
