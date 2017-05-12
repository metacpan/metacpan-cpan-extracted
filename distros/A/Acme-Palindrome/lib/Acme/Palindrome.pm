package Acme::Palindrome;
# $Id: $
use strict qw[vars subs];

use vars qw[$VERSION $TIE];
$VERSION = (qw$Revision: 0.1$)[1];
$TIE = " \t"x8;

sub backward { "$TIE\n".palindrome(split "\n", $_[0])."\n" }
sub forward  { palindrome(split "\n", $_[0]) }

sub is_forward  { $_[0] !~ /^$TIE/ }
sub is_backward { $_[0] =~ /^$TIE/ }

open 0 or print "Can't reverse '$0'\n" and exit;
(my $code = join "", <0>) =~ s/.*^\s*use\s+Acme::Palindrome\s*;\n//sm;
local $SIG{__WARN__} = \&is_forward;
do {eval forward $code; exit} if is_backward $code;
open 0, ">$0" or print "Cannot reverse '$0'\n" and exit;
print {0} "use Acme::Palindrome;\n", backward $code and exit;

sub palindrome {
    my $max = 0;
    length > $max && ( $max = length ) for @_;
    return join "\n",
      map sprintf( "%${max}s", scalar reverse $_ ),
	reverse @_;
}

1;

__END__

=head1 NAME

Acme::Palindrome - Programs are the same backward and forward

=head1 SYNOPSIS

  use Acme::Palindrome;

  print "Hello world";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::Palindrome>, the module reverses the code in your source file from top to bottom, left to right.  The code continues to work exactly as it did before, but now it looks like this:

  use Acme::Palindrome;


  ;"dlrow olleH" tnirp

=head1 DIAGNOSTICS

=over 4 C<Can't reverse "%s">

Acme::Palindrome could not access the source file to modify it.

=head1 SEE ALSO

L<Acme::Bleach> - Code and documentation nearly taken verbatim.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 COPYRIGHT

  Copyright (c) 2003, Casey West.  All Rights Reserved.
  This module is free software.  It may be used under the
  same terms as Perl itself.

=cut
