package Aion::Carp;
use 5.008001;
use common::sense;

our $VERSION = "1.6";

use Carp qw//;
use Scalar::Util qw//;

sub handler {
    my ($x) = @_;

    if(!ref $x) {
        no utf8; use bytes;
        if($x =~ s/\n[ \t]+\.\.\.propagated at .* line \d+\.\n\z/\n/) {}
        else {
            $x =~ s/ at .*? line \d+\.\n\z//;
            my $c = Carp::longmess('');
            $c =~ s/^( at .*? line \d+)\.\n/$x\n\tdie(...) called$1\n/;
            $x = $c;
        }
    }
    elsif(Scalar::Util::reftype($x) eq "HASH" && !exists $x->{STACKTRACE}) {
        my $c = Carp::longmess("die(...) called");
        $c =~ s/^(.*\d+)\.\n/$1\n/;
        $x->{STACKTRACE} = $c;
    }

    die $x;
}

sub import {
    $SIG{__DIE__} = \&handler;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Carp - adds stack trace to exceptions

=head1 VERSION

1.6

=head1 SYNOPSIS

	use Aion::Carp;
	
	sub A { die "hi!" }
	sub B { A() }
	sub C { eval { B() }; die if $@ }
	sub D { C() }
	
	eval { D() };
	
	my $expected = "hi!
	    die(...) called at t/aion/carp.t line 15
	    main::A() called at t/aion/carp.t line 16
	    main::B() called at t/aion/carp.t line 17
	    eval {...} called at t/aion/carp.t line 17
	    main::C() called at t/aion/carp.t line 18
	    main::D() called at t/aion/carp.t line 20
	    eval {...} called at t/aion/carp.t line 20
	";
	$expected =~ s/^ {4}/\t/gm;
	
	substr($@, 0, length $expected) # => $expected
	
	
	my $exception = {message => "hi!"};
	eval { die $exception };
	$@  # -> $exception
	$@->{message}  # => hi!
	$@->{STACKTRACE}  # ~> ^die\(\.\.\.\) called at
	
	$exception = {message => "hi!", STACKTRACE => 123};
	eval { die $exception };
	$exception->{STACKTRACE} # -> 123
	
	$exception = [];
	eval { die $exception };
	$@ # --> []

=head1 DESCRIPTION

This module replaces C<$SIG{__DIE__}> with a function that adds a stack trace to exceptions.

If the exception is a string, a stack trace is added to the message. And if the exception is a hash (C<{}>) or a hash-based object (C<bless {}, "..."), then the>STACKTRACE` key with stacktrace is added to it.

When the exception is thrown again, the stack trace is not added, but remains the same.

=head1 SUBROUTINES

=head2 handler ($message)

Adds a stack trace to C<$message>.

	eval { Aion::Carp::handler("hi!") }; $@  # ~> ^hi!\n\tdie

=head2 import

Replaces C<$SIG{__DIE__}> with C<handler>.

	$SIG{__DIE__} = undef;
	$SIG{__DIE__} # --> undef
	
	Aion::Carp->import;
	
	$SIG{__DIE__} # -> \&Aion::Carp::handler

=head1 SEE ALSO

=over

=item * C<Carp::Always>

=back

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Surf module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
