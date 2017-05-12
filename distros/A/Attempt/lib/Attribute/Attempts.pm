package Attribute::Attempts;

use strict;
use warnings;

use Sub::Attempts ();
use Attribute::Handlers;

our $VERSION = "1.00";

sub UNIVERSAL::attempts :ATTR(CODE)
{
  my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
  Sub::Attempts::_attempts($referent,$symbol,@{$data});
}

1;

__END__

=head1 NAME

Attribute::Attempts - attribute version of Attempt::Sub

=head1 SYNOPSIS

  use Attribute::Attempts;

  # alter db will try three times before failing
  sub alter_db : attempts(tries => 3, delay => 2)
  {
    my $dbh = DBI->connect("DBD::Mysql:foo", "mark", "opensaysme")
      or die "Can't connect to database";
    $dbh->{RaiseException} = 1;
    $dbh->do("alter table items change pie pies int(10)");
  }

=head1 DESCRIPTION

It's an attribute version of B<Sub::Attempts>.  See L<Sub::Attempts>
for information on how the attributes work.

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 BUGS

As far as I know, works on any platform L<Attribute::Handlers> does.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Attribute::Attempts>.

=head1 SEE ALSO

L<Sub::Attempts>, L<Attempt>

=cut

1;
