
package Apache2::ASP::API;

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';

sub context { shift->ua->context }
sub config { shift->ua->context->config }

1;

__END__

=pod

=head1 NAME

Apache2::ASP::API - A public API for all Apache2::ASP web applications.

=head1 SYNOPSIS

  use Apache2::ASP::API;
  
  my $api = Apache2::ASP::API->new();
  
  my HTTP::Response $res = $api->ua->get("/index.asp");
  die $res->as_string unless $res->is_success;
  
=head1 DESCRIPTION

Wouldn't it be great if your website had its own public coding API?  How about 
one that you could subclass and add your own features to?

That's what Apache2::ASP::API is all about.

Apache2::ASP::API provides a programatic interface to your Apache2::ASP web 
applications, allowing you to execute requests against ASP scripts and handlers
just as you would from a browser, but without the use of an HTTP server.

=head2 Why do I need this?

Consider the case where you want to upload hundreds of files into your website,
but you don't want to do it one-at-a-time.

The following snippet of code would do the trick:

  #!/usr/bin/perl -w
  
  use strict;
  use warnings 'all';
  use Apache2::ASP::API;
  
  my $api = Apache2::ASP::API->new();
  
  my @files = @ARGV or die "Usage: $0 <filename(s)>\n";
  
  foreach my $file ( @files )
  {
    # Assuming /handlers/MM is a subclass of Apache2::ASP::MediaManager:
    my $id = rand();
    my $res = $api->upload("/handlers/MM?mode=create&uploadID=$id", [
      filename => [ $file ]
    ]);
    
    die "Error on '$file': " . $res->as_string
      unless $res->is_success;
    
    print "'$file' uploaded successfully\n";
  }# end foreach()

If only logged-in users may upload files, simply log in before uploading anything:

  my $api = Apache2::ASP::API->new();
  
  my $res = $api->ua->post("/handlers/user.login", {
    user_email    => $email,
    user_password => $password,
  });
  
  # Assuming $Session->{user} is set upon successful login:
  unless( $api->session->{user} )
  {
    die "Invalid credentials";
  }# end unless()
  
  ... continue uploading files ...

Or...you could even subclass the API with your own:

  package MyApp::API;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::API';
  
  sub login
  {
    my ($s, $email, $password) = @_;
    
    my $res = $s->ua->post("/handlers/user.login", {
      user_email    => $email,
      user_password => $password
    });
    
    # Assuming $Session->{user} is set upon successful login:
    unless( $api->session->{user} )
    {
      die "Invalid credentials";
    }# end unless()
    
    return 1;
  }# end login()
  
  1;# return true:

Then your uploader script could just do this:

  #!/usr/bin/perl -w
  
  use strict;
  use warnings 'all';
  use MyApp::API;
  
  my $api = MyApp::API->new();
  $api->login( 'test@test.com', 's3cr3t!' );
  
  # Upload all the files:
  $api->ua->upload("/handlers/MM?mode=create&uploadID=" . rand(), [
    filename => [ $_ ]
  ]) foreach @ARGV;

=head1 INTEGRATION TESTING

I often develop websites that have both "public" and an "administrative" interfaces
that are completely different websites.

For instances in which users of the public website are allowed to submit records
that an administrator would manage through the administrative interface, this presents
a problem:

=head2 How to Test Multiple Websites at the Same Time

My tests look something like this:

  #!/usr/bin/perl -w

  use strict;
  use warnings 'all';
  use Apache2::ASP::API;
  use HTML::Form;
  use Test::More 'no_plan';
  use Cwd 'cwd';

  # We can inspect the data from both the public site and the Admin dashboard:
  my ($admin, $public); BEGIN {
    $public = Apache2::ASP::API->new( 'cwd' => cwd() );
    chdir("../admin-website");
    $admin = Apache2::ASP::API->new( 'cwd' => cwd() );
    chdir("../public-website");
  }

  # Now load up our modules:
  use_ok('My::Foo');
  use_ok('My::Bar');

  # Do stuff on the public website:
  ok( $public->ua->get('/page.asp')->is_success, "yay public" );

  # Do stuff on the admin website:
  ok( $admin->ua->get('/admin-page.asp')->is_success, "yay admin" );

=head1 PUBLIC METHODS

Apache2::ASP::API is a subclass of L<Apache2::ASP::Test::Base> and inherits
everything from that class.

=head1 PUBLIC PROPERTIES

=head2 context

Read-only.  Returns the current L<Apache2::ASP::HTTPContext> object.

=head2 config

Read-only.  Returns the current L<Apache2::ASP::Config> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut
