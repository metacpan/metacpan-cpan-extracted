#!perl

# autoprint => 1 causes EzDD obj to print to STDOUT if called in void
# context.  autoprint => 2 sends output STDERR
use strict;
use Test::More (tests => 24);

pass "test void-context calls";
use_ok qw( Data::Dumper::EasyOO );

my $ddez = Data::Dumper::EasyOO->new(indent=>1);
isa_ok ($ddez, 'Data::Dumper::EasyOO', "new() retval");

cleanup(); $!=0;

sub content_matches {		# Mojo, the helper monkey
    my ($fname, $rex) = @_;
    open (my $fh, $fname) or die "$!: $fname";
    local $/ = undef;
    my $buf = <$fh>;
    return 1 if $buf =~ m/$rex/;
    print "failed content-check, got: $buf, expected $rex\n";
    return 0;
}

sub write2it {
    my ($it, $i, $tag, $what) = @_;
    my $ddez = Data::Dumper::EasyOO->new(indent=>1);
    $ddez->Set(indent => $i, autoprint => $it);
    $ddez->($tag => $what);
}

SKIP: {
    eval "use Test::Output";
    skip "need Test::Output to test autoprint to stdout,stderr", 9 if $@;

    stdout_is(sub{write2it(0, 1, 'foo','to stdout')},
	      '',
	      "stdout is empty, as expected");

    stdout_is(sub{write2it(1, 1, 'foo','to stdout')},
	      qq{\$foo = 'to stdout';\n},
	      "stdout has expected output");

    stderr_is(sub{write2it(2,1, 'foo','to stderr')},
	      qq{\$foo = 'to stderr';\n},
	      "stderr has expected output");

    stdout_is(sub{write2it(\*STDOUT,1, 'foo','to stdout')},
	      qq{\$foo = 'to stdout';\n},
	      '\*STDOUT has expected output');

    stderr_is(sub{write2it(\*STDERR,1, 'foo','to stderr')},
	      qq{\$foo = 'to stderr';\n},
	      '\*STDERR has expected output');

    stdout_is(sub{write2it(1, 1, 'bar',{a=>1, b=>2})},
	      <<'EORef', "stdout has expected hashdump");
$bar = {
  'a' => 1,
  'b' => 2
};
EORef

    stdout_is(sub{write2it(1, 2, 'bar',{a=>1, b=>2})},
	      <<'EORef', "stdout has expected hashdump");
$bar = {
         'a' => 1,
         'b' => 2
       };
EORef

    stderr_is(sub{write2it(2, 1, 'baz',[qw(foo bar bum)])},
	      <<'EORef', "stderr has expected arraydump");
$baz = [
  'foo',
  'bar',
  'bum'
];
EORef

    stderr_is(sub{write2it(2, 2, 'baz',[qw(foo bar bum)])},
	      <<'EORef', "stderr has expected arraydump");
$baz = [
         'foo',
         'bar',
         'bum'
       ];
EORef
}


SKIP: {
    skip "- open(my \$fh) not in 5.00503", 3 unless $] >= 5.006;
    pass "testing autoprint to open filehandle (ie GLOB)";

    open (my $fh, ">out.autoprint") or die "cant open out.autoprint: $!";
    $ddez->Set(autoprint => $fh);
    $ddez->(foo => 'to file');
    close $fh;

    # diag ("Note: expecting \$! warning: print() on closed filehandle \$fh");
    local $SIG{__WARN__} = sub {}; # silence the warning

    eval { $ddez->(foo => 'to file') };
    like ($!, qr/Bad file (number|descriptor)/,
	  "got expected err writing to closed file: $!");

    ok (content_matches("out.autoprint", qr/^\$foo = 'to file';$/),
	"out.autoprint has expected content");
}

SKIP: {
    eval "use IO::String";
    skip "these tests need IO::String", 2 if $@;
    pass "testing autoprint => IO using IO::string";

    my $io = IO::String->new(my $var);
    $ddez->Set(autoprint => $io);
    $ddez->(foo => 'bar to iostring obj');
    is ($var, "\$foo = 'bar to iostring obj';\n",
	"autoprint to IO::string storage");
}

SKIP: {
    skip "these tests need 5.8.0", 2 if $] < 5.008;
    pass "testing autoprint => IO using 5.8 open (H, '>', \\\$scalar)";
    my ($var,$io);
    # w/o eval, this breaks compile under 5.5.3 
    eval "open (\$io, '>', \\\$var)";
    warn $@ if $@;

    $ddez->Set(autoprint => $io);
    $ddez->(foo => 'bar to opened scalar-ref');
    is ($var, "\$foo = 'bar to opened scalar-ref';\n",
	"autoprint to opened scalar ref");
}

SKIP: {
    eval "use Test::Warn";
    skip("these tests need Test::Warn", 5) if $@;

    pass("testing autoprint invocation w.o setup");

    my $ddez = Data::Dumper::EasyOO->new(indent=>1);
    # warning_like is more relaxed vs carp vs warn
    warning_like ( sub { $ddez->(foo=>'bar') },
		   qr/called in void context, without autoprint defined/,
		   "expected warning b4 setup");

    open (my $fh, ">out.autoprint") or die "cant open out.autoprint: $!";
    $ddez->Set(autoprint => $fh);
    $ddez->(ok => 'yeah');
    $ddez->(foo => 'to file');

    close $fh;

    ok (content_matches("out.autoprint",
			qr/^\$ok = 'yeah';\n\$foo = 'to file';$/),
	"out.autoprint has expected content");

    $ddez->Set(autoprint => undef);
    warning_like ( sub { $ddez->(foo=>'bar') },
		   qr/called in void context, without autoprint defined/,
		   "expected warning after autoprint reset to undef");

    {	# test package, which cannot print
	package Foo;
	sub new { bless {}, shift}
    }
    
    $ddez->Set(autoprint => new Foo);
    local $SIG{__WARN__} = sub {}; # silence the warning to the terminal
    $ddez->(\%INC);
    warning_like ( sub { $ddez->(foo=>'bar') },
		   qr/illegal autoprint value: Foo=HASH/,
		   "expected warning when autoprinting to un-capable object");
}



unless ($ENV{TEST_VERBOSE}) {
    cleanup();
} else {
    diag "to see output files (normally deleted), set TEST_VERBOSE b4 test";
}

sub cleanup {
    unlink "auto.stderr2","auto.stdout2";
    unlink "auto.stderr1","auto.stdout1";
    unlink "auto.stderr","auto.stdout";
    unlink "out.autoprint";
}

__END__

