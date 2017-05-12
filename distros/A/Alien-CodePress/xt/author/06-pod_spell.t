use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
use File::Basename qw(basename);
use FileHandle;
use File::Find;
use English qw( -no_match_vars );
use 5.006_001;

my @REQUIRED_MODULES_FOR_THIS_TEST = qw(
    File::Which
    Test::Spelling
);

# List of spelling programs ordered by the
# ones we want most.
my @SPELL_PROGRAMS = qw(
    aspell
    spell
);

my @STOPWORD_FILES = qw(
    stopwords-asksh.txt
);

if ( not $ENV{GETOPTLL_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{GETOPTLL_AUTHOR} to a true value to run.';
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

    for my $line (<$fh>) {
        chomp $line;
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

my $UPDIR  = File::Spec->updir;
my $libdir = File::Spec->catfile($Bin, $UPDIR, $UPDIR, 'lib');

my @pm_files;
my $spelltest_pm_files = sub {
    my $source_file = $File::Find::name; ## no critic
    return if not -f $source_file;
    return if not -T $source_file;
    return if not $source_file =~ m{\. (?: pm | pod | pl ) $}xms;
    
    push @pm_files, $source_file; 
};

find( $spelltest_pm_files, $libdir );

plan( tests => scalar @pm_files );

for my $pm_file (@pm_files) {
    pod_file_spelling_ok($pm_file);
}
