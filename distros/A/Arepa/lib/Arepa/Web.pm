package Arepa::Web;

use strict;
use warnings;

use base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->secret("b1Tx3z.duN'tKn0Wbout4r3p4");
    $self->plugin("more_tag_helpers");

    # Stash defaults
    $self->defaults(is_synced        => undef,
                    remote_repo_path => undef,
                    is_user_admin    => 0);

    # Routes
    my $r = $self->routes;
    my $auth = $r->bridge->to('auth#login');
    # Default route
    $auth->route('/')->to('dashboard#index')->name('home');
    $auth->route('/public/rss/repository')->name('rss_repository')->
      to(controller => 'public', action => 'rss_repository');
    $auth->route('/public/rss/queue')->name('rss_queue')->
      to(controller => 'public', action => 'rss_queue');
    $auth->route('/public/rss')->name('rss_legacy')->
      to(controller => 'public', action => 'rss_queue');
    $auth->route('/:controller/:action/:id')->name('generic_id');
    $auth->route('/:controller/:action')->name('generic');
    $auth->route('/:controller')->name('generic_wo_action');
}

1;
