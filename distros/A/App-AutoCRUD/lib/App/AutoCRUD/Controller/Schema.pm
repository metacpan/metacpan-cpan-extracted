package App::AutoCRUD::Controller::Schema;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::Controller';
use YAML;
use Clone qw/clone/;

use namespace::clean -except => 'meta';


#----------------------------------------------------------------------
# entry point to the controller
#----------------------------------------------------------------------
sub serve {
  my ($self) = @_;

  # extract from path : method to dispatch to
  my $meth_name = $self->context->extract_path_segments(1)
    or die "URL too short, missing method name";
  my $method = $self->can($meth_name)
    or die "no such method: $meth_name";

  # dispatch to method
  return $self->$method();
}

#----------------------------------------------------------------------
# published methods
#----------------------------------------------------------------------

sub tablegroups {
  my ($self) = @_;

  my $context = $self->context;
  $context->set_template("schema/tablegroups.tt");
  return $context->datasource->tablegroups;
}

sub perl_code {
  my ($self) = @_;

  # set view to "plain"
  my $view_class = $self->app->find_class("View::Plain")
    or die "no Plain view";
  $self->context->set_view($view_class->new);

  # call datasource schema (which may indirectly generate the perl class
  # on the fly, from the DBI connection)
  my $schema = $self->datasource->schema;

  # retrieve perl code, either just generated, or from an existing .pm module
  my $perl_code = $self->datasource->generated_schema || do {

    # retrieve loaded classname
    my $schema_class = $self->datasource->loaded_class || ref $schema || $schema;

    # find source file and slurp its content
    $schema_class =~ s[::][/]g;
    my $path = $INC{$schema_class . ".pm"}
      or die "can't find source code for $schema_class.pm";
    open my $fh, "<", $path 
      or die "can't open $path";
    local $/;
    <$fh>;
  };

  return $perl_code;
}


1;

__END__

=head1 NAME

App::AutoCRUD::Controller::Schema

=head1 DESCRIPTION

This controller serves information from a given
L<App::AutoCRUD::DataSource> instance.

=head1 METHODS

=head2 tablegroups

Returns the content of
L<App::AutoCRUD::DataSource/tablegroups>.

=head2 perl_code

Returns source code of the L<DBIx::DataModel> schema
associated with the datasource (this can be either
an existing Perl class, loaded from the config, or
some Perl code generated on the fly from the L<DBI>
connection).
