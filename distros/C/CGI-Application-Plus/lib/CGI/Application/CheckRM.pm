package CGI::Application::CheckRM ;
$VERSION = 1.21 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; use Data::FormValidator

; use Object::props
      ( { name       => 'dfv_results'
        , allowed => qr /::checkRM$/
        }
      )
     
; use Object::groups
      ( { name       => 'dfv_defaults'
        , no_strict  => 1
        }
      )

; sub checkRM
   { my $s       = shift
   ; my $profile = shift || croak 'Missing required profile'
   ; $profile = do
                 {  ref $profile eq 'HASH' && $profile
                 || $s->can($profile)      && $s->$profile()
                 || eval { $s->$profile() }
                 }
   ; $@ && croak qq(Error running profile method "$profile": $@)
   ; my $dfv = Data::FormValidator
               ->new( {}
                    , scalar $s->dfv_defaults
                    )
   ; my $r = $dfv->check( $s->query
                        , $profile
                        )
   ; if (  $r->has_missing
        || $r->has_invalid
        )
      { $^W && carp qq(Input error detected for run-mode "$$s{runmode}")
      ; $s->dfv_results = $r
      ; return 0
      }
     else
      { return 1
      }
   }

; 1

__END__

=head1 NAME

CGI::Application::CheckRM - Checks run modes using Data::FormValidator

=head1 VERSION 1.21

Included in CGI-Application-Plus 1.21 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

The distribution includes:

=over

=item * CGI::Application::Plus

CGI::Application rewriting with several pluses

=item * CGI::Application::Magic

Template based framework for CGI applications

=item * CGI::Application::CheckRM

Checks run modes using Data::FormValidator

=back

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1
    OOTools      >= 1.52

=item CPAN

    perl -MCPAN -e 'install CGI::Application::Plus'

If you want to install also all the prerequisites to use C<CGI::Application::Magic>), all in one easy step:

    perl -MCPAN -e 'install Bundle::Application::Magic'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

    use base 'CGI::Application::CheckRM';
    
    $s->checkRM('_form_profile')
      || return $s->switch_to('myOtherRunMode');
    
    my $ERRORS = $s->dfv_resuts->msgs

=head1 DESCRIPTION

This module integrates the C<Data::FormValidator> capability with C<CGI::Application::Plus> or with C<CGI::Application::Magic>.


=head1 INTEGRATION

The integration with C<CGI::Application::Magic> is very powerful.

You need just to pass the profile to the checkRM() method and put the labels in the template: no other configuration needed on your side: the error labels in any template will be auto-magically substituted with the error string when needed.

B<Note>: The hash reference returned by the msgs() method will be internally passed as a lookup location to the C<Template::Magic> object.

=head2 CGI::Application::Magic Example 1

In your WebAppMagic.pm

    use base 'CGI::Application::Magic';
    use base 'CGI::Application::CheckRM';
    
    sub RM_myRunMode
    {
      my $s = shift ;
      $s->checkRM('_form_profile')
        || return $s->switch_to('myOtherRunMode');
      ...
    }
    
    # the RM_myOtherRunMode method is optional
    
    sub _form_profile
    {
       return { required => 'email',
                msgs     => { any_errors => 'some_errors',
                              prefix     => 'err_',
                             },
              };
    }

Somewhere in the 'myOtherRunMode.html' template (or in any other template) all the label prefixed with 'err_' will be substitute with the relative error if present (with the _form_profile in the example it happens just with 'err_email'):

    <!--{err_email}-->

=head2 CGI::Application::Magic Example 2

In your WebAppMagic.pm

    use base 'CGI::Application::Magic';
    use base 'CGI::Application::CheckRM';
    
    sub RM_myRunMode
    {
      my $s = shift ;
      $s->checkRM('_form_profile')
        || return $s->switch_to('myOtherRunMode');
      ...
    }
    
    # the RM_myOtherRunMode method is optional
    
    sub _form_profile
    {
       return { required => 'email',
                msgs     => { any_errors => 'some_errors',
                              prefix     => 'err_',
                             },
              };
    }
    
    package WebAppMagic::Lookups;
    
    sub MISSING
    {
      my $s = shift ;
      my $missing
      if ( $s->dfv_resuts->has_missing )
      {
        foreach my $f ( $s->dfv_resuts->missing )
        {
           $missing .= $f, " is missing\n";
        }
      }
      $missing
    }

Somewhere in the 'myOtherRunMode.html' template (or in any other template) all the 'MISSING' labels will be substitute with the relative error if present:

    <!--{MISSING}-->

=head2 CGI::Application::Plus Example

You can use this module with C<CGI::Application::Plus>, but you will have to handle the errors in the runmethod:

In your WebAppPlus.pm

    use base 'CGI::Application::Plus';
    use base 'CGI::Application::CheckRM';
    
    sub RM_myRunMode
    {
      my $s = shift ;
      $s->checkRM('_form_profile')
        || return $s->switch_to('myOtherRunMode');
      ...
    }
    
    sub RM_myOtherRunMode
    {
      my $s  = shift;
      my $ERRORS = $s->dfv_resuts->msgs ; # classical way
      
      # or do something else with the result object
      
      if ( $s->dfv_resuts->has_missing )
      {
        foreach my $f ( $s->dfv_resuts->missing )
        {
           $ERRORS .= $f, " is missing\n";
        }
      }
      ... do_something_useful ...
    }
    
    sub _form_profile
    {
       return { required => 'email',
                msgs     => { any_errors => 'some_errors',
                              prefix     => 'err_',
                             },
              };
    }

=head1 METHODS

=head2 checkRM ( dfv_profile )

Use this method to check the query parameters with the I<dfv_profile>. It returns 1 on success and 0 on failure. If there are some missing or unvalid fields it set also the C<dfv_results> property to the Data::FormValidator::Results object.

=head1 PROPERTY and GROUP ACCESSORS

This module adds a couple of properties to the standard C<CGI::Application::Plus> properties.

=head2 dfv_defaults

This group accessor handles the C<Data::FormValidator> constructor arguments that are used in the creation of the internal C<Data::FormValidator> object.

=head2 dfv_results

This property allows you to access the C<Data::FormValidator::Results> object set by the C<checkRM()> method only if there are some missing or invalid fields.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?CGI::Application::CheckRM.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.
