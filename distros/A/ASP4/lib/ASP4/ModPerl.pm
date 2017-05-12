
package ASP4::ModPerl;

use strict;
use warnings 'all';
use APR::Table ();
use APR::Socket ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::RequestUtil ();
use ASP4::HTTPContext ();
use CGI( ':cgi' );


#==============================================================================
sub handler : method
{
  my ($class, $r) = @_;
  
  $ENV{DOCUMENT_ROOT}   = $r->document_root;
  $ENV{REMOTE_ADDR}     = $r->connection->get_remote_host();
  $ENV{HTTP_HOST}       = $r->hostname;
  
  my $context = ASP4::HTTPContext->new();
  $r->pool->cleanup_register(sub { $context->DESTROY });
  
  if( ($r->headers_in->{'content-type'}||'') =~ m/multipart\/form\-data/ )
  {
    $context->{r} = $r;
    if( $@ )
    {
      warn $@;
      $r->status( 500 );
      return $r->status;
    }# end if()
    
    my $handler_class = eval {
      $context->config->web->handler_resolver->new()->resolve_request_handler( $r->uri )
    };
    if( $@ )
    {
      warn $@;
      $r->status( 500 );
      return $r->status;
    }# end if()
    
    return 404 unless $handler_class;
    
    eval {
      my $cgi = CGI->new( $r );
      my %args = map { my ($k,$v) = split /\=/, $_; ( $k => $v ) } split /&/, $ENV{QUERY_STRING};
      map { $cgi->param($_ => $args{$_}) } keys %args;
      $context->setup_request( $r, $cgi);
      $context->execute;
    };
    if( $@ )
    {
      if( $@ =~ m/Software\scaused\sconnection\sabort/ )
      {
        return 0;
      }# end if()
      warn $@;
      $r->status( 500 );
    }# end if()
    return $r->status =~ m/^2/ ? 0 : $r->status == 500 ? 0 : $r->status;
  }
  else
  {
    my $cgi = CGI->new( $r );
    eval {
      $context->setup_request( $r, $cgi );
      $context->execute;
    };
    if( $@ =~ m/Software\scaused\sconnection\sabort/ )
    {
      return 0;
    }# end if()
    warn $@ if $@;
    
    
    if( $context->response->Status == 200 )
    {
      $r->status( 200 );
      if( $context->did_end && $context->did_send_headers )
      {
        $r->rflush();
      }# end if()
      return 0;
    }
    else
    {
      $r->status( $context->response->Status );
      if( $context->did_end && $context->did_send_headers )
      {
        $r->rflush();
      }
      else
      {
        # Make sure we send our headers now, since we haven't done so already:
        $context->send_headers();
        $context->did_end(1);
        $r->rflush();
      }# end if()
      return $context->response->Status == 500 ? 0 : $context->response->Status;
    }# end if()
  }# end if()
  
}# end handler()

1;# return true:

=pod

=head1 NAME

ASP4::ModPerl - mod_perl2 PerlResponseHandler for ASP4

=head1 SYNOPSIS

In your httpd.conf

  # Load up some important modules:
  PerlModule DBI
  PerlModule DBD::mysql
  PerlModule ASP4::ModPerl
  
  <VirtualHost *:80>
  
    ServerName    mysite.com
    ServerAlias   www.mysite.com
    DocumentRoot  /usr/local/projects/mysite.com/htdocs
    
    # Set the directory index:
    DirectoryIndex index.asp
    
    # All *.asp files are handled by ASP4::ModPerl
    <Files ~ (\.asp$)>
      SetHandler  perl-script
      PerlResponseHandler ASP4::ModPerl
    </Files>
    
    # !IMPORTANT! Prevent anyone from viewing your GlobalASA.pm
    <Files ~ (\.pm$)>
      Order allow,deny
      Deny from all
    </Files>
    
    # All requests to /handlers/* will be handled by their respective handler:
    <Location /handlers>
      SetHandler  perl-script
      PerlResponseHandler ASP4::ModPerl
    </Location>
    
  </VirtualHost>

=head1 DESCRIPTION

C<ASP4::ModPerl> provides a mod_perl2 PerlResponseHandler interface to
L<ASP4::HTTPContext>.

Under normal circumstances, all you have to do is configure it and forget about it.

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

