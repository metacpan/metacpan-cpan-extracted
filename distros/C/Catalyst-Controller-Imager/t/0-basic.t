use Test::More;
use Test::Exception;
use Catalyst ();
use FindBin;
use Path::Class::File;
use Imager;
use Image::Info qw(image_info image_type dim);

# setup our Catalyst :-)
my $c = Catalyst->new();
$c->setup_log();
$c->setup_home("$FindBin::Bin");

{
    no warnings;
    
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
    
    package Catalyst::Controller::Imager;
    sub action_for {
        my ($self, $name) = @_;
        if ($self->can($name)) {
            return {
                code => $self->can($name),
                self => $self,
            };
        }
        die "cannot find $name as sub...";
    };
}

#
# check available imager formats
#
ok(scalar(keys(%Imager::formats)) > 0, 'Imager.pm tells some formats');
ok(exists($Imager::formats{png}),  'png format is possible');
ok(exists($Imager::formats{gif}),  'gif format is possible');
ok(exists($Imager::formats{jpeg}), 'jpeg format is possible');

BAIL_OUT('Imager.pm not configured as expected - please reinstall with gif, jpeg and png support!')
    if (!exists($Imager::formats{png}) || 
        !exists($Imager::formats{gif}) ||
        !exists($Imager::formats{jpeg}) );

#
# test basic things
#
# can we use it?
use_ok('Catalyst::Controller::Imager');
can_ok('Catalyst::Controller::Imager' => qw(base scale image convert_image 
                                            end 
                                            want_w want_h want_thumbnail));

# instantiate
my $controller;
lives_ok { $controller = Catalyst->setup_component('Catalyst::Controller::Imager') }
         'setup component worked';
is(ref($controller), 'Catalyst::Controller::Imager', 'controller class looks good');

# check default attributes
is($controller->root_dir,       'static/images', 'default root directory looks good');
is($controller->cache_dir,      undef,           'default cache directory looks good');
is($controller->default_format, 'jpg',           'default format sub looks good');
is($controller->max_size,       1000,            'default max size looks good');
is($controller->thumbnail_size, 80,              'default thumbnail size looks good');

#
# base() checking
#
%{ $c->stash } = ();
is_deeply($c->stash, {}, 'stash is empty');
lives_ok { $controller->base($c) } 'base() can be called';
is_deeply($c->stash, 
          { 
              image_path   => [],
              image        => undef,
              image_data   => undef,
              cache_path   => [],
              scale        => {w => undef, h => undef, mode => 'min'},
              format       => undef,
              before_scale => [],
              after_scale  => [],
          },
          'stash is initially set');

####
# scale() and other methods can not non-trivially checked in a simple manner...
####

#
# get a not existing file
#
$c->stash(
    image_path => ['rails_logo.png'],
    format     => 'png',
    image_data => undef,
);
dies_ok { $controller->convert_image($c) }
         'unknown file retrieval dies';

#
# test image conversion calling it directly
#
# try to load catalyst logo
# original size = 171 x 244 pix
# original format = png
my @test_cases = (
    # original size, different formats
    { format => 'png',  scale => {w => undef, h => undef, mode => 'min'},
      type   => 'PNG',  dim => [171,244], size => 10000 },
    { format => 'jpeg', scale => {w => undef, h => undef, mode => 'min'},
      type   => 'JPEG', dim => [171,244], size => 1000 },
    { format => 'gif',  scale => {w => undef, h => undef, mode => 'min'},
      type   => 'GIF',  dim => [171,244], size => 8000 },

    # width set, different formats
    { format => 'png',  scale => {w => 200, h => undef, mode => 'min'},
      type   => 'PNG',  dim => [200,285], size => 10000 },
    { format => 'jpeg', scale => {w => 200, h => undef, mode => 'min'},
      type   => 'JPEG', dim => [200,285], size => 1000 },
    { format => 'gif',  scale => {w => 200, h => undef, mode => 'min'},
      type   => 'GIF',  dim => [200,285], size => 10000 },

    # height set, different formats
    { format => 'png',  scale => {w => undef, h => 200, mode => 'min'},
      type   => 'PNG',  dim => [140,200], size => 10000 },
    { format => 'jpeg', scale => {w => undef, h => 200, mode => 'min'},
      type   => 'JPEG', dim => [140,200], size => 1000 },
    { format => 'gif',  scale => {w => undef, h => 200, mode => 'min'},
      type   => 'GIF',  dim => [140,200], size => 5000 },

    # width+height set, oversized width
    { format => 'png',  scale => {w => 400, h => 150, mode => 'min'},
      type   => 'PNG',  dim => [105,150], size => 10000 },
    { format => 'jpeg', scale => {w => 400, h => 150, mode => 'min'},
      type   => 'JPEG', dim => [105,150], size => 1000 },
    { format => 'gif',  scale => {w => 400, h => 150, mode => 'min'},
      type   => 'GIF',  dim => [105,150], size => 6000 },
);

foreach my $test_case (@test_cases) {
    $c->stash(
        image_path => ['catalyst_logo.png'],
        format     => $test_case->{format},
        image_data => undef,
        scale      => { %{ $test_case->{scale} } },
    );
    my $name = "$test_case->{format} $test_case->{dim}->[0]x$test_case->{dim}->[1]";

    lives_ok { $controller->convert_image($c) }
             "$name lives";
    ok(length($c->stash->{image_data}) > $test_case->{size}, "$name size is reasonable (${\length($c->stash->{image_data})} > $test_case->{size})");
    file_type_is($name, $test_case->{type});
    file_dimension_is($name, @{$test_case->{dim}});
}

done_testing;

#################################################
#
# helper subs
#
sub file_type_is {
    my $name = shift;
    my $format = shift;
    
    my $image_type = image_type(\do{ $c->stash->{image_data} });
    ok(ref($image_type) eq 'HASH' &&
       exists($image_type->{file_type}) &&
       $image_type->{file_type} eq $format, "$name is '$format'");
}

sub file_dimension_is {
    my $name = shift;
    my $w = shift;
    my $h = shift;

    is_deeply([dim(image_info(\do { $c->stash->{image_data} }))], [$w, $h], "$name is $w x $h");
}
