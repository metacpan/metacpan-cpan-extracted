package CatalystX::RoleApplicator;
our $VERSION = '0.005';

# ABSTRACT: apply roles to your Catalyst application-related classes

use strict;
use warnings;
use Moose ();
use Moose::Util::MetaRole;
use Moose::Exporter;
use MooseX::RelatedClassRoles;

Moose::Exporter->setup_import_methods();

sub init_meta {
  my $self = shift;
  my %p = @_;
  my $meta = Moose->init_meta(%p);

  # leave out context_class because it's set later in Catalyst.pm instead of
  # up-front, so anyone who doesn't set it will get explosions; also, it's just
  # MyApp, most of the time, so add your own roles
  for (qw(request response engine dispatcher stats)) {
    Class::MOP::class_of('MooseX::RelatedClassRoles')
      ->apply($meta, name => $_, require_class_accessor => 0);
  }

  return $meta;
}

1;




=pod

=head1 NAME

CatalystX::RoleApplicator - apply roles to your Catalyst application-related classes

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package MyApp;

    use base 'Catalyst';
    use Catalyst;
    use CatalystX::RoleApplicator;

    __PACKAGE__->apply_request_class_roles(
      qw/My::Request::Role Other::Request::Role/
    );

=head1 DESCRIPTION

CatalystX::RoleApplicator makes it easy for you to apply roles to all the
various classes that your Catalyst application uses.

=head1 METHODS

=head2 apply_request_class_roles

=head2 apply_response_class_roles

=head2 apply_engine_class_roles

=head2 apply_dispatcher_class_roles

=head2 apply_stats_class_roles

Apply the named roles to one of the classes your application uses.

=head2 init_meta

Apply the Moose extensions that power this class.

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Hans Dieter Pearcey <hdp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut 



__END__

