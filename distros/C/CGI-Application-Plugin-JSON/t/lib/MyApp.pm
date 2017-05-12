package MyBase::MyApp;
use base 'CGI::Application';
use strict;
use CGI::Application::Plugin::JSON qw(:all);

sub setup {
    my $self = shift;
    $self->run_modes([qw(
        test_json
        test_add
        test_clear
        test_body
        test_callback
    )]);

    $self->start_mode('test_json');
}

sub test_json {
    my $self = shift;
    $self->json_header( foo => 'stuff', bar => 'more_stuff');
    $self->json_header( foo => 'blah', baz => 'stuff' );
    return ' ';
}

sub test_add {
    my $self = shift;
    $self->add_json_header( foo => 'stuff', bar => 'more_stuff');
    $self->add_json_header( foo => 'blah', baz => 'stuff' );
    return ' ';
}

sub test_clear {
    my $self = shift;
    $self->add_json_header( foo => 'stuff', bar => 'more_stuff');
    $self->add_json_header( foo => 'blah', baz => 'stuff' );
    $self->clear_json_header();
    return ' ';
}

sub test_body {
    my $self = shift;
    return $self->json_body(
      {
        foo => 'blah',
        baz => 'stuff',
        bar => 'more_stuff',
      }
    );
}

sub test_callback {
    my $self = shift;
    return $self->json_callback(
       'my_callback',
      {
        foo => 'blah',
        baz => 'stuff',
        bar => 'more_stuff',
      }
    );
}

1;
