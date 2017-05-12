package Config::apiLayers;

use strict;
use warnings;
use Symbol qw{ qualify_to_ref };

BEGIN {
    use vars    qw($VERSION $LASTMOD $DEBUG $CXLCFG $CXLDATA);
    $VERSION    = '0.11';
    $LASTMOD    = 20160329;
    $DEBUG      = 0;
    $CXLCFG     = '_cxl_cfg';
    $CXLDATA    = '_cxl_data';
}

sub _api_factory ($;$) {
    my $self        = shift;
    my $apiname     = shift;
    my $validator   = shift || undef;

    my $f_validator = sub ($;$) {
        my $self        = shift;
        my $name        = shift;
        my $validator   = shift;
        my $value       = shift;
        if (!defined $validator) {
            return $value;
        }
        elsif (ref $validator eq "CODE") {
            return $validator->($self,$name,$value);
        }
        elsif (!ref $validator) {
            return $value if $value =~ /$validator/;
            return undef;
        }
    };

    # The method for setting/getting the attribute's value
    warn "Creating Getter/Setter for $apiname called.\n" if $self->{'DEBUG'};
    
    return sub {
        my $name    = $apiname;
        warn "Getter/Setter for $name called.\n" if $self->{'DEBUG'};
        my $self    = shift;
        my $value   = shift || undef;

        if (defined $value) {

            if (my $valid = $f_validator->($self,$name,$validator,$value)) {
                #return $self->config({ 'data' => { $name => $valid } });
                $self->config({ 'data' => { $name => $valid } });
                return 1;
            } else {
                return undef;
            }

        } else {

    # In the future, we'll do more here
    my $paramedic = sub {
        my $value = shift;
        if (ref $value eq "CODE") {
            return $value->($self);
        } else {
            return $value;
        }
    };

    foreach my $layer (reverse @{$self->{$CXLDATA}}) {
        if (exists $layer->{$name}) {
            return $paramedic->($layer->{$name});
        }
    }

    return undef;

        }
    };
}

sub _api_define ($;$) {
    my $self        = shift;
    my $apiname     = shift;
    my $function    = shift || return undef;

    # Qualifying symbols

    # This does not work in Perl 5.12 and lower
    #my $ref = *{ Symbol::qualify_to_ref( $apiname ) };
    #*{ $ref } = $function;

    # This is verified to work in at least Perl 5.10.1 through 5.16.3
    #*{ Symbol::qualify_to_ref( $apiname ) } = $function;
    my $ref = Symbol::qualify_to_ref( $apiname );
    *{ $ref } = $function;

    return 1;
}

sub _api_undefine ($) {
    my $self         = shift;
    my $apiname      = shift;
    my $ref = *{ Symbol::qualify_to_ref( $apiname ) };
    *{ $ref } = undef;
}


# @attributes = [ a, b, c ];
# @attributes = [ { a => v1, b => v2, c => v3 } ]
# @attributes = [ { name => 'length', validator => \&func, getoptlong => 'length|l:i', description => 'long description' } ]
# @autoproto = 1|0 ; default is 1
sub new (;$) {
    my $pkg     = shift;
    my $args    = shift;
    my $class   = ref($pkg) || $pkg;
    my $self    = bless {},$class;

    my $autoproto = $args->{'autoproto'} || 1;

    my $attr_add = sub {
        my $attr_name   = shift;
        my $validator   = shift || undef;
        my $getoptlong  = shift || undef;
        my $description = shift || undef;
        push (@{$self->{$CXLCFG}->{'attributes'}}, $attr_name);
        $self->{$CXLCFG}->{'validators'}->{$attr_name}  = $validator if defined $validator;
        $self->{$CXLCFG}->{'getoptlong'}->{$attr_name}  = $getoptlong if defined $getoptlong;
        $self->{$CXLCFG}->{'description'}->{$attr_name} = $description if defined $description;
        my $attr_func   = $self->_api_factory($attr_name,$validator);
        warn "ERROR in creating function for $attr_name\n" if !defined $attr_func;
        $self->{$CXLCFG}->{'api'}->{$attr_name} = $attr_func;
        if ($autoproto == 1) {
            $self->_api_define($attr_name,$attr_func);
        }
    };
    my $attr_add_hash = sub {
        my $attr_hash = shift;
        if (exists $attr_hash->{'name'}) {
            my $name = $attr_hash->{'name'}; 
            my $validator = $attr_hash->{'validator'} || undef;
            my $getoptlong = $attr_hash->{'getoptlong'} || undef;
            my $description = $attr_hash->{'description'} || undef;
            $attr_add->($name, $validator, $getoptlong, $description);
        } else {
            foreach my $attr (keys %{$attr_hash}) {
                $attr_add->($attr, $attr_hash->{$attr});
            }
        }
    };
    if ((exists $args->{'attributes'}) && (ref $args->{'attributes'} eq "ARRAY")) {
        foreach my $attr (@{$args->{'attributes'}}) {
            if (ref $attr eq "HASH") {
                $attr_add_hash->($attr);
            } else {
                $attr_add->($attr);
            }
        }
    } elsif ((exists $args->{'attributes'}) && (ref $args->{'attributes'} eq "HASH")) {
        foreach my $attr_name (keys %{$args->{'attributes'}}) {
            $attr_add_hash->($attr_name);
        }
    }

    return $self;
}


# Set or retrieve a configuration layer, without validation.
# Set with @index and @data, or jusr @data for the last existing index
# Retrieve with only @index, or without index retrieve the last existing index
# @data
# @index
sub config ($) {
    my $self        = shift;
    my $args        = shift || {};
    my $lastLayer   = ref $self->{$CXLDATA} eq "ARRAY" ? (scalar @{$self->{$CXLDATA}} - 1) : 0;
    my $layer_idx   = exists $args->{'index'} ? $args->{'index'} : $lastLayer;
    if (! exists $args->{'data'}) {
        if (defined $self->{$CXLDATA}->[$layer_idx]) {
            return $self->{$CXLDATA}->[$layer_idx];
        } else {
            return undef;
        }
    }
    my $config      = $args->{'data'};
    my $attrs       = $self->{$CXLCFG}->{'attributes'};
    foreach my $key (keys %{$config}) {
        next unless grep {/^$key$/} @{$attrs};
        $self->{$CXLDATA}->[$layer_idx]->{$key} = $config->{$key};
    }
}

# Import the data, performing validation as available
# @data - the data to import
sub importdata ($) {
    my $self        = shift;
    my $args        = shift;
    my $attrs       = $self->{$CXLCFG}->{'attributes'};
    my $errors      = 0;
    if (exists $args->{'data'}) {
        foreach my $key (keys %{$args->{'data'}}) {
            next unless grep {/^$key$/} @{$attrs};
            unless ($self->apicall($key,$args->{'data'}->{$key})) {
                $errors++;
            }
        }
    }
    return 0 if $errors >= 1;
    return 1;
}

# Export the data
# @cfg - getoptlong|descriptions
# @data - undef|layerNumber|[startingLayer,endingLayer]
sub exportdata ($) {
    my $self        = shift;
    my $args        = shift;
    my $attrs       = $self->{$CXLCFG}->{'attributes'};
    if ((exists $args->{'cfg'}) && ($args->{'cfg'} eq "getoptlong")) {
        my $getoptlong  = [];
        foreach my $attr_name (@{$attrs}) {
            next unless defined $self->{$CXLCFG}->{'getoptlong'}->{$attr_name};
            push (@{$getoptlong}, $self->{$CXLCFG}->{'getoptlong'}->{$attr_name});
        }
        return $getoptlong;
    } elsif ((exists $args->{'cfg'}) && ($args->{'cfg'} eq "descriptions")) {
        my $description = [];
        foreach my $attr_name (@{$attrs}) {
            next unless defined $self->{$CXLCFG}->{'description'}->{$attr_name};
            push (@{$description}, $attr_name);
            push (@{$description}, $self->{$CXLCFG}->{'description'}->{$attr_name});
        }
        return $description;
    } elsif (exists $args->{'data'}) {
        my $firstLayer  = 0;
        my $lastLayer   = (scalar @{$self->{$CXLDATA}} - 1);
        if (    (defined $args->{'data'})
             && (!ref $args->{'data'})
             && ($args->{'data'} >= $firstLayer)
             && ($args->{'data'} <= $lastLayer)) {
            return $self->{$CXLDATA}->[$args->{'data'}];
        } elsif (ref $args->{'data'} eq "ARRAY") {
            $firstLayer = shift @{$args->{'data'}} || $firstLayer;
            $lastLayer  = pop @{$args->{'data'}} || $lastLayer;
        }
        my $export = {};
        foreach my $key (@{$attrs}) {
            for ($firstLayer..$lastLayer) {
                my $layer_idx = $_;
                next unless exists $self->{$CXLDATA}->[$layer_idx]->{$key};
                $export->{$key} = $self->{$CXLDATA}->[$layer_idx]->{$key};
            }
        }
        return $export if keys %{$export};
        return undef;
    }
}


# Add layers up to the given index, with or without data.
# Add a layer with @index and @data, or just @index, or add one more layer without @index
# Add more than one layer by providing the appropriate @index layer number. 
# The @data is only set into the last layer.
# @index
# @data
sub add_layer($) {
    my $self        = shift;
    my $args        = shift || {};
    if (ref $self->{$CXLDATA} ne "ARRAY") {
        $self->{$CXLDATA} = [];
    }
    my $nextLayer   = scalar @{$self->{$CXLDATA}};
    my $layerNumber = exists $args->{'index'} ? $args->{'index'} : $nextLayer;

    for ($nextLayer..$layerNumber) {
        push( @{$self->{$CXLDATA}}, {} );
    }

    if (exists $args->{'data'}) {
        $self->config({ data => $args->{'data'} , index => $layerNumber });
    }

    return (scalar @{$self->{$CXLDATA}} - 1);
}

sub apican(;$) {
    my $self         = shift;
    my $attr_name    = shift || undef;
    if (defined $attr_name) {
        return $self->{$CXLCFG}->{'api'}->{$attr_name} if exists $self->{$CXLCFG}->{'api'}->{$attr_name};
        return undef;
    } else {
        return wantarray ? @{$self->{$CXLCFG}->{'attributes'}} : $self->{$CXLCFG}->{'attributes'};
    }
}

sub apicall(;$){
    my $self         = shift;
    my $attr_name    = shift || return undef;
    if (defined $attr_name) {
        my $subref = $self->apican($attr_name);
        unshift(@_,$self);
        #goto &$subref if defined $subref;
        $subref->(@_) if defined $subref;
    }
}


#
# Non-Object helper functions
# To be used inside the api functions
#

sub _mendPath(@) {
    my @path = @_;
    my $path;
    foreach my $p (@path) {
        next unless defined $p;
        if ($path =~ /.+\/$/) {
            chop($path);
        }
        while ($p =~ /.+\/\/$/) {
            chop($p);
        }
        if (!defined $path) {
            $path = $p;
        } else {
            $path = ($path.'/'.$p);
        }
    }
    return $path;
}

# _mendLastRootPath
# Given an array of items that may define one or more paths from root '/'
# return the last grouping of items that define one path from root
# ex: _mendLastRootPath(qw( /path to file /next path to dir))
# returns: '/next/path/to/dir'
# This is handy when the users input for a parameter can either be a full path
# from root, or a subpath of another parameter.
# In this case, this would be the resulting example:
#   # when $homedir = /home
#   # and $userhomedir = ( jsmith | /home/jsmith )
#   my $path = mendlastrootpath( $homedir, $userhomedir);
#   # $path eq '/home/jsmith'
sub _mendLastRootPath (@) {
    my $self    = shift;
    my @items   = @_;
    my @rootitems;
    foreach my $item (@items) {
        if ($item =~ /^\//) {
            @rootitems = ();
            push (@rootitems,$item);
        } else {
            push (@rootitems,$item);
        }
    }
    return $self->mendPath(@rootitems);
}

sub _dirFileSplit($) {
    my $path = shift;
    if (-d $path) {
        return ($path,undef);
    }
    my ($baseDir,$fileName) = $path =~ /^(.*\/)([^\/]*)$/;
    return @{[$baseDir,$fileName]};
}

sub _dirBase($) {
    my $path = shift;
    my ($baseDir,$fileName) = _DirFileSplit($path);
    $baseDir = './' unless defined $baseDir;
    return $baseDir;
}

sub _fileName($) {
    my $path = shift;
    my ($baseDir,$fileName) = _DirFileSplit($path);
    return $fileName;
}

1;
__END__

=pod

=head1 NAME

Config::apiLayers - Auto-prototyping object properties in multiple configuration layers.


=head1 SYNOPSIS

    use Config::apiLayers;
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => [qw(length width area)]
    });
    # Set the default values
    $cfg->config({
        data => {
            'length' => 6,
            'width' => 10,
            'area' => sub {
                my $cfg = shift;
                return ($cfg->apicall('length') * $cfg->apicall('width'))
            }
        }
    });

    $cfg->length( 3 );
    print ("This rectangle has length ".$cfg->length." by width ".$cfg->width.
           ", with an area of ".$cfg->area.".\n");
    
    $cfg->width( 4 );
    print ("This rectangle has length ".$cfg->length." by width ".$cfg->width.
           ", with an area of ".$cfg->area.".\n");

Resulting output:

    This rectangle has length 3 by width 10, with an area of 30.
    This rectangle has length 3 by width 4, with an area of 12.

=head1 DESCRIPTION

Used as a base module or on its own to manage configuration properties of an
application. Its default behavior is to auto-prototype property attributes.
Validators can be used to validate values to be set. Configuration can be used
with C<Getopt::Long> and C<Getopt::LongUsage> for obtaining configuration.

Properties that are imported or directly configured can be stored in one or
multiple layers, and do not immediately affect each other. When retrieved, the
values of properties are obtained from the layers in a top-down fashion.

The values of properties can also be functions. When the value is retrieved, the
function is executed which can be used to combine multiple property values
together, or do smoething entirely different.


=head1 REQUIREMENTS

None.
This module is Pure Perl.
This module does not use AUTOLOAD.


=head1 METHODS


=head2 new

=over

=item attributes - configure the allowed attributes. Three styles are available.

=item autoproto - 1 or 0 ; Default is 1; Set to 1 for the attributes to be functions of the object.

=back

    # Style 1 - Only set the attributes, and each attribute stores a value. Order is retained.
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => [qw(length width area)]
    });

    # Style 2 - Only set the attributes with a validator. Attributes with undef valdiator
    #           store a provided values without validation. Order is NOT retained.
    my $val_greater_than_zero = sub {
        my $cfg = shift;
        my $attribute_name = shift;
        my $value = shift;
        return undef unless $value > 0;
        return $value;
    };
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => {
            'length'    => $val_greater_than_zero,
            'width'     => $val_greater_than_zero,
            'area'      => sub { return undef },  # do not allow storing any value
            'store_any' => undef
        }
    });
    # Style 3 - Same as Style 2, but retain the order of the attributes in configuration.
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => [
            {'length'    => $val_greater_than_zero},
            {'width'     => $val_greater_than_zero},
            {'area'      => sub { return undef }},  # do not allow storing any value
            {'store_any' => undef}
        ]
    });
    # Style 3 gives the ability to provide additional attribute configuration.
    # Configure optional information for use with C<Getopt::Long> and
    # C<Getopt::LongUsage> modules, while retaining order of the attributes.
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => [
            { name        => 'length',
              validator   => $val_greater_than_zero,
              getoptlong  => 'length|l:i',
              description => "The length of a rectangle"
            },
            { name        => 'width',
              validator   => $val_greater_than_zero,
              getoptlong  => 'width|w:i',
              description => "The width of a rectangle"
            },
            { name        => 'area',
              validator   => sub { return undef },  # do not allow storing any value
              getoptlong  => 'area|a',
              description => "The area of the rectangle, length times width"
            },
            { name        => 'store_any',
              validator   => undef,
              getoptlong  => 'store_any_value:s',
              description => "Store a value of your choosing, unvalidated"
            }
        ]
    });

    # Example use of configuration
    # Set the default values (the first layer is layer number 0)
    $cfg->config({
        data => {
            'length' => 6,
            'width' => 10,
            'area' => sub {
                my $cfg = shift;
                return ($cfg->apicall('length') * $cfg->apicall('width'))
            }
        }
    });
    # Perform the computation
    $cfg->length(5);
    $cfg->width(8);
    my $area = $cfg->area;  # $area == 40


=head2 config

Add configuration data to either the given C<index> layer, or the highest
layer if C<index> is not provided. Data is NOT validated.

=over

=item index - the index number of the top most configuration data layer to add.

=item data - the configuration data to add to the top most layer.

=back

    # Configure the 2nd layer (layer numbering starts at 0) 
    $cfg->config({
        index => 1,
        data => {
            'length' => 6,
            'width' => 10,
            'area' => sub {
                my $cfg = shift;
                return ($cfg->apicall('length') * $cfg->apicall('width'))
            }
        }
    });


=head2 importdata

Import the data, performing validation as available. This method will import
each attribute individually with C<apicall>, which performs the validation if a
validator was configured (see C<new> for configuring a validator for an attribute).

=over

=item data - the configuration data to import into the top most layer.

=back

    $cfg->importdata({ data => { length => 4, width => 2 } });


=head2 exportdata

Export the data or specific configuration information.

=over

=item cfg - the type of configuration to export. Provide this in two formats.

=over

=item cfg => 'getoptlong' - return an array of GetoptLong config, as configured in C<new>. This can be used with the C<Getopt::Long> module. Or you can parse it for a custom purpose using C<Getopt::LongUsage::ParseGetoptLongConfig> method.

=item cfg => 'descriptions' - return a hash of attribute and descriptions, as configured in C<new>. This can be used with the C<Getopt::LongUsage> module.

=back

=item data - the configuration data to export. Provide this in three formats:

=over

=item data => 'undef' - (this is the default action) to export each attribute among all layers

=item data => 'layerNumber' - to export attributes only from the given layer number

=item data => ['startingLayer','endingLayer'] - to export attributes only from the given layer range

=item data => /invalid or unrecognized value/ - preform the default action

=back

=back

    my $getoptlong_config = $cfg->exportdata({ cfg => 'getoptlong' });
    my %options;
    GetOptions( \%options, @$getoptlong_config );
    $cfg->importdata({ data => \%options });

    # Export Data from layers. Data for each attribute in top most layer is exported.
    my $exported_data = $cfg->exportdata({ data => undef });

=head2 add_layer

Add a new configuration layer. If C<index> is provided, then configuration data
layers are added until C<index> number of layers exist. If C<data> is provided,
then the given configuration data is added to the highest configuration data
layer. If both C<index> and C<data> are provided, the layers are added first,
then the configuration data is added to the top most existing layer.

=over

=item index - the index number of the top most configuration data layer to add.

=item data - the configuration data to add to the top most layer.

=back

    # Add one more layer to the existing layers.
    $cfg->add_layer();
    # Add one more layer and set the data for that layer.
    $cfg->add_layer({
        data => {
            'length' => 6,
            'width' => 10,
            'area' => sub {
                my $cfg = shift;
                return ($cfg->apicall('length') * $cfg->apicall('width'))
            }
        }
    });
    # Add 3 layers (layer numbering starts at 0)
    $cfg->add_layer({ 'index' => 2 });


=head2 apican

Determine if the apiname is available to be called.
Returns undef if false, or the referenced function if true.

=over

=item apiname - the name of the property/api

=back

    my $subref = $cfg->apican("apiname");


=head2 apicall

Call the apiname to get or set the attribute.

=over

=item apiname - the name of the property/api

=item arguments - any arguments required by the apicall, i.e. like a value to set

=back

    # Both of these calls do the same thing
    my $res = $cfg->apicall("apiname" [, arguments ]);
    my $res = $cfg->apiname([ arguments ]);


=head1 VALIDATORS


=head2 VALIDATOR FORMAT

=over

The format of the validator is to return the value to store if the value is
validated successfully, or return undef is not validated successfully.

Validators must be a function, or a string that can be evaluated as a regex.
Validators that are hashes or arrays are invalid.

An undefined validator will allow any value passed in to be stored.

=back

=head2 VALIDATOR AS A FUNCTION

=over

This allows a function that is used as the validator to change the value, as
the stored value is whatever the function returns.

Validator Function Call Format:

    # The Validator is called internally as follows:
    $validator->( <Config::apiLayers Object>, <attribute_name>, <attribute_value> )

Validator Function Example:

    # Accept any value that is not a reference
    [{ "FirstName" => sub{ return $_[2] if !ref $_[2] } }]

=back

=head2 VALIDATOR AS A STRING

=over

If a string/scalar is provided as the validator, it is used as a regex to
test the value. The value is considered to be validated successfully if the
regex match test is true.

Validator Format:
    # The Validator is called similar to:
    if ($value =~ /$validator_string/) { <store the value> }

Validator Example:

    # Accept any value that matches a word
    [{ "FirstName" => "\w" }]
    [{ name => "FirstName", validator => "\w" }]
    [{ name => "FirstName", validator => "\w", description => "The first name" }]

=back


=head1 EXAMPLES

=head2 Use Config::apiLayers with Getopt::Long and Getopt::LongUsage

    use Getopt::Long;
    use Getopt::LongUsage;
    use Config::apiLayers;

    # Note the missing getoptlong configuration and description for area attribute
    my $cfg = new Config::apiLayers({
        autoproto => 1,
        attributes => [
            { name        => 'length',
              validator   => sub { return $_[2] > 0 ? $_[2] : undef },
              getoptlong  => 'length|l:i',
              description => "The length of a rectangle"
            },
            { name        => 'width',
              validator   => sub { return $_[2] > 0 ? $_[2] : undef },
              getoptlong  => 'width|w:i',
              description => "The width of a rectangle"
            },
            { name        => 'area',
              validator   => sub { return undef }  # do not allow storing any value
            }
        ]
    });
    # Set the default values
    $cfg->config({
        data => {
            'length' => 6,
            'width' => 10,
            'area' => sub {
                my $cfg = shift;
                return ($cfg->apicall('length') * $cfg->apicall('width'))
            }
        }
    });

    my $getoptlong_config = $cfg->exportdata({ cfg => 'getoptlong' });
    my $attr_descriptions = $cfg->exportdata({ cfg => 'descriptions' });

    my %options;
    my @getoptconf = (  \%options,
                        @{$getoptlong_config},
                        'verbose|v',
                        'help|h'
                        );
    my $usage = sub {
        my @getopt_long_configuration = @_;
        GetLongUsage (
            'cli_use'       => ($0 ." [options]"),
            'descriptions'  =>
                [   @{$attr_descriptions},
                    'verbose'       => "verbose",
                    'help'          => "this help message"
                    ],
            'Getopt_Long'   => \@getopt_long_configuration,
        );
    };
    GetOptions( @getoptconf ) || die ($usage->( @getoptconf ),"\n");
    $cfg->add_layer();
    $cfg->importdata({ data => \%options }) || die ($usage->( @getoptconf ),"\n");
    print "Area is: ",$cfg->area,"\n";

Example outputs:

    linux$ ./test_it.pl --not-an-option
    Unknown option: not-an-option
    ./test_it.pl [options]
      --length       The length
      --width        The width
      -v, --verbose  verbose
      -h, --help     this help message

    linux$ ./test_it.pl --width=101
    Area is: 606


=head1 AUTHOR

Russell E Glaue, http://russ.glaue.org

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015-2016 Russell E Glaue,
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
