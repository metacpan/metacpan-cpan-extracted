# --8<--8<--8<--8<--
#
# Copyright (C) 1998-2015 Smithsonian Astrophysical Observatory
#
# This file is part of Config-Wild
#
# Config-Wild is free software: you can redistribute it and/or modify
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

package Config::Wild;

use strict;
use warnings;

our $VERSION = '2.01';

use custom::failures __PACKAGE__ . '::Error' => [ 'exists', 'read', 'parse' ];

use Carp;

use List::Util qw[ first ];
use File::pushd;
use Path::Tiny qw[ path cwd ];

use Try::Tiny;

use Log::Any '$log';



sub new {
    my $this = shift;
    my $class = ref( $this ) || $this;

    my %attr = (
        UNDEF      => undef,    # function to call from value when
                                # keyword not defined
        dir        => undef,
        path       => undef,
        ExpandWild => 0,        # match wildcards when expanding
    );

    my $attr = ref $_[-1] eq 'HASH' ? pop @_ : {};

    ## no critic (ProhibitAccessOfPrivateData)
    $attr{$_} = $attr->{$_}
      for
      grep { CORE::exists( $attr{$_} ) or croak( "unknown attribute: $_\n" ) }
      keys %$attr;

    croak( "options dir and path may not both be specified\n" )
      if defined $attr{dir} && defined $attr{path};

    my $self = {
        wild => [],       # regular expression keywords
        abs  => {},       # absolute keywords
        attr => \%attr,
    };

    bless $self, $class;

    my $file = shift;

    croak( "extra arguments passed to new. forgot a hashref?\n" )
      if @_;

    $self->load( $file )
      if $file;

    return $self;
}

sub load {
    my ( $self, $file ) = @_;

    croak( 'no file specified' )
      if !defined $file;

    my $cwd
      = defined $self->{attr}{dir}
      ? pushd( $self->{attr}{dir} )
      : cwd;

    $self->_read_config( $file, path( $cwd ) );

}

# note that Path::Tiny::path will strip ./ from ./file, so
# don't convert file to a P::T object until after
# checking for ./
sub _read_config {

    my $self = shift;

    my ( $file, $cwd ) = @_;

    my $file_p = path( $file );


    # relative to current dir or parent
    if ( !defined $self->{attr}{dir} && $file =~ m|^[.]{1,2}/| ) {

        $file_p = $cwd->child( $file );

    }

    elsif ( $self->{attr}{path} && !$file_p->is_absolute ) {

      SEARCH: {
            $log->info( "Searching for configuration file $file_p" );

            for my $path ( @{ $self->{attr}{path} } ) {

                $file_p = path( $path, $file );
                last SEARCH if $file_p->is_file;

            }

            _log_fatal( 'Config::Wild::Error::exists', $file, "unable to find file in "
			. join( ':', @{ $self->{attr}{path} } ) );

        }

    }

    _log_fatal( 'Config::Wild::Error::exists', $file_p, 'unable to find file' )
      unless $file_p->is_file;

    $log->info( "Reading configuration file ", $file_p->absolute->canonpath )
      if $log->is_info;

    my @lines;

    local $! = 0;
    try {
        @lines = $file_p->lines( { chomp => 1 } );
    }
    catch {
	_log_fatal( 'Config::Wild::Error::read', $file_p, $_ );
    };

    try {

        my $line_idx = 1;
        for my $line ( @lines ) {

            # ignore comment lines or empty lines
            next if $line =~ /^\s*\#|^\s*$/;

            if ( $line =~ /^\s*%include\s+(.*)/ ) {

                $self->_read_config( $1, $file_p->parent );

            }

            else {

                $self->_parsepair( $line )
                  or die( "can't parse line $line_idx" );
            }

        }
        continue {
            ++$line_idx;
        }

    }
    catch {
	_log_fatal( 'Config::Wild::Error::parse', $file_p, $_ );
    };

}

sub load_cmd {
    my ( $self, $argv, $attr ) = @_;
    my $keyword;

    $attr = {} unless defined $attr;

    foreach ( @$argv ) {
        if (   $$attr{Exists}
            && ( $keyword = ( $self->_splitpair( $_ ) )[0] )
            && !$self->_exists( $keyword ) )
        {
            croak( "keyword `$keyword' doesn't exist" );
        }

        $self->_parsepair( $_ ) or croak( "can't parse line $_" );
    }

    return;
}


sub set {
    my ( $self, $keyword, $value ) = @_;

    die unless defined( $keyword ) and defined( $value );
    # so, is it a regular expression or not?
    if ( $keyword =~ /\{/ ) {
        # quote all characters outside of curly brackets.
        $keyword = join(
            '',
            map {
                substr( $_, 0, 1 ) ne '{'
                  ? quotemeta( $_ )
                  : substr( $_, 1, -1 )
            } $keyword =~ /( [^{}]+ | {[^\}]*} )/gx
        );

        unshift @{ $self->{wild} }, [ $keyword, $value ];
    }
    else {
        $self->{abs}->{$keyword} = $value;
    }
}

# for backwards compatibility
=pod

=begin pod_coverage

=head3 value

=end pod_coverage

=cut

*value = \&get;

sub get {
    my ( $self, $keyword ) = @_;

    croak( 'no keyword specified' )
      if !defined $keyword;


    return $self->_expand( $self->{abs}->{$keyword} )
      if CORE::exists( $self->{abs}->{$keyword} );

    foreach ( @{ $self->{wild} } ) {
        ## no critic (ProhibitAccessOfPrivateData)
        return $self->_expand( $_->[1] ) if $keyword =~ /$_->[0]/;
    }

    return $self->{attr}{UNDEF}->( $keyword )
      if defined $self->{attr}{UNDEF};

    return;
}

sub getbool {

    require Lingua::Boolean::Tiny;

    my $self = shift;

    return Lingua::Boolean::Tiny::boolean( $self->get( @_ ) );
}

sub delete {
    my ( $self, $keyword ) = @_;

    croak( 'no keyword specified' )
      if !defined $keyword;

    if ( CORE::exists $self->{abs}->{$keyword} ) {
        delete $self->{abs}->{$keyword};
    }
    else {
        ## no critic (ProhibitAccessOfPrivateData)
        $self->{wild} = grep( $_->[0] ne $keyword, @{ $self->{wild} } );
    }
    1;
}

sub exists {
    my ( $self, $keyword ) = @_;

    croak( 'no keyword specified' )
      if !defined $keyword;

    return $self->_exists( $keyword );
}

sub _exists {
    my ( $self, $keyword ) = @_;

    return 1 if CORE::exists( $self->{abs}->{$keyword} );

    foreach ( @{ $self->{wild} } ) {
        return 1 if $keyword =~ /$_->[0]/;
    }

    undef;

}


sub set_attr {
    my ( $self, $attr ) = @_;
    my ( $key, $value );

    while ( ( $key, $value ) = each %{$attr} ) {

        croak( "unknown attribute: `$key'" )
          unless CORE::exists $self->{attr}{$key};


        $self->{attr}{$key} = $value;
    }

}

#========================================================================
#
# AUTOLOAD
#
# Autoload function called whenever an unresolved object method is
# called.  If the method name relates to a defined VARIABLE, we patch
# in $self->get() and $self->set() to magically update the varaiable
# (if a parameter is supplied) and return the previous value.
#
# Thus the function can be used in the folowing ways:
#    $cfg->variable(123);     # set a new value
#    $foo = $cfg->variable(); # get the current value
#
# Returns the current value of the variable, taken before any new value
# is set.  Throws an exception if the variable isn't defined (i.e. doesn't
# exist rather than exists with an undef value) and returns undef.
#
#========================================================================

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $keyword;
    my ( $oldval, $newval );


    # splat the leading package name
    ( $keyword = $AUTOLOAD ) =~ s/.*:://;

    # ignore destructor
    $keyword eq 'DESTROY' && return;

    if ( CORE::exists( $self->{abs}->{$keyword} ) ) {
        $oldval = $self->_expand( $self->{abs}->{$keyword} );
    }
    else {
        my $found = 0;
        foreach ( @{ $self->{wild} } ) {
            ## no critic (ProhibitAccessOfPrivateData)
            $oldval = $self->_expand( $_->[1] ), $found++, last
              if $keyword =~ /$_->[0]/;
        }
        if ( !$found ) {
            return $self->{attr}{UNDEF}->( $keyword )
              if defined( $self->{attr}{UNDEF} );

            croak( "$keyword doesn't exist" );
        }
    }

    # set a new value if a parameter was supplied
    $self->set( $keyword, $newval )
      if defined( $newval = shift );

    # return old value
    return $oldval;
}

sub _expand {
    my ( $self, $value ) = @_;

    my $stop = 0;
    until ( $stop ) {
        $stop = 1;

        # expand ${VAR} as environment variables
        $value =~ s/\$\{(\w+)\}/defined $ENV{$1} ? $ENV{$1} : ''/ge
          and $stop = 0;

        # expand $(VAR) as a ConfigWild variable
        $value =~ s{\$\((\w+)\)} {
	    my $var = $1;
	    if ( defined $self->{abs}->{$var} ) {
                 $self->{abs}->{$var};
            }

            elsif ( $self->{attr}{ExpandWild}
		    && (my $kwd = first { $var =~ $_->[0] } @{ $self->{wild} } )
		  ) {

		$kwd->[1];

	    }

	    else {

		''
	    }

	}gex
          and $stop = 0;

        # expand any unparenthesised/braced variables,
        # e.g. "$var", as ConfigWild vars or environment variables.
        # leave untouched if not
        $value =~ s{\$(\w+)} {
	    defined $self->{abs}->{$1} ? $self->{abs}->{$1} :
	      defined $ENV{$1} ? $ENV{$1} :
		"\$$1"
	    }gex
          and $stop = 0;
    }
    # return the value
    $value;
}

sub _splitpair {
    my ( $self, $pair ) = @_;
    my ( $keyword, $value );

    $pair =~ s/^\s+//;
    $pair =~ s/\s+$//;

    return 2 != ( ( $keyword, $value ) = $pair =~ /([^=\s]*)\s*=\s*(.*)/ )
      ? ()
      : ( $keyword, $value );
}

sub _parsepair {
    my ( $self, $pair ) = @_;

    my ( $keyword, $value );

    $pair =~ s/^\s+//;
    $pair =~ s/\s+$//;

    return
      if 2 != ( ( $keyword, $value ) = $pair =~ /([^=\s]*)\s*=\s*(.*)/ );

    $self->set( $keyword, $value );
    1;
}


sub _log_fatal {

    my ( $package, $file, @err )  = @_;

    $file = $file->absolute->canonpath if ref $file;

    my $err = join( '', $file, ': ', @err );

    $log->error( $err );
    $package->throw( $err );

}


1;
__END__


=head1 NAME

Config::Wild - parse an application configuration file with wildcard keywords

=head1 SYNOPSIS

  use Config::Wild;
  $cfg = Config::Wild->new();
  $cfg = Config::Wild->new( $configfile, \%attr );

=head1 DESCRIPTION

This module reads I<key - value> data pairs from a file.  What sets
it apart from other configuration systems is that keys may contain
Perl regular expressions, allowing one entry to match multiple
requested keys.

Configuration information in the file has the form

  key = value

where I<key> is a token which may contain Perl regular expressions
surrounded by curly brackets, e.g.

  foobar.{\d+}.name = goo

and I<value> is the remainder of the line after any whitespace following
the C<=> character is removed.

Keys which contain regular expressions are termed I<wildcard>
keys; those without are called I<absolute> keys.  Wildcard
keys serve as templates to allow grouping of keys which have
the same value.  For instance, say you've got a set of keys which
normally have the same value, but where on occaision you'd like to
override the default:

  p.{\d+}.foo = goo
  p.99.foo = flabber

I<value> may reference environment variables or other B<Config::Wild>
variables via the following expressions:

=over 4

=item *

Environment variables may be accessed via C<${var}>:

  foo = ${HOME}/foo

If the variable doesn't exist, the expression is replaced with
an empty string.


=item *

Other B<Config::Wild> variables may be accessed via C<$(var)>.

  root = ${HOME}
  foo = $(root)/foo

If the variable doesn't exist, the expression is replaced with
an empty string.  Variable expansions can be nested, as in

  root = /root
  branch = $(root)/branch
  tree = $(branch)/tree

C<tree> will evaluate to C</root/branch/tree>.

=item *

I<Either> type of variable may be accessed via C<$var>.
In this case, if I<var> is not a B<Config::Wild> variable, it is
assumed to be an environment variable.
If the variable doesn't exist, the expression is left as is.

=back

Substitutions are made when the B<value> method is called, not when
the values are first read in.

Lines which begin with the C<#> character are ignored.  There is also a
set of directives which alter where and how B<Config::Wild> reads
configuration information.  Each directive begins with the C<%> character
and appears alone on a line in the config file:

=over 4

=item B<%include> F<path>

Temporarily interrupt parsing of the current configuration file, and
switch the input stream to the file specified via I<path>.
See L</Finding Configuration Files>.

=back

=head2 Finding Configuration Files

The C<dir> and C<path> options to the constructor determine where
configuration files are searched for.  They are optional and may not be
specified in combination.

In the following tables:

=over

=item *

C<file> is the provided path to the configuration file.

=item *

C<option = default> indicates that neither C<dir> nor C<path>
has been specified.

=item *

The file patterns are,

  /*         absolute path
  ./* ../*   paths relative to the current directory
  *          all other paths

=item *

In the results,

  cwd        the current working directory
  path       an entry in the path option array

=back

=head3 Files loaded via B<new> and B<load>

  +==========================================+
  |         |            file                |
  |---------+--------------------------------|
  | option  |  /*  |  ./* ../*   |  *        |
  |==========================================|
  | default | file | cwd/file    | cwd/file  |
  | path    | file | cwd/file    | path/file |
  | dir     | file | dir/file    | dir/file  |
  +---------+------+-------------+-----------+

=head3 Files included from other files

C<incdir> is the directory containing the file including the new
configuration file, e.g. the one with the C<%include> directive.

  +==========================================+
  |         |            file                |
  |---------+--------------------------------|
  | option  |  /*  |  ./* ../*   |  *        |
  |==========================================|
  | default | file | incdir/file | cwd/file  |
  | path    | file | incdir/file | path/file |
  | dir     | file | dir/file    | dir/file  |
  +---------+------+-------------+-----------+

=head1 METHODS

=head2 Constructor

=head3 new

  $cfg = Config::Wild->new( \%attr );
  $cfg = Config::Wild->new( $config_file, \%attr );

Create a new B<Config::Wild> object, optionally loading configuration
information from a file.

See L</Finding Configuration Files> for more information on how
configuration files are found.

Additional attributes which modify the behavior of the object may be
specified in the passed C<%attr> hash. They may also be specifed or modified after
object creation using the C<set_attr> method.

The following attributes are available:

=over

=item C<UNDEF> I<subroutine reference>

This specifies a subroutine to be called when the value of an undefined
key is requested.  The subroutine is passed the name of the key.
It should return a value, which will be returned as the value of the
key.

For example,

  $cfg = Config::Wild->new( "foo.cnf", { UNDEF => \&undefined_key } );

  sub undefined_key
  {
    my $key = shift;
    return 33;
  }

You may also use this to centralize error messages:

  sub undefined_key
  {
    my $key = shift;
    die("undefined key requested: $key\n");
  }

To reset this to the default behavior, set C<UNDEF> to C<undef>:

  $cfg->set_attr( UNDEF => undef );


=item C<dir> F<directory>

If specified, the current working directory will be changed to the
specified directory before a configuration file is loaded.

See L</Finding Configuration Files>.

This option may not be combined with the C<path> option.

=item C<path> I<paths>

An array of paths to search for configuration files.

See L</Finding Configuration Files>.

This option may not be combined with the C<dir> option.

=item C<ExpandWild> I<boolean>

If set, when expanding C<$(var)> in key values, C<var> will be
matched first against absolute keys, then against wildcard
keys.  If not set (the default), C<var> is matched only against the
absolute keys.

=back

=head3 load

  $cfg->load( $file );

Load information from a configuration file into the current object.
New configuration values will supersede previous ones, in the
following complicated fashion.  Absolutely specified keys will
overwrite previously absolutely specified values.  Since it is
difficult to determine whether the set of keys matched by two
regular expressions overlap, wildcard keys are pushed onto a
last-in first-out (LIFO) list, so that when the application requests a
value, it will use search the wildcard keys in reverse order that
they were specified.

It throws an exception (as a string) if an error ocurred.

See L</Finding Configuration Files> for more information on how
configuration files are found.


=head3 load_cmd

  $cfg->load_cmd( \@ARGV );
  $cfg->load_cmd( \@ARGV,\%attr );

Parse an array of key-value pairs (possibly command line
arguments), and insert them into the list of keys.  It can take an
optional hash of attributes with the following values:

=over 8

=item C<Exists>

If true, the keys must already exist. An error will be returned if
the key isn't in the absolute list, or doesn't match against the
wildcards.

=back

It throws an exception (as a string) if an error ocurred.

=head3 set

  $cfg->set( $key, $value );

Explicitly set a key to a value.  Useful to specify keys that
should be available before parsing the configuration file.

=head3 get

  $value = $cfg->get( $key );

Return the value associated with a given key.  B<$key> is
first matched against the absolute keys, then agains the
wildcards.  If no match is made, C<undef> is returned.

=head3 getbool

  $value = $cfg->getbool( $key );

Convert the value associated with a given key to a true or false
value using B<L<Lingua::Boolean::Tiny>>.  B<$key> is first matched against the absolute keys,
then agains the wildcards.  If no match is made, or the value could
not be converted to a truth value, C<undef> is returned.


=head3 delete

  $cfg->delete( $key );

Delete C<$key> from the list of keys (either absolute or wild)
stored in the object.  The key must be an exact match.  It is not
an error to delete a key which doesn't exist.


=head3 exists

  $exists = $cfg->exists( $key );

Returns non-zero if the given key matches against the list of
keys in the object, C<undef> if not.


=head3 set_attr

  $cfg->set_attr( \%attr );

Set object attribute. See <L/METHODS/"new"> for a list of attributes.

=head2 Keyword-named Accessors Methods

You may access a value by specifying the keyword as the method,
instead of using the B<get()> method.  The following are equivalent:

   # keyword is foo
   $foo = $cfg->get( 'foo' );
   $foo = $cfg->foo;

If C<foo> doesn't exist, it returns C<undef>.

You can set a value using a similar syntax.  The following are
equivalent, if the key already exists:

   $cfg->set( 'key', $value );
   $cfg->key( $value );

If the key doesn't exist, the second statement does nothing.

It is a bit more time consuming to use these methods rather than using
B<set> and B<get>.

=head1 LOGGING

B<Config::Wild> uses L<Log::Any> to log C<info> level messages during
searching and reading configuration files.  In the event of an error
during searching, reading, and parsing files, it will log C<error>
level messages.

=head1 ERRORS AND EXCEPTIONS

For most errors, B<Config::Wild> will croak.

If an error ocurrs during searching for, reading, or parsing a
configuration file, objects in the following classes will be thrown:

=over

=item *

Config::Wild::Error::exists

=item *

Config::Wild::Error::read

=item *

Config::Wild::Error::parse

=back

They stringify into an appropriate error message.

=head1 COPYRIGHT & LICENSE

Copyright 1998-2015 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 SEE ALSO

B<AppConfig>, an early version of which was the inspiration for this
module.


=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>
