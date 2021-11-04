package Astro::Catalog::Query::SuperCOSMOS;

# Depressingly the generic reg expression used the SkyCat.pm doesn't
# seem to work for SuperCOSMOS URL's, eventually we're going to have
# to make the regexp more generic. In the interim, I've cut and pasted
# the entire module into this sub-class so I can do queries.
#
# Yes Tim, I know this sucks.

=head1 NAME

Astro::Catalog::Query::SuperCOSMOS - A query request to the SuperCOSMOS catalogue

=head1 SYNOPSIS

    $supercos = new Astro::Catalog::Query::SuperCOSMOS(
            RA     => $ra,
            Dec    => $dec,
            Radius => $radius,
            Nout   => $number_out,
            Colour => $band);

    my $catalog = $supercos->querydb();

=head1 WARNING

This code totally ignores the epoch of the observations and the associated
proper motions, this pretty much means that for astrometric work the catalogues
you get back from the query are pretty much bogus. This should be sorted in
the next distribution.

=head1 DESCRIPTION

The module is an object orientated interface to the online SuperCOSMOS
catalogue using the generic Astro::Catalog::Query::SkyCat class

Stores information about an prospective query and allows the query to
be made, returning an Astro::Catalog::Query::SuperCOSMOS object.

The object will by default pick up the proxy information from the HTTP_PROXY
and NO_PROXY environment variables, see the LWP::UserAgent documentation for
details.

See L<Astro::Catalog::BaseQuery> for the catalog-independent methods.

=cut

use strict;
use warnings;
use warnings::register;
use base qw/Astro::Catalog::Transport::REST/;

use Data::Dumper;
use Carp;
use File::Spec;
use Carp;

# generic catalog objects
use Astro::Catalog;
use Astro::Catalog::Item;

use Astro::Flux;
use Astro::FluxColor;
use Astro::Fluxes;
use Number::Uncertainty;

our $VERSION = '4.36';
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

Simple constructor, handles the 'Colour' option, e.g.

    long_name:      SuperCOSMOS catalog - blue (UKJ) southern survey
    short_name:     SSScat_UKJ@WFAU

    long_name:      SuperCOSMOS catalog - red (UKR) southern survey
    short_name:     SSScat_UKR@WFAU

    long_name:      SuperCOSMOS catalog - near IR (UKI) southern survey
    short_name:     SSScat_UKI@WFAU

    long_name:      SuperCOSMOS catalog - red (ESOR) southern survey
    short_name:     SSScat_ESOR@WFAU

    $q = new Astro::Catalog::Query::SuperCOSMOS(colour => 'UKJ', %options);

Allowed options are 'UKJ', 'UKR', 'UKI', and 'ESOR' for the UK Blue, UK Red,
UK near-IR and ESO Red catalogues respectively.

All other options are passed on to SUPER::new().

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Instantiate via base class
    my $block = $class->SUPER::new( @_ );

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
    croak "Error instantiating SuperCOSMOS object since no config was located"
    unless %CONFIG;

    # Now we need to configure this object based on the
    # supplied catalog name. This is not really a public interface
    # let's call it a protected interface available to subclases
    # even though we are not technically a subclass...
    my %args = Astro::Catalog::_normalize_hash(@_);

    croak "A colour must be provided using the 'colour' key"
        unless exists $args{colour};

    # case-insensitive
    my $colour = lc($args{colour});

    if ($colour eq 'ukj') {
        $self->_selected_catalog('ssscat_ukj@wfau');

    }
    elsif ($colour eq 'ukr') {
        $self->_selected_catalog('ssscat_ukr@wfau');

    }
    elsif ($colour eq 'uki') {
        $self->_selected_catalog('ssscat_uki@wfau');

    }
    elsif ($colour eq 'esor') {
        $self->_selected_catalog('ssscat_esor@wfau');

    }
    else {
        # default to UKR
        $self->_selected_catalog('SSScat_UKR@WFAU');
    }

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

    # Now for each token replace it in the URL
    for my $key (keys %translated) {
        my $tok = "%". $key;
        croak "Token $tok is mandatory but was not specified"
            unless defined $translated{$key};
        $url =~ s/$tok/$translated{$key}/;
    }

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
            $params{$key} = $CONFIG{$cat}->{$key};
        }
    }

    # Time to pad the params with known values, this is yet another un-Godly
    # hack for which I'm duely ashamed. God help us if they ever change the
    # catalogues. Why is SuperCOSMOS so much bloody trouble?

    # Make sure we set origin and field centre if we know it
    my $query = new Astro::Catalog(
            Format => 'TST',
            Data => $self->{BUFFER},
            ReadOpt => \%params,
            Origin => $CONFIG{$cat}->{long_name});

    # Grab each star in the catalog and add some value to it
    my $catalog = new Astro::Catalog();
    $catalog->origin($query->origin());
    $catalog->set_coords($query->get_coords()) if defined $query->get_coords();

    my @stars = $query->allstars();

    my (@mags, @cols);
    foreach my $i (0 ... $#stars) {
        my ($cval, $err, $mag, $col);
        my @mags = undef;
        my @cols = undef;

        my $star = $stars[$i];

        # if we have a non-zero quality, set the quality to 1 (this sucks!)
        $star->quality(1) if( $star->quality() != 0 );

        # calulate the errors

        $err = 0.04;
        if ( $star->get_magnitude( "BJ" ) != 99.999 ) {
            $err = 0.04 if $star->get_magnitude( "BJ" ) > 15.0;
            $err = 0.05 if $star->get_magnitude( "BJ" ) > 17.0;
            $err = 0.06 if $star->get_magnitude( "BJ" ) > 19.0;
            $err = 0.07 if $star->get_magnitude( "BJ" ) > 20.0;
            $err = 0.12 if $star->get_magnitude( "BJ" ) > 21.0;
            $err = 0.08 if $star->get_magnitude( "BJ" ) > 22.0;
        }
        else {
            $err = 99.999;
        }
        $mag = new Astro::Flux(new Number::Uncertainty(
                    Value => $star->get_magnitude("BJ"),
                    Error => $err ),
                'mag', 'BJ' );
        push @mags, $mag;

        $err = 0.06;
        if ( $star->get_magnitude( "R1" ) != 99.999 ) {
            $err = 0.06 if $star->get_magnitude( "R1" ) > 11.0;
            $err = 0.03 if $star->get_magnitude( "R1" ) > 12.0;
            $err = 0.09 if $star->get_magnitude( "R1" ) > 13.0;
            $err = 0.10 if $star->get_magnitude( "R1" ) > 14.0;
            $err = 0.12 if $star->get_magnitude( "R1" ) > 18.0;
            $err = 0.18 if $star->get_magnitude( "R1" ) > 19.0;
        }
        else {
            $err = 99.999;
        }
        $mag = new Astro::Flux(new Number::Uncertainty(
                    Value => $star->get_magnitude("R1"),
                    Error => $err),
                'mag', 'R1' );
        push @mags, $mag;

        $err = 0.02;
        if ( $star->get_magnitude( "R2" ) != 99.999 ) {
            $err = 0.02 if $star->get_magnitude( "R2" ) > 12.0;
            $err = 0.03 if $star->get_magnitude( "R2" ) > 13.0;
            $err = 0.04 if $star->get_magnitude( "R2" ) > 15.0;
            $err = 0.05 if $star->get_magnitude( "R2" ) > 17.0;
            $err = 0.06 if $star->get_magnitude( "R2" ) > 18.0;
            $err = 0.11 if $star->get_magnitude( "R2" ) > 19.0;
            $err = 0.16 if $star->get_magnitude( "R2" ) > 20.0;
        }
        else {
            $err = 99.999;
        }
        $mag = new Astro::Flux( new Number::Uncertainty(
                    Value => $star->get_magnitude("R2"),
                    Error => $err ),
                'mag', 'R2' );
        push @mags, $mag;

        $err = 0.05;
        if ( $star->get_magnitude( "I" ) != 99.999 ) {
            $err = 0.05 if $star->get_magnitude( "I" ) > 15.0;
            $err = 0.06 if $star->get_magnitude( "I" ) > 16.0;
            $err = 0.09 if $star->get_magnitude( "I" ) > 17.0;
            $err = 0.16 if $star->get_magnitude( "I" ) > 18.0;
        }
        else {
            $err = 99.999;
        }
        $mag = new Astro::Flux( new Number::Uncertainty(
                    Value => $star->get_magnitude("I"),
                    Error => $err ),
                'mag', 'I' );
        push @mags, $mag;

        # calculate colours UKST Bj - UKST R, UKST Bj - UKST I

        if ($star->get_magnitude( "BJ" ) != 99.999 &&
                $star->get_magnitude( "R2" ) != 99.999) {
            my $bj_minus_r2 = $star->get_magnitude( "BJ" ) -
                $star->get_magnitude( "R2" );
            $bj_minus_r2 =  sprintf("%.4f", $bj_minus_r2 );

            my $delta_bjmr = ( ( $star->get_errors( "BJ" ) )**2.0 +
                    ( $star->get_errors( "R2" ) )**2.0     )** (1/2);
            $delta_bjmr = sprintf("%.4f", $delta_bjmr );

            $cval = $bj_minus_r2;
            $err = $delta_bjmr;
        }
        else {
            $cval = 99.999;
            $err = 99.999;
        }
        $col = new Astro::FluxColor(
                upper => 'BJ',
                lower => "R2",
                quantity => new Number::Uncertainty(
                    Value => $cval,
                    Error => $err ) );
        push @cols, $col;

        if ($star->get_magnitude( "BJ" ) != 99.999 &&
                $star->get_magnitude( "I" ) != 99.999) {

            my $bj_minus_i = $star->get_magnitude( "BJ" ) -
                $star->get_magnitude( "I" );
            $bj_minus_i =  sprintf("%.4f", $bj_minus_i );

            my $delta_bjmi = ( ( $star->get_errors( "BJ" ) )**2.0 +
                    ( $star->get_errors( "I" ) )**2.0     )** (1/2);
            $delta_bjmi = sprintf("%.4f", $delta_bjmi );

            $cval = $bj_minus_i;
            $err = $delta_bjmi;

        }
        else {
            $cval = 99.999;
            $err = 99.999;
        }
        $col = new Astro::FluxColor(
                upper => 'BJ',
                lower => "I",
                quantity => new Number::Uncertainty(
                    Value => $cval,
                    Error => $err ) );
        push @cols, $col;

        # Push the data back into the star object, overwriting ther previous
        # values we got from the initial Skycat query. This isn't a great
        # solution, but it wasn't easy in version 3 syntax either, so I guess
        # your milage may vary.

        my $fluxes = new Astro::Fluxes( @mags, @cols );
        $star->fluxes( $fluxes, 1 );  # the 1 means overwrite the previous values

        # push it onto the stack
        $stars[$i] = $star if defined $star;
    }

    $catalog->allstars( @stars );

    # set the field centre
    my %allow = $self->_get_allowed_options();
    my %field;
    for my $key ("ra","dec","radius") {
        if (exists $allow{$key}) {
            $field{$key} = $self->query_options($key);
        }
    }
    $catalog->fieldcentre( %field );

    return $catalog;
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
C<$PERLPREFIX/etc/sss.cfg>.

=cut

sub cfg_file {
    my $class = shift;

    my $cfg_file;
    if (@_) {
        $cfg_file = shift;
        $class->_load_config() || ($cfg_file = undef);
    }
    else {
        # generate the default path to the $PERLPRFIX/etc/sss.cfg file,
        # this is a horrible hack, there is probably an elegant way to do
        # this but I can't be bothered looking it up right now.
        my $perlbin = $^X;
        my ($volume, $dir, $file) = File::Spec->splitpath( $perlbin );
        my @dirs = File::Spec->splitdir( $dir );
        my @path;
        foreach my $i ( 0 .. $#dirs-2 ) {
            push @path, $dirs[$i];
        }
        my $directory = File::Spec->catdir( @path, 'etc' );

        # reset to the default
        $cfg_file = File::Spec->catfile( $directory, "sss.cfg" );

        # debugging and testing purposes
        unless (-f $cfg_file) {
            # use blib version!
            $cfg_file = File::Spec->catfile( '.', 'etc', 'sss.cfg' );
        }
    }

    print "SuperCOSMOS.pm: \$cfg_file in cfg_file() is $cfg_file\n" if $DEBUG;
    return $cfg_file;
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
    my $cfg = $self->cfg_file;

    unless (defined $cfg) {
        warnings::warnif("Config file not specified (undef)");
        return;
    }

    unless (-e $cfg) {
        my $xcfg = (defined $cfg ? $cfg : "<undefined>");
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
    my @configs = $self->_extract_raw_info( \@lines );

    # Close file
    close( $fh ) or do {
        warnings::warnif("Error closing config file, $cfg: $!");
        return;
    };

    # Get the token mapping for validation
    my %map = $self->_token_mapping;

    # Currently we are only interested in catalog, namesvr and archive
    # so throw everything else away
    @configs = grep { $_->{serv_type} =~ /(namesvr|catalog|archive)/  } @configs;

    # Process each entry. Mainly URL processing
    for my $entry ( @configs ) {
        # Skip if we have already analysed this server
        if (exists $CONFIG{lc($entry->{short_name})}) {
            next;
        }

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
        if ( $entry->{url} =~ m|^http://www-wfau.roe.ac.uk/~sss/cgi-bin/gaia_obj.cgi?
                (.*)               # CGI options without trailing space
                |x) {
            $entry->{remote_host} = "www-wfau.roe.ac.uk";
            $entry->{url_path} = "~sss/cgi-bin/gaia_obj.cgi?";
            my $options = $1;

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
            warnings::warnif( "No tokens found in $options!!!" )
                unless @tokens;

            # Just need to make sure that these are acceptable tokens
            # Get the lookup table and store that as the allowed options
            my %allow;
            for my $tok (@tokens) {
                # only one token. See if we recognize it
                my $strip = $tok;
                $strip =~ s/%//;

                if (exists $map{$strip}) {
                    if (!defined $map{$strip}) {
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

            # And store this in the config. Only store it if we have
            # tokens
            $CONFIG{lc($entry->{short_name})} = $entry;
        }
    }

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
                push(@configs, $self->_dir_check( $current ));

                # Clear the config and store the serv_type
                $current = { $key => $value  };
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
catalogue server configs.

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
        m2 => 'magfaint',
        m1 => 'magbright',

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

    return ($allow{dec},$dec);
}

sub _from_ra {
    my $self = shift;
    my $ra = $self->query_options("ra");
    my %allow = $self->_get_allowed_options();

    # need colons
    $ra =~ s/\s+/:/g;

    return ($allow{ra},$ra);
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

=head1 COPYRIGHT

Copyright (C) 2001 University of Exeter. All Rights Reserved.
Some modifications copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=cut
