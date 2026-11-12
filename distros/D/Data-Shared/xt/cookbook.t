use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir tempfile);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

# Needs a store the earlier sections built and a path outside this harness.
my %standalone_exempt = ('FREEZE AND SHIP' => 1);

my $base = "$FindBin::Bin/..";
my $pod = "$base/lib/Data/Shared/Cookbook.pod";

open my $fh, '<', $pod or die "$pod: $!";
my (@sections, $current);
my $lineno = 0;
while (my $line = <$fh>) {
    $lineno++;
    if ($line =~ /^=head[12]\s+(.+?)\s*$/) {
        push @sections, $current if $current && @{ $current->{code} };
        # DESCRIPTION declares the root, which the preamble below supplies.
        $current = $1 eq 'DESCRIPTION' ? undef : { title => $1, line => $lineno, code => [] };
        next;
    }
    push @{ $current->{code} }, [ $1, $lineno ] if $current && $line =~ /^    (.*)$/;
}
push @sections, $current if $current && @{ $current->{code} };
close $fh;

ok @sections >= 10, 'recipe sections found' or BAIL_OUT('Cookbook layout changed');

my $preamble = <<'PRE';
use strict;
use warnings;
no warnings 'void';
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set shared_delete shared_exists shared_incr
    shared_call shared_push shared_pop shared_compile shared_node shared_children
    shareda_get shareda_set shareda_call sharedc_get sharedc_set sharedc_incr sharedc_call);
my $dir = tempdir(CLEANUP => 1);
my $root = Data::Shared->new($dir);
sub _claim {
    my ($line, $want, $got) = @_;
    $got = 'undef' unless defined $got;
    print STDERR "CLAIM-MISMATCH line $line: got '$got', recipe says '$want'\n"
        unless "$got" eq "$want";
    return;
}
PRE

# Only a line whose comment is a bare number becomes a comparison; prose or
# '(42, 7)' cannot be compared without guessing what it meant.
sub _checkable {
    my ($code, $line) = @_;
    return $code unless $code =~ /^(\s*)(\S.*?);\s*\#\s*(-?\d+)(?:\s*:.*)?$/;
    my ($indent, $expr, $want) = ($1, $2, $3);
    return $code if $expr =~ /^(?:my|our|local|for|while|if|unless|\}|\{)\b/;
    return $code if $expr =~ /=(?![=~>])/;      # an assignment claims its own value
    return "$indent" . "_claim($line, $want, scalar do { $expr });";
}

for my $section (@sections) {
    next if $standalone_exempt{ $section->{title} };
    my $dir = tempdir(CLEANUP => 1);
    open my $out, '>', "$dir/recipe.pl" or die $!;
    print $out $preamble,
        join("\n", map { _checkable($_->[0], $_->[1]) } @{ $section->{code} }), "\n";
    close $out or die $!;

    # The croaks that classify a failure go to stderr, so it is captured too.
    my ($errfh, $errfile) = tempfile(UNLINK => 1);
    my $output = do {
        open my $saved, '>&', \*STDERR or die $!;
        open STDERR, '>&', $errfh or die $!;
        open my $run, '-|', $^X, "-I$base/lib", "$dir/recipe.pl" or die $!;
        my $o = do { local $/; <$run> };
        close $run;
        open STDERR, '>&', $saved or die $!;
        $o;
    };
    my $status = $?;
    $output .= do { open my $e, '<', $errfile or die $!; local $/; <$e> };
    my @mismatched = $output =~ /^(CLAIM-MISMATCH .*)$/mg;
    if (@mismatched) {
        fail "$section->{title} (line $section->{line}): the numbers beside it are right";
        diag $_ for @mismatched;
    }
    next if $status == 0;

    my ($first) = split /\n/, ($output // '');
    $first = '' unless defined $first;
    my $label = "$section->{title} (line $section->{line})";
    if ($first =~ /is not available; install the|Can't locate \S+\.pm/) {
        fail "$label: DS_ALL_BACKENDS is set, yet a backend is missing" if $ENV{DS_ALL_BACKENDS};
        note "$label: skipped, backend not installed";
        next;
    }
    # A section showing two spellings of one mount names it twice on purpose.
    if ($first =~ /mount '\S+' already exists/) {
        note "$label: alternative forms of one mount";
        next;
    }
    fail "$label runs as pasted";
    diag $first;
}

pass 'every recipe ran, skipped a missing backend, or showed alternatives';
done_testing;
