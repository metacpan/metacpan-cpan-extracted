#!/usr/bin/env perl
use strict;
use warnings;
use App::Microsite::Assemble;
use Path::Class;
use Getopt::Long;

my $with_cms;
GetOptions ( with_cms => \$with_cms );

my %args = (
    helpers => {
        activeMenu => sub {
            my ($context, $menu) = @_;
            if( $context->{'active-menu'} && $context->{'active-menu'} eq $menu ) {
                return 'class=active';
            }
        },
    },
);

if ($with_cms) {
    $args{fragment_filter} = sub {
        my ($content, $file, $name) = @_;
        my $relative_file = $file;
        $relative_file =~ s/^fragments\///;
        return "<iicmsfragment path='$relative_file'>$content</iicmsfragment>";
    };

    $args{missing_fragment} = sub {
        my ($name, $paths) = @_;
        my $relative_fragment = $paths->[0];
        $relative_fragment =~ s/^fragments\///;
        dir($relative_fragment)->mkpath;
        return "<iicmsfragment path='$relative_fragment/$name'>$name</iicmsfragment>";
    };
}

my $report = App::Microsite::Assemble->assemble(%args);

# find all the fragments that were not referenced by any template
# and warn about it
my $fragment_iter = File::Next::files('fragments/');
while (defined(my $fragment = $fragment_iter->())) {
    warn "Unused fragment $fragment\n"
        if !$report->{seen_fragments}->{$fragment};
}

my $files = keys %{ $report->{built_files} };
if ($files == 1) {
    print "Built 1 file\n";
}
else {
    print "Built $files files\n";
}
