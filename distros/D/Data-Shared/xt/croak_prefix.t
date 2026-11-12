use strict;
use warnings;
use Test::More;
use FindBin;
use File::Find ();
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my @files;
File::Find::find(sub { push @files, $File::Find::name if /\.pm\z/ }, "$FindBin::Bin/../lib");
cmp_ok scalar @files, '>=', 15, 'every module is scanned';

my ($checked, @bare) = (0);
for my $file (sort @files) {
    open my $fh, '<', $file or die "$file: $!";
    my ($rel, $n) = ($file =~ m{(lib/.*)}s ? $1 : $file, 0);
    while (my $line = <$fh>) {
        $n++;
        next unless $line =~ /Carp::croak\(/;
        # Only a literal message is visible to this scan.
        next unless $line =~ /Carp::croak\(\s*(?:sprintf\s*)?(['"])(.*?)\1/;
        my $msg = $2;
        $checked++;
        push @bare, "$rel:$n: $msg" unless $msg =~ /\AData::Shared: /;
    }
    close $fh;
}
cmp_ok $checked, '>=', 120, 'and a realistic number of literal messages seen';
is_deeply \@bare, [], 'every literal croak message carries the facade prefix'
    or diag join "\n", @bare;

done_testing;
