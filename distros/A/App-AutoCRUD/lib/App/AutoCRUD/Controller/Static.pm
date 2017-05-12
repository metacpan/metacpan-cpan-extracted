package App::AutoCRUD::Controller::Static;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::Controller';

use List::MoreUtils qw/firstval/;

use namespace::clean -except => 'meta';

sub serve {
  my ($self) = @_;

  my $context  = $self->context;
  my @dirs     = $context->app->share_paths;
  my $root_dir = $context->config(qw/static root/);
  unshift @dirs, $root_dir if $root_dir;

  my $path = $context->path;
  my $file = firstval {-f $_} map {"$_/static$path"} @dirs
    or die "$path: no such static file";

  my $view_class = $context->app->find_class("View::Download")
    or die "no Download view";
  $context->set_view($view_class->new);

  return $file;
}

1;


__END__

