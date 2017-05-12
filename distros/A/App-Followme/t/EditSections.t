use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

use Test::More tests => 11;

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
require App::Followme::EditSections;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;
mkdir catfile($test_dir, "sub");
chdir $test_dir;

my %configuration = (
                    remove_comments => 0,
                    data_pkg => 'App::Followme::WebData',
                    );

#----------------------------------------------------------------------
# Write test pages

do {
   my $page = <<'EOQ';
<html>
<head>
<meta name="robots" content="archive">
<!-- begin meta -->
<title>page %%</title>
<!-- end meta -->
</head>
<body>
<!-- begin content -->
<h1>page %%</h1>
<!-- end content -->
<ul>
<li><a href="">&& link</a></li>
<!-- begin nav -->
<li><a href="">link %%</a></li>
<!-- end nav -->
</ul>
</body>
</html>
EOQ

    my $es = App::Followme::EditSections->new(%configuration);

    foreach my $dir (('sub', '')) {
        foreach my $count (qw(four three two one)) {
            my $output = $page;

            $output =~ s/%%/$count/g;

            my $filename = $dir ? catfile($dir, $count) : $count;
            $filename .= '.html';

            if ($filename eq 'one.html') {
                $output =~ s/begin/section/g;
                $output =~ s/end/endsection/g;
            }

            fio_write_page($filename, $output);
            sleep(2);
        }
    }

#----------------------------------------------------------------------
};
# Test comment removal

do {
    my $es = App::Followme::EditSections->new(%configuration);

    my $output = $es->strip_comments('one.html', 1);
    my $output_ok = fio_read_page('one.html');
    is($output, $output_ok, 'strip comments, keep sections'); # test 1

    $output = $es->strip_comments('one.html', 0);
    $output_ok =~ s/(<!--.*?-->)//g;
    is($output, $output_ok, 'strip comments and sections'); # test 2

    $output = $es->strip_comments('two.html', 0);
    $output_ok = fio_read_page('two.html');
    is($output, $output_ok, 'don\'t strip comments'); # test 3

    $configuration{remove_comments} = 1;
    $es = App::Followme::EditSections->new(%configuration);
    $configuration{remove_comments} = 0;

    $output = $es->strip_comments('two.html', 0);
    $output_ok =~ s/(<!--.*?-->)//g;
    is($output, $output_ok, 'strip comments'); # test 4
};

#----------------------------------------------------------------------
# Test update folder

do {
    my $es = App::Followme::EditSections->new(%configuration);

    my $prototype = $es->strip_comments('one.html', 1);
    $es->update_folder($test_dir);

    my $output_template = <<EOQ;
<html>
<head>
<meta name="robots" content="archive">
<!-- section meta -->
<!-- begin meta -->
<title>page %%</title>
<!-- end meta -->
<!-- endsection meta -->
</head>
<body>
<!-- section content -->
<!-- begin content -->
<h1>page %%</h1>
<!-- end content -->
<!-- endsection content -->
<ul>
<li><a href="">&& link</a></li>
<!-- section nav -->
<!-- begin nav -->
<li><a href="">link %%</a></li>
<!-- end nav -->
<!-- endsection nav -->
</ul>
</body>
</html>
EOQ

    foreach my $dir (('sub', '')) {
        for my $count (qw(one two three four)) {
            my $file = $dir ? catfile($dir, $count) : $count;
            next if $file eq 'one';

            $file .= '.html';
            my $output = fio_read_page($file);

            my $output_ok = $output_template;
            $output_ok =~ s/%%/$count/g;

            is($output, $output_ok, "update file $file"); # test 5-11
        }
    }

};
