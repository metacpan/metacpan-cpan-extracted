# Copyright (c) 2004-2012 by Karl Gaissmaier, Ulm University, Germany
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#


# for documentation see Config::Scoped.pod

package Config::Scoped;

use strict;
use warnings;

use Storable qw(dclone lock_nstore lock_retrieve);
use Carp;
use Safe;
use Digest::MD5 qw(md5_base64);
use File::Basename qw(fileparse);
use File::Spec;
use Config::Scoped::Error;
use base 'Parse::RecDescent';

our $VERSION = '0.22';

my $grammar;
{
    local $/;
    $grammar = <DATA>;
    close DATA;
}

my @state_hashes = qw(config params macros warnings includes);

sub new {
    my $class = shift;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("odd number of arguments,") )
      if @_ % 2;

    my %args = @_;

    ##############################################
    # Delayed compilation of grammar in method parse()
    #
    my $empty_grammar = '';
    $args{compiled} = undef;

    ##############################################
    # create the parser object, delayed grammar
    #
    my $thisparser = $class->SUPER::new($empty_grammar)
      or Config::Scoped::Error->throw(
        -text => "Can't create a '$class' parser," );

    ##############################################
    # store the args in the P::RD object below 'local'
    # don't use deep copy since we use always one and
    # only one global config hash
    #
    $thisparser->{local} = {%args};

    # frequent typos, be polite
    $thisparser->{local}{warnings} ||= $thisparser->{local}{warning};
    $thisparser->{local}{lc}       ||= $thisparser->{local}{lowercase};
    $thisparser->{local}{safe}     ||= $thisparser->{local}{Safe};
    $thisparser->{local}{file}     ||= $thisparser->{local}{File};

    ##############################################
    # validate and munge the 'file' param
    #
    # a cfg_file isn't necessary, the parse method can be feeded
    # with a plain text string
    if ( my $cfg_file = $thisparser->{local}{file} ) {

        Config::Scoped::Error->throw(
            -text => Carp::shortmess("can't use filehandle as cfg file") )
          if ref $cfg_file;

        # retrieve the dir part, later on needed for relative include files
        my ( undef, $cfg_dir ) = fileparse($cfg_file)
          or Config::Scoped::Error->throw(
            -text => "error in fileparse",
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
          );

        $cfg_file = File::Spec->rel2abs($cfg_file)
          or Config::Scoped::Error->throw(
            -text => "error in rel2abs",
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
          );

        $thisparser->{local}{cfg_file} = $cfg_file;
        $thisparser->{local}{cfg_dir}  = $cfg_dir;
    }

    else {

        # no cfg_file defined, use _STRING and cwd
        $thisparser->{local}{cfg_file} = '_STRING';
        $thisparser->{local}{cfg_dir}  =
          File::Spec->rel2abs( File::Spec->curdir );
    }

    ##############################################
    # check for warnings
    #
    # set the default to all on
    $thisparser->{local}{warnings} = { all => 'on' }
      unless $thisparser->{local}{warnings};

    # allow the simple form: 'warnings' => 'on/off'
    if ( ref $thisparser->{local}{warnings} ne 'HASH' ) {
        $thisparser->{local}{warnings} = { all => 'on' }
          if $thisparser->{local}{warnings} =~ m/on/i;
        $thisparser->{local}{warnings} = { all => 'off' }
          if $thisparser->{local}{warnings} =~ m/off/i;
    }

    # store the warnings in a normalized form
    foreach my $name ( keys %{ $thisparser->{local}{warnings} } ) {
        my $switch = delete $thisparser->{local}{warnings}{$name};
        $thisparser->_set_warnings(
            name   => $name,
            switch => $switch,
        );
    }

    ##############################################
    # preset the state hashes
    #
    # use empty state_hashes if not defined
    foreach my $hash_name (@state_hashes) {
        $thisparser->{local}{$hash_name} ||= {};

        # be defensive
        Config::Scoped::Error->throw(
            -text => Carp::shortmess("$hash_name is no hash ref") )
          unless ref $thisparser->{local}{$hash_name} eq 'HASH';
    }

    # install/create Safe compartment for perl_code
    my $compartment = $thisparser->{local}{safe};
    if ( $thisparser->{local}{safe} ) {
        Config::Scoped::Error->throw(
            -text => Carp::shortmess("can't find method 'reval' on compartment")
          )
          unless UNIVERSAL::can( $thisparser->{local}{safe}, 'reval' );
    }
    else {
        $thisparser->{local}{safe} = Safe->new
          or Config::Scoped::Error->throw(
            -text => "can't create a Safe compartment!" );
    }

    return $thisparser;
}

sub parse {
    my $thisparser = shift;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("odd number of arguments,") )
      if @_ % 2;

    unless (defined $thisparser->{local}{compiled} ){
	$thisparser->Replace($grammar);
	$thisparser->{local}{compiled} = 1; 
    }

    my %args = @_;

    my $cfg_text = $args{text};

    unless ( defined $cfg_text ) {
        my $cfg_file = $thisparser->{local}{cfg_file}
          or Config::Scoped::Error->throw(
            -text => Carp::shortmess("no cfg_file defined"),
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
          );

        Config::Scoped::Error->throw( -text => "no text to parse defined" )
          if $cfg_file eq '_STRING';

        # slurp the cfg file
        $cfg_text = $thisparser->_get_cfg_text( %args, file => $cfg_file );

        Config::Scoped::Error->throw(
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
            -text => "'$cfg_file' is empty"
          )
          unless $cfg_text;

        # calculate the message digest and remember this cfg text in includes
        my $digest = md5_base64($cfg_text);

        Config::Scoped::Error->throw(
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
            -text => "include loop for '$cfg_file' encountered",
          )
          if $thisparser->{local}{includes}{$digest};

        $thisparser->{local}{includes}{$digest} = $cfg_file;
    }

    # call the P::RD with the startrule of the grammar
    $thisparser->config($cfg_text);

    ##############################################
    # no declarations but parameters in scope?
    #
    # copy them to an automatically generated _GLOBAL hash
    # first use some shortcuts
    my $params = $thisparser->{local}{params};
    my $config = $thisparser->{local}{config};

    # all $config keys other than _GLOBAL are real declarations
    my @declarations = grep !/^_GLOBAL$/, keys %$config;

    # no declarations but parameters in global scope
    if ( !@declarations && %$params ) {

        # the overall parent scope overrides scopes from include files
        $config->{_GLOBAL} = dclone $params;
    }
    else {

        # perhaps a prior parse for an include file filled this slot
        delete $config->{_GLOBAL};
    }

    return $thisparser->{local}{config};
}

sub warnings_on {
    my $thisparser = shift;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("odd number of arguments,") )
      if @_ % 2;

    my %args = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless defined $args{name};

    my $name     = $args{name};
    my $warnings = $thisparser->{local}{warnings};

    $name = $thisparser->_trim_warnings($name);

    return undef if exists $warnings->{$name} && $warnings->{$name} eq 'off';
    return 1     if exists $warnings->{$name} && $warnings->{$name} eq 'on';

    # use 'all'
    return undef if exists $warnings->{all} && $warnings->{all} eq 'off';
    return 1     if exists $warnings->{all} && $warnings->{all} eq 'on';

    # hmm, name and all not defined, defaults to on
    return 1;
}

sub set_warnings {
    my $thisparser = shift;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("odd number of arguments,") )
      if @_ % 2;

    my %args = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("no warnings switch (on/off) defined") )
      unless defined $args{switch};

    my $warnings = $thisparser->{local}{warnings};
    my $name     = $args{name} || 'all';
    my $switch   = $args{switch};

    $name = $thisparser->_trim_warnings($name);

    # trim the switch, convert to lowercase
    $switch = lc($switch);

    if ( $name eq 'all' ) {

        # reset the hash
        %{$warnings} = ();
        $warnings->{all} = $args{switch};
    }
    else {

        # override the key, key is 'macro', 'declaration', 'parameter', ...
        $warnings->{$name} = $args{switch};
    }

    return 1;
}

# just a wrapper for the same method without leading _
# this method is called in the grammar file whereas the set_warnings
# may be overriden by the application
sub _set_warnings {
    my $thisparser = shift;
    $thisparser->set_warnings(@_);
}

# shortcuts allowed, less spelling errors
sub _trim_warnings {
    my ( $thisparser, $name ) = @_;

    # trim the names
    return 'declaration' if $name =~ /^decl/i;
    return 'parameter'   if $name =~ /^param/i;
    return 'macro'       if $name =~ /^mac/i;
    return 'permissions' if $name =~ /^perm/i;
    return 'digests'     if $name =~ /^dig/i;
    return $name;
}

sub store_cache {
    my $thisparser = shift;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("odd number of arguments,") )
      if @_ % 2;

    my %args = @_;

    my $cache_file = $args{cache};

    unless ($cache_file) {
        my $cfg_file = $thisparser->{local}{cfg_file}
          or Config::Scoped::Error->throw(
            -text => Carp::shortmess("no cache_file and no cfg_file defined") );

        Config::Scoped::Error->throw( -text =>
              Carp::shortmess("parameter 'cache' needed for parsed strings") )
          if $cfg_file eq '_STRING';

        $cache_file = $cfg_file . '.dump';
    }

    my $cfg_hash = {
        includes => $thisparser->{local}{includes},
        config   => $thisparser->{local}{config},
    };

    my $result = eval { lock_nstore( $cfg_hash, $cache_file ); };

    Config::Scoped::Error->throw( -text => Carp::shortmess($@) ) if $@;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("can't store the cfg hash to '$cache_file'") )
      unless $result;
}

sub retrieve_cache {
    my $thisparser = shift;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("odd number of arguments,") )
      if @_ % 2;

    my %args = @_;

    my $cache_file = $args{cache};
    $args{parent_file} = $cache_file;    # for better error messages

    unless ($cache_file) {
        my $cfg_file = $thisparser->{local}{cfg_file}
          or Config::Scoped::Error->throw(
            -text => Carp::shortmess("no cache_file and no cfg_file defined") );

        Config::Scoped::Error->throw(
            -text => Carp::shortmess("cache not supported for strings") )
          if $cfg_file eq '_STRING';

        $cache_file = $cfg_file . '.dump';
    }

    Config::Scoped::Error::IO->throw(
        -text => Carp::shortmess("Can't read the cfg_cache '$cache_file'") )
      unless -r $cache_file;

    # check the permission and ownership, I know, it's no handle and of
    # restricted usage
    Config::Scoped::Error::Validate::Permissions->throw(
        -text => Carp::shortmess(
            "permissions_validate returned false for cache_file '$cache_file'")
      )
      unless $thisparser->permissions_validate( %args, file => $cache_file );

    my $cfg_cache = eval { lock_retrieve($cache_file); };

    Config::Scoped::Error->throw( -text => Carp::shortmess($@) ) if $@;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess( "cfg cache is empty", ) )
      unless $cfg_cache;

    # warnings for digests enabled?
    return $cfg_cache->{config}
      unless $thisparser->warnings_on( %args, name => 'digests', );

    # check the include digests for modification
    while ( my ( $digest, $file ) = each %{ $cfg_cache->{includes} } ) {

        my $text = $thisparser->_get_cfg_text( %args, file => $file, );

        if ( $digest ne md5_base64($text) ) {
            Config::Scoped::Error->throw(
                -text => Carp::shortmess(
                    "'$file' modified, can't use the cache '$cache_file',")
            );
        }
    }

    return $cfg_cache->{config};
}

# _include
#
# this method is called as an action in the INCLUDE grammar rule
# the current localized $thisparser->{local}... parameters are used and adjusted
# and a new P::RD parser with the same grammar is created and started
# for the include file.
# After that the parse in the parent cfg file is continued.

# We don't change the $text and don't resync the linecounter in P::RD, since
# this would result in awfully wrong line numbers in error messages and
# we would still have no hint in which include file the error happened.
#
# The current scope, macro and warnings hash is used during include file parsing
# so the include file can use (or overwrite) the current parse state.
#
# The changed state during the include file parse is propagated to the
# parent parser state (except warnings). If this import isn't intended
# put the include # in a own block: { %include filename; }
#

sub _include {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => Carp::shortmess("missing parameters"),
      )
      unless defined $args{file};

    my $include_file    = $args{file};
    my $parent_cfg_file = $thisparser->{local}{cfg_file};
    my $parent_cfg_dir  = $thisparser->{local}{cfg_dir};

    # absolute path? else concat with parent cfg dir
    unless ( File::Spec->file_name_is_absolute($include_file) ) {
        $include_file = File::Spec->catfile( $parent_cfg_dir, $include_file )
          or Config::Scoped::Error->throw(
            -file => $parent_cfg_file,
            -line => $thisparser->_get_line(%args),
            -text => "error in catfile for '$include_file'"
          );
    }

    # Create a new parser for this include file parsing.
    # Use the current parser states (perhaps already localized
    # in a grammar { action }), and change some args for the new
    # include parser creation.
    #
    my $clone_parser =
      ( ref $thisparser )
      ->new( %{ $thisparser->{local} }, file => $include_file )

      or Config::Scoped::Error->throw(
        -file => $parent_cfg_file,
        -line => $thisparser->_get_line(%args),
        -text => "Internal error: Can't create a clone parser"
      );

    # parse the include file (recursively) and return to the parent
    # cfg parse. Loop includes are detected (via md5) and throws an exception.
    return $clone_parser->parse(
        parent_file => $parent_cfg_file,    # for better error reporting
    );
}

# this method is called as an action in the MACRO rule in order
# to store the macro in the macros hash
sub _store_macro {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{name} && defined $args{value} );

    # macro validation, may be overwritten by the application
    my $valid_macro = $thisparser->macro_validate(%args);

    return $thisparser->{local}{macros}{ $args{name} } = $valid_macro;
}

sub macro_validate {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{name} && defined $args{value} );

    my $name  = $args{name};
    my $value = $args{value};

    # warnings for macros enabled?
    if ( $thisparser->warnings_on( name => 'macro', ) ) {
        Config::Scoped::Error::Validate::Macro->throw(
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
            -text => "macro redefinition for '$name"
          )
          if exists $thisparser->{local}{macros}{$name};
    }

    # return unchanged, subclass methods may do it different
    return $value;
}

# macro expansion
sub _expand_macro {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless defined $args{value};

    my $value = $args{value};

    while ( my ( $macro, $defn ) = each %{ $thisparser->{local}{macros} } ) {
        $value =~ s/\Q$macro\E/$defn/g;
    }

    # a P::RD rule can't return undef, then the rule will fail
    return defined $value ? $value : '';
}

# parameter storage, called as action from within the grammar
sub _store_parameter {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{value} && defined $args{name} );

    $args{name} = lc( $args{name} ) if $thisparser->{local}{lc};

    # parameter validation, may be overwritten by the application
    my $valid_value = $thisparser->parameter_validate(%args);

    # store the return value in the params hash
    return $thisparser->{local}{params}{ $args{name} } = $valid_value;
}

sub parameter_validate {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{value} && defined $args{name} );

    # warnings for parameters enabled?
    if ( $thisparser->warnings_on( name => 'parameter', ) ) {
        Config::Scoped::Error::Validate::Parameter->throw(
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
            -text => "parameter redefinition for '$args{name}'"
          )
          if exists $thisparser->{local}{params}{ $args{name} };
    }

    # return unchanged, subclass methods may do it different
    return $args{value};
}

# declaration storage, called as action from within the grammar
sub _store_declaration {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{name} && defined $args{value} );

    {
        local $_;
        map { $_ = lc($_) } @{ $args{name} }
          if $thisparser->{local}{lc};
    }

    # convert declaration: foo bar ... baz { parameters }
    # to the data structure
    # $config->{foo}{bar}...{baz} = { parameters };
    my $tail = $thisparser->{local}{config};

    # walking down the street ...
    foreach my $name ( @{ $args{name} } ) {
        $tail->{$name} = {} unless exists $tail->{$name};
        $tail = $tail->{$name};
    }

    # now we have baz = {}

    # application validation
    my $valid_value = $thisparser->declaration_validate( %args, tail => $tail );

    # store the current scope in the last $config->{foo}...{baz} = $params
    # use deep copy to break dependencies when config parameters
    # get's changed in the application in different declarations
    return %$tail = %{ dclone( $args{value} ) };
}

sub declaration_validate {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{name} && defined $args{value} );

    # warnings for declarations enabled and 'tail' already set?
    if ( $thisparser->warnings_on( name => 'declaration', ) ) {
        Config::Scoped::Error::Validate::Declaration->throw(
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
            -text => "declaration redefinition for '@{$args{name}}'"
          )
          if %{ $args{tail} };
    }

    # return unchanged, subclass methods may do it different
    return $args{value};
}

sub permissions_validate {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameters") )
      unless ( defined $args{handle} || defined $args{file} );

    my $warnings = $thisparser->{local}{warnings};

    # warnings for files enabled?
    return 1
      unless $thisparser->warnings_on(
        name     => 'permissions',
        warnings => $warnings,
      );

    my $fh = $args{handle} || $args{file};

    # mysteriously vaporized
    Config::Scoped::Error::IO->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => "'$args{file}' can't stat cfg file/handle: $!"
      )
      unless stat $fh;

    my ( $dev, $ino, $mode, $nlink, $uid, $gid ) = stat(_);

    # owner is not root and not real uid
    Config::Scoped::Error::Validate::Permissions->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => "'$args{file}' is unsafe: owner is not root and not real uid",
      )
      if $uid != 0 && $uid != $<;

    Config::Scoped::Error::Validate::Permissions->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => "'$args{file}' is unsafe: writeable by group or others",
      )
      if $mode & 022;

    return 1;
}

# handle quoted strings, expand macro's and interpolate backslash
# patterns like \t, \n, etc. Called as action from within the grammar.
sub _quotelike {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("missing parameter") )
      unless defined $args{value};

    my $value = $args{value};

    # accepts only '', "", <<foo, <<'foo', <<"foo" quotes and
    # not q, qq, qx, qw, ..., s///, tr/// etc.
    my %accept = ( single => 1, double => 1, '<<' => 1 );

    # see Text::Balanced::extract_quotelike() to understand this
    # and of course Parse::RecDescent <perl_quotelike> directive
    my $quote_name  = $value->[0];
    my $quote_delim = substr( $value->[1], 0, 1 );
    my $quote_text  = $value->[2];

    # the quote_name isn't set with plain quotes, set it now
    unless ($quote_name) {
        $quote_name = 'double' if $quote_delim eq '"';
        $quote_name = 'single' if $quote_delim eq "'";
    }

    # let the rule fail if not an accepted quote name
    return undef unless $accept{$quote_name};

    # backslash substitution in double quoted strings is
    # done by reval() in the Safe compartment since
    # it's possible to smuggle a subroutine call
    # in a double quoted string.
    #
    $quote_text = $thisparser->_perl_code( expr => "\"$quote_text\"" )
      unless $quote_name eq 'single' || $quote_delim eq "'";

    # macro expansion for double quoted constructs
    $quote_text = $thisparser->_expand_macro( %args, value => $quote_text )
      unless $quote_name eq 'single' || $quote_delim eq "'";

    # a P::RD rule can't return undef, then the rule would fail
    return defined $quote_text ? $quote_text : '';
}

# slurp in the cfg files
sub _get_cfg_text {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("no cfg_file defined") )
      unless defined $args{file};
    my $cfg_file = $args{file};

    local *CFG;

    # open the cfg file
    Config::Scoped::Error::IO->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => "Can't open cfg_file '$cfg_file': $!"
      )
      unless open( CFG, $cfg_file );

    # check the permission and ownership
    Config::Scoped::Error::Validate::Permissions->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => "permissions_validate returned false for cfg_file '$cfg_file'"
      )
      unless $thisparser->permissions_validate( %args, handle => \*CFG );

    # slurp the cfg_file, close the handle and return the text
    my $cfg_text = join '', <CFG>;

    Config::Scoped::Error::IO->throw(
        -file => $thisparser->_get_file(%args),
        -line => $thisparser->_get_line(%args),
        -text => "Can't close cfg_file '$cfg_file' : $!"
      )
      unless close CFG;

    return $cfg_text;
}

# eval perlcode in Safe compartment, called as action from within the grammar.
sub _perl_code {
    my $thisparser = shift;
    my %args       = @_;

    Config::Scoped::Error->throw(
        -text => Carp::shortmess("no expression to eval defined") )
      unless defined $args{expr};

    my $expr = $args{expr};

    # macro expansion before code evaluation
    $expr = $thisparser->_expand_macro( %args, value => $expr );

    my $compartment = $thisparser->{local}{safe};

    # eval in Safe compartment
    my $result = $compartment->reval($expr);

    # adjust error message and rethrow
    if ( !defined $result && $@ ) {
        chomp $@;
        $@ .= "\n... (re)blessed and propagated via perl_code{}";

        Config::Scoped::Error::Parse->throw(
            -file => $thisparser->_get_file(%args),
            -line => $thisparser->_get_line(%args),
            -text => $@,
        );
    }

    # a P::RD rule can't return undef, then the rule would fail
    return defined $result ? $result : '';
}

# used for well spotted error messages
sub _get_file {
    my $thisparser = shift;
    my %args       = @_;
    return $args{parent_file}
      || $args{file}
      || $thisparser->{local}{cfg_file}
      || '?';
}

# used for well spotted error messages
sub _get_line {
    my $thisparser = shift;
    my %args       = @_;
    return $args{line} || $thisparser->{local}{line} || 0;
}

1;

__DATA__

#######################################################################
# Grammar for Config::Scoped
#######################################################################
#
# Do you to understand this grammar?
# Be warned, dragons ahead, recursive brain damage possible!
#
# First, read the Config::Scoped manual to understand what's going on here!
#
# Second, read the Parse::RecDescent manual and learn it by heart to
# understand what's going on here!
#
# INHERITANCE!
# The real action is done via $thisparser->_method() calls
# to methods in the Config::Scoped package in order to keep the actions in
# this grammar file simple and maintainable.
#
# The logic is heavily based on localization via <rulevar's> in order to
# handle scopes properly.
#
# Call by value are always deep copies via Storable::dclone.
#
# Blocks, declarations and hashes start new scopes for parameters, macros
# and warnings.
#
# Include files are handled by a cloned Config::Scoped parser.
# Include files import parameters and macros to the current scope 
# but not the warnings. Warnings are scoped within the include files and don't
# leak to the parent file. If you don't wish the leakage of parameters and
# macros to the parent file, put the %inlcude pragma inside a block {}.
#
# Declarations collect the parameters and store them
# in the unscoped $config hashref. The declaration name(s) are the
# keys in the $config hashref. Declarations are never scoped,
# they always add to the global config. Declarations are just (named)
# collectors of the parameters.
#
# The principle is easy, isn't it?
#
#########################################################################
#
# START of GRAMMAR for Config::Scoped
#
#########################################################################
#
# STARTRULE
#

config :      config_item(s) eofile 
	    | {
		# Error handling:
		# fetch only the first error, this is the most important one
		my $parse_error = shift @{ $thisparser->{errors} };

		  # keep P::RD silent, see the P::RD FAQ
		  $thisparser->{errors} = undef;

		  # throw an exception
		  Config::Scoped::Error::Parse->throw(
		    -text => $parse_error->[0],
		    -line => $parse_error->[1],
		    -file => $thisparser->{local}{cfg_file}
		  );
	      } <reject>


# hack, could be done without this intermediate rule, but
# the error messages are more readable with this hack.
#
# commit hack: with a <commit> we get better error messages
config_item :   <commit> statement
	       | <error?> <reject>

#########################################################################
# STATEMENT'S
#########################################################################
#
# use $break to shortcut the alternate productions after a rejected commit
# in a subrule.
#
# This is a hack since P::RD is missing a <committed?: action> directive.
# I do this programmatically with a localized <rulevar> and { ++$break }
#
statement :   <rulevar: local $break>
statement :    <reject: $break> parameter
	     | <reject: $break> block
	     | <reject: $break> declaration
	     | <reject: $break> pragma
	     | <reject: $break> comment

#########################################################################
# BLOCK'S: { statement(s) }
#########################################################################
#
# Open a new scope, inherit (deep copy) the scoped hashes.
#

block : <rulevar: local $thisparser->{local}{params} =
	      Storable::dclone $thisparser->{local}{params}>

block :	<rulevar: local $thisparser->{local}{macros} =
	      Storable::dclone $thisparser->{local}{macros}>

block : <rulevar: local $thisparser->{local}{warnings} =
	      Storable::dclone $thisparser->{local}{warnings}>

block : '{' <commit> { ++$break } statement(s) '}' stop_pattern
       | <error?> <reject>

#########################################################################
# DECLARATIONS
#########################################################################
#
# Open a new scope, inherit (deep copy) the scoped hashes.
#

declaration : <rulevar:	local $thisparser->{local}{params} =
		  Storable::dclone $thisparser->{local}{params}>

declaration : <rulevar:	local $thisparser->{local}{macros} =
		  Storable::dclone $thisparser->{local}{macros}>

declaration : <rulevar:	local $thisparser->{local}{warnings} =
		  Storable::dclone $thisparser->{local}{warnings}>

declaration : key(s) '{' <commit> { ++$break } decl_item(s?) '}' stop_pattern
		{
		    $thisparser->{local}{line} = $thisline;
		    $thisparser->_store_declaration(
			name  => $item{'key(s)'},
			value => $thisparser->{local}{params},
		    );

		    # rule success, errors in the method don't raise syntax errors
		    1;
		}
	      | <error?> <reject>

decl_item : ...!'}' <commit> parameter_or_macro_or_comment_or_warning
	    | <error?> <reject>

#########################################################################
# HASH
#########################################################################
#
# Open a new scope, inherit (deep copy) the localized hashes
# for macros and warnings.
# Reset the params hash!
#

hash : <rulevar: local $thisparser->{local}{params} = {}>

hash : <rulevar: local $thisparser->{local}{macros} =
	      Storable::dclone $thisparser->{local}{macros}>

hash : <rulevar: local $thisparser->{local}{warnings} =
	      Storable::dclone $thisparser->{local}{warnings}>

hash : '{' <commit> { ++$break } hash_item(s?) '}'
	    {
		# returns just the filled parameter hash as value
		$return = $thisparser->{local}{params};
	    }
      | <error?> <reject>

hash_item : ...!'}' <commit> parameter_or_macro_or_comment_or_warning m/,?/
	  | <error?> <reject>

#########################################################################
# LIST
#########################################################################
#
# lists start no scope, they are just a special kind of parameters
#
list : <rulevar: local @list>
list : '[' <commit> { ++$break } list_item(s?) ']'
	    {
		# returns just the filled list as value
		$return = \@list;
	    }
	| <error?> <reject>

list_item :  ...!']' <commit> hash_or_list_or_value_or_comment m/,?/
	  | <error?> <reject>

#########################################################################
# PARAMETER'S
#########################################################################
#
parameter : key /=>?/ <commit> { ++$break } hash_or_list_or_value stop_pattern
	    {
		$thisparser->{local}{line}  = $thisline;
		# store the parameter in the local scope
		$thisparser->_store_parameter(
		    name  => $item{key},
		    value => $item{hash_or_list_or_value},
		);

		# rule success, errors in the method don't raise syntax errors
		1;
	    }
	 | <error?> <reject>

#########################################################################
# intermediate compounds
#########################################################################
#
# use $break to shortcut the alternations after a rejected commit
parameter_or_macro_or_comment_or_warning : <rulevar: local $break>
parameter_or_macro_or_comment_or_warning :  <reject: $break> parameter
					 |  <reject: $break> macro
				         |  <reject: $break> warning
				         |  <reject: $break> comment

# use $break to shortcut the alternations after a rejected commit
hash_or_list_or_value_or_comment : <rulevar: local $break>
hash_or_list_or_value_or_comment :  <reject: $break> hash_or_list_or_value
				{
				    # fill the list, but not with comments!
				    push @list, $item{hash_or_list_or_value}
				}
			     |  <reject: $break> comment

# use $break to shortcut the alternations after a rejected commit
hash_or_list_or_value :  <rulevar: local $break>
hash_or_list_or_value :   <reject: $break> hash
			| <reject: $break> list
			| <reject: $break> value

#########################################################################
# PRAGMA's
#########################################################################
#
pragma : macro | include | warning

macro : '%macro' <commit> { ++$break } key value stop_pattern
	    {
		$thisparser->{local}{line} = $thisline;
		$thisparser->_store_macro(
		    name  => $item{key},
		    value => $item{value},
		);

		# rule success, errors in the method don't raise syntax errors
		1;
	    }

	| <error?> <reject>

# call recursively a new P::RD parser for this include file
# call by value for the current $warnings
include : <rulevar: local $thisparser->{local}{warnings} =
		  Storable::dclone $thisparser->{local}{warnings}>

include : '%include' <commit> { ++$break } value stop_pattern
	    {
		$thisparser->{local}{line}  = $thisline;
		$thisparser->_include( file => $item{value}, );

		# rule success, errors in the method don't raise syntax errors
		1;
	    }
	  | <error?> <reject>

warning : warning_short | warning_long

warning_short : /%warnings?/i on_off <commit> { ++$break } stop_pattern
	{
	    $thisparser->{local}{line} = $thisline;
	    $thisparser->_set_warnings( switch => $item{on_off} );

	    # rule success, errors in the method don't raise syntax errors
	    1;
	}
	| <error?> <reject>

warning_long :
    /%warnings?/i ...!on_off key <commit> { ++$break } on_off stop_pattern
    {
	$thisparser->{local}{line} = $thisline;
        $thisparser->_set_warnings(
            name   => $item{key},
            switch => $item{on_off},
        );

        # rule success, errors in the method don't raise syntax errors
        1;
    }
    | <error?> <reject>

on_off : /on|off/i

#########################################################################
# KEY and VALUE'S
#########################################################################
#
key   : perl_code | token | perl_quote
value : perl_code | token | perl_quote

# everything unless separator characters, better than \w in unicode times
token : /[^ \s >< }{ )( [\] ; , ' " = # % ]+/x

perl_quote : .../"|'|<</ <perl_quotelike>
    {
	$thisparser->{local}{line} = $thisline;
        $return = $thisparser->_quotelike( value => $item{__DIRECTIVE1__} );
    }

perl_code : /perl_code|eval/i <perl_codeblock>
    {
	$thisparser->{local}{line} = $thisline;
        $return = $thisparser->_perl_code( expr => $item{__DIRECTIVE1__}, );
    }

#########################################################################
# helpers
#########################################################################
#
# The skip reset is necessary, since the default eats the newlines.
# stop_pattern is:
# a newline, a semicolon, a comma or a look-ahead for '}', ']', '\s'
#
stop_pattern : <skip: qr//> m/\s* (\n | ; | , | \z | (?=[ \} \] \s ]) )/x

eofile : /\z/

comment : m/#.*\n/

#########################################################################
#
# END of GRAMMAR, without headache?
#
#########################################################################

