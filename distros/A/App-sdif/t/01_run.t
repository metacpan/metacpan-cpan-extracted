use strict;
use warnings;
use utf8;
use Test::More;
use Config;
use File::Basename qw(dirname);
use File::Spec;
use Command::Run::Tmpfile;

my $lib       = File::Spec->rel2abs('lib');
my $script    = File::Spec->rel2abs('script');
my $sdif      = "$script/sdif";
my $cdif      = "$script/cdif";
my $watchdiff = "$script/watchdiff";

# Prepend, not append.  These scripts execute each other by name
# (sdif and watchdiff invoke cdif), and their `#!/usr/bin/env perl'
# line makes the interpreter be looked up in PATH again.  Appending
# would let an installed copy, or an unrelated perl, win over the one
# under test.
$ENV{PATH}     = join ':', $script, dirname($Config{perlpath}), $ENV{PATH};
$ENV{PERL5LIB} = join ':', $lib, $ENV{PERL5LIB} // ();

# Skip on systems where /dev/fd/N (N>2) is unavailable, e.g. FreeBSD
# without fdescfs mounted.
{
    my $probe = Command::Run::Tmpfile->new;
    my $path  = $probe->path;
    unless (defined $path and -r $path) {
	plan skip_all => 'no /dev/fd or /proc/self/fd path available';
    }
}

for my $data (qw(t/DIFF.out t/DIFF-c.out t/DIFF-u.out t/DIFF-graph.out)) {
    is(sdif('-W160', $data), 0);
    is(cdif($data), 0);
}

is(sdif('--colortable'), 0);

done_testing;

sub sdif      { system($^X, "-I$lib", $sdif, @_) }
sub cdif      { system($^X, "-I$lib", $cdif, @_) }
sub watchdiff { system($^X, "-I$lib", $watchdiff, @_) }
