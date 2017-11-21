package App::optex::util;

1;

package util;

sub setenv {
    while (($a, $b) = splice @_, 0, 2) {
	$ENV{$a} = $b;
    }
}

1;

=head1 NAME

util - optex utility modules

=head1 SYNOPSIS

optex -Mutil

=head1 DESCRIPTION

This module sample utility functions for command B<optex>.

Function can be called with option declaration.  Parameters for the
function are passed by name and value list: I<name>=I<value>.  Value 1
is assigned for the name without value.

In this example,

    optex -Mutil::function(debug,message=hello,count=3)

option I<debug> has value 1, I<message> has string "hello", and
I<count> also has string "3".

=head1 FUNCTION

=over 7

=item B<setenv>(I<NAME>=VALUE,I<NAME2>=VALUE2,...)

Set environment variable I<NAME> to I<VALUE>, and so on.

=back

=cut
