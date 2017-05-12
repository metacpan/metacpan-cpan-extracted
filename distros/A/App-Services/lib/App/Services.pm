# ABSTRACT: Makes reusable services easy
#
package App::Services;
{
  $App::Services::VERSION = '0.002';
}

1;

__END__

=pod

=head1 NAME

App::Services - Makes reusable services easy

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use App::Services::<service>::Container;

  my $cntnr = App::Services::<service>::Container->new(
	  %service_config,
  );

  my $svc = $cntnr->resolve( service => '<service_name>' );

  $svc->do_something;

=head1 DESCRIPTION

App::Services::* are a set of modules that provide common functionality
where much of the low-level coding and configuration is already done.
If one is starting a new Perl application, the intent is that by using
App::Services, more rapid development can be achieved by focusing on
the application's main purpose and minimizing time spent on minutiae
and learning details of multiple ancillary CPAN modules. The
existence of this module is a testament to its utility in our own
application development.

The types of functionality provide by App::Services are convenient
implementations to logging, database connections, forking, email and a
persistent object store.

App::Services::* provides a layer of abstraction that hides the
implementation of the functionality and minimizes the configuration to
common bare essentials. This allows for coding at a high, single layer
of abstraction for application code. The abstraction layer used is
inversion of control using Moose and Bread::Board. The App::Services
module itself serves only as the root and main document for the
distribution.

There are pre-packaged container classes,
App::Services::<service>::Container, included that can be used
to instantiate the services, but in many cases you will want to write
your own.

=head1 LIST OF SERVICES

=head2 App:Services::Logger

Easy access to a Log::Log4perl logger.

=head2 App:Services::Forker

A simple fork service.

=head2 App:Services::Email

Email!

=head2 App:Services::DB

Get a database connection real quick.

=head2 App:Services::ObjStore

A persistent object store based on KiokuDB

=head1 Authors

Sean Blanton

=head1 TODO

Docs barely exist.

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
