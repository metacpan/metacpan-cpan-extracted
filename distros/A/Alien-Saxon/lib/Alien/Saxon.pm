package Alien::Saxon;

use strict;
use warnings;
use File::ShareDir 'dist_file';

our $VERSION = '0.01';

sub jar { dist_file('Alien-Saxon', 'saxon9he.jar') }

#sub Inline {
#  require Alien::Saxon::Install::Files;
#  goto &Alien::Saxon::Install::Files::Inline;
#}

1;

__END__

=head1 NAME

Alien::Saxon - Distribute and make available as shared Saxon 9 JAR file

=head1 SYNOPSIS

  use Alien::Saxon;
  say Alien::Saxon->jar;

=head1 DESCRIPTION

Bundles and makes available (together with the rest of the Zip file,
including the licenses) F<saxon9he.jar> via the C<jar> method.

The code belongs to
L<Saxonica|https://www.saxonica.com/download/download_page.xml> and this
distribution is simply a convenient bundle for it for Perl purposes.

This version is from F<SaxonHE9-8-0-7J.zip>.

Available methods:

=head2 jar

The path of the JAR file.

=head1 AUTHOR

Ed J

=head1 SEE ALSO

L<XML::Saxon::XSLT3>, L<ExtUtils::Depends>.
