package Class::DBI::Untaint;

$VERSION = '1.00';

use strict;

use CGI::Untaint;
use Class::DBI;

sub Class::DBI::_constrain_by_untaint {
  my ($class, $col, $string, $type) = @_;
  $class->add_constraint(
    untaint => $col => sub {
      my $h = CGI::Untaint->new({ $col => +shift });
      $h->extract("-as_$type" => $col);
      !$h->error;
    });
}

=head1 NAME

Class::DBI::Untaint - Class::DBI constraints using CGI::Untaint

=head1 SYNOPSIS

  use base 'Class::DBI';
  use Class::DBI::Untaint;

  ___PACKAGE__->columns(All => qw/id value entered/);
  ___PACKAGE__->constrain_column(value => Untaint => "integer");
  ___PACKAGE__->constrain_column(entered => Untaint => "date");

=head1 DESCRIPTION

Using this module will plug-in a new constraint type to Class::DBI that
uses CGI::Untaint.

Any column can then be said to require untainting of a given type -
i.e. that any value which you attempted to set that column to (include
at create() time) must pass an untaint as_type() check.

In the examples above, the 'value' column must pass the check in
CGI::Untaint::integer, and similarly 'entered' must untaint as a date.

=head1 SEE ALSO

L<Class::DBI>, L<CGI::Untaint>.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-Untaint@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
