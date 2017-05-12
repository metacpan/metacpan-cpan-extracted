package Apache2::CGI::Builder ;
$VERSION = 1.3 ;
use strict ;
# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++
; $Carp::Internal{__PACKAGE__.'::_'}++

; use mod_perl2
; use ModPerl::Util
; use Apache2::RequestRec
; use Apache2::Response
; use Apache2::Const( -compile => 'OK' )

; use File::Basename ()

; our $usage = << ''
Apache2::CGI::Builder should be used INSTEAD of CGI::Builder and should not be included as an extension

; sub import
   { undef $usage
   ; require CGI::Builder
   ; unshift @_, 'CGI::Builder'
   ; goto &CGI::Builder::import
   }

; use Class::props
        { name       => 'no_page_content_status'
        , default    => '404 Not Found'
        }

; use Object::props
        { name     => 'r'
        , default  => sub{ Apache2::RequestUtil->request }
        }

; sub PerlResponseHandler
   { my $s = shift
   ; $s = $s->new() unless ref $s
   ; $s->process()
   ; Apache2::Const::OK()
   }

; sub OH_init
   { my $s = shift
   ; $ENV{MOD_PERL_API_VERSION}
     or croak 'Cannot use Apache2::CGI::Builder without mod_perl2, died'
   ; my $filename = $s->r->filename
   ; my ( $page_name, $page_path, $page_suffix )
   ; if (-d $filename)
      { $page_path = $filename
      }
     else
      { ( $page_name, $page_path, $page_suffix )
        = File::Basename::fileparse ( $filename
                                    , qr/\..+$/
                                    )
      }
   ; $s->page_name($page_name)     unless defined $$s{page_name}
   ; $s->page_path($page_path)     unless defined $$s{page_path}
   ; $s->page_suffix($page_suffix) unless defined $$s{page_suffix}
   }

; sub handler : method
   { my ($s, $r) = @_
   ; my $cur = ModPerl::Util::current_callback()
   ; if ( my $h = $s->can($cur) )
      { $h->(@_)
      }
     else
      { croak sprintf '"%s" does not implement any "%s" method, died'
                    , ref $s
                    , $cur
      }
   }

; 1

__END__

=pod

=head1 NAME

Apache2::CGI::Builder - CGI::Builder and Apache/mod_perl2 (new namespace)integration

=head1 VERSION 1.3

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    Apache/mod_perl2  (PERL_METHOD_HANDLERS enabled)
    CGI::Builder >= 1.2

=item CPAN

    perl -MCPAN -e 'install Apache::CGI::Builder'

You have also the possibility to use the Bundle to install all the extensions and prerequisites of the CBF in just one step. Please, notice that the Bundle will install A LOT of modules that you might not need, so use it specially if you want to extensively try the CBF.

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back


=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module is the mod_perl2 compilant version of the L<Apache::CGI::Builder|Apache::CGI::Builder> extension. Use it only if you have installed the official release of mod_perl 2 (Apache2::* namespace). Read the documentation in L<Apache::CGI::Builder>.

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
