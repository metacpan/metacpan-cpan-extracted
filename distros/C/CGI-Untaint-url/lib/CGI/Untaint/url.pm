package CGI::Untaint::url;

$VERSION = '1.00';

use strict;
use base 'CGI::Untaint::printable';
use URI::Find::Schemeless::Stricter;

sub is_valid {
	my $self = shift;
	my $value = $self->value or die "No value\n";
	my @urls;
	our $finder = URI::Find::Schemeless::Stricter->new(
		sub {
			push @urls, shift;
		}
	);
	$finder->find(\$value);
	return $self->value($urls[0]) if @urls;
	return;
}

=head1 NAME

CGI::Untaint::url - validate a URL

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $url = $handler->extract(-as_url => 'web_address');

=head1 DESCRIPTION

=head2 is_valid

This Input Handler verifies that it is dealing with a reasonable
URL. This mostly means that it will find the first thing that looks
like a URL in your input, where by "looks like", we mean anything that
URI::URL thinks is sensible, (with some tweaks, courtesy of
URI::Find::Schemeless::Stricter), so it will accept any of (for example):

  http://c2.com/cgi/wiki
  www.tmtm.com
  See: http://www.redmeat.com/redmeat/1996-09-30/
  [http://www.angelfire.com/la/carlosmay/Tof.html]
  ftp://ftp.ftp.org/

The resulting value will be a L<URI::URL> object. 

=head1 SEE ALSO

L<URI::URL>. L<URI::Find::Schemeless::Stricter>.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CGI-Untaint-url@rt.cpan.org

=head1 COPYRIGHT

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;
