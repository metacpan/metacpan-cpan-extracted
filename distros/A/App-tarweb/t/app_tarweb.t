use Test2::V0 -no_srand => 1;
use 5.034;
use experimental qw( signatures );
use App::tarweb;
use Test2::Tools::HTTP;
use Test2::Tools::DOM;
use HTTP::Request::Common;
use Mojo::DOM58;
use URI;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_stderr );

subtest 'no archive' => sub {

  my $cli = App::tarweb->new;

  my($stderr, $exit) = capture_stderr {
    $cli->main;
  };

  is $exit, 2, 'returned 2 on exit';
  like $stderr, qr/no archive file given!/;
};

subtest 'basic' => sub {

  my $cli = App::tarweb->new;

  my $called_run = 0;

  my $mock = mock 'Plack::Runner' => (
    override => [
      run => sub ($, $app) {

        $called_run = 1;

        my $url = URI->new('http://localhost');

        my $guard = psgi_app_guard $url => $app;

        $url->path('/');

        http_request
          GET($url),
          http_response {
            http_code 200;
            http_content_type 'text/html';
            call content => dom {
              find 'ul li a' => [
                dom { attr href => 'foo.html'; content 'foo.html' },
                dom { attr href => 'foo.txt';  content 'foo.txt'  },
              ];
            };
          };

        note http_tx->res->as_string;

        foreach my $href (map { $_->attr('href') } Mojo::DOM58->new(http_tx->res->decoded_content)->find('ul li a')->to_array->@*)
        {
          my $url = URI->new_abs( $href, $url );
          http_request
            GET($url),
            http_response {
              http_code 200;
            }
        }

        $url->path('favicon.ico');

        http_request
          GET($url),
          http_response {
            http_code 200;
          };

      }
    ],
  );

  is $cli->main('corpus/foo.tar'), 0, 'returned 0 on exit';
  ok $called_run, 'called $runner->run';

};

subtest 'multiple' => sub {

  my $cli = App::tarweb->new;

  my $called_run = 0;

  my $mock = mock 'Plack::Runner' => (
    override => [
      run => sub ($, $app) {
        $called_run = 1;

        my $url = URI->new('http://localhost');

        my $guard = psgi_app_guard $url => $app;

        http_request
          GET($url),
          http_response {
            http_code 200;
            http_content_type 'text/html';
            http_content_type_charset 'UTF-8';
            http_content dom {
                find 'ul li a' => [
                  dom { attr href => 'foo.tar';    content 'foo.tar'   },
                  dom { attr href => 'foo.tar-0';  content 'foo.tar-0' },
                ];
            };
          };


        $url->path("/favicon.ico");

        http_request
          GET($url),
          http_response {
            http_code 200;
            http_content_type 'image/vnd.microsoft.icon';
            http_content path('share/favicon.ico')->slurp_raw;
          };

        foreach my $base (qw( /foo.tar /foo.tar-0 ))
        {

          $url->path($base);

          http_request
            GET($url),
            http_response {
              http_code 301;
              http_header 'location', "$base/";
            };

          $url = URI->new_abs(http_tx->res->header('location'), $url);

          http_request
            GET($url),
            http_response {
              http_code 200;
              http_content_type 'text/html';
              call content => dom {
                find 'ul li a' => [
                  dom { attr href => 'foo.html'; content 'foo.html' },
                  dom { attr href => 'foo.txt';  content 'foo.txt'  },
                ];
              };
            };

          foreach my $href (map { $_->attr('href') } Mojo::DOM58->new(http_tx->res->decoded_content)->find('ul li a')->to_array->@*)
          {
            my $url = URI->new_abs( $href, $url );
            http_request
              GET($url),
              http_response {
                http_code 200;
              }
          }

        }

      },
    ],
  );

  is $cli->main('corpus/foo.tar', 'corpus/foo.tar'), 0, 'returned 0 on exit';
  ok $called_run, 'called $runner->run';

};

done_testing;
