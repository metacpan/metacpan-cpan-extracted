package Data::PathSimple;

use strict;
use warnings;

use version 0.77;
our $VERSION = qv("v2.0.1");

use Scalar::Util qw[ reftype ];

use base 'Exporter';
our @EXPORT_OK = qw{
  get
  set
};

sub _error {
    'CODE' eq ref $_[0] ? $_[0]->() : $_[0];
}

sub get {

  my ( $root_ref, $root_path, $options ) = @_;

  my %opts = ( path_sep => '/',
	       error => undef,
	       %{ $options // {} },
	     );

  return _error( $opts{error} ) unless defined $root_path;

  my $path_sep = $opts{path_sep};
  $path_sep = qr/\Q$path_sep\E/
    unless ( reftype( $path_sep ) // '' ) eq 'REGEXP';

  $root_path =~ s/^$path_sep//;

  my @root_parts  = split $path_sep, $root_path;
  my $current_ref = $root_ref;

  return _error( $opts{error} ) unless @root_parts;

  foreach my $current_part ( @root_parts ) {
    if ( ref $current_ref eq 'HASH' ) {
      if ( exists $current_ref->{$current_part} ) {
        $current_ref = $current_ref->{$current_part};
        next;
      }
    }
    elsif ( ref $current_ref eq 'ARRAY' ) {
      return _error( $opts{error} ) if $current_part !~ /^\d+$/;

      if ( exists $current_ref->[$current_part] ) {
        $current_ref = $current_ref->[$current_part];
        next;
      }
    }

    return _error( $opts{error} );
  }

  return $current_ref;
}

sub set {

  my ( $root_ref, $root_path, $value, $options ) = @_;

  my %opts = ( path_sep => '/',
	       error => undef,
	       %{ $options // {} },
	     );

  return _error( $opts{error} ) unless defined $root_path;

  my $path_sep = $opts{path_sep};
  $path_sep = qr/\Q$path_sep\E/
    unless ( reftype( $path_sep ) // '' ) eq 'REGEXP';

  $root_path  =~ s/^$path_sep//;

  my @root_parts  = split $path_sep, $root_path;
  my $current_ref = $root_ref;

  return _error( $opts{error} ) unless @root_parts;

  for ( my $i = 0; $i < ( @root_parts - 1 ); $i++ ) {
    my $current_part = $root_parts[ $i ];
    my $next_part    = $root_parts[ $i + 1 ];

    if ( ref $current_ref eq 'HASH' ) {
      if ( not ref $current_ref->{$current_part} ) {

        # don't use an integer as a hash key if need to
        # create the next level in the tree
        return undef if $current_part =~ /^\d+$/;

        $current_ref->{$current_part}
          = $next_part =~ /^\d+$/
            ? []
            : {};
      }

      $current_ref = $current_ref->{$current_part};
      next;
    }
    elsif ( ref $current_ref eq 'ARRAY' ) {
      return _error( $opts{error} ) if $current_part !~ /^\d+$/;

      if ( not ref $current_ref->[$current_part] ) {
        $current_ref->[$current_part]
          = $next_part =~ /^\d+$/
            ? []
            : {};
      }

      $current_ref = $current_ref->[$current_part];
      next;
    }

    # ! ref $root_ref && @root_parts > 1
    return _error( $opts{error} );
  }

  my $last_part = pop @root_parts;

  if ( ref $current_ref eq 'HASH' ) {
    return $current_ref->{$last_part} = $value;
  }

  if ( ref $current_ref eq 'ARRAY' ) {
    return _error( $opts{error} ) if $last_part !~ /^\d+$/;
    return $current_ref->[$last_part] = $value;
  }

  # ! ref $root_ref && @root_parts == 1
  return _error( $opts{error} );
}

1;

__END__

=head1 NAME

Data::PathSimple - Navigate and manipulate data structures using paths

=head1 SYNOPSIS

  use Data::PathSimple qw{
    get
    set
  };

  my $data = {
    Languages => {
      Perl   => {
        CurrentVersion => '5.16.1',
        URLs           => [
          'http://www.perl.org',
          'http://www.cpan.org',
        ],
      },
      PHP    => {
        CurrentVersion => '5.4.7',
        URLs           => [
          'http://www.php.net',
          'http://pear.php.net',
        ],
      },
      Python => {
        CurrentVersion => '2.7.3',
        URLs           => [
          'http://www.python.org',
        ],
      },
    },
  };

  my $current_perl = get( $data, '/Languages/Perl/CurrentVersion' );
  my @perl_urls    = @{ get( $data, '/Languages/Perl/URLs' ) || [] };

  set( $data, '/Languages/Perl/CurrentVersion', '5.16.2' );
  set( $data, '/Languages/Python/URLs/1/', 'http://pypi.python.org' );

=head1 DESCRIPTION

B<Data::PathSimple> allows you to get and set values deep within a data structure
using simple paths to navigate (think XPATH without the steroids).

Why do this when we already have direct access to the data structure? The
motivation is that the path will come from a user using a command line tool.

=head2 Path Specifications

A path is specified as a string consisting of components separated by
a I<path separator>.  By default the separator is the C</> character,
but that may be changed via the C<path_sep> option.  Paths are always
specified relative to the root of the structure; a leading path
separator is optional.

A path component is treated as an array index if it matches an integer
number, as a hash key otherwise.

=head2 Error returns

If an error occurs (e.g, an incorrect input, or if a path cannot be resolved)
an error value is returned.  By default this is C<undef>, but it may
be changed with the C<error> option. That option can also take a code reference,
so, for example,

  error => sub { require Croak; Croak::carp( "error" ) }

would cause an exception to be thrown on errors.

=head1 FUNCTIONS

Functions are not exported by default.

=head2 get

Gets the value at the specified path:

  my $current_perl = get( $data, '/Languages/Perl/CurrentVersion', ?\%options );

The following options are supported:

=over

=item path_sep

A string or reqular expression which will match the path separator.
It defaults to the string C</>.

=item error

How non-existent paths or mismatched array indices or hash keys
should be handled. If set to a coderef, the result of the coderef will
be returned.  Otherwise, whatever C<error> is set to will be returned.
It defaults to C<undef>.

=back

If a path does not exist, an error value is returned. For example, the following will
return an error since the C<Ruby> path does not exist:

  my $current_ruby = get( $data, '/Languages/Ruby/CurrentVersion' );

If the path is not an integer yet we are accessing an array ref, an error value is
returned. For example, the following will return an error since the C<first> path
is not an integer:

  my $perl_url = get( $data, '/Languages/Perl/URLs/first' );

Note that no autovivification occurs. In other words, your data structure will
never be modified by a call to C<get()>.

=head2 set

Sets the value at the specified path:

  set( $data, '/Languages/Perl/CurrentVersion', '5.16.2', ?\%options );

The following options are supported:

=over

=item path_sep

A string or reqular expression which will match the path separator.
It defaults to the string C</>.

=item error

How errors should be handled. If set to a coderef, the result of the
coderef will be returned.  Otherwise, whatever C<error> is set to will
be returned.  It defaults to C<undef>.

=back

If a path does not exist, it will be autovivified. For example, the following
will create the C<Ruby> path:

  set( $data, '/Languages/Ruby/CurrentVersion', '1.9.3' );

By default hash refs are used when autovivifying. However if the path is an
integer, then an array ref will be used instead. For example, the following
will create an array ref for the C<URLs> path:

  set( $data, '/Languages/Ruby/URLs/0', 'http://www.ruby-lang.org' );

If the path is not an integer yet we are accessing an array ref, an error value is
returned. For example, the following will return C<undef> since the C<first> path
is not an integer:

  my $perl_url = set( $data, '/Languages/Perl/URLs/first', '5.16.2' );

=head1 SEE ALSO

The latest version can be found at:

  https://github.com/alfie/Data-PathSimple

Watch the repository and keep up with the latest changes:

  https://github.com/alfie/Data-PathSimple/subscription

=head1 SUPPORT

Please report any bugs or feature requests at:

  https://github.com/alfie/Data-PathSimple/issues

Feel free to fork the repository and submit pull requests :)

=head1 INSTALLATION

To install this module type the following:

  perl Makefile.PL
  make
  make test
  make install

=head1 DEPENDENCIES

=over

=item Perl v5.10.0

=back

=head1 AUTHOR

Alfie John E<lt>alfie@alfie.wtfE<gt>

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>

=head1 WARRANTY

IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
