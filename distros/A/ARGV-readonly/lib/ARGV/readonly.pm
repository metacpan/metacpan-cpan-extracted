package ARGV::readonly;

use 5.00001;

$VERSION = '0.01';

sub import{
   # Tom Christiansen in Message-ID: <24692.1217339882@chthon>
   # reccomends essentially the following:
   for (@ARGV){
       s/^(\s+)/.\/$1/;	# leading whitespace preserved
       s/^/< /;		# force open for input
       $_.=qq/\0/;	# trailing whitespace preserved & pipes forbidden
   };
};


1;
__END__

=head1 NAME

ARGV::readonly - make <> open files regardless of leading/trailing whitespace and/or control characters such as |, >, amd <. 

=head1 SYNOPSIS

this module allows

  use ARGV::readonly;
  while(<>){
       ...

to be safer in hostile environments where one is bullheaded enough to
give * as the command line argument.  See rants on P5P from July, 2008.

=head1 DESCRIPTION

the code is shorter than the documentation.  Please look at it.

=head2 EXPORT

None by default.

=head1 TO DO

ideally a suite of ARGV::* modules will appear, each doing their little thing,
in a way that they won't stomp on each other's toes.  This module has no
exclusion interface or anything, so an @ARGV modifier that, for instance,
preprocesses *.gz into C<"gunzip -c $_ |"> is either going to have to undo
the mods made here or be incompatible.

=head1 HISTORY

=over 8

=item 0.01

modified suggestion made by Tom Christiansen in Message-ID: <24692.1217339882@chthon>

=back

=head1 SEE ALSO

L<Encode::Argv>

July 2008 perl5 porters archive

=head1 AUTHOR

furtively assembled by
David Nicol <davidnico@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is hereby placed in the public domain.

=cut
