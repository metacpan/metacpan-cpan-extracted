package Test2::Plugin::HTTPTinyFile;

use strict;
use warnings;
use HTTP::Tiny;
use HTTP::Date qw( time2str );
use URI;
use Test2::API qw( context );

my $request_method = \&HTTP::Tiny::request;

my $request_wrapper = sub
{
  # TODO options to support 'If-Modified-Since' see PAUSE::Packages
  my($self, $method, $url, $args) = @_;
  my $uri = URI->new($url);

  my $ctx = context();
  $ctx->note("HTTP::Tiny $method $url");


  if($uri->scheme eq 'file')
  {
    tie my %headers, 'Test::HTTPTinyFile::ResponseHeaderTie';
    my $path = $uri->path;
    $path =~ s{^/([A-Za-z]:)}{$1} if $^O eq 'MSWin32';
    my $result = { url => $url, content => '', headers => \%headers }; # TODO include some headers
    my $content = '';

    if($method =~ /(GET|HEAD)/)
    {
      if(-d $path)
      {
        die "TODO";
      }
      elsif(-r $path)
      {
        if($method eq 'GET')
        {
          eval {
            use autodie;
            open my $fh, '<', $path;
            binmode $fh;
            local $/;
            $content = <$fh> if $method eq 'GET';
            close $fh;
          };
          if($@)
          {
            $result->{success} = 0;
            $result->{status} = 599;
            $result->{reason} = 'Internal Exception';
          }
        }
        unless(defined $result->{success})
        {
          $result->{success} = 1;
          $result->{status}  = 200;
          $result->{reason}  = 'OK';
          $headers{'last-modified'} = time2str((stat $path)[9]);
        }
      }
      elsif(-e $path)
      {
        $result->{success} = 0;
        $result->{status}  = 403;
        $result->{reason}  = 'Forbidden';
      }
      else
      {
        $result->{success} = 0;
        $result->{status}  = 404;
        $result->{reason}  = 'Not Found';
      }
    }
    elsif($method eq 'POST')
    {
      die "TODO";
    }
    elsif($method eq 'PUT')
    {
      die "TODO";
    }
    elsif($method eq 'DELETE')
    {
      die "TODO";
    }
    else
    {
      die "unknown HTTP method: $method";
    }
    $ctx->note("HTTP::Tiny ", join(' ', $result->{success}, $result->{status}, $result->{reason}));
    if($args->{data_callback})
    {
      $args->{data_callback}->($content, $result);
    }
    else
    {
      $result->{content} = $content;
    }
    $ctx->release;
    return $result;
  }
  else
  {
    $request_method->(@_);
  }
};

do { no warnings; *HTTP::Tiny::request = $request_wrapper };

package
  Test::HTTPTinyFile::ResponseHeaderTie;

use Test2::API qw( context );

sub TIEHASH
{
  my($class) = @_;
  bless {}, $class;
}

sub FETCH
{
  my($self, $key) = @_;
  my $ctx = context();
  $ctx->note("header FETCH $key");
  $ctx->release;
  $self->{$key};
}

sub STORE
{
  my($self, $key, $value) = @_;
  my $ctx = context();
  $ctx->note("header STORE $key $value");
  $ctx->release;
  $self->{$key} = $value;
}

sub DELETE
{
  my($self, $key) = @_;
  my $ctx = context();
  $ctx->note("header DELETE $key");
  $ctx->release;
  delete $self->{$key};
}

sub CLEAR
{
  my($self) = @_;
  my $ctx = context();
  $ctx->note("header CLEAR");
  $ctx->release;
  %$self = ();
}

sub EXISTS
{
  my($self, $key) = @_;
  my $ctx = context();
  $ctx->note("header EXISTS $key");
  $ctx->release;
  exists $self->{$key};
}

sub FIRSTKEY
{
  my($self) = @_;
  die "TODO";
}

sub NEXTKEY
{
  my($self, $lastkey) = @_;
  die "TODO";
}

sub SCALAR
{
  my($self) = @_;
  my $ctx = context();
  $ctx->note("header SCALAR");
  $ctx->release;
  scalar %$self;
}

sub DESTROY
{
  my($self) = @_;
  my $ctx = context();
  $ctx->note("header DESTROY");
  $ctx->release;
}

sub UNTIE
{
  my($self) = @_;
  my $ctx = context();
  $ctx->note("header UNTIE");
  $ctx->release;
}

1;
