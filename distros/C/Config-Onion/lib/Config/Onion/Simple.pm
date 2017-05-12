package Config::Onion::Simple;

use strict;
use warnings;

our $VERSION = 1.004;

use Config::Onion;

use base 'Exporter';
BEGIN {
  our @EXPORT = ();
  our @EXPORT_OK = qw(
    cfg
    cfg_obj
  );
  our %EXPORT_TAGS = (
    all         => [ @EXPORT, @EXPORT_OK ],
  );
}

my $cfg_obj;

sub cfg { cfg_obj()->get }

sub cfg_obj { $cfg_obj ||= Config::Onion->new }

1;

=pod

=encoding UTF-8

=head1 NAME

Config::Onion::Simple - Simple interface to a Config::Onion singleton

=head1 VERSION

version 1.007

=head1 SYNOPSIS

  use Config::Onion::Simple qw( cfg cfg_obj );

  cfg_obj->load('myapp');
  my $setting = cfg->{setting};

=head1 DESCRIPTION

It is often useful for a single master configuration to be shared across
multiple modules in an application.  Config::Onion::Simple provides an
interface to do this without requiring any of those modules to know about
each other.

=head1 EXPORTABLE FUNCTIONS

Config::Onion::Simple exports nothing by default.  The following functions
are exported only on request.

=head2 cfg

Returns a reference to the complete configuration hash managed by the
Config::Onion singleton.  This hash should be treated as read-only, as any
changes will be lost if the configuration is altered using the underlying
Config::Onion instance's methods.

Calling C<cfg> is equivalent to calling C<< cfg_obj->get >>.

=head2 cfg_obj

Returns a reference to the Config::Onion singleton.  Use this object's methods
to make any changes to the configuration.

=head1 SEE ALSO

L<Config::Onion>

=head1 AUTHOR

Dave Sherohman <dsheroh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Lund University Library.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Simple interface to a Config::Onion singleton

