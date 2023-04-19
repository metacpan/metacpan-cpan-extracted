package Astro::Catalog::Query::SkyCat;

=head1 NAME

Astro::Catalog::Query::SkyCat - Generate SkyCat catalog query clients

=head1 SYNOPSIS

=head1 DESCRIPTION

On load, automatically parse the SkyCat server specification file
from C<~/.skycat/skycat.cfg>, if available, and dynamically
generate query classes that can send queries to each catalog
server and parse the results.

=cut

use strict;
use warnings;
use warnings::register;

use Data::Dumper;
use Carp;
use File::Spec;

use base qw/Astro::Catalog::Transport::REST/;

our $VERSION = '4.37';
our $DEBUG = 0;

# Controls whether we follow 'directory' config entries and recursively
# expand those. Default to false at the moment.
our $FOLLOW_DIRS = 0;

# This is the name of the config file that was used to generate
# the content in %CONFIG. Can be different to the contents ofg_file
# if that
my $CFG_FILE;

# This is the content of the config file
# organized as a hash indexed by remote server shortname
# this has the advantage of removing duplicates
my %CONFIG;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Simple constructor. Forces read of config file if one can be found and
the config has not been read previously. If no config file can be located
the query object can not be instantiated since it will not know the
location of any servers.

    $q = new Astro::Catalog::Query::SkyCat(catalog => 'gsc', %options);
    $q = new Astro::Catalog::Query::SkyCat(catalog => 'gsc@eso', %options);

The C<catalog> field must be present, otherwise the new object will
not know which remote server to use and which options are mandatory
in the query. Note that the remote catalog can not be changed after
the object is instantiated. In general it is probably not wise to
try to change the remote host via either the C<query_url> or
C<url> methods unless you know what you are doing. Modifying your
C<skycat.cfg> file is safer.

Currently only one config file is supported at any given time.
If a config file is changed (see the C<cfg_file> class method)
the current config is overwritten automatically.

It is not possible to override the catalog file in the
constructor. Use the C<cfg_file> class method instead.

Obviously a config per object can be supported but this is
probably not that helpful. This will be reconsidered if demand
is high.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Instantiate via base class
    my $block = $class->SUPER::new(@_);

    return $block;
}

=back

=head2 Accessor methods

=over 4

=item B<_selected_catalog>

Catalog name selected by the user and currently configured for
this object. Not to be used outside this class..

=cut

sub _selected_catalog {
    my $self = shift;
    if (@_) {
        # The class has to be configured as a hash!!!
        $self->{SKYCAT_CATALOG} = shift;
    }
    return $self->{SKYCAT_CATALOG};
}

=back

=head2 General methods

=over 4

=item C<configure>

Configure the object. This calls the base class configure , after it has
made sure that a sky cat config file has been read (otherwise we will
not be able to vet the incoming arguments.

=cut

sub configure {
    my $self = shift;

    # load a config if we do not have one read yet
    # Note that this may force a remote URL read via directory
    # directives even though we do not have a user agent configured...
    $self->_load_config() unless %CONFIG;

    # Error if we have no config yet
    croak "Error instantiating SkyCat object since no config was located"
    unless %CONFIG;

    # Now we need to configure this object based on the
    # supplied catalog name. This is not really a public interface
    # let's call it a protected interface available to subclases
    # even though we are not technically a subclass...
    my %args = Astro::Catalog::_normalize_hash(@_);

    croak "A remote service catalog name must be provided using a 'catalog' key"
        unless exists $args{catalog};

    # case-insensitive
    my $cat = lc($args{catalog});

    # if we have an entry in %CONFIG then we can use it directly
    # else we may have a root name without a remote server
    if (! exists $CONFIG{$cat}) {
        my $name = $cat;
        # clear it and look for another
        $cat = undef;

        # if name does not include an @ we probably have a generic catalog
        # and just need to choose a random specific version
        if ($name !~ /\@/) {
            # look through the catalog
            for my $rmt (keys %CONFIG) {
                if ($rmt =~ /^$name\@/) {
                    # a match
                    $cat = $rmt;
                }
            }
        }
        # No luck finding catalog name
        croak "unable to find a remote service named $name"
            unless defined $cat;
    }

    # Now we know the details we need to store this somewhere in
    # the object so that it won't get clobbered. Otherwise the
    # super class configure will not be able to get the information
    # it needs. We can not simply store this in options since configure
    # does not know it is an allowed option...
    $self->_selected_catalog( $cat );

    # delete catalog from list
    delete $args{catalog};

    # Configure
    $self->SUPER::configure(%args);
}

=item B<_build_query>

Construct a query URL based on the options.

    $url = $q->_build_query();

=cut

sub _build_query {
    my $self = shift;

    my $cat = $self->_selected_catalog();

    # Get the URL
    my $url = $CONFIG{$cat}->{url};

    # Translate all the options to the internal skycat format
    my %translated = $self->_translate_options();

    print "Translated query: ".Dumper(\%translated,$url) if $DEBUG;

    # Now for each token replace it in the URL
    for my $key (keys %translated) {
        my $tok = "%". $key;
        croak "Token $tok is mandatory but was not specified"
            unless defined $translated{$key};
        $url =~ s/$tok/$translated{$key}/;
    }

    print "Final URL: $url\n" if $DEBUG;

    return $url;
}


=item B<_parse_query>

All the SkyCat servers return data in TST format.
Need to make sure that column information is passed
into the TST parser.

=cut

sub _parse_query {
    my $self = shift;

    # Get the catalog info
    my $cat = $self->_selected_catalog();

    # and extract formatting information needed by the TST parser
    my %params;
    for my $key (keys %{ $CONFIG{$cat} }) {
        if ($key =~ /_col$/) {
            print "FOUND column specified $key\n" if $DEBUG;
            $params{$key} = $CONFIG{$cat}->{$key};
        }
    }

    # If this catalog is a GSC, pass in a GSC parameter
    $params{gsc} = 1 if $cat =~ /^gsc/i;

    print $self->{BUFFER} ."\n" if $DEBUG;

    # Make sure we set origin and field centre if we know it
    my $newcat = new Astro::Catalog(
            Format => 'TST',
            Data => $self->{BUFFER},
            ReadOpt => \%params,
            Origin => $CONFIG{$cat}->{long_name},
        );

    # set the field centre
    my %allow = $self->_get_allowed_options();
    my %field;
    for my $key ("ra","dec","radius") {
        if (exists $allow{$key}) {
            $field{$key} = $self->query_options($key);
        }
    }
    $newcat->fieldcentre(%field);

    return $newcat;
}

=item B<_get_allowed_options>

This method declares which options can be configured by the user
of this service. Generated automatically by the skycat config
file and keyed to the requested catalog.

=cut

sub _get_allowed_options {
    my $self = shift;
    my $cat = $self->_selected_catalog();

    return %{ $CONFIG{$cat}->{allow} };
}

=item B<_get_default_options>

Get the default options that are relevant for the selected
catalog.

    %defaults = $q->_get_default_options();

=cut

sub _get_default_options {
    my $self = shift;

    # Global skycat defaults
    my %defaults = (
        # Target information
        ra => undef,
        dec => undef,
        id => undef,

        # Limits
        radmin => 0,
        radmax => 5,
        width => 10,
        height => 10,

        magfaint => 100,
        magbright => 0,

        nout => 20000,
        cond => '',
    );

    # Get allowed options
    my %allow = $self->_get_allowed_options();

    # Trim the defaults (could do with hash slice?)
    my %trim = map {$_ => $defaults{$_}} keys %allow;

    return %trim;
}

=item B<_get_supported_init>

=cut

sub _get_supported_init {
    croak "xxx - get supported init";
}

=back

=head2 Class methods

These methods are not associated with any particular object.

=over 4

=item B<cfg_file>

Location of the skycat config file. Default location is
C<$SKYCAT_CFG>, if defined, else C<$HOME/.skycat/skycat.cfg>,
or C<$PERLPREFIX/etc/skycat.cfg> if there isn't a version
in the users home directory

This could be made per-class if there is a demand for running
queries with different catalogs. This would also move the config
contents into the query object itself.

=cut

sub _set_cfg_file {
    my $cfg_file;

    if (exists $ENV{SKYCAT_CFG}) {
        $cfg_file = $ENV{SKYCAT_CFG};
    }
    elsif (-f File::Spec->catfile($ENV{HOME}, ".skycat", "skycat.cfg")) {
        $cfg_file = File::Spec->catfile($ENV{HOME}, ".skycat", "skycat.cfg");
    }
    else {
        # generate the default path to the $PERLPRFIX/etc/skycat.cfg file,
        # this is a horrible hack, there is probably an elegant way to do
        # this but I can't be bothered looking it up right now.
        my $perlbin = $^X;
        my ($volume, $dir, $file) = File::Spec->splitpath($perlbin);
        my @dirs = File::Spec->splitdir($dir);
        my @path;
        foreach my $i (0 .. $#dirs-2) {
            push @path, $dirs[$i];
        }
        my $directory = File::Spec->catdir(@path, 'etc');

        # reset to the default
        $cfg_file = File::Spec->catfile($directory, "skycat.cfg");

        # debugging and testing purposes
        unless (-f $cfg_file) {
            # use blib version!
            $cfg_file = File::Spec->catfile('.', 'etc', 'skycat.cfg');
        }
    }
    return $cfg_file;
}

sub cfg_file {
    my $class = shift;
    my $cfg_file;
    if (@_) {
        $cfg_file = shift;
        if (((defined $CFG_FILE) && $cfg_file ne $CFG_FILE)
                || ! (defined $CFG_FILE)) {
            # We were given a new config file, so load it.
            $class->_load_config($cfg_file);
            $CFG_FILE = $cfg_file;
        }
    }
    unless (defined $CFG_FILE) {
        $CFG_FILE = _set_cfg_file;
    }
    return $CFG_FILE;
}

=back

=begin __PRIVATE_METHODS__

=head2 Internal methods

=over 4

=item B<_load_config>

Method to load the skycat config information into
the class and configure the modules.

    $q->_load_config() or die "Error loading config";

The config file name is obtained from the C<cfg_file> method.
Returns true if the file was read successfully and contained at
least one catalog server. Otherwise returns false.

Requires an object to attach itself to (mainly for the useragent
remote directory follow up). The results of this load are
visible to all instances of this class.

Usually called automatically from the constructor if a config
has not previously been read.

=cut

sub _load_config {
    my $self = shift;
    my $cfg = shift;

    print "SkyCat.pm: \$cfg = $cfg\n" if $DEBUG;

    unless (defined $cfg) {
        $cfg = _set_cfg_file;
        $self->cfg_file( $cfg );
    }

    unless (-e $cfg) {
        my $xcfg = (defined $cfg ? $cfg : "<undefined>" );
        return;
    }

    my $fh;
    unless (open $fh, "<$cfg") {
        warnings::warnif( "Specified config file, $cfg, could not be opened: $!");
        return;
    }

    # Need to read the contents into an array
    my @lines = <$fh>;

    # Process the config file and extract the raw content
    my @configs = $self->_extract_raw_info(\@lines);

    print "Pre-filtering has \@configs " . @configs . " entries\n" if $DEBUG;

    # Close file
    close( $fh ) or do {
        warnings::warnif("Error closing config file, $cfg: $!");
        return;
    };

    # Get the token mapping for validation
    my %map = $self->_token_mapping;

    # Currently we are only interested in catalog, namesvr and archive
    # so throw everything else away
    @configs = grep {$_->{serv_type} =~ /(namesvr|catalog|archive)/ } @configs;

    print "Post-filtering has \@configs " . @configs . " entries\n" if $DEBUG;

    # Process each entry. Mainly URL processing
    for my $entry ( @configs ) {
        # Skip if we have already analysed this server
        if (exists $CONFIG{lc($entry->{short_name})}) {
            print "Already know about " . $entry->{short_name} . "\n"
                if $DEBUG;
            next;
        }

        print "  Processing " . $entry->{short_name} . "\n" if $DEBUG;
        print Dumper( $entry ) if( $DEBUG );

        # Extract info from the 'url'. We need to extract the following info:
        #  - Host name and port
        #  - remaining url path
        #  - all the CGI options including the static options
        # Note that at the moment we do not do token replacement (the
        # rest of the REST architecture expects to get the above
        # information separately). This might well prove to be silly
        # since we can trivially replace the tokens without having to
        # reconstruct the url. Of course, this does allow us to provide
        # mandatory keywords. $url =~ s/\%ra/$ra/;
        if ($entry->{url} =~ m|^http://  # Standard http:// prefix
                ([\w\.\-]+    # remote host
                 (?::\d+)?) # Optional port number
                /          # path separator
                ([\w\/\-\.]+\?) # remaining URL path and ?
                (.*)       # CGI options without trailing space
                |x) {
            $entry->{remote_host} = $1;
            $entry->{url_path} = $2;
            my $options = $3;

            # if first character is & we append that to url_path since it
            # is an empty argument
            $entry->{url_path} .= "&" if $options =~ s/^\&//;

            # In general the options from skycat files are a real pain
            # Most of them have nice blah=%blah format but there are some cases
            # that do ?%ra%dec or coords=%ra %dec that just cause more trouble
            # than they are worth given the standard URL constructor that we
            # are attempting to inherit from REST
            # Best idea is not to fight against it. Extract the host, path
            # and options separately but simply use token replacement when it
            # comes time to build the URL. This will require that the url
            # is moved into its own method in REST.pm for subclassing.
            # We still need to extract the tokens themselves so that we
            # can generate an allowed options list.

            # tokens have the form %xxx but we have to make sure we allow
            # %mime-type. Use the /g modifier to get all the matches
            my @tokens = ( $options =~ /(\%[\w\-]+)/g);

            # there should always be tokens. No obvious way to reomve the anomaly
            warnings::warnif("No tokens found in $options!!!")
                unless @tokens;

            # Just need to make sure that these are acceptable tokens
            # Get the lookup table and store that as the allowed options
            my %allow;
            for my $tok (@tokens) {
                # only one token. See if we recognize it
                my $strip = $tok;
                $strip =~ s/%//;

                if (exists $map{$strip}) {
                    unless (defined $map{$strip}) {
                        warnings::warnif("Do not know how to process token $tok" );
                    }
                    else {
                        $allow{ $map{$strip} } = $strip;
                    }
                }
                else {
                    warnings::warnif("Token $tok not currently recognized")
                        unless exists $map{$strip};
                }
            }

            # Store them
            $entry->{tokens} = \@tokens;
            $entry->{allow}  = \%allow;

            print Dumper($entry) if $DEBUG;

            # And store this in the config. Only store it if we have
            # tokens
            $CONFIG{lc($entry->{short_name})} = $entry;
        }
    }

    # Debug
    print Dumper(\%CONFIG) if $DEBUG;

    return;
}

=item B<_extract_raw_info>

Go through a skycat.cfg file and extract the raw unprocessed entries
into an array of hashes. The actual content of the file is passed
in as a reference to an array of lines.

    @entries = $q->_extract_raw_info(\@lines);

This routine is separate from the main load routine to allow recursive
calls to remote directory entries.

=cut

sub _extract_raw_info {
    my $self = shift;
    my $lines = shift;

    # Now read in the contents
    my $current; # Current server spec
    my @configs; # Somewhere temporary to store the entries

    for my $line (@$lines) {
        # Skip comment lines and blank lines
        next if $line =~ /^\s*\#/;
        next if $line =~ /^\s*$/;

        if ($line =~ /^(\w+):\s*(.*?)\s*$/) {
            # This is content
            my $key = $1;
            my $value = $2;
            # Assume that serv_type is always first
            if ($key eq 'serv_type') {
                # Store previous config if it contains something
                # If it actually contains information on a serv_type of
                # directory we can follow the URL and recursively expand
                # the content
                push(@configs, $self->_dir_check($current));

                # Clear the config and store the serv_type
                $current = {$key => $value};
            }
            else {
                # Just store the key value pair
                $current->{$key} = $value;
            }
        }
        else {
            # do not know what this line signifies since it is
            # not a comment and not a content line
            warnings::warnif("Unexpected line in config file: $line\n");
        }
    }

    # Last entry will still be in %$current so store it if it contains
    # something.
    push(@configs, $self->_dir_check( $current ));

    # Return the entries
    return @configs;
}

=item B<_dir_check>

If the supplied hash reference has content, look at the content
and decide whether you simply want to keep that content or
follow up directory specifications by doing a remote URL call
and expanding that directory specification to many more remote
catalog server configs.

    @configs = $q->_dir_check(\%current);

Returns the supplied argument, additional configs derived from
that argument or nothing at all.

Do not follow a 'directory' link if we have already followed a link with
the same short name. This prevents infinite recursion when the catalog
pointed to by 'catalogs@eso' itself contains a reference to 'catalogs@eso'.

=cut

my %followed_dirs;
sub _dir_check {
    my $self = shift;
    my $current = shift;

    if (defined $current && %$current) {
        if ($current->{serv_type} eq 'directory') {
            # Get the content of the URL unless we are not
            # reading directories
            if ($FOLLOW_DIRS && defined $current->{url} &&
                    !exists $followed_dirs{$current->{short_name}}) {
                print "Following directory link to ". $current->{short_name}.
                    "[".$current->{url}."]\n"
                    if $DEBUG;

                # Indicate that we have followed this link
                $followed_dirs{$current->{short_name}} = $current->{url};

                # Retrieve the url, pass that array to the raw parser and then
                # return any new configs to our caller
                # Must force scalar context to get array ref
                # back rather than a simple list.
                return $self->_extract_raw_info(scalar $self->_get_directory_url( $current->{url} ));
            }
        }
        else {
            # Not a 'directory' so this is a simple config entry. Simply return it.
            return ($current);
        }
    }

    # return empty list since we have no value
    return ();
}


=item B<_get_directory_url>

Returns the content of the remote directory URL supplied as
argument. In scalar context returns reference to array of lines. In
list context returns the lines in a list.

    $lines = $q->_get_directory_url($url);
    @lines = $q->_get_directory__url($url);

If we have an error retrieving the file, just return an empty
array (ie skip it).

=cut

sub _get_directory_url {
    my $self = shift;
    my $url = shift;

    # Call the base class to get the actual content
    my $content = '';
    eval {
        $content = $self->_fetch_url( $url );
    };

    # Need an array
    my @lines;
    @lines = split("\n", $content) if defined $content;

    if (wantarray) {
        return @lines;
    }
    else {
        return \@lines;
    }
}

=item B<_token_mapping>

Provide a mapping of tokens found in SkyCat config files to the
internal values used generically by Astro::Catalog::Query classes.

    %map = $class->_token_mappings;

Keys are skycat tokens.

=cut

sub _token_mapping {
    return (
        id => 'id',

        ra => 'ra',
        dec => 'dec',

        # Arcminutes
        r1 => 'radmin',
        r2 => 'radmax',
        w  => 'width',
        h  => 'height',

        n => 'nout',

        # which filter???
        m1 => 'magfaint',
        m2 => 'magbright',

        # Is this a conditional?
        cond => 'cond',

        # Not Yet Supported
        cols => undef,
        'mime-type' => undef,
        ws => undef,
    );
}

=back

=head2 Translations

SkyCat specific translations from the internal format to URL format
go here.

RA/Dec must match format described in
http://vizier.u-strasbg.fr/doc/asu.html
(at least for GSC) ie  hh:mm:ss.s+/-dd:mm:ss
or decimal degrees.

=over 4

=cut

sub _from_dec {
    my $self = shift;
    my $dec = $self->query_options("dec");
    my %allow = $self->_get_allowed_options();

    # Need colons
    $dec =~ s/\s+/:/g;

    # Need a + preprended
    $dec = "+" . $dec if $dec !~ /^[\+\-]/;

    return ($allow{dec}, $dec);
}

sub _from_ra {
    my $self = shift;
    my $ra = $self->query_options("ra");
    my %allow = $self->_get_allowed_options();

    # need colons
    $ra =~ s/\s+/:/g;

    return ($allow{ra}, $ra);
}

=item B<_translate_one_to_one>

Return a list of internal options (as defined in C<_get_allowed_options>)
that are known to support a one-to-one mapping of the internal value
to the external value.

    %one = $q->_translate_one_to_one();

Returns a hash with keys and no values (this makes it easy to
check for the option).

This method also returns, the values from the parent class.

=cut

sub _translate_one_to_one {
    my $self = shift;
    # convert to a hash-list
    return ($self->SUPER::_translate_one_to_one,
            map { $_, undef }(qw/
                cond
                /)
           );
}

1;

__END__

=back

=end __PRIVATE_METHODS__

=head1 NOTES

'directory' entries are not followed by default although the class
can be configured to do so by setting

    $Astro::Catalog::Query::SkyCat::FOLLOW_DIRS = 1;

to true.

This class could simply read the catalog config file and allow queries
on explicit servers directly rather than going to the trouble of
auto-generating a class per server. This has the advantage of allowing
a user to request USNO data from different servers rather than generating
a single USNO class. ie

    my $q = new Astro::Catalog::Query::SkyCat(
            catalog => 'usnoa@eso',
            target => 'HL Tau',
            radius => 5);

as opposed to

    my $q = new Astro::Catalog::Query::USNOA(
            target => 'HL Tau',
            radius => 5 );

What to do with catalog mirrors is an open question. Of course,
convenience wrapper classes could be made available that simply delegate
the calls to the SkyCat class.

=head1 SEE ALSO

SkyCat FTP server. [URL goes here]

SSN75 [http://www.starlink.rl.ac.uk/star/docs/ssn75.htx//ssn75.html]
by Clive Davenhall.

=head1 BUGS

At the very least for testing, an up-to-date skycat.cfg file
should be distributed with this module. Whether it should be
used by this module once installed is an open question (since
many people will not have a version in the standard location).

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter and Particle Physics and
Astronomy Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free
software; you can redistribute it and/or modify it under the terms of
the GNU Public License.

=head1 AUTHORS

Tim Jenness E<lt>tjenness@cpan.orgE<gt>,
Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=cut
