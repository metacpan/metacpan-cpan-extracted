package CGI::Untaint::isbn;

use strict;
use base 'CGI::Untaint::printable';
require Business::ISBN;

use vars qw/$VERSION/;
$VERSION = '0.01';

sub is_valid {
  my $self = shift;
  my $isbn = $self->value;
  my $bi = Business::ISBN->new($isbn) or return;
  return unless $bi->is_valid == 1;
  $self->value( $bi->as_string([]) );
  return $self->value;
}

1;

__END__

=head1 NAME

CGI::Untaint::isbn - validate an isbn

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $isbn = $handler->extract(-as_isbn => 'isbn');

=head1 DESCRIPTION

This Input Handler verifies that it is dealing with a reasonable
isbn (i.e. one that Business::ISBN believes to be valid.)

=head1 SEE ALSO

L<CGI::Untaint>.
L<Business::ISBN>.

=head1 AUTHOR

Steve Rushe, steve-cpan@deeden.co.uk       

=head1 COPYRIGHT

Copyright (C) 2001 Steve Rushe. All rights reserved.

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
