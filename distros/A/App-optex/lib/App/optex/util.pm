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

=cut

package App::optex::util;

use strict;
use warnings;

use List::Util qw(pairmap);

=pod

=over 7

=item B<setenv>(I<NAME>=VALUE,I<NAME2>=VALUE2,...)

Set environment variable I<NAME> to I<VALUE>, and so on.

=back

=cut

sub setenv {
    pairmap { $ENV{$a} = $b } @_;
}

=pod

=over 7

=item B<chdir>(B<PATH>=I<directory>)

Change working directory to I<directory>.

=back

=cut

sub chdir {
    my %arg = @_;
    my $dir = $arg{PATH} or do {
	warn __PACKAGE__."::chdir PATH is required.\n";
	return;
    };
    chdir $dir or warn "$dir: $!\n";
}

1;

__DATA__

option --chdir -M__PACKAGE__::chdir(PATH=$<shift>)
