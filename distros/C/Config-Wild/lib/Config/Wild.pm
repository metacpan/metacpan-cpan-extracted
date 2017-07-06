package Config::Wild;

# ABSTRACT: parse an application configuration file with wildcard keywords

use strict;
use warnings;

our $VERSION = '2.02';

use custom::failures __PACKAGE__ . '::Error' => [ 'exists', 'read', 'parse' ];

use Carp;

use List::Util qw[ first ];
use File::pushd;
use Path::Tiny qw[ path cwd ];

use Try::Tiny;

use Log::Any '$log';

use namespace::clean;

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
#pod =pod
#pod
#pod =begin pod_coverage
#pod
#pod =head3 value
#pod
#pod =end pod_coverage
#pod
#pod =cut

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

#
# This file is part of Config-Wild
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

Config::Wild - parse an application configuration file with wildcard keywords

=head1 VERSION

version 2.02

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
normally have the same value, but where on occasion you'd like to
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

=begin pod_coverage

=head3 value

=end pod_coverage

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
specified in the passed C<%attr> hash. They may also be specified or modified after
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

It throws an exception (as a string) if an error occurred.

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

It throws an exception (as a string) if an error occurred.

=head3 set

  $cfg->set( $key, $value );

Explicitly set a key to a value.  Useful to specify keys that
should be available before parsing the configuration file.

=head3 get

  $value = $cfg->get( $key );

Return the value associated with a given key.  B<$key> is
first matched against the absolute keys, then against the
wildcards.  If no match is made, C<undef> is returned.

=head3 getbool

  $value = $cfg->getbool( $key );

Convert the value associated with a given key to a true or false value
using B<L<Lingua::Boolean::Tiny>>.  B<$key> is first matched against
the absolute keys, then against the wildcards.  If no match is made,
or the value could not be converted to a truth value, C<undef> is
returned.

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

If an error occurs during searching for, reading, or parsing a
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

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Wild>.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use Config::Wild;
#pod   $cfg = Config::Wild->new();
#pod   $cfg = Config::Wild->new( $configfile, \%attr );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module reads I<key - value> data pairs from a file.  What sets
#pod it apart from other configuration systems is that keys may contain
#pod Perl regular expressions, allowing one entry to match multiple
#pod requested keys.
#pod
#pod Configuration information in the file has the form
#pod
#pod   key = value
#pod
#pod where I<key> is a token which may contain Perl regular expressions
#pod surrounded by curly brackets, e.g.
#pod
#pod   foobar.{\d+}.name = goo
#pod
#pod and I<value> is the remainder of the line after any whitespace following
#pod the C<=> character is removed.
#pod
#pod Keys which contain regular expressions are termed I<wildcard>
#pod keys; those without are called I<absolute> keys.  Wildcard
#pod keys serve as templates to allow grouping of keys which have
#pod the same value.  For instance, say you've got a set of keys which
#pod normally have the same value, but where on occasion you'd like to
#pod override the default:
#pod
#pod   p.{\d+}.foo = goo
#pod   p.99.foo = flabber
#pod
#pod I<value> may reference environment variables or other B<Config::Wild>
#pod variables via the following expressions:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Environment variables may be accessed via C<${var}>:
#pod
#pod   foo = ${HOME}/foo
#pod
#pod If the variable doesn't exist, the expression is replaced with
#pod an empty string.
#pod
#pod
#pod =item *
#pod
#pod Other B<Config::Wild> variables may be accessed via C<$(var)>.
#pod
#pod   root = ${HOME}
#pod   foo = $(root)/foo
#pod
#pod If the variable doesn't exist, the expression is replaced with
#pod an empty string.  Variable expansions can be nested, as in
#pod
#pod   root = /root
#pod   branch = $(root)/branch
#pod   tree = $(branch)/tree
#pod
#pod C<tree> will evaluate to C</root/branch/tree>.
#pod
#pod =item *
#pod
#pod I<Either> type of variable may be accessed via C<$var>.
#pod In this case, if I<var> is not a B<Config::Wild> variable, it is
#pod assumed to be an environment variable.
#pod If the variable doesn't exist, the expression is left as is.
#pod
#pod =back
#pod
#pod Substitutions are made when the B<value> method is called, not when
#pod the values are first read in.
#pod
#pod Lines which begin with the C<#> character are ignored.  There is also a
#pod set of directives which alter where and how B<Config::Wild> reads
#pod configuration information.  Each directive begins with the C<%> character
#pod and appears alone on a line in the config file:
#pod
#pod =over 4
#pod
#pod =item B<%include> F<path>
#pod
#pod Temporarily interrupt parsing of the current configuration file, and
#pod switch the input stream to the file specified via I<path>.
#pod See L</Finding Configuration Files>.
#pod
#pod =back
#pod
#pod =head2 Finding Configuration Files
#pod
#pod The C<dir> and C<path> options to the constructor determine where
#pod configuration files are searched for.  They are optional and may not be
#pod specified in combination.
#pod
#pod In the following tables:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod C<file> is the provided path to the configuration file.
#pod
#pod =item *
#pod
#pod C<option = default> indicates that neither C<dir> nor C<path>
#pod has been specified.
#pod
#pod =item *
#pod
#pod The file patterns are,
#pod
#pod   /*         absolute path
#pod   ./* ../*   paths relative to the current directory
#pod   *          all other paths
#pod
#pod =item *
#pod
#pod In the results,
#pod
#pod   cwd        the current working directory
#pod   path       an entry in the path option array
#pod
#pod =back
#pod
#pod =head3 Files loaded via B<new> and B<load>
#pod
#pod   +==========================================+
#pod   |         |            file                |
#pod   |---------+--------------------------------|
#pod   | option  |  /*  |  ./* ../*   |  *        |
#pod   |==========================================|
#pod   | default | file | cwd/file    | cwd/file  |
#pod   | path    | file | cwd/file    | path/file |
#pod   | dir     | file | dir/file    | dir/file  |
#pod   +---------+------+-------------+-----------+
#pod
#pod =head3 Files included from other files
#pod
#pod C<incdir> is the directory containing the file including the new
#pod configuration file, e.g. the one with the C<%include> directive.
#pod
#pod   +==========================================+
#pod   |         |            file                |
#pod   |---------+--------------------------------|
#pod   | option  |  /*  |  ./* ../*   |  *        |
#pod   |==========================================|
#pod   | default | file | incdir/file | cwd/file  |
#pod   | path    | file | incdir/file | path/file |
#pod   | dir     | file | dir/file    | dir/file  |
#pod   +---------+------+-------------+-----------+
#pod
#pod =head1 METHODS
#pod
#pod =head2 Constructor
#pod
#pod =head3 new
#pod
#pod   $cfg = Config::Wild->new( \%attr );
#pod   $cfg = Config::Wild->new( $config_file, \%attr );
#pod
#pod Create a new B<Config::Wild> object, optionally loading configuration
#pod information from a file.
#pod
#pod See L</Finding Configuration Files> for more information on how
#pod configuration files are found.
#pod
#pod Additional attributes which modify the behavior of the object may be
#pod specified in the passed C<%attr> hash. They may also be specified or modified after
#pod object creation using the C<set_attr> method.
#pod
#pod The following attributes are available:
#pod
#pod =over
#pod
#pod =item C<UNDEF> I<subroutine reference>
#pod
#pod This specifies a subroutine to be called when the value of an undefined
#pod key is requested.  The subroutine is passed the name of the key.
#pod It should return a value, which will be returned as the value of the
#pod key.
#pod
#pod For example,
#pod
#pod   $cfg = Config::Wild->new( "foo.cnf", { UNDEF => \&undefined_key } );
#pod
#pod   sub undefined_key
#pod   {
#pod     my $key = shift;
#pod     return 33;
#pod   }
#pod
#pod You may also use this to centralize error messages:
#pod
#pod   sub undefined_key
#pod   {
#pod     my $key = shift;
#pod     die("undefined key requested: $key\n");
#pod   }
#pod
#pod To reset this to the default behavior, set C<UNDEF> to C<undef>:
#pod
#pod   $cfg->set_attr( UNDEF => undef );
#pod
#pod
#pod =item C<dir> F<directory>
#pod
#pod If specified, the current working directory will be changed to the
#pod specified directory before a configuration file is loaded.
#pod
#pod See L</Finding Configuration Files>.
#pod
#pod This option may not be combined with the C<path> option.
#pod
#pod =item C<path> I<paths>
#pod
#pod An array of paths to search for configuration files.
#pod
#pod See L</Finding Configuration Files>.
#pod
#pod This option may not be combined with the C<dir> option.
#pod
#pod =item C<ExpandWild> I<boolean>
#pod
#pod If set, when expanding C<$(var)> in key values, C<var> will be
#pod matched first against absolute keys, then against wildcard
#pod keys.  If not set (the default), C<var> is matched only against the
#pod absolute keys.
#pod
#pod =back
#pod
#pod =head3 load
#pod
#pod   $cfg->load( $file );
#pod
#pod Load information from a configuration file into the current object.
#pod New configuration values will supersede previous ones, in the
#pod following complicated fashion.  Absolutely specified keys will
#pod overwrite previously absolutely specified values.  Since it is
#pod difficult to determine whether the set of keys matched by two
#pod regular expressions overlap, wildcard keys are pushed onto a
#pod last-in first-out (LIFO) list, so that when the application requests a
#pod value, it will use search the wildcard keys in reverse order that
#pod they were specified.
#pod
#pod It throws an exception (as a string) if an error occurred.
#pod
#pod See L</Finding Configuration Files> for more information on how
#pod configuration files are found.
#pod
#pod
#pod =head3 load_cmd
#pod
#pod   $cfg->load_cmd( \@ARGV );
#pod   $cfg->load_cmd( \@ARGV,\%attr );
#pod
#pod Parse an array of key-value pairs (possibly command line
#pod arguments), and insert them into the list of keys.  It can take an
#pod optional hash of attributes with the following values:
#pod
#pod =over 8
#pod
#pod =item C<Exists>
#pod
#pod If true, the keys must already exist. An error will be returned if
#pod the key isn't in the absolute list, or doesn't match against the
#pod wildcards.
#pod
#pod =back
#pod
#pod It throws an exception (as a string) if an error occurred.
#pod
#pod =head3 set
#pod
#pod   $cfg->set( $key, $value );
#pod
#pod Explicitly set a key to a value.  Useful to specify keys that
#pod should be available before parsing the configuration file.
#pod
#pod =head3 get
#pod
#pod   $value = $cfg->get( $key );
#pod
#pod Return the value associated with a given key.  B<$key> is
#pod first matched against the absolute keys, then against the
#pod wildcards.  If no match is made, C<undef> is returned.
#pod
#pod =head3 getbool
#pod
#pod   $value = $cfg->getbool( $key );
#pod
#pod Convert the value associated with a given key to a true or false value
#pod using B<L<Lingua::Boolean::Tiny>>.  B<$key> is first matched against
#pod the absolute keys, then against the wildcards.  If no match is made,
#pod or the value could not be converted to a truth value, C<undef> is
#pod returned.
#pod
#pod
#pod =head3 delete
#pod
#pod   $cfg->delete( $key );
#pod
#pod Delete C<$key> from the list of keys (either absolute or wild)
#pod stored in the object.  The key must be an exact match.  It is not
#pod an error to delete a key which doesn't exist.
#pod
#pod
#pod =head3 exists
#pod
#pod   $exists = $cfg->exists( $key );
#pod
#pod Returns non-zero if the given key matches against the list of
#pod keys in the object, C<undef> if not.
#pod
#pod
#pod =head3 set_attr
#pod
#pod   $cfg->set_attr( \%attr );
#pod
#pod Set object attribute. See <L/METHODS/"new"> for a list of attributes.
#pod
#pod =head2 Keyword-named Accessors Methods
#pod
#pod You may access a value by specifying the keyword as the method,
#pod instead of using the B<get()> method.  The following are equivalent:
#pod
#pod    # keyword is foo
#pod    $foo = $cfg->get( 'foo' );
#pod    $foo = $cfg->foo;
#pod
#pod If C<foo> doesn't exist, it returns C<undef>.
#pod
#pod You can set a value using a similar syntax.  The following are
#pod equivalent, if the key already exists:
#pod
#pod    $cfg->set( 'key', $value );
#pod    $cfg->key( $value );
#pod
#pod If the key doesn't exist, the second statement does nothing.
#pod
#pod It is a bit more time consuming to use these methods rather than using
#pod B<set> and B<get>.
#pod
#pod =head1 LOGGING
#pod
#pod B<Config::Wild> uses L<Log::Any> to log C<info> level messages during
#pod searching and reading configuration files.  In the event of an error
#pod during searching, reading, and parsing files, it will log C<error>
#pod level messages.
#pod
#pod =head1 ERRORS AND EXCEPTIONS
#pod
#pod For most errors, B<Config::Wild> will croak.
#pod
#pod If an error occurs during searching for, reading, or parsing a
#pod configuration file, objects in the following classes will be thrown:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod Config::Wild::Error::exists
#pod
#pod =item *
#pod
#pod Config::Wild::Error::read
#pod
#pod =item *
#pod
#pod Config::Wild::Error::parse
#pod
#pod =back
#pod
#pod They stringify into an appropriate error message.
#pod
