
package Apache2::ASP::ModPerl;

use strict;
use warnings 'all';
use APR::Table ();
use APR::Socket ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::RequestUtil ();
use Apache2::ASP::HTTPContext ();
use CGI();
use Apache2::ASP::UploadHook;

local $Apache2::ASP::HTTPContext::ClassName = 'Apache2::ASP::HTTPContext';


#==============================================================================
sub handler : method
{
  my ($class, $r) = @_;
  
  my $context = Apache2::ASP::HTTPContext->new();
  
  if( uc($r->method) eq 'POST' && $r->headers_in->{'content-type'} =~ m/multipart\/form\-data/ )
  {
    $context->{r} = $r;
    eval {
      $context->_load_class( $context->config->web->handler_resolver );
    };
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
      $context->_load_class( $handler_class );
      
      my $cgi = CGI->new( $r );
      my %args = map { my ($k,$v) = split /\=/, $_; ( $k => $v ) } split /&/, $ENV{QUERY_STRING};
      map { $cgi->param($_ => $args{$_}) } keys %args;
      $context->setup_request( $r, $cgi);
      $handler_class->init_asp_objects( $context );
      
      $context->execute;
    };
    if( $@ )
    {
      warn $@;
      $r->status( 500 );
    }# end if()
    return $r->status =~ m/^2/ ? 0 : $r->status;
  }
  else
  {
    my $cgi = CGI->new( $r );
    eval {
      $context->setup_request( $r, $cgi );
      $context->execute;
    };
    warn $@ if $@;
    
    return 500 if $@;
    return $r->status =~ m/^2/ ? 0 : $r->status;
  }# end if()
  
}# end handler()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ModPerl - mod_perl2 PerlResponseHandler for Apache2::ASP

=head1 SYNOPSIS

In your httpd.conf
  
  # Needed for file uploads to work properly:
  LoadModule apreq_module    modules/mod_apreq2.so

  # Load up some important modules:
  PerlModule DBI
  PerlModule DBD::mysql
  PerlModule Apache2::ASP::ModPerl

  # Admin website:
  <VirtualHost *:80>

    ServerName    mysite.com
    ServerAlias   www.mysite.com
    DocumentRoot  /usr/local/projects/mysite.com/htdocs
    
    # Set the directory index:
    DirectoryIndex index.asp
    
    # All *.asp files are handled by Apache2::ASP::ModPerl
    <Files ~ (\.asp$)>
      SetHandler  perl-script
      PerlResponseHandler Apache2::ASP::ModPerl
    </Files>
    
    # !IMPORTANT! Prevent anyone from viewing your GlobalASA.pm
    <Files ~ (\.pm$)>
      Order allow,deny
      Deny from all
    </Files>
    
    # All requests to /handlers/* will be handled by their respective handler:
    <Location /handlers>
      SetHandler  perl-script
      PerlResponseHandler Apache2::ASP::ModPerl
    </Location>
    
  </VirtualHost>

=head1 DESCRIPTION

C<Apache2::ASP::ModPerl> provides a mod_perl2 PerlResponseHandler interface to
L<Apache2::ASP::HTTPContext>.

Under normal circumstances, all you have to do is configure it and forget about it.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

