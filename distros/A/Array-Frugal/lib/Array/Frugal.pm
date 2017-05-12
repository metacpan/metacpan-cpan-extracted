package Array::Frugal;

use 5.000;
use strict;

use vars qw /$VERSION/;

$VERSION = '0.01';


# Preloaded methods go here.

sub new{
	bless [1,2,3,4,5,6,7,0];
}
sub PUSH{ # pop reuse stack or extend
	my $a = shift;
        my $i = $a->[0];
	if($i){
		$a->[0] = $a->[$i];
	}else{
		$i = ++$#$a; #extend
	};
	$a->[$i] = shift;
	$i;

}
sub FETCH{
	${$_[0]}[$_[1]];
}
sub STORE{
	${$_[0]}[$_[1]] = $_[2];

}
sub DELETE{  # stack index for reuse
	my $r = ${$_[0]}[$_[1]];
	${$_[0]}[$_[1]] = ${$_[0]}[0];
	${$_[0]}[0] = $_[1];
	$r;
};

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Array::Frugal - Arrays that re-use deleted indices

=head1 SYNOPSIS

  use Array::Frugal;
  my $stash = new Array::Frugal;
  $index = $stash->PUSH(34);
  print $stash->FETCH($index);  # prints 34;
  $stash->DELETE($index); # $index can be re-used now
  

=head1 DESCRIPTION

Frugal as in memory use. Instead of continuing to count upwards
toward MAXINT, when an element is deleted from a frugal array
the index is available for re-use.

Currently new, PUSH, FETCH, STORE, and DELETE are all the
methods that are defined, but this may become tieable in
a future release.


=head1 HISTORY

=over 8

=item 0.01

Original version;

=back



=head1 SEE ALSO


=head1 AUTHOR

david l nicol, E<lt>davidnico@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by david l nicol

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
