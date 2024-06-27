package xt::ZipDiff;
use strict;
use warnings;
use utf8;
use Path::Tiny;

sub new {
    my $class = shift;

    my $workdir = Path::Tiny->tempdir();
    #my $workdir = path("./diff_tmp")->absolute;
    return bless { workdir => $workdir }, $class;
}

sub workdir { shift->{workdir} }

sub diff {
    my ($self, $got, $expected) = @_;

    return "$expected is not readble" unless -r $expected;

    my $abs_expected = path($expected)->absolute;
    my $workdir = $self->workdir;
    my $shell_cmd = join(" && ",
                         "cd $workdir",
                         "mkdir got",
                         "mkdir expected",
                         "cd got",
                         "unzip -qq -x $got",
                         "cd ../expected",
                         "unzip -qq -x $abs_expected",
                         "cd ..",
                         "diff -r got expected",
                         "true");
    #print STDERR $shell_cmd, "\n";
    open my $diffout, "-|:utf8", $shell_cmd
        or die "can't exec shell command: $!";
    my @output;
    while (<$diffout>) {
        chomp;
        next if is_ok_pattern($_);
        push @output, "$_";
    }
    return join("\n", @output);
}

sub is_ok_pattern {
    my $s = shift;

    return 1 if $s eq q{diff -r got/EPUB/content.opf expected/EPUB/content.opf};
    return 1 if $s =~ /^\d+c\d+$/;
    return 1 if $s =~ /^\d+,\d+c\d+,\d+$/; 
    return 1 if $s =~ m{<dc:identifier id="epub-id-1">urn:uuid:};
    return 1 if $s eq '---';
    return 1 if $s =~ m{<dc:date id="epub-date">};
    return 1 if $s =~ m{<meta property="dcterms:modified">};
    return;
}

1;
