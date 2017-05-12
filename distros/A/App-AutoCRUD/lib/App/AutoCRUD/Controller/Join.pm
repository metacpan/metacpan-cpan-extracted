package App::AutoCRUD::Controller::Join;

# WORK IN PROGRESS

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::Controller';
use SQL::Abstract::More;
use Clone                      qw/clone/;
use JSON;
use URI;

use namespace::clean -except => 'meta';

#----------------------------------------------------------------------
# entry point to the controller
#----------------------------------------------------------------------
sub serve {
  my ($self) = @_;

  my $context = $self->context;

  # extract from path : join specification and method to dispatch to
  my ($join_spec, $meth_name) = $context->extract_path_segments(2)
    or die "URL too short, missing join specification and method name";
  my $method = $self->can($meth_name)
    or die "no such method: $meth_name";
  my @join_args = split /\s*([<=>]+)\s*/, $join_spec;
  @join_args >= 3
    or die "incorrect join specification: $join_spec";

#CONTINUE HERE

  # set default template and title
  $context->set_template("join/$meth_name.tt");
  $context->set_title($context->title . "-" . $table);

  # dispatch to method
  return $self->$method(\@join_args);
}


#----------------------------------------------------------------------
# published methods
#----------------------------------------------------------------------

sub descr {
  my ($self, $join_args) = @_;

  die "TODO";
}


sub list {
  my ($self, $join_args) = @_;

  die "TODO";
}





sub search {
  my ($self, $join_args) = @_;

  die "TODO";
}



1;

__END__

=head1 NAME

App::AutoCRUD::Controller::Join - Join controller

=head1 DESCRIPTION

This controller provides methods for searching and describing
a given join within some datasource.

=head1 METHODS

TODO

