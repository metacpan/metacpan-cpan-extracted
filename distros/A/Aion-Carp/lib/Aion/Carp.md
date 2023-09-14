# NAME

Aion::Carp - added stacktrace to exceptions

# VERSION

1.5

# SYNOPSIS

```perl
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
```

# DESCRIPTION

This module replace `$SIG{__DIE__}` to function, who added to exception stacktrace.

If exeption is string, then stacktrace added to message. And if exeption is hash (`{}`), or object on base hash (`bless {}, "..."`), then added to it key `STACKTRACE` with stacktrace.

Where use propagation, stacktrace do'nt added.

# SUBROUTINES

## handler ($message)

It added to `$message` stacktrace.

```perl
eval { Aion::Carp::handler("hi!") }; $@  # ~> ^hi!\n\tdie
```

## import

Replace `$SIG{__DIE__}` to `handler`.

```perl
$SIG{__DIE__} = undef;
$SIG{__DIE__} # --> undef

Aion::Carp->import;

$SIG{__DIE__} # -> \&Aion::Carp::handler
```

# INSTALL

Add to **cpanfile** in your project:

```cpanfile
on 'test' => sub {
	requires 'Aion::Carp',
		git => 'https://github.com/darviarush/perl-aion-carp.git',
		ref => 'master',
	;
};
```

And run command:

```sh
$ sudo cpm install -gvv
```

# SEE ALSO

* `Carp::Always`

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

⚖ **GPLv3**