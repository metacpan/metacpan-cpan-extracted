
package Apache2::ASP;

use strict;
use warnings 'all';
use vars '$VERSION';

$VERSION = '2.46';

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP - ASP for Perl, reloaded. (DEPRECATED use ASP4 instead)

=head1 SYNOPSIS

B<DEPRECATED:> Use L<ASP4> instead.

=head2 Hello World

  <html>
  <body><%= "Hello, World!" %></body>
  </html>

=head2 Favorite Color

  <html>
  <body>
  <%
    if( $Form->{favorite_color} )
    {
  %>
    Your favorite color is <%= $Server->HTMLEncode( $Form->{favorite_color} ) %>.
  <%
    }
    else
    {
  %>
    What is your favorite color?
    <form>
      <input type="text" name="favorite_color">
      <input type="submit" value="Submit">
    </form>
  <%
    }# end if()
  %>
  </body>
  </html>

=head1 DESCRIPTION

Apache2::ASP scales out well and has brought the ASP programming model to Perl 
in a new way.

This rewrite had a few major goals:

=over 4

=item * Master Pages

Like ASP.Net has, including nested Master Pages.

=item * Partial-page caching

Like ASP.Net has.

=item * Better configuration

The original config format was unsatisfactory.

=item * Handle multiple VirtualHosts better.

Configuration was the root of this problem.

B<NOTE>: If you use an ORM, make sure your ORM doesn't have any "global" configuration
object in memory, unless it is schema-aware.  L<DBIx::Class> is good and L<Class::DBI::Lite>
also works well with Apache2::ASP.  Do not use L<Class::DBI> with Apache2::ASP
because of configuration overlap problems which arise when you have 2 tables with
the same name in 2 different databases.

=item * Better performance

Server resources were being wasted on unnecessary activities like storing
session state even when it had not changed, etc.

=back

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

