
package ASP4::SimpleCGI;

use strict;
use warnings 'all';
use HTTP::Body;


sub new
{
  my ($s, %args) = @_;
  
  my %params = ();
  my %upload_data = ();
  no warnings 'uninitialized';
  if( length($args{querystring}) )
  {
    foreach my $part ( split /&/, $args{querystring} )
    {
      my ($k,$v) = map { $s->unescape($_) } split /\=/, $part;
      
      if( exists($params{$k}) )
      {
        if( ref($params{$k}) )
        {
          push @{$params{$k}}, $v;
        }
        else
        {
          $params{$k} = [ $params{$k}, $v ];
        }# end if()
      }
      else
      {
        $params{$k} = $v;
      }# end if()
    }# end foreach()
  }# end if()
  
  if( $args{body} )
  {
    my $body = HTTP::Body->new( $args{content_type}, $args{content_length} );
    $body->add( $args{body} );
    
    # Parse form values:
    my $form_info = $body->param || { };
    if( keys(%$form_info) )
    {
      foreach( keys(%$form_info) )
      {
        $params{$_} = $form_info->{$_};
      }# end foreach()
    }# end if()
    
    # Parse uploaded data:
    if( my $uploads = $body->upload )
    {
      foreach my $name ( keys(%$uploads) )
      {
        open my $ifh, '<', $uploads->{$name}->{tempname}
          or die "Cannot open '$uploads->{$name}->{tempname}' for reading: $!";
        $upload_data{$name} = {
          %{$uploads->{$name}},
          'filehandle'  => $ifh,
          tempname      => $uploads->{$name}->{tempname},
        };
        $params{$name} = $ifh;
      }# end foreach()
    }# end if()
  }# end if()
  
  my $cookies = { };
  if( my $cookie_str = $ENV{HTTP_COOKIE} )
  {
    foreach my $part ( split /;\s*/, $cookie_str )
    {
      my ($name,$val) = map { $s->unescape( $_ ) } split /\=/, $part;
      $cookies->{$name} = $val;
    }# end foreach()
  }# end if()
  
  return bless {
    params  => \%params,
    uploads => \%upload_data,
    cookies => $cookies,
    %args
  }, $s;
}# end new()


sub upload
{
  my ($s, $key) = @_;
  
  no warnings 'uninitialized';
  return exists( $s->{uploads}->{$key} ) ? $s->{uploads}->{$key}->{filehandle} : undef;
}# end upload()


sub param
{
  my ($s, $key) = @_;
  
  if( defined($key) )
  {
    if( ref($s->{params}->{$key}) )
    {
      return wantarray ? ref($s->{params}->{$key}) eq 'ARRAY' ? @{ $s->{params}->{$key} } : $s->{params}->{$key} : $s->{params}->{$key};
    }
    else
    {
      return $s->{params}->{$key};
    }# end if()
  }
  else
  {
    return keys(%{ $s->{params} });
  }# end if()
}# end param()

*url_param = \&param;


sub Vars { shift->{params} }


sub cookie
{
  my $s = shift;
  
  if( @_ )
  {
    my $name = shift;
    if( exists( $s->{cookies}->{ $name } ) )
    {
      return $s->{cookies}->{ $name };
    }
    else
    {
      return;
    }# end if()
  }
  else
  {
    return %{ $s->{cookies} };
  }# end if()
}# end cookies()


sub escape
{
  my $toencode = $_[1];
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end escape()


sub unescape
{
  my ($s, $todecode) = @_;
  return unless defined($todecode);
  $todecode =~ tr/+/ /;       # pluses become spaces
  $todecode =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
  defined($1)? chr hex($1) : utf8_chr(hex($2))/ge;
  return $todecode;
}# end unescape()


sub DESTROY
{
  my $s = shift;
  
  map {
    close($s->{uploads}->{$_}->{filehandle});
    unlink($s->{uploads}->{$_}->{tempname});
  } keys(%{$s->{uploads}});
  undef(%$s);
}# end DESTROY()


1;# return true:

=pod

=head1 NAME

ASP4::SimpleCGI - Basic CGI functionality

=head1 SYNOPSIS

  use ASP4::SimpleCGI;
  
  my $cgi = ASP4::SimpleCGI->new(
    content_type    => 'multipart/form-data',
    content_length  => 1200,
    querystring     => 'mode=create&uploadID=234234',
    body            => ...
  );
  
  my $val = $cgi->param('mode');
  foreach my $key ( $cgi->param )
  {
    print $key . ' --> ' . $cgi->param( $key ) . "\n";
  }# end foreach()
  
  my $escaped = $cgi->escape( 'Hello world' );
  my $unescaped = $cgi->unescape( 'Hello+world' );
  
  my $upload = $cgi->upload('filename');
  
  my $filehandle = $cgi->upload_info('filename', 'filehandle' );

=head1 DESCRIPTION

This package provides basic CGI functionality and is also used for testing and
in the API enironment.

C<ASP4::SimpleCGI> uses L<HTTP::Body> under the hood.

=head1 PUBLIC METHODS

=head2 new( %args )

Returns a new C<ASP4::SimpleCGI> object.

C<%args> can contain C<content_type>, C<content_length>, C<querystring> and C<body>.

=head2 param( [$key] )

If C<$key> is given, returns the value of the form or querystring parameter by that name.

If C<$key> is not given, returns a list of all parameter names.

=head2 escape( $str )

Returns a URL-encoded version of C<$str>.

=head2 unescape( $str )

Returns a URL-decoded version of C<$str>.

=head2 upload( $field_name )

Returns all of the information we have about a file upload named C<$field_name>.

=head2 upload_info( $field_name, $item_name )

Returns just that part of C<$field_name>'s upload info.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
