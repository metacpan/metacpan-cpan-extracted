#!/usr/bin/env perl
use strict;

use Test::More tests => 8;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

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
require App::Followme::Module;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;
chmod 0755, $test_dir;
chdir $test_dir;
$test_dir = cwd();

my $subdir = catfile($test_dir, 'sub');
mkdir ($subdir);
chmod 0755, $subdir;

my $template_file = 'template.htm';

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::Module->new(template_directory => 'sub',
                                     template_file => $template_file);

isa_ok($obj, "App::Followme::Module"); # test 1
can_ok($obj, qw(new run)); # test 2

#----------------------------------------------------------------------
# Write test pages

do {
       my $template = <<'EOQ';
<html>
<head>
<!-- section meta -->
<title>$title</title>
<meta name="date" content="$date" />
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<h1>$title</h1>

$body
<!-- endsection primary -->

<ul>
<!-- section nav -->
<!-- endsection nav -->
</ul>
</body>
</html>
EOQ

   fio_write_page($template_file, $template);

   my $code = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<title>Page %%</title>
<!-- endsection meta -->
</head>
<body>
<!-- section primary -->
<h1>%%</h1>

<p>This is paragraph %%</p>
<!-- endsection primary -->
<ul>
<li><a href="">&& link</a></li>
<!-- section nav -->
<li><a href="">link %%</a></li>
<!-- endsection nav -->
</ul>
</body>
</html>
EOQ

	my $sec = 80;
    foreach my $dir (('sub', '')) {
        foreach my $count (qw(four three two one)) {
            my $output = $code;
            my $dir_name = $dir ? $dir : 'top';

            $output =~ s/%%/$count/g;
            $output =~ s/&&/$dir_name/g;

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
# Test find prototype

do {
    my $subdir = catfile($test_dir, 'sub');
    my $prototype = $obj->find_prototype($subdir, 0);

    my $prototype_ok = catfile($subdir, 'one.html');
    is($prototype, $prototype_ok, 'Find prototype in current directory'); # test 3

    $prototype = $obj->find_prototype($subdir, 1);
    $prototype_ok = catfile($test_dir, 'one.html');
    is($prototype, $prototype_ok, 'Find prototype in directory above'); # test 4

};

#----------------------------------------------------------------------
# Test get template

do {
    my $template_file = 'three.html';
    my $template = $obj->get_template_name($template_file);
    my $template_ok = catfile($test_dir, $template_file);
    is($template, $template_ok, 'Get template name'); # test 5
};

#----------------------------------------------------------------------
# Test read configuration

do {
    my %configuration = ('' => {one => 1, two => 2});
    my $app = App::Followme::Module->new();

    my $source = <<'EOQ';
# Test configuration file

three = 3
four = 4

run_after = App::Followme::CreateSitemap

EOQ

    my $filename = 'test.cfg';
    my $fd = IO::File->new($filename, 'w');
    print $fd $source;
    close($fd);

    %configuration = $app->read_configuration($filename, %configuration);

    my %configuration_ok = ('' => {one => 1, two => 2,
                                   three => 3, four => 4,
                                   run_before => [],
                                   run_after => ['App::Followme::CreateSitemap'],
                                  }
                           );

    is_deeply(\%configuration, \%configuration_ok,
              'Read configuration'); # test 6
};

#----------------------------------------------------------------------
# Test reformat file

do {
    my $three = 'three.html';
    my $prototype = catfile($test_dir, 'one.html');
    my $file = catfile($subdir, $three);

    my $page = $obj->reformat_file($prototype, $file);
    like($page, qr(top link), 'Reformat file'); # test 7
};

#----------------------------------------------------------------------
# Test render file

do {
   my $page = $obj->render_file('one.html');

   like($page, qr(Page one), 'render file'); # test 8
};
