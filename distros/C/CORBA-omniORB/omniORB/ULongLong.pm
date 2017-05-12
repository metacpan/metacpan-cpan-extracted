package CORBA::ULongLong;

use overload
'+'     =>      \&add,
'-'     =>      \&subtract,
'/'     =>      \&div,
'*'     =>      \&mul,
'%'     =>      \&mod,
'abs'   =>      sub { $_[0] },
'<=>'   =>      \&cmp,
'""'    =>      \&stringify;

1;

=head1 NAME

CORBA::omniORB::ULongLong - Unsigned Long long integer arithmetic for CORBA.

=head1 SYNOPSIS

 use CORBA:::omniORB;

 $a = new CORBA::ULongLong "12345678912345";
 print $a - 1000                 # produces "123456789121345"

=head1 DESCRIPTION

CORBA::omniORB::ULongLong implements the package CORBA::ULongLong.
The range of values of a CORBA::ULongLong is exactly that
of your C compiler's unsigned long long type.

Aside from overloaded C<+>, C<->, C<*>, C</>, C<%>,  C<<=>>, C<abs>, 
and C<""> operations, C<CORBA::omniORB::ULongLong> provides the 
following method:

=over 4

=item new STRING 

creates a new CORBA::ULongLong from a string.

=back

=head1 AUTHOR

Owen Taylor <otaylor@gtk.org>

=head1 SEE ALSO

perl(1).

=cut
