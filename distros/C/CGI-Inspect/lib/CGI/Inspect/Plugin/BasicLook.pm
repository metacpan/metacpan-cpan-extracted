package CGI::Inspect::Plugin::BasicLook;

use strict;
use base 'CGI::Inspect::Plugin';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  push @{ $self->manager->{html_headers} }, qq{
    <link rel="stylesheet" type="text/css" href="mon.css">
    <link rel="stylesheet" href="js/themes/smoothness/jquery-ui-1.7.1.custom.css" type="text/css" media="screen">
    <link rel="stylesheet" href="js/jquery-treeview/jquery.treeview.css" />
    <script type="text/javascript" src="js/jquery.js"></script>
    <script type="text/javascript" src="js/jquery.ui.all.js"></script>
    <script type="text/javascript" src="js/jquery-treeview/jquery.treeview.js"></script>
    <script type="text/javascript" src="js/jquery.cookie.js"></script>
    <script type="text/javascript" src="mon.js"></script>
  };
  return $self;
}

sub process {
  my $self = shift;
  return '';
}

1;

