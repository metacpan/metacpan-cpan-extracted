#!/usr/bin/env perl
use strict;

use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 29;

#----------------------------------------------------------------------
# Change the modification date of a file

sub age {
	my ($filename, $sec) = @_;
	return unless -e $filename;
	return if $sec <= 0;
	
    my @stats = stat($filename);
    my $date = $stats[9];
    $date -= $sec;
    utime($date, $date, $filename);
    
    return; 
}

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::FormatPage;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;
chmod 0755, $test_dir;
mkdir catfile($test_dir, "sub");
chmod 0755, catfile($test_dir, "sub");
chdir $test_dir;

my %configuration = ();

#----------------------------------------------------------------------
# Create object

my $up = App::Followme::FormatPage->new();

isa_ok($up, "App::Followme::FormatPage"); # test 1
can_ok($up, qw(new run)); # test 2

#----------------------------------------------------------------------
# Test parse_blocks

do {
    my $blocks = {};
    my $block_handler = sub {
        my ($blockname, $in, $blocktext) = @_;
        $blocks->{$blockname} = $blocktext;
        return;
    };

    my $prototype = [];
    my $template_handler = sub {
        my ($blocktext) = @_;
        push(@$prototype, $blocktext);
        return;
    };

    my @page = (
                "Top line",
                "<!-- section first in folder -->",
                "First block",
                "<!-- endsection first -->",
                "Middle line",
                "<!-- section second -->",
                "Second block",
                "<!-- endsection second -->",
                "Last line",
               );

    my $page = join("\n", @page) . "\n";
    $up->parse_blocks($page, $block_handler, $template_handler);

    my $ok_blocks = {
        first => join("\n", @page[1..3]),
        second => join("\n", @page[5..7]),
    };

    my $ok_prototype = [
                        "Top line\n",
                        "\nMiddle line\n",
                        "\nLast line\n",
                           ];

    is_deeply($blocks, $ok_blocks, 'Parse blocks'); # test 3
    is_deeply($prototype, $ok_prototype, 'Parse prototype'); # test 4

    $blocks = {};
    $prototype = [];
    my @bad_page = @page;
    pop(@bad_page); pop(@bad_page);
    $page =join("\n", @bad_page) . "\n";

    eval {
        $up->parse_blocks($page, $block_handler, $template_handler);
    };
    is($@, "Unmatched block (<!-- section second -->)\n", 'Missing end'); # test 5

    @bad_page = @page;
    shift(@bad_page); shift(@bad_page);
    $page =join("\n", @bad_page) . "\n";

    eval {
        $up->parse_blocks($page, $block_handler, $template_handler);
    };
    is($@, "Unmatched (<!-- endsection first -->)\n", 'Missing begin'); # test 6

    @bad_page = @page;
    splice(@bad_page, 3, 1);
    $page =join("\n", @bad_page) . "\n";

    eval {
        $up->parse_blocks($page, $block_handler, $template_handler);
    };
    is($@, "Improperly nested block (<!-- section second -->)\n",
       'Begin inside of begin'); # test 7

    @bad_page = @page;
    splice(@bad_page, 3, 3);
    $page =join("\n", @bad_page) . "\n";

    eval {
        $up->parse_blocks($page, $block_handler, $template_handler);
    };
    is($@, "Unmatched (<!-- endsection second -->)\n",
       'Begin does not match end'); # test 8
};

#----------------------------------------------------------------------
# Test parse_page

do {
    my @page = (
                "Top line",
                "<!-- section first -->",
                "First block",
                "<!-- endsection first -->",
                "Middle line",
                "<!-- section second -->",
                "Second block",
                "<!-- endsection second -->",
                "Last line",
               );

    my $page = join("\n", @page) . "\n";
    my $up = App::Followme::FormatPage->new;
    my $blocks = $up->parse_page($page);

    my $ok_blocks = {
        first => join("\n", @page[1..3]),
        second => join("\n", @page[5..7]),
    };

    is_deeply($blocks, $ok_blocks, 'Parse undecorated blocks'); # test 9

    my $bad_page = $page;
    $bad_page =~ s/second/first/g;
    $blocks = eval {$up->parse_page($bad_page)};

    is($@, "Duplicate block name (first)\n", 'Duplicate block names'); # test 10
};

#----------------------------------------------------------------------
# Test update_file

do {
    my @prototype = (
                "Top line",
                "<!-- section first in folder -->",
                "First block",
                "<!-- endsection first -->",
                "Middle line",
                "<!-- section second -->",
                "Second block",
                "<!-- endsection second -->",
                "Last line",
               );

    my $prototype = join("\n", @prototype) . "\n";

    my $page = $prototype;
    $page =~ s/line/portion/g;
    $page =~ s/block/section/g;

    my $prototype_path = {folder => 1};
    my $up = App::Followme::FormatPage->new;
    my $output = $up->update_page($page, $prototype, $prototype_path);
    my @output = split(/\n/, $output);

    my @output_ok = @prototype;
    $output_ok[6] =~ s/block/section/;

    is_deeply(\@output, \@output_ok, 'Update file'); # test 11
    my $bad_page = $page;
    $bad_page =~ s/second/third/g;

    $output = eval{$up->update_page($bad_page, $prototype, $prototype_path)};
    is($@, "Unused blocks (third)\n", 'Update file bad block'); # test 12
};

#----------------------------------------------------------------------
# Write test pages

do {
   my $code = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Page %%</title>
<!-- endsection meta -->
</head>
<body>
<!-- section content -->
<h1>Page %%</h1>
<!-- endsection content -->
<ul>
<li><a href="">&& link</a></li>
<!-- section nav -->
<li><a href="">link %%</a></li>
<!-- endsection nav -->
</ul>
</body>
</html>
EOQ

    my $up = App::Followme::FormatPage->new(%configuration);

	my $sec = 80;
    foreach my $dir (('sub', '')) {
        foreach my $count (qw(four three two one)) {
            my $output = $code;
            my $dir_name = $dir ? $dir : 'top';

            $output =~ s/%%/$count/g;
            $output =~ s/&&/$dir_name/g;
            $output =~ s/section nav/section nav in $dir/ if $dir;

            my @dirs;
            push(@dirs, $test_dir);
            push(@dirs, $dir) if $dir;
            my $filename = catfile(@dirs, "$count.html");

            fio_write_page($filename, $output);
			age($filename, $sec);
			$sec -= 10;
        }
    }
};

#----------------------------------------------------------------------
# Test get prototype path

do {
    my $up = App::Followme::FormatPage->new(%configuration);
    my $bottom = catfile($test_dir, 'sub');
    chdir($bottom);

    my $prototype_path = $up->get_prototype_path('one.html');

    is_deeply($prototype_path, {sub => 1}, 'Get prototype path'); # test 13
};

#----------------------------------------------------------------------
# Test run

do {
    chdir ($test_dir);
    my $up = App::Followme::FormatPage->new(%configuration);

    foreach my $dir (('sub', '')) {
        my $path = $dir ? catfile($test_dir, $dir) : $test_dir;
        chdir($path);

        $up->run($path);
        foreach my $count (qw(two one)) {
            my $filename = "$count.html";
            my $input = fio_read_page($filename);

            like($input, qr(Page $count),
               "Format block in $dir/$count"); # test 14, 18, 22, 26

            like($input, qr(top link),
               "Format prototype $dir/$count"); # test 15, 19, 23 27

            if ($dir) {
                like($input, qr(section nav in sub --),
                   "Format section tag in $dir/$count"); # test 24, 28
                like($input, qr(link one),
                   "Format folder block $dir/$count"); # test 25, 29

            } else {
                like($input, qr(section nav --),
                   "Format section tag in $dir/$count"); # test 16, 20
                like($input, qr(link $count),
                   "Format folder block in $dir/$count"); # test 17, 23
            }
        }
    }
}
