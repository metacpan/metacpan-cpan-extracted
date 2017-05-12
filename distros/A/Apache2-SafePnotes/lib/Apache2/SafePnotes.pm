package Apache2::SafePnotes;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.03';

my ($pn, $cn);
BEGIN {
  require Apache2::RequestUtil;
  eval {require Apache2::ConnectionUtil;};
  $pn=\&Apache2::RequestRec::pnotes;
  $cn=\&Apache2::Connection::pnotes if defined &Apache2::Connection::pnotes;
}

sub safe_pnotes {
  my $r=shift;
  $r->$pn(@_==2 ? ($_[0], my $x=$_[1]) : @_);
}

sub safe_cpnotes {
  my $r=shift;
  $r->$cn(@_==2 ? ($_[0], my $x=$_[1]) : @_);
}

sub import {
  my $module=shift;
  my $fn=shift || 'safe_pnotes';

  no warnings 'redefine';
  no strict 'refs';

  *{'Apache2::RequestRec::'.$fn}=\&safe_pnotes;
  *{'Apache2::Connection::'.$fn}=\&safe_cpnotes if defined $cn;
}

1;
__END__

=head1 NAME

Apache2::SafePnotes - a safer replacement for Apache2::RequestUtil::pnotes

=head1 SYNOPSIS

  use Apache2::SafePnotes;
  use Apache2::SafePnotes qw/pnotes/;
  use Apache2::SafePnotes qw/whatever/;

=head1 DESCRIPTION

This module cures a problem with C<Apache2::RequestRec::pnotes> and
 C<Apache2::Connection::pnotes> (available since mod_perl 2.0.3).
These functions store perl variables making
them accessible from various phases of the Apache request cycle.

According to the docs there are 2 ways to store data as a pnote:

  $r->pnotes( key=>"value" );

and

  $r->pnotes->{key}="value";

Unfortunately, these 2 versions work slightly different.
Assuming the following code

  my $v=1;
  $r->pnotes( 'v'=>$v );
  $v++;
  my $x=$r->pnotes('v');

I'd expect C<$x> to be C<1> but it turns out to be C<2>. Further on, also
this code snippet leads to unexpected results:

  my $v=1;
  $r->pnotes( 'v'=>$v );
  $r->pnotes->{v}++;
  my $x=$v;

Surprise, C<$x> is C<2> as well.

The problem lies in C<$r-E<gt>pnotes( 'v'=E<gt>$v )>. With
C<$r-E<gt>pnotes-E<gt>{v}=$v> all works as expected (C<$x==1>).

With C<Apache2::SafePnotes> the problem goes away and C<$x> will be C<1>
in both cases.

=head2 INTERFACE

This module must be C<use>'d not C<require>'d. It does it's work in an
C<import> function.

=over 4

=item B<use Apache2::SafePnotes>

creates the function C<Apache::RequestRec::safe_pnotes> as a replacement
for C<pnotes>. The old C<pnotes> function is preserved just in case some
code relies on the odd behavior.

=item B<use Apache2::SafePnotes qw/NAME/>

creates the function C<Apache::RequestRec::I<NAME>> as a replacement
for C<pnotes>. If C<pnotes> is passed as I<NAME> the original C<pnotes>
function is replaced by the safer one.

=back

=head1 SEE ALSO

modperl2, L<Apache2::RequestUtil>, L<Apache2::Connection>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
