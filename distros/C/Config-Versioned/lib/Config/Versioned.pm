## Config::Versioned
##
## Written 2011-2012 by Scott T. Hardin for the OpenXPKI project
## Copyright (C) 2010-2012 by The OpenXPKI Project
##
## Was based on the CPAN module App::Options, but the import() stuff
## bit me so we're turning into a Moose.
##
## vim: syntax=perl

package Config::Versioned;

use Moose;
use namespace::autoclean;

=head1 NAME

Config::Versioned - Simple, versioned access to configuration data

=cut

our $VERSION = '1.01';

use Carp;
use Config::Std;
use Data::Dumper;
use DateTime;
use Git::PurePerl;
use Path::Class;

has 'path' => ( is => 'ro', isa => 'ArrayRef', default => sub { [qw( . )] } );
has 'filename' => ( is => 'ro', isa => 'Str' );
has 'dbpath' =>
  ( is => 'ro', default => 'cfgver.git', required => 1 );
has 'author_name' => ( is => 'ro', isa => 'Str', default => "process: $@" );
has 'author_mail' => (
    is      => 'ro',
    isa     => 'Str',
    default => $ENV{GIT_AUTHOR_EMAIL} || $ENV{USER} . '@localhost'
);
has 'autocreate' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'commit_time' => ( is => 'ro', isa => 'DateTime' );
has 'comment'     => ( is => 'rw', isa => 'Str' );
has 'delimiter'   => ( is => 'ro', isa => 'Str', default => '.' );
has 'delimiter_regex' =>
  ( is => 'ro', isa => 'RegexpRef', default => sub { qr{ \. }xms } );
has 'log_get_callback' => ( is => 'ro' );
has '_git'             => ( is => 'rw'  );
has 'debug'            => ( is => 'rw', isa => 'Int', default => 0 );

# a reference to the singleton Config::Versioned object that parsed the command line
#my ($default_option_processor);

#my (%path_is_secure);

=head1 SYNOPSIS

    use Config::Versioned;

    my $cfg = Config::Versioned->new();
    my $param1 = $cfg->get('subsystem1.group.param1');
    my $old1 = $cfg->get('subsystem1.group.param1', $version);
    my @keys = $cfg->list('subsys1.db');


=head1 DESCRIPTION

Config::Versioned allows an application to access configuration parameters
not only by parameter name, but also by version number. This allows for
the configuration subsystem to store previous versions of the configuration
parameters. When requesting the value for a specific attribute, the programmer
specifies whether to fetch the most recent value or a previous value.

This is useful for long-running tasks such as in a workflow-based application
where task-specific values (e.g.: profiles) are static over the life of a
workflow, while global values (e.g.: name of an LDAP server to be queried)
should always be the most recent.

Config::Versioned handles the versions by storing the configuration data
in an internal Git repository. Each import of configuration files into
the repository is documented with a commit. When a value is fetched, it is
this commit that is referenced directly when specifying the version.

The access to the individual attributes is via a named-parameter scheme, where 
the key is a dot-separated string.

Currently, C<Config::Std> is used for the import of the data files into the 
internal Git repository. Support for other configuration modules (e.g.:
C<Config::Any>) is planned.

=head1 METHODS

=head2 init()

This is invoked automatically via import(). It is called when running the
following code:

 use Config::Versioned;

The init() method reads the configuration data from the configuration files
and populates an internal data structure.

Optionally, parameters may be passed to init(). The following
named-parameters are supported:

=over 8

=item path

Specifies an anonymous array contianing the names of the directories to
check for the configuration files.

 path => qw( /etc/yourapp/etc /etc/yourapp/local/etc . ),

The default path is just the current directory.

=item filename

Specifies the name of the configuration file to be found in the given path.

 filename => qw( yourapp.conf ),

If no filename is given, no new configuration data will be imported and
the internal git repository will be used.

=item dbpath

The directory for the internal git repository that stores the config.

 dbpath => qw( config.git ),

The default is "cfgver.git".

=item author_name, author_mail

The name and e-mail address to use in the internal git repository for
commits.

=item autocreate

If no internal git repository exists, it will be created during code
initialization. Note that if an import filename is specified, this 
automatically sets autocreate to true.

 autocreate => 1,

The default is "0".

Note: this option might become deprecated. I just wanted some extra
"insurance" during the early stages of development. 

=item commit_time

This sets the time to use for the commits in the internal git repository.
It is used for debugging purposes only!

Note: this must be a DateTime object instance.

=item delimiter

Specifies the delimiter used to separate the different levels in the
string used to designate the location of a configuration parameter. [Default: '.']

=item delimiter_regex

Specifies the delimiter used to separate the different levels in the
string used to designate the location of a configuration parameter.
[Default: qr/ \. /xms]

=item log_get_callback

Specifies a callback function to be called by get() after fetching
the value for the given key. The subroutine should accept the
parameters LOCATION, VERSION, VALUE. The VALUE may either be a single
scalar value or an array reference containing a list of values.

    sub cb_log_get {
        my $self = shift;
        my $loc = shift;
        my $ver = shift;
        my $val = shift;

        warn "Access config parameter: $loc ($ver) => ",
            ref($val) eq 'ARRAY'
                ? join(', ', @{ $val })
                : $val,
            "\n";
    }
    my $cfg = Config::Versioned->new( { log_get_callback => 'cb_log_get' } );

Note: if log_get_callback is a code ref, it will be called as a function.
Otherwise, the log_get_callback will specify a method name that is to be
called on the current object instance.

=back

=head2 BUILD( { PARAMS } )

NOTE: This is used internally, so the typical user shouldn't bother with this.

This is called after an object is created. When cloning, it is important that
the new instance gets a reference to the same Git::PurePerl instance. This
will prevent two instances from getting out of sync if modifications are made
to the configuration data at runtime. To handle this, the parameter 'GITREF'
must be passed when cloning.

Note 2: this should be handled automatically in the _near_ future.

    my $cv2 = $cv1->new( GITREF => $cv1->_git() );

=cut

sub BUILD {
    my $self = shift;
    my $args = shift;

    if ( defined $ENV{CONFIG_VERSIONED_DEBUG} ) {
        $self->debug( $ENV{CONFIG_VERSIONED_DEBUG} );
    }

    if ( not $self->_init_repo() ) {
        return;
    }
#    if ( not $self->_git() ) {
#        if ( $args->{GITREF} ) {
#            $self->_git( $args->{GITREF} );
#        }
#        else {
#            if ( not $self->_init_repo() ) {
#                return;
#            }
#        }
#    }
#
#    $self->parser($args);

    return ($self);
}

=head2 get( LOCATION [, VERSION ] )

This is the accessor for fetching the value(s) of the given parameter. The
value may either be zero or more elements.

In list context, the values are returned. In scalar context, C<undef> is 
returned if the variable is empty. Otherwise, the first element is returned.

Optionally, a VERSION may be specified to return the value for that
specific version.

=cut

sub get {
    my $self     = shift;
    my $location = shift;
    my $version  = shift;
    my $cb       = $self->log_get_callback();
    my ( $obj, $deobj ) = $self->_findobjx( $location, $version );

    if ( not defined $obj ) {
        $self->$cb( $location, $version, '<undefined>' ) if $cb;
        return;
    }

    if ( $obj->kind eq 'blob' ) {
        $self->$cb( $location, $version, $obj->content ) if $cb;
        if ( $deobj->mode() == 120000 ) {
            my $tmp = $obj->content;
            return \$tmp;
        }
        else {
            return $obj->content;
        }
    }
    elsif ( $obj->kind eq 'tree' ) {
        my @entries = $obj->directory_entries;
        my @ret     = ();
        foreach my $de (@entries) {
            push @ret, $de->filename;
        }
        my @sorted =
          sort { ( $a =~ /^\d+$/ and $b =~ /^\d+$/ ) ? $a <=> $b : $a cmp $b }
          @ret;
        $self->$cb( $location, $version, \@sorted ) if $cb;
        return @sorted;
    }
    else {
        $self->$cb( $location, $version,
            "<error: non-blob object '" . $obj->kind . "' not supported>" )
          if $cb;
        warn "# DEBUG: get() was asked to return a non-blob object [kind=",
          $obj->kind, "]\n" if $self->debug();
        return;
    }
}

=head2 kind ( LOCATION [, VERSION ] )

The get() method tries to return a scalar when the location corresponds
to a single value and a list when the location has child nodes. Sometimes,
however, it is helpful to have a definitive answer on what a location 
contains. 

The kind() method returns the object type that the given location accesses.
This can be one of the following values:

=over

=item tree

The given location contains a tree object containing zero or more child 
objects. The get() method will return a list of the entry names.

=item blob

The data node that usually contains a scalar value, but in future implementations
may contain other encoded data.

=back

B<Note:> As a side-effect, this can be used to test whether the given location
exists at all in the configuration. If not found, C<undef> is returned.

=cut

sub kind {
    my $self     = shift;
    my $location = shift;
    my $version  = shift;

    my $obj = $self->_findobj( $location, $version );

    if ( not defined $obj ) {
        return;    # if nothing found, just return undef
    }

    if ( $obj->kind eq 'blob' ) {
        return 'blob';
    }
    elsif ( $obj->kind eq 'tree' ) {
        return 'tree';
    }
    else {
        $@ = "Internal object error (expected tree or blob): [gpp kind="
          . $obj->kind . "]\n";
        warn "# DEBUG: " . $@ if $self->debug();
        return;
    }

}

=head2 listattr( LOCATION [, VERSION ] )

This fetches a list of the parameters available for a given location in the 
configuration tree.

=cut

sub listattr {
    my $self     = shift;
    my $location = shift;
    my $version  = shift;

    my $obj = $self->_findobj( $location, $version );
    if ( $obj and $obj->kind eq 'tree' ) {
        my @entries = $obj->directory_entries;
        my @ret     = ();
        foreach my $de (@entries) {
            push @ret, $de->filename;
        }
        return @ret;
    }
    else {
        $@ = "obj at $location not found";
        return;
    }
}

=head2 dumptree( [ VERSION ] )

This fetches the entire tree for the given version (default: newest version)
and returns a hashref to a named-parameter list.

=cut

sub dumptree {
    my $self    = shift;
    my $version = shift;
    my $cfg     = $self->_git();

    # If no version hash was given, default to the HEAD of master

    if ( not $version ) {
        my $master = $self->_git()->ref('refs/heads/master');
        if ( $master ) {
            $version = $master->sha1;
        } else {
            # if no sha1s are in repo, there's nothing to return
            return;
        }
    }

    my $obj = $cfg->get_object($version);
    if ( not $obj ) {
        $@ = "No object found for SHA1 " . $version ? $version : '';
        return;
    }

    if ( $obj->kind eq 'commit' ) {
        $obj = $obj->tree;
    }

    my $ret = {};

    my @directory_entries = $obj->directory_entries;

    foreach my $de (@directory_entries) {
        my $child = $cfg->get_object( $de->sha1 );

        #        warn "DEBUG: dump - child name = ", $de->filename, "\n";
        #        warn "DEBUG: dump - child kind = ", $child->kind, "\n";

        if ( $child->kind eq 'tree' ) {
            my $subret = $self->dumptree( $de->sha1 );
            foreach my $key ( keys %{$subret} ) {
                $ret->{ $de->filename . $self->delimiter() . $key } =
                  $subret->{$key};
            }
        }
        elsif ( $child->kind eq 'blob' ) {
            $ret->{ $de->filename } = $child->content;
        }
        else {
            die "ERROR: unexpected kind: ", $child->kind, "\n";
        }

    }
    return $ret;
}

=head2 version

This returns the current version of the configuration database, which
happens to be the SHA1 hash of the HEAD of the internal git repository.

Optionally, a version hash may be passed and version() will return a true
value if it is found.

=cut

sub version {
    my $self    = shift;
    my $version = shift;
    my $cfg     = $self->_git();

    if ($version) {
        my $obj = $cfg->get_object($version);
        if ( $obj and $obj->sha1 eq $version ) {
            return $version;
        }
        else {
            return;
        }
    }
    else {
        my $head = $cfg->head;
        return $head->sha1;
    }
}

=head1 INTERNALS

=head2 _init_repo

Initializes the internal git repository used for storing the config
values. 

If the I<objects> directory in the C<dbpath> does not exist, an
C<init()> on the C<Git::PurePerl> class is run. Otherwise, the 
instance is initialized using the existing bare repository.

On error, it returns C<undef> and the reason is in C<$@>.

=cut

sub _init_repo {
    my $self = shift;

    my $git;

    #    if ( not $init_args->{dbpath} ) {
    #        die "ERROR: dbpath not set";
    #    }

    if ( not -d $self->dbpath() . '/objects' ) {
        if ( $self->filename() || $self->autocreate() ) {
            if ( not -d $self->dbpath() ) {
                if ( not dir( $self->dbpath() )->mkpath ) {
                    die 'Error creating directory ' . $self->dbpath() . ': ' . $!;
                }
            }
            $git = Git::PurePerl->init( gitdir => $self->dbpath() );
        } else {
            die 'Error: dbpath (' . $self->dbpath() . ') does not exist';
        }
    }
    else {
        $git = Git::PurePerl->new( gitdir => $self->dbpath() );
    }
    $self->_git($git);
    $self->parser();
    return $self;
}

=head2 _get_anon_scalar

Creates an anonymous scalar for representing symlinks in the tree structure.

=cut

sub _get_anon_scalar {
    my $temp = shift;
    return \$temp;
}

=head2 parser ARGS

Imports the configuration read and writes it to the internal database. If no
filename is passed as an argument, then it will quietly skip the commit.

Note: if you override this method in a child class, it must create an
anonymous hash tree and pass the reference to the commit() method. Here
is a simple example:

    sub parser {
        my $self = shift;
        my $args = shift;
        $args->{comment} = 'import from my perl hash';
        
        my $cfg = {
            group1 => {
                subgroup1 => {
                    param1 => 'val1',
                    param2 => 'val2',
                },
            },
            group2 => {
                subgroup1 => {
                    param3 => 'val3',
                    param4 => 'val4',
                },
            },
            # This creates a symlink from 'group3.subgroup3' to 'connector1/group4'.
            # Note the use of the scalar reference using the backslash.
            group3 => {
                subgroup3 => \'connector1/group4',
            },

        };
        
        # pass original args, appended with a comment string for the commit
        $self->commit( $cfg, $args );
    }

In the comment, you should include details on where the config came from
(i.e.: the filename or directory).

=cut

sub parser {
    my $self = shift;
    my $args = shift;

    foreach
      my $key (qw( comment filename path author_name author_mail commit_time ))
    {
        if ( not exists $args->{$key} ) {
            $args->{$key} = $self->$key();
        }
    }

    # If no filename was specified, then there is no import of
    # configuration files needed. Quietly exit method.

    if ( not $args->{filename} ) {
        return $self;
    }

    # Read the configuration from the import files

    my %cfg = ();
    $self->_read_config_path( $args->{filename}, \%cfg, @{ $args->{path} } );

    $args->{comment} ||= "Import config from "
      . $self->_which( $args->{filename}, @{ $args->{path} } );

    # convert the foreign data structure to a simple hash tree,
    # where the value is either a scalar or a hash reference.

    my $tmphash = {};
    foreach my $sect ( keys %cfg ) {

        # build up the underlying branch for these leaves

        my @sectpath = split( $self->delimiter_regex(), $sect );
        my $sectref = $tmphash;
        foreach my $nodename (@sectpath) {
            $sectref->{$nodename} ||= {};
            $sectref = $sectref->{$nodename};
        }

        # now add the leaves

        foreach my $leaf ( keys %{ $cfg{$sect} } ) {

            # If the leaf start or ends with an '@', treat it as
            # a symbolic link.
            if ( $leaf =~
                m{ (?: \A @ (.*?) @ \z | \A @ (.*) | (.*?) @ \z ) }xms )
            {
                my $match = $1 || $2 || $3;

                # make it a ref to an anonymous scalar so we know it's a symlink
                #my $t = _get_anon_scalar($1);
                $sectref->{$match} = \( $cfg{$sect}{$leaf} );
            }
            else {
                $sectref->{$leaf} = $cfg{$sect}{$leaf};
            }
        }

    }

    $self->commit( $tmphash, $args );
}

=head2 commit CFGHASH[, ARGS]

Import the configuration tree in the CFGHASH anonymous hash and commit
the modifications to the internal git bare repository.

ARGS is a ref to a named-parameter list (e.g. HASH) that may contain the
following keys to override the instance defaults:

    author_name, author_mail, comment, commit_time

=cut

sub commit {
    my $self = shift;
    my $hash = shift;
    my $args = shift;

    if ( ref($hash) ne 'HASH' ) {
        confess "ERR: commit() - arg not hash ref [$hash]";
    }

    my $parent = undef;
    my $master = undef;

    $master = $self->_git()->ref('refs/heads/master');
    if ( $master ) {
        $parent = $master->sha1;
    }

    #    warn "# author_name: ", $self->author_name(), "\n";
    my $tree = $self->_hash2tree($hash);

    if ( $self->debug() ) {
        print join( "\n# ", '', $self->_debugtree($tree) ), "\n";
    }

    #
    # Now that we have a "staging" tree, compare its hash with
    # that of the current top-level tree. If they are the same,
    # there were no changes made to the config and we should
    # not create a commit object
    #

    if ( $parent and $master->tree->sha1 eq $tree->sha1 ) {
        if ( $self->debug() ) {
            carp("Nothing to commit (index matches HEAD)");
        }
        return $self;
    }

    #
    # Prepare and execute the commit
    #

    my $actor = Git::PurePerl::Actor->new(
        name  => $args->{author_name} || $self->author_name,
        email => $args->{author_mail} || $self->author_mail,
    );

    my $time = $args->{commit_time} || $self->commit_time || DateTime->now;

    my @commit_attrs = (
        tree           => $tree->sha1,
        author         => $actor,
        authored_time  => $time,
        committer      => $actor,
        committed_time => $time,
        comment        => $args->{comment} || $self->comment(),
    );
    if ($parent) {
        push @commit_attrs, parent => $parent;
    }

    my $commit = Git::PurePerl::NewObject::Commit->new(@commit_attrs);
    $self->_git()->put_object($commit);

}

sub _hash2tree {
    my $self = shift;
    my $hash = shift;

    if ( ref($hash) ne 'HASH' ) {
        confess "ERR: _hash2tree() - arg not hash ref [$hash]";
    }
    if ( $self->debug() ) {
        warn "Entered _hash2tree( $hash ): ", join( ', ', %{$hash} ), "\n";
    }

    my @dir_entries = ();

    foreach my $key ( keys %{$hash} ) {
        if ( $self->debug() ) {
            warn "# _hash2tree() processing $key -> ", $hash->{$key}, "\n";
        }
        if ( ref( $hash->{$key} ) eq 'HASH' ) {
            if ( $self->debug() ) {
                warn "# _hash2tree() adding subtree for $key\n";
            }
            my $subtree = $self->_hash2tree( $hash->{$key} );
             
            next unless($subtree);

            my $local_key = $key;
            if ( $] > 5.007 && utf8::is_utf8($local_key) ) {
                utf8::downgrade($local_key);
            }

            my $de      = Git::PurePerl::NewDirectoryEntry->new(
                mode     => '40000',
                filename => $local_key,
                sha1     => $subtree->sha1(),
            );
            push @dir_entries, $de;
        }
        elsif ( ref( $hash->{$key} ) eq 'SCALAR' ) {

            # Support for symbolic links
            if ( $self->debug() ) {
                warn "# _hash2tree() adding symlink for $key\n";
            }
            my $obj =
              Git::PurePerl::NewObject::Blob->new(
                content => ${ $hash->{$key} } );
            $self->_git()->put_object($obj);
            my $local_key = $key;
            if ( $] > 5.007 && utf8::is_utf8($local_key) ) {
                utf8::downgrade($local_key);
            }
            my $de = Git::PurePerl::NewDirectoryEntry->new(
                mode     => '120000',     # symlink
                filename => $local_key,
                sha1     => $obj->sha1(),
            );
            push @dir_entries, $de;
        }
        elsif ( defined $hash->{$key} ) {
            my $obj =
              Git::PurePerl::NewObject::Blob->new( content => $hash->{$key} );

            my $local_key = $key;
            if ( $] > 5.007 && utf8::is_utf8($local_key) ) {
                utf8::downgrade($local_key);
            }

            warn "# created blob for '$key' with sha " . $obj->sha1() if $self->debug();
            warn "#      '$key' utf8 flag: ", utf8::is_utf8($key) if $self->debug();
            $self->_git()->put_object($obj);
            my $de = Git::PurePerl::NewDirectoryEntry->new(
                mode     => '100644',     # plain file
                filename => $local_key,
                sha1     => $obj->sha1(),
            );
            push @dir_entries, $de;
        } else {
            warn "#  _hash2tree() value is undef for key $key\n" if $self->debug();            
        }
    }

    if (!scalar @dir_entries) {
        warn "# _hash2tree() nothing to push\n" if $self->debug();;        
        return undef;
    }

    my $tree =
      Git::PurePerl::NewObject::Tree->new( directory_entries =>
          [ sort { $a->filename cmp $b->filename } @dir_entries ] );

    if ( $self->debug() ) {
        my $content = $tree->content;
        $content =~ s/(.)/sprintf("%x",ord($1))/eg;
        warn "# Added tree with dir entries: ",
          join( ', ', map { $_->filename } @dir_entries ), "\n";
        warn "#     content: ", $content, "\n";
        warn "#     size: ", $tree->size, "\n";
        warn "#     kind: ", $tree->kind, "\n";
        warn "#     sha1: ", $tree->sha1, "\n";

    }

    $self->_git()->put_object($tree);

    return $tree;
}

=head2 _mknode LOCATION

Creates a node at the given LOCATION, creating parent nodes if necessary.

A reference to the node at the LOCATION is returned.

=cut

sub _mknode {
    my $self     = shift;
    my $location = shift;
    my $ref      = $self->_git();
    foreach my $key ( split( $self->delimiter_regex(), $location ) ) {
        if ( not exists $ref->{$key} ) {
            $ref->{$key} = {};
        }
        elsif ( ref( $ref->{$key} ) ne 'HASH' ) {

            # TODO: fix this ugly error to something more appropriate
            die "Location at $key in $location already assigned to non-HASH";
        }
        $ref = $ref->{$key};
    }
    return $ref;
}

=head2 _findobjx LOCATION [, VERSION ]

Returns the Git::PurePerl and Git::PurePerl::DirectoryEntry objects found in
the file path at LOCATION.

    my ($ref1, $de1) = $cfg->_findnode("smartcard.ldap.uri");
    my $ref2, $de2) = $cfg->_findnode("certs.signature.duration", $wfcfgver);

In most cases, the C<_findobj> version is sufficient. This extended version
is used to look at the attribtes of the directory entry for things like whether
the blob is a symlink.

=cut

sub _findobjx {
    my $self     = shift;
    my $location = shift;
    my $ver      = shift;
    my $cfg      = $self->_git();
    my ( $obj, $deobj );

    # If no version hash was given, default to the HEAD of master

    if ( not $ver ) {
        my $master = $self->_git()->ref('refs/heads/master');
        if ( $master ) {
            $ver = $master->sha1;
        } else {
            # if no sha1s are in repo, there's nothing to return
            return;
        }

    }

    # TODO: is this the way we want to handle the error of not finding
    # the given object?

    $obj = $cfg->get_object($ver);
    if ( not $obj ) {
        $@ = "No object found for SHA1 $ver";
        return;
    }

    if ( $obj->kind eq 'commit' ) {
        $obj = $obj->tree;
    }
    my @keys = split $self->delimiter_regex(), $location;

    # iterate thru the levels in the location

    while (@keys) {
        my $key = shift @keys;

        # if the object is a blob, we already reached the leaf
        if ($obj->kind eq 'blob') {
            return undef;
        }

        # $obj should contain the parent tree object.

        my @directory_entries = $obj->directory_entries;

        # find the corresponding child object

        my $found = 0;
        foreach my $de (@directory_entries) {
            if ( $de->filename eq $key ) {
                $found++;
                $obj   = $cfg->get_object( $de->sha1 );
                $deobj = $de;
                last;
            }
        }

        if ( not $found ) {
            return;
        }
    }
    return $obj, $deobj;

}

=head2 _findobj LOCATION [, VERSION ]

Returns the Git::PurePerl object found in the file path at LOCATION.

    my $ref1 = $cfg->_findnode("smartcard.ldap.uri");
    my $ref2 = $cfg->_findnode("certs.signature.duration", $wfcfgver);

=cut

sub _findobj {
    my $self = shift;
    my ( $obj, $deobj ) = $self->_findobjx(@_);
    if ( defined $obj ) {
        return $obj;
    }
    else {
        return;
    }
}

=head2 _get_sect_key LOCATION

Returns the section and key needed by Config::Std to access the
configuration values. The given LOCATION is split on the last delimiter. 
The resulting section and key are returned as a list.

=cut

sub _get_sect_key {
    my $self = shift;
    my $key  = shift;

    # Config::Std uses section/key, so we need to split up the
    # given key

    my @tokens = split( $self->delimiter_regex(), $key );
    $key = pop @tokens;
    my $sect = join( $self->delimiter(), @tokens );

    return $sect, $key;
}

=head2 _which( NAME, DIR ... )

Searches the directory list DIR, returning the full path in which the file NAME was
found.

=cut

sub _which {
    my $self = shift;
    my $name = shift;
    my @dirs = @_;

    foreach (@dirs) {
        my $path = $_ . '/' . $name;
        if ( -f $path ) {
            return $path;
        }
    }
    return;
}

=head2 _read_config_path SELF, FILENAME, CFGREF, PATH

Searches for FILENAME in the given directories in PATH. When found,
the file is parsed and a data structure is written to the location
in CFGREF.

Note: this is the wrapper around the underlying libs that read the
configuration data from the files.

=cut

sub _read_config_path {
    my $self    = shift;
    my $cfgname = shift;
    my $cfgref  = shift;

    my $cfgfile = $self->_which( $cfgname, @_ );
    if ( not $cfgfile ) {
        die "ERROR: couldn't find $cfgname in ", join( ', ', @_ );
    }

    read_config( $cfgfile => %{$cfgref} );
}

=head2 _debugtree( OBJREF | SHA1 )

This fetches the entire tree for the given SHA1 and dumps it in a
human-readable format.

=cut

sub _debugtree {
    my $self   = shift;
    my $start  = shift;
    my $indent = shift || 0;
    my $cfg    = $self->_git();
    my @out    = ();

    my $tabsize = 2;
    my $obj;

    # Soooo, let's see what we've been fed...
    if ( not $start ) {    # default to the HEAD of master
        my $master = $cfg->ref('refs/heads/master');
        if ( $master ) {
            $obj = $cfg->get_object( $master->sha1 );
        }
        else {
            push @out, "NO SHA1s IN TREE";
            return @out;    # if no sha1s are in repo, there's nothing to return
        }

    }
    elsif ( not ref($start) ) {    # possibly a sha1
        $obj = $cfg->get_object($start);
        if ( not $obj ) {
            $@ = "No object found for SHA1 " . $start ? $start : '';
            return $@;
        }
    }
    elsif ( ref($start) =~ /^(REF|SCALAR|ARRAY|HASH|CODE|GLOB)$/ ) {
        croak( "_debugtree doesn't support ref type " . ref($start) );
    }
    else {
        $obj = $start;
    }

    # At this point, we should have a Git::PurePerl (new) Object.
    # Let's double-check.

    if ( $obj->can('kind') ) {

        #        push @out, ( ' ' x ( $tabsize * $indent ) ) . ('=' x 40);
        #foreach my $attr (qw( kind size content sha1 git )) {
        foreach my $attr (qw( kind size sha1 )) {
            if ( $obj->can($attr) ) {
                push @out,
                  ( ' ' x ( $tabsize * $indent ) ) . $attr . ': ' . $obj->$attr;
            }
        }
    }
    elsif ($obj->isa('Git::PurePerl::NewDirectoryEntry')
        or $obj->isa('Git::PurePerl::DirectoryEntry') )
    {
        foreach my $attr (qw( mode filename sha1 )) {
            if ( $obj->can($attr) ) {
                push @out,
                  ( ' ' x ( $tabsize * $indent ) ) . $attr . ': ' . $obj->$attr;
            }
        }
        push @out, $self->_debugtree( $obj->sha1, $indent + 1 );
        return @out;
    }
    else {
        die "Obj $obj doesn't seem to be supported";
    }

    if ( $obj->kind eq 'commit' ) {
        foreach my $attr (
            qw( tree_sha1 parent_sha1s author authored_time committer
            commited_time comment encoding )
          )
        {
            if ( $obj->can($attr) ) {
                push @out,
                  ( ' ' x ( $tabsize * $indent ) ) . $attr . ': ' . $obj->$attr;
            }
        }
        push @out, $self->_debugtree( $obj->tree, $indent + 1 );
    }
    elsif ( $obj->kind eq 'tree' ) {

        push @out, ( ' ' x ( $tabsize * $indent ) ) . 'raw: ';
        push @out, map {
            chomp $_;
            ( ' ' x ( $tabsize * $indent ) ) . $_
        } hdump( $obj->kind . ' ' . $obj->size . "\0" . $obj->content );

        my $sha1a = Digest::SHA->new;
        $sha1a->add( $obj->kind . ' ' . $obj->size . "\0" . $obj->content );

        push @out,
            ( ' ' x ( $tabsize * $indent ) )
          . 'my sha1 from Digest::SHA: '
          . $sha1a->hexdigest;

        my @directory_entries = $obj->directory_entries;

        foreach my $de (@directory_entries) {
            push @out,
              ( ' ' x ( $tabsize * $indent ) )
              . 'Directory Entry: ';    # . $de->filename;

            push @out, $self->_debugtree( $de, $indent + 1 );
        }
    }
    elsif ( $obj->kind eq 'blob' ) {
        push @out, ' ' x ( $tabsize * ($indent) ) . 'content: ';
        push @out, ( ' ' x ( $tabsize * ( $indent + 1 ) ) )
          . join(
            "\n" . ( ' ' x ( $tabsize * ( $indent + 1 ) ) ),
            split( /\n/, $obj->content )
          );
    }
    else {
        push @out,
            ' ' x ( $tabsize * $indent )
          . 'Dump object kind '
          . $obj->kind
          . ' not implemented';
    }
    return @out;

}

=head2 hdump

Return hexdump of given data. 

=cut

sub hdump {
    my $offset = 0;
    my @out    = ();
    my ( @array, $format );
    foreach
      my $data ( unpack( "a16" x ( length( $_[0] ) / 16 ) . "a*", $_[0] ) )
    {
        my ($len) = length($data);
        if ( $len == 16 ) {
            @array = unpack( 'N4', $data );
            $format = "0x%08x (%05d)   %08x %08x %08x %08x   %s\n";
        }
        else {
            @array = unpack( 'C*', $data );
            $_ = sprintf "%2.2x", $_ for @array;
            push( @array, '  ' ) while $len++ < 16;
            $format =
              "0x%08x (%05d)" . "   %s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n";
        }
        $data =~ tr/\0-\37\177-\377/./;
        push @out, sprintf $format, $offset, $offset, @array, $data;
        $offset += 16;
    }
    return @out;
}

=head1 ACKNOWLEDGEMENTS

Was based on the CPAN module App::Options, but since been converted to Moose.

=head1 AUTHOR

Scott T. Hardin, C<< <mrscotty at cpan.org> >>

Martin Bartosch

Oliver Welter

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-versioned at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Versioned>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Versioned


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Versioned>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Versioned>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Versioned>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Versioned/>

=back


=head1 COPYRIGHT

Copyright 2011 Scott T. Hardin, all rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;    # End of Config::Versioned

