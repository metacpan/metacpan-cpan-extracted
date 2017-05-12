
package Apache2::ASP::Test::Fixtures;

use strict;
use warnings 'all';
use base 'Data::Properties::YAML';


#====================================================================
sub as_hash
{
  wantarray ? %{ $_[0]->{data} } : $_[0]->{data};
}# end as_hash()

1;# return true:

__END__

=head1 NAME

Apache2::ASP::Test::Fixtures - Simle text fixtures for Apache2::ASP web applications.

=head1 SYNOPSIS

  my $data = Apache2::ASP::Test::Fixtures->new(
    properties_file => $config->application_root . '/etc/test_fixtures.yaml'
  );
  
  print $data->message->greeting->english;

=head1 METHODS

=head2 as_hash( )

Returns a hash or hashref or your test fixture data, depending on the context in which
this method is called.

=head1 PUBLIC PROPERTIES

Each top-level node in your YAML file is assigned a public accessor.

So if your YAML looks something like this

  ---
  message:
    greeting:
      english: Hello
      spanish: Hola
      french:  Bonjour

You would get an object with a public accessor named C<message> with an accessor named C<greeting>
with accessors named C<english>, C<spanish> and C<french>.

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
