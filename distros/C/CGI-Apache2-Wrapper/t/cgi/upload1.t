use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(UPLOAD_BODY GET_BODY_ASSERT);
use constant WIN32 => Apache::TestConfig::WIN32;
use Cwd;
require File::Basename;

my $cwd = getcwd();

my $module = 'TestCGI::upload1';
my $location = Apache::TestRequest::module2url($module);

my %types = (perl => 'application/octet-stream',
             httpd => 'application/octet-stream',
             );

my $vars = Apache::Test::vars;
my $perlpod = $vars->{perlpod};
if (-d $perlpod) {
    opendir(my $dh, $perlpod);
    my @files = grep { /\.(pod|pm)$/ } readdir $dh;
    closedir $dh;
    if (scalar @files > 1) {
        for my $i (0 .. 1) {
            my $file = $files[$i];
            $types{$file} = ($file =~ /\.pod$/) ? 'text/x-pod' : 'text/plain';
        }
    }      
}

my @names = sort keys %types;

eval {require Digest::MD5;};
my $has_md5 = $@ ? 0 : 1;
my $filetests = $has_md5 ? 6 : 5;
plan tests => $filetests * @names, need_lwp;

foreach my $name (@names) {
    my $url = ( ($name =~ /\.(pod|pm)$/) ?
        "getfiles-perl-pod/" : "/getfiles-binary-" ) . $name;
    my $content = GET_BODY_ASSERT($url);
    my $path = File::Spec->catfile($cwd, 't', $name);
    open my $fh, ">", $path or die "Cannot open $path: $!";
    binmode $fh;
    print $fh $content;
    close $fh;
}

foreach my $file( map {File::Spec->catfile($cwd, 't', $_)} @names) {
    my $size = -s $file;
    my $cs = $has_md5 ? cs($file) : 0;
    my $basename = File::Basename::basename($file);

    my $result = UPLOAD_BODY("$location?has_md5=$has_md5",
                               filename => $file);
    my %h = map {$_;} split /[=&;]/, $result, -1;
    ok t_cmp($h{name}, "filename", "test for name");
    ok t_cmp($h{ref}, "GLOB", "test for ref");
    ok t_cmp($h{type}, $types{$basename}, "test for type");
    ok t_cmp($h{size}, $size, "test for size");
    ok t_cmp($h{filename}, $basename, "test for filename");
    if ($has_md5) {
        ok t_cmp($h{md5}, $cs, "test for cs");
    }
    unlink $file if -f $file;
}

sub cs {
    my $file = shift;
    open my $fh, '<', $file or die qq{Cannot open "$file": $!};
    binmode $fh;
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
    close $fh;
    return $md5;
}
