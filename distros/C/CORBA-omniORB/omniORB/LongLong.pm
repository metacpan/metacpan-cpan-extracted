package CORBA::LongLong;

use overload
'+'     =>      \&add,
'-'     =>      \&subtract,
'/'     =>      \&div,
'*'     =>      \&mul,
'%'     =>      \&mod,
'abs'   =>      \&abs,
'neg'   =>      \&neg,
'<=>'   =>      \&cmp,
'""'    =>      \&stringify;

1;

=head1 NAME

CORBA::omniORB::LongLong - Long long integer arithmetic for CORBA.

=head1 SYNOPSIS

 use CORBA:::omniORB;

 $a = new CORBA::LongLong "12345678912345";
 print $a - 1000                 # produces "123456789121345"

=head1 DESCRIPTION

CORBA::omniORB::LongLong implements the package CORBA::LongLong.
The range of values of a CORBA::LongLong is exactly that
of your C compiler's long long type.

Aside from overloaded C<+>, C<->, C<*>, C</>, C<%>,  C<<=>>, C<abs>, 
C<neg>, and C<""> operations, C<CORBA::omniORB::LongLong> provides the 
following method:

=over 4

=item new STRING 

creates a new CORBA::LongLong from a string.

=back

=head1 AUTHOR

Owen Taylor <otaylor@gtk.org>

=head1 SEE ALSO

perl(1).

=cut
