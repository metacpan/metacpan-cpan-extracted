use Test::Most;

{
    package  MyApp::View::Include;
    $INC{'MyApp/View/Include.pm'} = __FILE__;

    use Moose;
    extends 'Catalyst::View::Template::Pure';

    sub now { scalar localtime }

    __PACKAGE__->config(
      template => q{
        <div class="timestamp">The Time is now: </div>
      },
      directives => [
        '.timestamp' => 'now'
      ],
    );

    __PACKAGE__->meta->make_immutable;

    package  MyApp::View::Story;
    $INC{'MyApp/View/Story.pm'} = __FILE__;

    use Moose;
    use Catalyst::View::Template::Pure::Helpers (':ALL');
    extends 'Catalyst::View::Template::Pure';

    has [qw/title body capture arg q author_action/] => (is=>'ro', required=>1);

    sub timestamp { scalar localtime }

    __PACKAGE__->config(
      returns_status => [200],
      init_time => scalar(localtime),
      template => q[
        <!doctype html>
        <html lang="en">
          <head>
            <title>Title Goes Here</title>
          </head>
          <body>
            <div id="main">Content goes here!</div>
            <div id="timestamp">Server Started on:</div>
            <a name="hello">hello</a>
            <a href="aaa?aa=1&bb=2">sss</a>
            <?pure-include src='Views.Include'?>
            <a name="authors">Authors</a>
          </body>
        </html>      
      ],
      directives => [
        'title' => 'title',
        '#main' => 'body',
        '#timestamp+' => 'timestamp',
        'a[name="hello"]@href' => Uri('last',['={capture}'], '={arg}', {q=>'={q}',rows=>5}),
        #  'a[name="authors"]@href' => Uri('Story::Authors.last',['={capture}']),
        #'a[name="authors"]@href' => Uri('authors/last',['={capture}']),
        #'a[name="authors"]@href' => Uri('/story/authors/last',['={capture}']),
        'a[name="authors"]@href' => Uri('={author_action}',['={capture}']),


      ],
    );

    __PACKAGE__->meta->make_immutable;

    package MyApp::Controller::Story;
    $INC{'MyApp/Controller/Story.pm'} = __FILE__;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub display_story :Path('') Args(0) {
      my ($self, $c) = @_;

      $c->view('Story',
        title => 'A Dark and Stormy Night...',
        body => 'It was a dark and stormy night. Suddenly...',
        capture => 100, arg => 200, q => 'why',
        author_action => $self->action_for('authors/last'),
      )->http_ok;

      Test::Most::is "${\$c->view('Story')}", "${\$c->view('Story')}",
        'make sure the view is per request not factory';
    }

    sub root :Chained(/) CaptureArgs(1) { }
    sub last :Chained(root) Args(1) {
      my ($self, $c, $id) = @_;
    }

    __PACKAGE__->meta->make_immutable;

    package MyApp::Controller::Story::Authors;
    $INC{'MyApp/Controller/Story/Authors.pm'} = __FILE__;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/story/root) CaptureArgs(0) { }
    sub last :Chained(root) Args(0) {
      my ($self, $c, $id) = @_;
    }


    __PACKAGE__->meta->make_immutable;

    package MyApp;
    $INC{'MyApp.pm'} = __FILE__;

    use Catalyst;

    MyApp->setup;
}

use Catalyst::Test 'MyApp';
use Mojo::DOM58;

ok my $res = request '/story';
ok my $dom = Mojo::DOM58->new($res->content);

#warn $res->content;

is $dom->at('title')->content, 'A Dark and Stormy Night...';
is $dom->at('#main')->content, 'It was a dark and stormy night. Suddenly...';
like $dom->at('#timestamp')->content, qr/Server Started on:.+$/;

done_testing;

