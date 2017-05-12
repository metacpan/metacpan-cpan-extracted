package MockCatalyst;
use strict;
use warnings;
use Test::MockObject;
use base 'Exporter';

our @EXPORT = qw/mk_catalyst mk_view $stash $view $body $content_type/;
our $stash;
our $view;
our $body;
our $content_type;

sub mk_catalyst {
    my $catalyst = Test::MockObject->new;
    $catalyst->set_always(path_to => 'a/path/root');
    $catalyst->{for} = 'testing';
    $catalyst->mock(stash => sub { 
                        if ($_[1]) { $stash->{$_[1]} = $_[2] };
                        return $stash;
                    });
    $catalyst->mock(view => sub { $view->ACCEPT_CONTEXT($_[0]) });
    $catalyst->set_always(action => 'test');
    $catalyst->set_always(response => 
                          Test::MockObject->new
                          ->mock(body => 
                                 sub { $body = $_[1] })
                          ->mock(content_type =>
                                 sub { $content_type = $_[1] }));
    $catalyst->set_always(config => { name => 'TestApp' });
    $catalyst->set_always(request => Test::MockObject->new->
                                      set_always(base => 'base'));
    $catalyst->set_always(debug => 0);
    $catalyst->set_always(log => Test::MockObject->new->set_always(debug => 0));
    return $catalyst;
}

# args are catalyst, args
sub mk_view {
    return TestApp::View::Something->COMPONENT($_[0], $_[1]);
}

1;
