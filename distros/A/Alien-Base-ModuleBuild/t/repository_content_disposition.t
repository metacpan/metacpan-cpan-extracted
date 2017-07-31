use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Alien::Base::ModuleBuild::Repository::HTTP;
use Alien::Base::ModuleBuild::File;

my $content_disposition;

my $mock = Test2::Mock->new(
  class => 'HTTP::Tiny',
  override => [
    mirror => sub {
      my $response = { success => 1 };
      $response->{headers}->{'content-disposition'} = $content_disposition
        if defined $content_disposition;
      $response;
    },
  ],
);

my $repo = Alien::Base::ModuleBuild::Repository::HTTP->new(
  host => 'foo.bar.com',
);

is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'bogus', 'no content disposition');

$content_disposition = 'attachment; filename=foo.txt';

is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo.txt', 'filename = foo.txt (bare)');

$content_disposition = 'attachment; filename="foo.txt"';

is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo.txt', 'filename = foo.txt (double quotes)');

$content_disposition = 'attachment; filename="foo with space.txt" and some other stuff';

is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo with space.txt', 'filename = foo with space.txt (double quotes with space)');

$content_disposition = 'attachment; filename=foo.txt and some other stuff';

is(Alien::Base::ModuleBuild::File->new( repository => $repo, filename => 'bogus' )->get, 'foo.txt', 'filename = foo.txt (space terminated)');

done_testing;
