package CORBA::LongDouble;

use overload
'+'     =>      \&add,
'-'     =>      \&subtract,
'/'     =>      \&div,
'*'     =>      \&mul,
'abs'   =>      \&abs,
'neg'   =>      \&neg,
'<=>'   =>      \&cmp,
'""'    =>      \&stringify;

1;

=head1 NAME

CORBA::ORBit::LongDouble - Long double arithmetic for CORBA.

=head1 SYNOPSIS

 use CORBA:::ORBit;

 $a = new CORBA::LongDouble "12345678.912345";
 print $a - 1000                 # produces "1.23446789121345e7"

=head1 DESCRIPTION

CORBA::ORBit::LongDouble implements the package CORBA::LongDouble.
The range of values of a CORBA::LongDouble is exactly that
of your C compiler's long double type.

Aside from overloaded C<+>, C<->, C<*>, C</>, C<<=>>, C<abs>, 
C<neg>, and C<""> operations, C<CORBA::ORBit::LongDouble> provides the 
following method:

=over 4

=item new STRING 

creates a new CORBA::LongDouble from a string.

=back

=head1 AUTHOR

Owen Taylor <otaylor@gtk.org>

=head1 SEE ALSO

perl(1).

=cut
