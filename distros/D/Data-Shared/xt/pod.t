use strict;
use warnings;
use Test::More;
use FindBin;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
eval { require Test::Pod; Test::Pod->import(); 1 }
    or plan skip_all => 'Test::Pod required';

# 'lib', not the default, which checks the blib copy when one exists. Parenthesised,
# because `sort Test::Pod::all_pod_files('lib')` parses as sort SUBNAME LIST.
my @files = sort(Test::Pod::all_pod_files('lib'));
cmp_ok scalar @files, '>=', 14, 'the POD files were found';
pod_file_ok($_) for @files;

# Wrapped in a sub, so nothing runs: the synopses address stores that do not exist here.
my $synopses = 0;
for my $file (@files) {
    open my $fh, '<', $file or die "$file: $!";
    my $code = '';
    while (my $l = <$fh>) {
        next unless $l =~ /^=head1 SYNOPSIS/ .. $l =~ /^=(?!head1 SYNOPSIS)\w/;
        $code .= $l =~ s/^\s{4}//r if $l =~ /^\s+\S/ || ($code && $l !~ /\S/);
    }
    next unless $code =~ /\S/;
    $synopses++;
    my %seen;
    my @vars = grep { !$seen{$_}++ } $code =~ /([\$\@\%][A-Za-z_]\w*)/g;
    # No warnings: predeclaring every variable shadows the ones the example declares.
    ok eval("no warnings;\nsub { my (" . join(', ', @vars) . ");\n$code\n}; 1"),
        "$file SYNOPSIS compiles as pasted" or diag "$@\n$code";
}
# The four public modules; the internal ones carry no synopsis.
cmp_ok $synopses, '>=', 4, 'the synopses were found';

# make rebuilds README in a checkout; this catches a POD edit committed without it.
SKIP: {
    skip 'Pod::Text required', 2 unless eval { require Pod::Text; 1 };
    my $regenerated = '';
    my $parser = Pod::Text->new;
    $parser->output_string(\$regenerated);
    $parser->parse_file("$FindBin::Bin/../lib/Data/Shared.pm");
    open my $fh, '<', "$FindBin::Bin/../README" or die $!;
    my $shipped = do { local $/; <$fh> };
    cmp_ok length $shipped, '>', 1000, 'the shipped README has content';
    is $shipped, $regenerated, 'README is pod2text of the current POD';
}

done_testing;
