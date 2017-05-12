# --8<--8<--8<--8<--
#
# Copyright (C) 2007 Smithsonian Astrophysical Observatory
#
# This file is part of Config::PFiles::Path
#
# Config::PFiles::Path is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Config::PFiles::Path;

use 5.008009;

use strict;
use warnings;

use Symbol;
use Carp;
use Sub::Uplevel;

our $VERSION = '0.03';

use overload '""' => '_export' ;

my %is_mutator
  = map { $_ => 1 } qw( _append _prepend _replace _remove );

our $AUTOLOAD;

# allow the user to do thing when loading the package
sub import {

    my $package = shift;

    return unless @_;

    my $method = shift;

    croak( "Can't call method '$method' in this context\n" )
      unless $is_mutator{ "_$method" };

    $AUTOLOAD = $method;
    uplevel 1, \&AUTOLOAD, $package, @_;
}

sub AUTOLOAD {
    (my $method = our $AUTOLOAD) =~ s/.*:://;

    # we don't have a DESTROY method, so ignore it.
    return if $method =~ /DESTROY/;

    my $imethod = '_' . $method;

    my $subref = *{qualify_to_ref($imethod,__PACKAGE__)}{CODE};

    # make sure it's an existing method
    croak( qq{Can't locate object method "$method" via package "}, 
	   __PACKAGE__, q{"} )
      if $method =~ /^_/ || ! defined $subref;


    # is this an object invocation?
    if ( ref $_[0] && $_[0]->isa(__PACKAGE__) )
    {
	goto &$imethod;
    }

    # nope.  create default object based on $ENV{PFILES} and replace
    # the class name in the argument list with the new object
    my $package = shift;
    my $env = $package->new( $ENV{PFILES} );
    unshift @_, $env;


    # if the method will alter the path, make sure to update $ENV{PFILES}
    # after it has been run
    if ( $is_mutator{$imethod} )
    {
	# respect calling context
	my $wantarray = wantarray();

	# void
	if ( ! defined $wantarray )
	{
	    uplevel 1, $subref, @_;
	    $ENV{PFILES} = $env->_export;
	    return;
	}

	# list
	elsif ( $wantarray)
	{
	    my @results = uplevel 1, $subref, @_;
	    $ENV{PFILES} = $env->_export;
	    return @results;
	}

	# scalar
	else
	{
	    my $result = uplevel 1, $subref, @_;
	    $ENV{PFILES} = $env->_export;
	    return $result;
	}
    }

    # nope, just execute the method
    else
    {
	goto &$imethod;
    }
}

sub new {
    my ( $class, $pfiles ) = @_;

    my $self = bless {}, $class;

    $self->__init( $pfiles );

    return $self;
}

sub __init {
    my ( $self, $pfiles ) = @_;

    $pfiles ||= q{};

    my %dirs;
    @dirs{ qw( RW RO ) } =
      $pfiles =~ /^
                  ([^;]*)    # grab everything that's not a semicolon (RW)
                  (?:|;(.*)) # and everything that's after a semicolon (RO)
                  $/x;

    croak( "illegal path: too many semi-colons: $pfiles\n" )
      if defined $dirs{RO} && $dirs{RO} =~ /;/;

    # split and store non-empty paths
    $self->{$_} = [ grep { $_ ne '' } split( /:/, $dirs{$_} || q{} ) ]
      for qw( RW RO );

    return;
}

sub __check_set {
    my ( $dir_set ) = shift;

    my $match;
    unless ( ($match ) = $dir_set =~ /^(RW|RO)$/i )
    {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	croak( "illegal value for directory set: $dir_set\n" )
    }

    return uc($match);
}

sub _append {
    my ( $self, $dir_set, @dirs ) = @_;

    push @{$self->{__check_set($dir_set)}}, @dirs;

    return;
}

sub _prepend {
    my ( $self, $dir_set, @dirs ) = @_;

    unshift @{$self->{__check_set($dir_set)}}, @dirs;

    return;
}

sub _extract {
    my ( $self, $dir_set ) = @_;

    return @{$self->{__check_set($dir_set)}};
}

sub _replace {
    my ( $self, $dir_set, @dirs ) = @_;

    $dir_set = __check_set($dir_set);

    my @old = @{$self->{$dir_set}};

    $self->{$dir_set} = [ @dirs ];

    return @old
      if defined wantarray;

    return;
}

sub _remove {
    my ( $self, $dir_set ) = @_;

    return $self->replace( $dir_set );
}

sub _export {
    my ( $self ) = @_;

    # join together the non-empty directories in the sets;
    my ( $rw, $ro ) =
      map { join( q{:}, grep { $_ ne q{} } @{$self->{$_}} ) }
	qw( RW RO );

    # construct a rational path
    return
          $rw eq q{} ? ";$ro"
	: $ro eq q{} ?   $rw
	:              "$rw;$ro";
}

1;

__END__

=head1 NAME

Config::PFiles::Path - manipulate PFILES path for IRAF Compatible parameter files


=head1 SYNOPSIS

    use Config::PFiles::Path;

    $path = Config::PFiles::Path->new( \%options);

    # append to writeable or readonly directories
    $path->append( RW => @dirs );
    $path->append( RO => @dirs );

    # prepend to writeable or readonly directories
    $path->prepend( RW => @dirs );
    $path->prepend( RO => @dirs );

    # extract directories
    @rw_dirs = $path->extract( 'RW' );
    @ro_dirs = $path->extract( 'RO' );

    # replace writeable or readonly directories
    @rw_dirs = $path->replace( RW => @dirs );
    @ro_dirs = $path->replace( RW => @dirs );

    # remove writeable or readonly directories
    @rw_dirs = $path->remove( 'RW' );
    @ro_dirs = $path->remove( 'RO' );

    # create a sring version of the path
    $pfiles = $path->export;

    # work directly on $ENV{PFILES}
    Config::PFiles::Path->append( RO => @dirs );


=head1 DESCRIPTION

B<Config::PFiles::Path> manipulates the parameter file path used by
IRAF "compatible" parameter interfaces (IRAF (of course), CIAO's
B<cxcparam>, MARX's B<libpfile>, INTEGRAL's B<PIL>).  The path is
composed of two sets of directories; the first is both user readable
and user writeable, the other is only user readable.  The path is kept
in the B<PFILES> environmental variable, and takes the form

  rw1:rw2;ro1:ro2

where directories to the left of the semicolon are user readable and
writeable and those to the right are readable only.

=head1 INTERFACE

B<Config::PFiles::Path> can operate directly upon C<$ENV{PFILES}> or
can operate on a path object which can be exported.

There are two approaches to operating directly on C<$ENV{PFILES}>.

=over

=item 1.

Use class methods

If the methods in B<Config::PFiles::Path> are used as class (rather
than object) methods, they work directly upon C<$ENV{PFILES}>.  For example,

    Config::PFiles::Path->prepend( RW => "$ENV{HOME}/pfiles" );

=item 2.

Specify the method and its parameters on package loading

Methods which change the path ( B<append>, B<prepend>, B<remove>, and
B<replace>) may be specified when the package is loaded:

    use Config::PFiles::Path prepend => RW => "$ENV{HOME}/pfiles";

Note that the method name is passed as a I<string>; this example uses
the C<< => >> operator to quote things.  The above may also have been
written as

    use Config::PFiles::Path ('prepend', 'RW', "$ENV{HOME}/pfiles");

This approach lends itself to situations where only a single manipulation
is required.

=back


Object methods don't touch C<$ENV{PFILES}>.  For example,

    $env = Config::PFiles::Path->new( $ENV{PFILES} );
    $env->prepend( RW => "$ENV{HOME}/pfiles" );

modifies the path object C<$env>.


=head2 Methods

=over

=item new

  $path = Config::PFiles::Path->new( $pfiles );

This creates a new B<Config::PFiles::Path> object using the provided
parameter file path.  Typically this will be C<$ENV{PFILES}>.  If
B<$pfiles> is not specified an empty path is constructed.

=item export

  $PFILES = $path->export;

This method generates a string version of the current path. See also
L<Overloaded Operators>.

=item append

  $path->append( RW => @dirs );
  $path->append( RO => @dirs );

Append a list of directories to either the read/write set or read-only
set of directories.  The first argument indicates the set to append to.

=item prepend

  $path->prepend( RW => @dirs );
  $path->prepend( RO => @dirs );

Prepend a list of directories to either the read/write set or read-only
set of directories.  The first argument indicates the set to prepend to.

=item replace

  @old_rw_dirs = $path->replace( RW => @dirs );
  @old_ro_dirs = $path->replace( RO => @dirs );

Replace either the read/write set or read-only set of directories.
The first argument indicates the set to replace.

=item remove

  @rw_dirs = $path->remove( 'RW' );
  @ro_dirs = $path->remove( 'RO' );

Delete either the read/write set or read-only set of directories.  The
set of deleted directories is returned.  The first argument indicates
the set to delete.

=item extract

  @rw_dirs = $path->extract( 'RW' );
  @ro_dirs = $path->extract( 'RO' );

Extract either the read/write set or read-only set of directories. The
first argument indicates the set to extract.

=back

=head2 Overloaded Operators

B<Config::PFiles::Path> overloads the "" operator.  When interpolating
an object in a string it will be replaced with the output of the
B<export()> method.


=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-config-pfiles-path@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-PFiles-Path>.

=head1 VERSION

Version 0.02

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 The Smithsonian Astrophysical Observatory

Config::PFiles::Path is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


