package CGI::Builder::DFVCheck ;
$VERSION = 1.28 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++

; use Object::groups qw | dfv_defaults |
; use Object::props
      ( { name       => 'dfv_results'
        , allowed    => qr /::dfv_check$/
        }
      )

; sub dfv_new
   { require Data::FormValidator
   ; $Carp::Internal{'Data::FormValidator'}++
   ; Data::FormValidator->new( {}
                             , scalar $_[0]->dfv_defaults
                             )
   }

; sub dfv_check
   { my ($s, $profile) = @_
   ; $profile || croak 'Missing required profile'
   ; $profile = $s->$profile()
                unless ref $profile eq 'HASH'
   ; my $r = $s->dfv_new->check( $s->cgi, $profile )
   ; $s->dfv_results($r)
   ; ( $r->has_missing || $r->has_invalid )
     ? do{ $s->page_error($r->msgs); 0 }
     : 1
   }
   
; 1

__END__

=pod

=head1 NAME

CGI::Builder::DFVCheck - CGI::Builder and Data::FormValidator integration

=head1 VERSION 1.28

To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder        >= 1.2
    Data::FormValidator >= 3.5

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::DFVCheck'

You have also the possibility to use the Bundle to install all the extensions and prerequisites of the CBF in just one step. Please, notice that the Bundle will install A LOT of modules that you might not need, so use it specially if you want to extensively try the CBF.

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

   use CGI::Builder
   qw| CGI::Builder::DFVCheck
     |;
    
   $s->dfv_check(\%form_profile)
      || return $s->switch_to('myOtherPage');
   
   # if there is any error
   # $s->page_error is automatically set
   # to the $result->msgs HASH ref
   
   # $s->dfv_results is always set to the results object
    
   $results = $s->dfv_results

=head1 DESCRIPTION

B<Note>: You should know L<CGI::Builder>.

This module integrates the C<Data::FormValidator> capability with C<CGI::Builder>. It adds to your build an useful C<dfv_check()> method that you can use in your Switch Handlers (or in your Page Handlers) to check the input e.g. from a form. If any error is found, then the methods will return '0' (false) and will set the C<page_error> group accessor to the $results->msgs.

=head2 CGI::Builder Example

    package My::WebApp ;
    use CGI::Builder
    qw| CGI::Builder::DFVCheck
      |;
    
    sub SH_myPage
    {
      my $s = shift ;
      $s->dfv_check({ required => 'email' })
        || $s->switch_to('myOtherPage');
    }
    
    # do something with page_error
    sub OH_pre_page {
        my $s  = shift ;
        my $E = $s->page_error ;
        while ( my($field, $err) = each %$E ) {
            $s->page_content .= "$field field has this problem: $err\n"
        }
    }

=head1 INTEGRATION WITH CGI::Builder::Magic

The integration with C<CGI::Builder::Magic> is very powerful.

You need just to pass the profile to the dfv_check() method, put the labels in the template and no other configuration needed on your side: the error labels in any template will be auto-magically substituted with the error string when needed.

B<Note>: The hash reference returned by the msgs() method will internally set the C<< $s->page_error >> which is passed as a lookup location to the C<Template::Magic> object.

=head2 CGI::Builder::Magic Example 1

Your CBB:

    package My::WebAppMagic ;
    use CGI::Builder
    qw| CGI::Builder::DFVCheck
        CGI::Builder::Magic
      |;
    
    sub SH_thank_you
    {
      my $s = shift ;
      $s->dfv_check({ required => 'email',
                      msgs     => { prefix     => 'err_' },
                    })
        || $s->switch_to('input_form');
    }
    
    # the PH_thank_you and the PH_input_form handlers are optional
    # if you have the templates 'thank_you.html' and 'input_form.html'

Somewhere in the F<input_form.html> template (or in any other template) all the label prefixed with 'err_' will be substituted with the relative error if present (with the profile passed in the example it happens just with 'err_email'):

    <!--{err_email}-->

This might be the F<input_form.html> template file:

    <!--{FillInForm}-->
    <form action="thank_you" method="get">
    Name: <input name="name" type="text" value=""><br>
    Email: <input name="email" type="text" value=""><!--{err_email}--><br>
    <input type="submit" name="submit" value="Submit">
    </form>
    <!--{/FillInForm}-->

B<Note>: The 'FillInForm' block is optional, but it will automatically re-fills the fields on error (if you are using CGI::Builder::Magic >= 1.2).

=head2 CGI::Builder::Magic Example 2

Your CBB:

    package My::WebAppMagic ;
    use CGI::Builder
    qw| CGI::Builder::DFVCheck
        CGI::Builder::Magic
      |;
    
    sub SH_thank_you
    {
      my $s = shift ;
      $s->dfv_check({ required => 'email',
                      msgs     => { prefix => 'err_' }
                   })
        || $s->switch_to('input_form');
    }
    
    # the PH_thank_you and the PH_input_form handlers are optional
    # if you have the templates 'thank_you.html' and 'input_form.html'
    
    package WebAppMagic::Lookups;
    
    sub MISSING {
        my $s = shift ;
        my $missing;
        if ( $s->dfv_resuts->has_missing ) {
            foreach my $f ( $s->dfv_resuts->missing ) {
               $missing .= "<b>$f</b> value is missing<br>\n";
            }
        }
        $missing;
    }

Somewhere in the 'input_form.html' template (or in any other template) all the 'MISSING' labels will be substituted with the relative error if present:

    <!--{MISSING}-->

This might be the F<input_form.html> template file:

    <!--{FillInForm}-->
    <form action="thank_you" method="get">
    <!--{MISSING}-->
    Name: <input name="name" type="text" value=""><br>
    Email: <input name="email" type="text" value=""><br>
    <input type="submit" name="submit" value="Submit">
    </form>
    <!--{/FillInForm}-->

B<Note>: The 'FillInForm' block is optional, but it will automatically re-fills the fields on error (if you are using CGI::Builder::Magic >= 1.2).

=head1 METHODS

=head2 dfv_check ( dfv_profile )

Use this method to check the query parameters with the I<dfv_profile>. It returns 1 on success and 0 on failure. If there are some missing or unvalid fields it set also the C<page_error> WebApp property to the C<< $s->dfv_results->msgs >> HASH reference.

=head2 dfv_new

This method is not intended to be used directly in your CBB. It is used internally to initialize and returns the C<Data::FormValidator> object. You should redefine this method in your CBB if you need some more customized object. (see L<Data::FormValidator>).

=head1 PROPERTY and GROUP ACCESSORS

This module adds a couple of properties to the standard CBF properties.

=head2 dfv_defaults

This group accessor handles the C<Data::FormValidator> defaults that are used in the creation of the internal C<Data::FormValidator> object.

B<Note>: You can completely override the creation of the internal object by overriding the C<dfv_new()> method.

=head2 dfv_results

This read only property allows you to access the C<Data::FormValidator::Results> object set by the C<dfv_check()> method.

=head1 EFFICIENCY

The C<Data::FormValidator> module is required only if-and-when you use the dfv_check method, that usually occours at run time. That will save loading time in CGI environment (i.e. false $ENV{MOD_PERL}) but if most requests use any dfv_check method, it might be more efficient add a 'use Data::FormValidator;' to your code, which will load the module at compile time (regardless the request will actually use it).

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut

