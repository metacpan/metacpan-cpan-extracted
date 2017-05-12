package Alien::Packages::Base;

use strict;
use warnings;
use vars qw($VERSION);

=head1 NAME

Alien::Packages::Base - base class for package backends

=cut

$VERSION = "0.003";

use Carp qw(croak);
require IPC::Cmd;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiates new object, no attributes evaluated.

=cut

sub _run_ipc_cmd
{
    $_[0]->isa('Alien::Packages::Base') and shift;
    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) = IPC::Cmd::run(@_);
    $stdout_buf = [ join( "", @$stdout_buf ) ];
    $stderr_buf = [ join( "", @$stderr_buf ) ];
    return ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf );
}

sub new
{
    my $class = $_[0];
    my $self = bless( {}, $class );
    return $self;
}

=head2 pkgtype

Returns the pkgtype

=cut

sub pkgtype
{
    my $self = $_[0];
    my $name = ref($self) ? ref($self) : $self;
    $name =~ s/.*::(\w+)/$1/;
    return lc $name;
}

=head2 list_packages

Returns a list of hashes containing installed packages.
Each item must contain:

  { Package => $pkg_name, Version => $version, Summary => $summary ]

=head2 list_fileowners

Returns a hash of lists containing the packages which are registered
file owners for the specified files. Each list must contain at least
one item:

  '/absolute/path/to/file' =>
      [
	  {
	      Package => $pkg_name,
	  }
      ],
  ...

=cut

sub list_packages   { croak "Abstract function " . __PACKAGE__ . "::list_packages called" }
sub list_fileowners { croak "Abstract function " . __PACKAGE__ . "::list_fileowners called" }

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
