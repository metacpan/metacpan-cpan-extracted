#perl -T 

use Test::Base;
use Carp;

my $OUTFILE = 'test-block.pl';
my $PERL5OPTS = '-Mblib -MCarp::Always';

sub Test::Base::Filter::exec_perl_stderr {
    my $self = shift;       # The Test::Base::Filter object
    my $tmpfile = $OUTFILE;
    $self->_write_to($tmpfile, @_);
    open my $execution, "$^X $PERL5OPTS $OUTFILE 2>&1 |"
      or die "Couldn't open subprocess: $!\n";
    local $/;
    my $output = <$execution>;
    close $execution;
    unlink($tmpfile)
      or die "Couldn't unlink $tmpfile: $!\n";
    return $output;
}

sub fixup_stderr {
    s/\.$//mg if $Carp::VERSION < '1.25';
}

filters { perl => 'exec_perl_stderr', stderr => 'fixup_stderr' };
run_is_deeply 'perl', 'stderr';

__END__

=== basic test
--- perl

package A;

sub f {
#line 1
    warn  "Beware!";
}

sub g {
#line 2
	f();
}

package main;

#line 3
A::g();

--- stderr
Beware! at test-block.pl line 1.
	A::f() called at test-block.pl line 2
	A::g() called at test-block.pl line 3

=== interpreter-thrown warnings

--- perl

package A;

sub f {
	use strict;
	my $a;
#line 1
	my @a = @$a;
}

sub g {
#line 2
	f();
}

package main;

#line 3
A::g();

--- stderr
Can't use an undefined value as an ARRAY reference at test-block.pl line 1.
	A::f() called at test-block.pl line 2
	A::g() called at test-block.pl line 3

=== warn ()

--- perl
warn

--- stderr
Warning: something's wrong at test-block.pl line 1.

=== die ()

--- perl
die

--- stderr
Died at test-block.pl line 1.

=== $@ = EXCEPTION; warn ()

--- perl
local $@ = 'EXCEPTION';
warn

--- stderr
EXCEPTION	...caught at test-block.pl line 2.

=== $@ = EXCEPTION; die ()

--- perl
local $@ = 'EXCEPTION';
die

--- stderr
EXCEPTION	...propagated at test-block.pl line 2.

=== foo at bar

--- perl
die "foo at bar"

--- stderr
foo at bar at test-block.pl line 1.

=== Kaboom + diagnostics RT#96561

--- perl
die "Kaboom at foo/bar.pl line 123
Some additional diagnostics added here by
a custom error handler\n"

--- stderr
Kaboom at foo/bar.pl line 123
Some additional diagnostics added here by
a custom error handler
 at test-block.pl line 1.

=== exception objects

--- perl

package error;
use overload '""' => sub { "Exception: " . shift->{error} . "\n" };

package main;
die bless { error => 'bad' }, error;

--- stderr
Exception: bad

=== Carp::carp

--- perl
use Carp;
carp 'foo';

--- stderr
foo at test-block.pl line 2.

=== Carp::croak

--- perl
use Carp;
croak 'foo';

--- stderr
foo at test-block.pl line 2.

=== no Carp::Always

--- perl
no Carp::Always;
warn "foo\n";

--- stderr
foo

=== no Carp::Always; use Carp::Always;

--- perl
Carp::Always->unimport;
warn "foo\n";
Carp::Always->import;
warn "foo\n";

--- stderr
foo
foo
 at test-block.pl line 4.

=== nested Carp::Carp

--- perl

package A;
use Carp 'carp';

sub f {
#line 1
    carp "Beware!";
}

sub g {
#line 2
	f();
}

package main;

#line 3
A::g();

--- stderr
Beware! at test-block.pl line 1.
	A::f() called at test-block.pl line 2
	A::g() called at test-block.pl line 3

=== Preserve non-repeated "at FILE line LINE" GH#8

--- perl
die "haha at /Where/isit.t line 4545.\n"

--- stderr
haha at /Where/isit.t line 4545.
 at test-block.pl line 1.

=== Carp::confess RT#123354

--- perl

package A;
use Carp 'confess';

sub f {
#line 1
    confess "Beware!";
}

sub g {
#line 2
	f();
}

package main;

#line 3
A::g();

--- stderr
Beware! at test-block.pl line 1.
	A::f() called at test-block.pl line 2
	A::g() called at test-block.pl line 3
