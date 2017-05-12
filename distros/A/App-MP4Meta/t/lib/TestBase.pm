use 5.010;
use strict;
use warnings;

package TestBase;
use base qw(Test::Class);
use Test::More;
use Test::MockObject;

use FindBin qw($Bin);
use File::Temp ();
use File::Copy ();

use App::MP4Meta::Source::Data::TVEpisode;

# return true if we can run live tests
sub can_live_test {
    return $ENV{'MP4META_CAN_LIVE_TEST'};
}

# create a copy of sample.m4v and put in in a temp place, returning filename
# sub get_temporary_m4v {
#     my ($self, $name) = @_;
#
#     my $dir = $self->get_temp_dir();
#     my $fname = "$dir/$name.m4v";
#     File::Copy::copy("$Bin/sample.m4v", $fname) or die "Copy failed: $!";
#
#     return $fname;
# }

# create and return a temp dir for our tests
# sub get_temp_dir {
#     my $self = shift;
#
#     if(! $self->{temp_dir}){
#         $self->{temp_dir} = File::Temp->newdir(CLEANUP => 1);
#     }
#     return $self->{temp_dir};
# }

# return a mocked version of AtomicParsley::Command
sub mock_ap {
    my $mock = Test::MockObject->new();
    $mock->set_always( 'write_tags', '/foo/bar' );
    $mock->{success} = 1;
    return $mock;
}

sub mock_tv_source {
    my ( $self, $episode ) = @_;

    $episode //= App::MP4Meta::Source::Data::TVEpisode->new(
        cover    => '/foo/bar.jpg',
        genre    => 'Comedy',
        overview => 'nice',
        title    => 'Test TV Episode',
        year     => '2012',
    );

    my $mock = Test::MockObject->new();
    $mock->set_always( 'get_tv_episode', $episode );
    $mock->set_always( 'name',           'test' );
    return $mock;
}

sub mock_film_source {
    my ( $self, $film ) = @_;

    $film //= App::MP4Meta::Source::Data::Film->new(
        cover    => '/foo/bar.jpg',
        genre    => 'Comedy',
        overview => 'nice',
        title    => 'Test Film',
        year     => '2012',
    );

    my $mock = Test::MockObject->new();
    $mock->set_always( 'get_film', $film );
    $mock->set_always( 'name',     'test' );
    return $mock;
}

1;
