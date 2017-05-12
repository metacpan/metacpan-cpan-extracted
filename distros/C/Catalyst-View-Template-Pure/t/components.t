use Test::Most;

{
    package  MyApp::View::Timestamp;
    $INC{'MyApp/View/Timestamp.pm'} = __FILE__;

    use Moose;
    use DateTime;

    extends 'Catalyst::View::Template::Pure';

    has 'format' => (is=>'ro', predicate=>'has_format');
    has 'tz' => (is=>'ro', predicate=>'has_tz');

    sub time {
      my ($self) = @_;
      my $now = DateTime->now();
      $now->set_time_zone($self->tz)
        if $self->has_tz;
      return $now;
    }

    __PACKAGE__->config(
      pure_class => 'Template::Pure::Component',
      auto_template_src => 1,
      directives => [
        '.timestamp' => 'time',
        '.timestamp@format' => 'format',
      ],
    );
    __PACKAGE__->meta->make_immutable;

    package  MyApp::View::Story;
    $INC{'MyApp/View/Story.pm'} = __FILE__;

    use Moose;
    extends 'Catalyst::View::Template::Pure';

    has [qw/title body/] => (is=>'ro', required=>1);
    
    sub settings { return +{ format => 'fffffffff' } }

    __PACKAGE__->config(
      returns_status => [200],
      init_time => scalar(localtime),
      auto_template_src => 1,
      directives => [
        'title' => 'title',
        '#main' => 'body',
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
      )->http_ok;
    }

    __PACKAGE__->meta->make_immutable;

    package MyApp;
    $INC{'MyApp.pm'} = __FILE__;

    use Catalyst;
    use File::Spec;

    MyApp->config(home => File::Spec->rel2abs(join '', (File::Spec->splitpath(__FILE__))[0, 1]));
    MyApp->setup;
}

use Catalyst::Test 'MyApp';
use Mojo::DOM58;

ok my $res = request '/story';
ok my $dom = Mojo::DOM58->new($res->content);

#warn $res->content;

is $dom->at('title')->content, 'A Dark and Stormy Night...';
is $dom->at('#main')->content, 'It was a dark and stormy night. Suddenly...';
ok $dom->at('.timestamp')->content;
ok $dom->at('head style')->content;
ok $dom->at('head script')->content;
ok $dom->find('.timestamp')->[0]->content;
ok $dom->find('.timestamp')->[1]->content;
is $dom->find('.timestamp')->[1]->attr('format'), 'fffffffff';

done_testing;

