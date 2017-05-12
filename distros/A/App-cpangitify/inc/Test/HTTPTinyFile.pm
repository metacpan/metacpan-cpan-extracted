package Test::HTTPTinyFile;

use strict;
use warnings;
use HTTP::Tiny;
use HTTP::Date qw( time2str );
use URI;
use Test::More ();

my $request_method = \&HTTP::Tiny::request;

BEGIN { *note = \&Test::More::note }

my $request_wrapper = sub
{
  # TODO options to support 'If-Modified-Since' see PAUSE::Packages
  my($self, $method, $url, $args) = @_;
  my $uri = URI->new($url);
  
  note "HTTP::Tiny $method $url";
  
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
    note "HTTP::Tiny ", join(' ', $result->{success}, $result->{status}, $result->{reason});
    if($args->{data_callback})
    {
      $args->{data_callback}->($content, $result);
    }
    else
    {
      $result->{content} = $content;
    }
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

BEGIN { *note = \&Test::More::note }

sub TIEHASH
{
  my($class) = @_;
  bless {}, $class;
}

sub FETCH
{
  my($self, $key) = @_;
  note "header FETCH $key";
  $self->{$key};
}

sub STORE
{
  my($self, $key, $value) = @_;
  note "header STORE $key $value";
  $self->{$key} = $value;
}

sub DELETE
{
  my($self, $key) = @_;
  note "header DELETE $key";
  delete $self->{$key};
}

sub CLEAR
{
  my($self) = @_;
  note "header CLEAR";
  %$self = ();
}

sub EXISTS
{
  my($self, $key) = @_;
  note "header EXISTS $key";
  exists $self->{$key};
}

sub FIRSTKEY
{
  my($self) = @_;
  note "header FIRSTKEY";
  die "TODO";
}

sub NEXTKEY
{
  my($self, $lastkey) = @_;
  note "header NEXTKEY $lastkey";
  die "TODO";
}

sub SCALAR
{
  my($self) = @_;
  note "header SCALAR";
  scalar %$self;
}

sub DESTROY
{
  my($self) = @_;
  note "header DESTROY";
}

sub UNTIE
{
  my($self) = @_;
  note "header UNTIE";
}

1;
