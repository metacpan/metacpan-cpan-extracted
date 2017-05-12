# $Id: pod-spell.t 24 2007-10-29 17:15:19Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/t/pod-spell.t $
# $Revision: 24 $
# $Date: 2007-10-29 18:15:19 +0100 (Mon, 29 Oct 2007) $
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
use File::Basename qw(basename);
use FileHandle;
use English qw( -no_match_vars );
use 5.006000;

my @POD_FILES = (
    [ qw(lib Class Dot.pm) ],
);

my @REQUIRED_MODULES_FOR_THIS_TEST = qw(
    File::Which
    Test::Spelling
);

# List of spelling programs ordered by the
# ones we want most.
my @SPELL_PROGRAMS = qw(
   spell
   aspell
);

my @STOPWORD_FILES = qw(
    stopwords-asksh.txt
);

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

if ( not $ENV{CLASS_DOT_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{CLASS_DOT_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

# ### Try to find the 'spell' program.

REQUIREDMODULE:
for my $module_name (@REQUIRED_MODULES_FOR_THIS_TEST) {
    eval qq{ use $module_name }; ## no critic
    if ($EVAL_ERROR) {
        plan( skip_all => "This test requires the $module_name module." );
    }
}

my $path_to_spell = q{};
my $spell_type    = q{};

SPELLCLONE:
for my $try_this_spell (@SPELL_PROGRAMS) {

    $path_to_spell
        = eval qq{ which("$try_this_spell") or die "no spell" }; ## no critic

    if ($path_to_spell) {
        $spell_type = $try_this_spell;
        last SPELLCLONE;
    }
}

if (! $path_to_spell) {
    my $spell_programs = join q{, }, @SPELL_PROGRAMS;
    plan( skip_all =>
        qq{This test requires a spell program. (one of: $spell_programs). } .
        qq{Please be sure it's executable and in your PATH. }
    );
}

my @stopwords;

STOPWORDFILE:
for my $stopword_file (@STOPWORD_FILES) {
    my $this_file = File::Spec->catfile($Bin, $stopword_file);

    my $fh = FileHandle->new();
    open $fh, "<$this_file" 
        or warn, next STOPWORDFILE; ## no critic

    LINE:
    for my $line (<$fh>) {
        chomp $line;
        next LINE if $line =~ m/^#/xms;
        $line =~ s/\A \s+   //xmsg;
        $line =~ s/   \s+ \z//xmsg;
        push @stopwords, $line;
    }

    close $fh;
}
add_stopwords(@stopwords);

if ($spell_type eq 'aspell') {
    $path_to_spell = "$path_to_spell list";
}
                            
set_spell_cmd($path_to_spell);

plan( tests => scalar @POD_FILES );

for my $POD_entry (@POD_FILES) {
    my $POD_file      = File::Spec->catdir(@{ $POD_entry });
    my $prev_dir      = File::Spec->updir();
    my $POD_file_path = File::Spec->catdir($Bin, $prev_dir, $POD_file);
    pod_file_spelling_ok($POD_file_path, "Spelling for $POD_file");
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
