#!/usr/bin/perl

package Test::Arepa::T01Smoke;

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Test::Arepa;

use Arepa::CommandManager;

use base qw(Test::Arepa);

sub setup : Test(setup => 7) {
    my ($self, @args) = @_;

    $self->config_path('t/webui/conf/default/config.yml');
    $self->SUPER::setup(@_);

    $self->login_ok("testuser", "testuser's password");
}

sub test_should_see_builders : Test(1) {
    my $self = shift;
    $self->t->content_like(qr/test-builder/);
}

sub test_incoming_package_list : Test(3) {
    my $self = shift;

    is($self->incoming_packages, 0,
       "There should not be any incoming packages to start with");

    # Copy one package to the upload queue, see what happens
    $self->queue_files(glob('t/webui/fixtures/foobar_1.0*'));

    $self->t->get_ok('/');
    is_deeply([ $self->incoming_packages ], [qw(foobar_1.0-1)],
              "Package 'foobar' should be in the upload queue");
}

sub test_approve_package : Test(3) {
    my $self = shift;

    $self->queue_files(glob("t/webui/fixtures/foobar_1.0*"));
    is($self->incoming_packages, 1,
       "There should be one incoming package in the queue after upload");
    my ($component, $priority, $section, $comments) =
        ("main", "optional", "misc", "Some comment for foobar_1.0-1");
    $self->t->post_form_ok("/incoming/process" =>
        { "package-1"   => "foobar_1.0-1_i386.changes",
          "component-1" => $component,
          "priority-1"  => $priority,
          "section-1"   => $section,
          "comments-1"  => $comments,
          "approve-1"   => "Approve",
        });
    is($self->incoming_packages, 0,
       "After approving, there should be no incoming packages in the queue");
}

sub test_compile_package : Test(2) {
    my $self = shift;

    $self->queue_files(glob("t/webui/fixtures/foobar_1.0*"));
    my ($component, $priority, $section, $comments) =
        ("main", "optional", "misc", "Some comment for foobar_1.0-1");
    $self->t->post_form_ok("/incoming/process" =>
        { "package-1"   => "foobar_1.0-1_i386.changes",
          "component-1" => $component,
          "priority-1"  => $priority,
          "section-1"   => $section,
          "comments-1"  => $comments,
          "approve-1"   => "Approve",
        });

    # Should be queued now, let's compile it
    my $command_manager = Arepa::CommandManager->new($self->config_path);
    $command_manager->build_pending;

    $self->is_package_in_repo('foobar_1.0-1', 'mylenny', 'i386');
}

1;
