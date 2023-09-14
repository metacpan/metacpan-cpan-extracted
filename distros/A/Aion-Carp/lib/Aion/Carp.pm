package Aion::Carp;
use 5.008001;
use common::sense;

our $VERSION = "1.5";

use Carp qw//;
use Scalar::Util qw//;

sub handler {
    my ($x) = @_;

    if(!ref $x) {
        no utf8; use bytes;
        if($x =~ s/\n[ \t]+\.\.\.propagated at .* line \d+\.\n\z/\n/a) {}
        else {
            $x =~ s/ at .*? line \d+\.\n\z//a;
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

Aion::Carp - added stacktrace to exceptions

=head1 VERSION

1.5

=head1 SYNOPSIS

	use Aion::Carp;
	
	sub A { die "hi!" }
	sub B { A() }
	sub C { eval { B() }; die if $@ }
	sub D { C() }
	
	eval { D() };
	
	my $expected = "hi!
	    die(...) called at t/aion/carp.t line 14
	    main::A() called at t/aion/carp.t line 15
	    main::B() called at t/aion/carp.t line 16
	    eval {...} called at t/aion/carp.t line 16
	    main::C() called at t/aion/carp.t line 17
	    main::D() called at t/aion/carp.t line 19
	    eval {...} called at t/aion/carp.t line 19
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

This module replace C<$SIG{__DIE__}> to function, who added to exception stacktrace.

If exeption is string, then stacktrace added to message. And if exeption is hash (C<{}>), or object on base hash (C<bless {}, "...">), then added to it key C<STACKTRACE> with stacktrace.

Where use propagation, stacktrace do'nt added.

=head1 SUBROUTINES

=head2 handler ($message)

It added to C<$message> stacktrace.

	eval { Aion::Carp::handler("hi!") }; $@  # ~> ^hi!\n\tdie

=head2 import

Replace C<$SIG{__DIE__}> to C<handler>.

	$SIG{__DIE__} = undef;
	$SIG{__DIE__} # --> undef
	
	Aion::Carp->import;
	
	$SIG{__DIE__} # -> \&Aion::Carp::handler

=head1 INSTALL

Add to B<cpanfile> in your project:

	on 'test' => sub {
		requires 'Aion::Carp',
			git => 'https://github.com/darviarush/perl-aion-carp.git',
			ref => 'master',
		;
	};

And run command:

	$ sudo cpm install -gvv

=head1 SEE ALSO

=over

=item * C<Carp::Always>

=back

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>
