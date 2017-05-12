package Data::FormValidator::Tutorial;
use strict;

our $VERSION = '1.61';



1;
__END__
=head1 NAME

Data::FormValidator::Tutorial

=head1 TUTORIAL

=head2 Introduction

  Trust the user.  Don't trust their data.

Have you ever needed some code to verify the user entered the right data, much less even entered it at all in the first place?  You may start off with an if branch, then more and more.  Then you may start with a fancy C<%required> hash with the field name keys and description values.  And you copy-n-paste that code everywhere?  Sound familiar?  It does to me and I wish I had someone point me in the direction of this module a long time ago.  I hope we are reaching you in time!

This tutorial will start off really basic and then get into how it can help even with complex situations.  So let's get started!

=head2 And so we begin...

To begin with, I'm going to assume that you're a Web developer, working on a CGI or mod_perl program.  You can also use this module for other application types and these examples will still apply, but it will help me if I can relate to what you're doing.  This tutorial is also based on the latest & greatest version - 3.62.  I hope I just didn't date myself.

So let's start off with a simple CGI script that handles when the user submits their input:

  use CGI;
  # This is a simple script that is the "action" of a subscribe form
  # that has fname, lname, over18 checkbox, dob, email, password1,
  # password2 and avatar form fields.
  my ( $cgi );

  $cgi = new CGI;
  # We need to make sure they provided all those fields!

So now let's create a new Data::FormValidator (you know, let's call it B<dfv> for short from here on out, ok?) object.  First, we'll need to add the C<use Data::FormValidator;> line at the top of your code and then call dfv's C<check> method on the $cgi object.  Here's what that code looks like so far:

  use CGI;
  use Data::FormValidator;
  my ( $cgi, $dfv_profile, $results );

  $cgi = new CGI;
  # We need to make sure they provided all those fields!
  $dfv_profile = {};
  $results = Data::FormValidator->check( $cgi, $dfv_profile );

I<I hope you don't object to me taking out those comments ... just showing the pertinent lines now that you have the grasp of what we're trying to do.>

That code won't work (yet).  The C<$dfv_profile> data structure is blank.  So dfv doesn't have anything to check, so everything will be hunky-dorey.  As you get this framework meshed out, you'll find yourself refining the C<$dfv_profile> data structure long after (What?  Management changes their mind on what's important?  Or how something looks?), so some people actually remove it to a separate subroutine:

  ...
    $results = Data::FormValidator->check( $cgi, dfv_profile() );
  ...
  sub dfv_profile {
    return {
      };
  }

Ok, so now let's hammer out the dfv profile.  We'll just keep it as a separate data structure, instead of using the subroutine method.  Let's first start off by saying we are going to require the C<fname>, C<lname>, C<email>, C<password1>, and C<password2> fields.  So here's how that would look:

  $dfv_profile =
    {
        'required' => [ qw( fname lname email password1 password2 ) ],
        # FYI, I always leave a comma at the end to make future changes easy
    };

So if the user doesn't provide any of those fields (or if the field only contains spaces), it will trigger C<has_missing()> to return true.

So after establishing the C<$results> variable through the C<check()> call, we can then use it to call dfv's support methods: C<has_invalid> and C<has_missing>

  ...
    $results = Data::FormValidator->check( $cgi, $dfv_profile );
    if ( $results->has_missing() || $results->has_invalid() ) {
      # There was something wrong w/ the data...
    } else {
      # We're in the clear!  The user has provided you with
      # good data
    }
  ...

So now if the user submits the form with any of those fields not filled out (or filled with spaces), then it will trigger the has_missing() method.

Our code isn't setup to handle that, so let's flesh that part out.  There are several ways to let the user know their data wasn't accepted.  Let's keep it simple and have a results page that either shows an error message or a message saying the data was accepted.  To do this, I will employ HTML::Template, though there are several ways to do this, too.

First, let's create the template code:

  <html>
  <head>
	<title>Subscription Results</title>
  </head>
  <body>
  <h2>Subscription Results</h2>
  <!-- TMPL_IF NAME="some_errors" -->
  <p>I'm sorry, but there were some problems with your subscription:</p>
  <ul>
	<!-- TMPL_IF NAME="err_fname" -->
	<li>You missed your first name.</li>
	<!-- /TMPL_IF -->
	<!-- TMPL_IF NAME="err_lname" -->
	<li>You missed your last name.</li>
	<!-- /TMPL_IF -->
    <!--  ... AND SO ON FOR EACH FIELD NAME ... -->
  </ul>
  <p>RESULTS Data Structure:</p>
  <pre>
	<!-- TMPL_VAR NAME="results" -->
  </pre>
  <!-- TMPL_ELSE -->
  <p>Your subscription has been processed.</p>
  <p><a href="/">Back to the Home Page?</a></p>
  <!-- /TMPL_IF -->
  </body>
  </html>

Now we need to modify the subscribe.cgi  script to use the results.TMPL file.  Here's what I have so far:

  #!/usr/bin/perl -wT

  use strict;

  $|++;

  use CGI;
  use CGI::Carp qw( fatalsToBrowser );
  use Data::FormValidator;
  use HTML::Template;

  use Data::Dumper;

  my ( $cgi, $dfv_profile, $results, $template );

  $cgi = new CGI;

  print $cgi->header;

  $dfv_profile =
    {
	'required' => [ qw(
                            fname lname emails
                            password1 password2
                       ) ],
    };

  $results = Data::FormValidator->check(
        $cgi, $dfv_profile
    );

  $template = HTML::Template->new(
        'filename'          => 'results.TMPL',
        'die_on_bad_params' => 0,
    );

  if (
    $results->has_invalid or
    $results->has_missing
   ) {
    # something's wrong, which you can
    # access what exactly from the
    # $results object

    my $res_dump = Dumper( $results );
    $template->param(
            'some_errors'   => 1,
            'results'       => $res_dump,
        );


  } else {
    # the user provided complete and valid
    # data ... it's cool to proceed
  }

  print $template->output;

This script and template are in a debug type of mode.  If you actually run this (without filling out the required fields), you'll see the $results object all written out in the results, which is probably not what you want your user to see.  We'll take it out when we go "live" (it'd be good to make a comment in your code to remind yourself later).

Ok, so now let's talk about the msgs stuff.  You see, you could pick apart the results object to get the missing and invalid fields and then pass them in, individually or you can shortcut it with dfv's msgs support.  Dfv's msgs also supports a flag for the overall error status.  To use it, we would extend the $dfv_profile, like so:

  $dfv_profile =
    {
	'required' # ... [snip] ...
        'msgs'  => {
                       'prefix'        => 'err_',
                       'any_errors'    => 'some_errors',
                   },
    };

Then you can use dfv's 'msgs' method from the $results object and pass that directly into the $template object:

    $template->param( $results->msgs );
    # I'm keeping this next line in here for debugging
    # purposes... take out when we go live
    $template->param(
            'results'       => $res_dump,
        );

So now dfv will take care of passing along the right template parameters dynamically.  Give it a shot and go back & forth between filling out particular form fields (make sure you've fleshed out the rest of the template code).

So this is great!  Now you have a system in place to verify that the user is providing all of the information in an user-friendly method as well as easy-to-maintain/read code for you.

Now the pointed-haired boss steps into your office and says "Hey, we're getting a lot of registrations with bogus email information and Marketing can't spam 'em!  Fix that code to only accept valid email addresses."  This is where I<constraints> comes into the picture.  Constraints take a closer look at the input to see if it's valid.  If not, it will trigger C<has_invalid()> to return true.

  $dfv_profile =
      {
        'required'    => [ qw( fname lname email password1 password2 ) ],
        'constraints' => {
            'email' => qr/\w+\@\w+\.\w+/,
          },
      };

This is saying that the C<email> field is valid only when the regex pattern fits the input.  Now I just gave a very rough (and probably inaccurate) pattern, just so you get the idea.  So many people have come across this type of thing, that there's a I<shortcut> for the bona-fide and accurate email address pattern that's built into the dfv package (you can see L<Data::FormValidator::Constraints> for other built-in constraint types, too).

  ...
            'email' => 'email',
  ...

Pretty sweet, huh?  There are other things you can do on the right-hand side of a constraint, too.  Right now, you've seen a regexp pattern and using a built-in constraint, but you can also point to a subroutine and do your own methodology:

  ...
            'email' => sub {
                my $email = shift;
                if ( $email =~ /purdy\.info$/ ) {
                  # only accepting emails from my domain
                  return 1;
                } else {
                  return 0;
                }
              },
  ...

You could also bump that subroutine outside the data structure somewhere and refer to it by name:

  ...
            'email' => \&my_domain_email(),
  ...
  sub my_domain_email {
    ...
  }

Lastly, either you or the PHB (pointed-haired boss) will note that password1 and password2 should be confirmed to be the same thing, to make sure the user didn't typo the password wrong.  I think you can handle that yourself, given the ammo I've given above, but it does use a twist, so let me introduce it.  First off, it would be a C<constraint> and it would point to a subroutine, but there are multiple parameters involved: C<password1> and C<password2>.  Whenever that happens, you define the constraint like so:

  ...
        'constraints' => {
            'email'     => 'email',
            'password1' => {
                'constraint' => "check_passwords",
                'params'     => [ qw( password1 password2 ) ],
              },
          },
  ...

So what this is saying is to check C<password1>, but instead of pointing to a regexp pattern, a built-in constraint or a subroutine, it's actually pointing to a more complex hashref.  Within that hashref is C<constraint>, which could be confusing, but it simply is the name of a subroutine that will be called.  Also within the hashref is C<params>, which is a list of the parameters to pass in as arguments to the subroutine.  So then somewhere in your code, you'll have the C<check_passwords> method:

  sub check_passwords {
    my ( $pw1, $pw2 ) = @_;
    if ( $pw1 eq $pw2 ) {
      return 1;
    } else {
      return 0;
    }
  }

=head1 TODO

This is just an early release of this tutorial - we're using the release early & often mentality, so there's still a few things left to do. We want to address of of the more complicated aspects of dfv, like Filters, etc.

=head1 SEE ALSO

L<Data::FormValidator> and the dfv mailing list: L<http://lists.sourceforge.net/lists/listinfo/cascade-dataform>

Also, Jason Purdy presented dfv at ApacheCon 2005 (L<http://www.apachecon.com>).  You can download the slides here:

L<http://www.purdy.info/useperl/th06_slides.pdf>

=head1 AUTHORS

Originally written by T. M. Brannon, <tbone@cpan.org>

William McKee, <william@knowmad.com> and Jason Purdy, <jason@purdy.info>

=head1 LICENSE

Copyright (C) 2004-2005 Jason Purdy, <jason@purdy.info> and William McKee, <william@knowmad.com>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut

