package CGI::Dispatcher::Simple;
use strict;
use base qw/Class::Accessor::Fast/;
use CGI;
use Carp;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw/args cgi/);

=head1 NAME

CGI::Dispatcher::Simple - Simple CGI Dispacher by PATH_INFO

=head1 SYNOPSIS

  # In your App

  package MyApp;
  use base qw/CGI::Dispacher::Simple/;

  sub run {
      my $self = shift;

      $self->dispatch({
          '/' => 'default',
	  '/list' => 'list',
	  '/add' => 'add',
      });
  }

  sub default {
      :
  }

   :

  # And in your CGI script

  my $app = MyApp->new;
  $app->run;


=head1 DESCRIPTION

This module provide you to simple dispatcher by using PATH_INFO.

You can set some methods as hashref, PATH_INFO are keys, METHODS are values.
like:

  '/' => 'default',
  '/list/add' => 'add',

And, rest of PATH_INFO is saved in $self->args as arrayref.
When PATH_INFO is '/list/add/foo/bar' in above example, $self->args is:

  [ 'foo', 'bar' ]


If you define $self->begin or $self->end methods, these are called automatically
 before/after PATH_INFO method.

And when PATH_INFO is not defined, dispatch to '/' method.

=head1 METHODS

=over 4

=item new

=cut

sub new {
    my $self = bless {}, shift;
    $self->cgi(CGI->new);
    $self->cgi->charset('utf-8');

    $self;
}

=item dispatch

=cut

sub dispatch {
    my ( $self, $methods ) = @_;

    my ($method, @path, @args);
    my $path_info = $self->cgi->path_info || '';
    my $keys = keys %$methods;

    @path = split '/', $path_info;
    shift @path;

    do {
        @path = () if ($method = $methods->{ '/' . join '/', @path});
    } while (unshift @args, pop @path and @path);

    shift @args if @args > 1;
    $self->args(@args);

    if ($self->can($method)) {
        $self->begin if $self->can('begin');
        $self->$method;
        $self->end if $self->can('end');
    } else {
        croak(qq!Method "$method" does not exitst.!);
    }
}

=back

=head1 AUTHOR

Daisuke Murase E<lt>typester@cpan.orgE<gt>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
