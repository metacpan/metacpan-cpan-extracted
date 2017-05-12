package Catalyst::ActionRole::NamedFields;

use Moose::Role;

our $VERSION = '0.001';

has named_fields => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_named_fields');

  sub _build_named_fields {
    my ($self) = @_;
    my $fields = join ',', @{$self->attributes->{Field}||['']};
    my $cb = eval qq[
      sub { 
        my \@args = \@{\$_[0]};
        my \%query = \%{\$_[1]};
        return $fields;
      }];

    unless($cb) {
      die "Trouble building Fields for action '$self': $@";
    } else {
      return $cb;
    }
  }

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  local %_ = $self->named_fields->(\@args, $ctx->req->query_parameters);
  local $_ = $ctx;
  return $self->$orig($controller, $ctx, @args);
};

1;

=head1 NAME

Catalyst::ActionRole::NamedFields - Name your fields

=head1 SYNOPSIS

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub fields :Local Args(1) Does('NamedFields') Field(id=>$args[0],search=>$query{q}) {
      # $_ is localized to $c
      $_->res->body("id is '$_{id}' and search is '$_{search}'");
    }

    __PACKAGE__->meta->make_immutable;

For https://localhost/example/fields/arg1?q=terms

    "id is 'arg1' and search is 'terms'"

=head1 DESCRIPTION

This is functionality I needed for a different upcoming distribution but it was
clearly isolated well enough I thought it merited a stand alone release.  By itself
maybe not so useful but you can use it to build interesting experiments.

This defines an action attribute called 'Field', which can be used to map arguments
and query parameters for a request to the '%_' special variable.  The value of the
attribute is evaluted into a callback, so be warned about what you put there.  Its
evaluated in a context where @args is the action arguments (typically defined by the
Args or CaptureArgs attribute) and where %query is %{$c->req->query_parameters}.  We
also localize $_ to be the current context or '$c' which you might find a useful
shorthand (although keeping mind that $_ gets clobbered easily in many common functions
such as map.

The idea is to map some variables to %_ for ease of access.  Although the syntax as
shown above is actually more verbose than the old fashioned way, one can vision some
additional action roles or attribute helpers that could build upon this for interesting
experiments.

Documentation here is deliberately light since I imagine most won't have a direct use
for it unless one can review the source and tests for meaningful information.

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
  
=head1 COPYRIGHT
 
Copyright (c) 2015 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
