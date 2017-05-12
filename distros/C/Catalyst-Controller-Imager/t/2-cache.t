use Test::More;
use Test::Exception;
use Catalyst ();
use Catalyst::Controller::Imager;
use FindBin;
use Path::Class::File;
use Path::Class::Dir;
#use Imager;
#use Image::Info qw(image_info image_type dim);

# setup our Catalyst :-)
my $c = Catalyst->new();
$c->setup_log();
$c->setup_home("$FindBin::Bin");

{
    # patch our Catalyst environment for testing
    package Catalyst;
    my %stash;
    use Moose;
    no warnings;
    __PACKAGE__->meta->make_mutable;
    sub forward {
        my ($c, $action, @args) = @_;
        $action->{code}->($action->{self}, $c, @args);
    }
    sub stash {
        my $self = shift;
        while (@_) {
            my $key = shift;
            my $value = shift;
            $stash{$key} = $value;
        }
        
        return \%stash;
    }
    around dispatch => sub {
        my $orig = shift;
        %stash = ();
        $orig->dispatch(@_);
    };
    __PACKAGE__->meta->make_immutable;
}

# empty cache
my $cache_dir = Path::Class::Dir->new($FindBin::Bin, 'cache');
$cache_dir->rmtree();
$cache_dir->mkpath();
ok(-d $cache_dir, 'Cache dir exists');
ok(scalar($cache_dir->children) == 0, 'Cache is empty');

my $controller;
lives_ok { $controller = Catalyst->setup_component('Catalyst::Controller::Imager') }
         'setup component worked';

# get a first file without caching
$c->stash(
    image_path => ['catalyst_logo.png'],
    cache_path => ['catalyst_logo.png'],
    format     => 'png',
    image_data => undef,
);
lives_ok { $controller->convert_image($c) }
         'file retrieval works';
ok(scalar($cache_dir->children) == 0, 'Cache is empty');

# set cache directory
$controller->cache_dir('cache');
$c->stash->{image_data} = undef;
lives_ok { $controller->convert_image($c) }
         'file retrieval works';
ok(scalar($cache_dir->children) == 1, 'Cache has 1 entry');

# fake a cache entry and see if it comes back
# (silently assume catalyst logo is older than this test-timestamp...)
open(my $file, '>', $cache_dir->file('catalyst_logo.png'))
    or die 'cannot write faked cache file';
print $file 'cached content blabla';
close($file);
# exit;

$c->stash->{image_data} = undef;
lives_ok { $controller->convert_image($c) }
         'file retrieval works';
is($c->stash->{image_data}, 'cached content blabla', 'contend is from cache');

done_testing;
