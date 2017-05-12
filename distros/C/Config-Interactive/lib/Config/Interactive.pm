package Config::Interactive;
use strict;
use warnings;
use 5.006_001;

=head1 NAME

Config::Interactive -  config module with support for interpolation, XML fragments and interactive UI

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 DESCRIPTION

This module opens a config file and parses it's contents for you. The  I<new()> method
accepts several parameters. The method  'parse'  returns a hash reference
which contains all options and it's associated values of your config file as well as comments above.
If the dialog mode is set then at the moment of parsing user will be prompted to enter different value and
if validation pattern for this particular key was defined then it will be validated and user could be asked to
enter different value if it failed.
The format of config files supported by L<Config::Interactive> is   
C<< <name>=<value> >> pairs or XML fragments (by L<XML::Simple>,  namespaces are not supported) and comments are any line which starts with #.
Comments inside of XML fragments will pop-up on top of the related fragment. It will interpolate any perl variable 
which looks as C< ${?[A-Za-z]\w+}? >.
Please not that interpolation works for XML fragments as well, BUT interpolated varialbles MUST be defined
by C<key=value> definition and NOT inside of other XML fragment!
The order of appearance of such variables in the config file is not important, means you can use C<$bar> variable anywhere in the config file but
set it to something on the last line (or even skip setting it at all , then it will be undef).
It stores internally config file contents as hash ref where data structure is:
Please note that array ref is used to store XML text elements and scalar for attributes.

   
   ( 'key1' => {'comment' => "#some comment\n#more comments\n", 
                'value' => 'Value1',
                'order' => '1',
              },
   'key2' => {'comment' => "#some comment\n#more comments\n", 
              'value' =>  'Value2',
              'order' => '2'
             },
    
   'XMLRootKey' =>  {'comment' => "#some comment\n#more comments\n",
                     'order' => '3',
                     'value' =>  { 
                                   'xmlAttribute1' => 'attribute_value',
                                   'subXmlKey1' =>    ['sub_xml_value1'],
                                   'subXmlKey2' =>    ['sub_xml_value2'],
                                   'subXmlKey3'=>     ['sub_xml_value3'],	
                   }	      
     }
   ) 
  

The normalized ( flat hash with only key=value pairs ) view of the config could be obtained by getNormalizedData() call.
All tree- like options will be flatted as key1_subkey1_subsubkey1. So the structure above will be converted into:

  ('key1' => 'Value1', 
   'key2' =>   'Value2', 
   'XMLRootKey_xmlAttribute1' => 'attribute_value',
   'XMLRootKey_subXmlKey1' =>  'sub_xml_value1' ,
   'XMLRootKey_subXmlKey2' =>   'sub_xml_value2',
   'XMLRootKey_subXmlKey3'=>    'sub_xml_value3' , )    

the case of the key will be preserved.			

=head1 SYNOPSIS

Provides a convenient way for loading	config values from a given file and
returns it as a hash structure, allows interpolation for the simple perl scalars C<( $xxxx ${xxx} )>
Also, it can run interactive session with user, use predefined prompts, use validation patterns
and store back into the file, preserving the order of original comments.
Motivation behind this module was inspired by L<Config::General> module which was missing required
functionality (preservation of the comments order and positioining, prompts and validation for 
command line based UI ). Basically, this is I<Yet-Another-Config-Module> with list of features found to be useful.

     use Config::Interactive;
     
     # define prompts for the keys
     my %CONF_prompts = ('username' =>  'your favorite username ',
                         'password'=>   'most secure password ever ', 
                         );
     
     my %validkeys = ('username' =>    ' your favorite username ',
                      'password'=>   '  most secure password ever ', 
                     );
     
     # Read in configuration information from some.config file 
     
     
     my $conf = Config::Interactive->new({file => 'some.conf', 
                                          prompts => \%CONF_prompts, 
                                          validkeys => \%validkeys,
                                          dialog => '1'}); 
     # OR
     # set interactive mode
       $conf->setDialog(1);
     #
     #   use dialog prompts from this hashref
       $conf->setPrompts(\%CONF_prompts); 
     #   
     #  set delimiter
     $conf->setDelimiter('='); # this is default delimiter
     #
     #   use validation patterns from this hashref
     $conf->setValidkeys(\%validkeys ); 			   
     #   parse it, interpolate variables and ask user abour username and password, validate entered values
      
     $conf->parse();
    
     # store config file back, preserving original order and comments  
     $conf->store; 			 


=head1 METHODS


=head2 new({})

creates new object, accepts hash ref as parameters 

Possible ways to call B<new()>:

  $conf = new Config::Interactive(); 
  
  # create object and will parse/store it within the my.conf file
  $conf = new Config::Interactive({file => "my.conf"}); 
  
  # use current hash ref with options
  $conf = new Config::Interactive({ file => "my.conf", data => $hashref });  
  
  # prompt user to enter new value for every -key- which held inside of  %prompts_hash  
  $conf = new Config::Interactive({ file => "my.conf", dialog => 'yes', prompts => \%promts_hash }); 
   
  # set delimiter as '?'... and validate every new value against the validation pattern
  $conf = new Config::Interactive({ file => "my.conf", dialog => 'yes', delimiter => '?',
                          prompts => \%promts_hash, validkeys => \%validation_patterns }); 

This method returns a B<Config::Interactive> object (a hash blessed into C<Config::Interactive> namespace.
All further methods must be used from that returned object. see below.
Please note that setting dialog option into the "true" is not enough, because the method 
will look only for the keys defined in the C<%prompts_hash> 
An alternative way to call B<new({})> is supplying an option C<-hash> with  hash reference to the set of  the options.

=over

=item B<debug>

 prints a lot of internal stuff if set to something defined

=item B<file>

 name of the  config file

 file => "my.conf"


=item B<data>

  A hash reference, which will be used as the config, i.e.:

  data => \%somehash,  

where %somehash should be formatted as:

     ( 'key1' => {'comment' => "#some comment\n#more comments\n", 
                  'value' => 'Value1',
                  'order' => '1',
                 },
                        
       'key2' => {'comment' => "#some comment\n#more comments\n", 
                  'value' =>  'Value2',
                  'order' => '2'
                 },
      
       'XML_root_key' =>  {'comment' => "#some comment\n#more comments\n",
                           'order' => '3',
                           'value' =>  { 
                                        'xml_attribute_1' => 'attribute_value',
                                        'sub_xml_key1' =>    ['sub_xml_value1'],
                                        'sub_xml_key2' =>    ['sub_xml_value2'],
                                        'sub_xml_key3'=>     ['sub_xml_value3'],	  
                                       } 
                                   
                         }
    )

=item B<dialog>

Set up an interactive mode, Please note that setting dialog option into the I<true> is not enough,
because this method will look only for the keys defined in the C<%prompts_hash> ,  

=item B<delimiter>

Default delimiter is C<=>. Any single character from this list  C<= : ; + ! # ?  - *>   is accepted. 
Please be careful with : since it could  be part of some URL for example.

=item B<prompts>

Hash ref with prompt text for  particular -key- ,   
where hash should be formatted as:

     ('key1' =>   ' Name of the key 1',
      'key2' =>   'Name of the key 2 ',
      'key3' =>  ' Name of the key 3 ', 
      'sub_xml_key1' =>  'Name of the key1   ',
      'sub_xml_key2' =>  ' Name of the key2 ' ,
      )

It will reuse the same prompt  for the same key name.
				   
=item B<validkeys>

Hash ref with  validation patterns  for  particular -key-  
where hash should be formatted as:

     ( 'key1' =>   '\w+',
       'key2' =>   '\d+',
       'key3' =>  '\w\w\:\w\w\:\w\w\:\w\w\:\w\w\:\w\w\', 
       'sub_xml_key1' =>  '\d+',
       'sub_xml_key2' =>  '\w+' ,
       
       
    ) 

It will reuse the same validation pattern  for the same key name as well.	

=back

=cut

use XML::Simple;
use Carp;
use Data::Dumper;
use fields qw(file debug delimiter data dialog validkeys prompts);
 

sub new {
    my ($that, $param) = @_;
    my $class = ref($that) || $that;
    my $self =  fields::new($class);
    
    if ($param) {
        croak( "ONLY hash ref accepted as param and not: " . Dumper $param ) unless  ref($param) eq 'HASH' ;
        $self->{debug} = $param->{debug} if  $param->{debug}; 
	foreach my $key  (qw/file  delimiter data dialog validkeys prompts/) {
            if($param->{$key}) {
	        $self->{$key} = $param->{$key};   
                print " Set parameter: \n" if  $self->{debug};
	    }  
	}
    }
    $self->{delimiter} = '=' unless $self->{delimiter};
    return $self;
}

=head2  setDelimiter()

    set delimiter from the list of supported delimiters  [\=\+\!\#\:\;\-\*] , 

=cut

sub setDelimiter {
    my ( $self, $sep ) = @_;

    if ( !$sep || $sep !~ /^[\=\+\!\#\:\;\-\*]$/ ) {
        croak("Delimiter is not supported or missed: $sep");
    }
    $self->{delimiter} = $sep;
    return $sep;
}

=head2  setDialog()

    set interactive mode (any defined value)
    accepts: single parameter - any defined
    returns: current state

=cut

sub setDialog {
    my ( $self, $dia ) = @_;
    $self->{dialog} = $dia;
    return $dia;
}

=head2  setFile()  

    set  config file name
    accepts: single parameter - filename
    returns: current filename
    
=cut

sub setFile {
    my ($self, $file) = @_;
    unless ( $file && -e $file ) {
        croak(" File name is missing or does not exist ");
    }
    $self->{file} = $file;
    return $self->{file};
}

=head2  setValidkeys()

    set  vaildation patterns hash
    accepts: single parameter - reference to hash with validation keys
    returns: reference to hash with validation keys
    
=cut

sub setValidkeys {
    my ( $self, $vk ) = @_;
    unless ( $vk && ref($vk) eq 'HASH' ) {
        croak(" Validation hash ref is misssing ");
    }
    $self->{validkeys} = $vk;
    return $self->{validkeys};
}

=head2  setPrompts()

    set  prompts hash
    accepts: single parameter - reference to hash with prompts  
    returns: reference to hash with  prompts 
    
=cut

sub setPrompts {
    my ( $self, $prompts ) = @_;
    unless ( $prompts && ref($prompts) eq 'HASH' ) {
        croak(" Prompts hash ref is misssing ");
    }
    $self->{prompts} = $prompts;
    return $self->{prompts};

}

=head2   getNormalizedData()

  This method returns a  normalized hash ref, see explanation above.
  the complex key will be normalized
       'key1' => { 'key2' =>   'value' }
   will be returned as 'key1_key2' => 'value'
   accepts; nothing
   returns: hash ref with normalized config data

=cut

sub getNormalizedData {
    my $self = shift;
    return _normalize( $self->{data} );
}

=head2  store() 
  
  Store into the config file,  preserve all comments from the original file
  Accepts filename as  argument
  Possible ways to call B<store()>:

  $conf->store("my.conf"); #store into the my.conf file, if -file was defined at the object creation time, then this will overwrite it
   
  $conf->store();  

=cut

sub store {
    my ( $self, $filen ) = @_;
    my $file_to_store = ( defined $filen ) ? $filen : $self->{file};

    open OUTF, "+>$file_to_store"
      or croak(" Failed to store config file: $file_to_store");
    foreach my $key (
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [ $self->{data}->{$_}{order}, $_ ] } keys %{ $self->{data} }
      )
    {
        my $comment =
            $self->{data}->{$key}{comment}
          ? $self->{data}->{$key}{comment}
          : "#\n";
        my $value = (
              $self->{data}->{$key}{pre}
            ? $self->{data}->{$key}{pre}
            : $self->{data}->{$key}{value}
        );

        carp(" This option  $key is : " . Dumper $value) if $self->{debug};
	 
        if ( ref($value) eq 'HASH' ) {
	    my $xml_out =  $self->{data}->{$key}{value};
	    foreach my $arg (keys %{$self->{data}->{$key}{pre}}) {
	        $xml_out->{$arg}  = $self->{data}->{$key}{pre}->{$arg};
	    }
            print OUTF $comment . XMLout( $xml_out , RootName => $key ) . "\n";
        }
        else {
            print OUTF $comment . $key . $self->{delimiter} . "$value\n";
            carp( $comment . $key . $self->{delimiter} . $value )
              if $self->{debug};
        }
    }
    close OUTF;
}

=head2  parse()

   Parse config file, return hash ref ( optional)
   Accepts filename as  argument

   Possible ways to call B<parse()>:

  $config_hashref = $conf->parse("my.conf"); # parse  my.conf file, if -file was defined at the object creation time, then this will overwrite -file option
 
  $config_hashref = $conf->parse();  
  
  This method returns a  a hash ref.

=cut

sub parse {
    my ( $self, $filen ) = @_;
    my $file_to_open = ( defined $filen && -e $filen ) ? $filen : $self->{file};

    open INF, "<$file_to_open"
        or croak(" Failed to open config file: $file_to_open");
    print("File $file_to_open opened for parsing ") if $self->{debug};
    my %config     = ();
    my $comment    = undef;
    my $order      = 1;
    my $xml_start  = undef;
    my $xml_config = undef;
    my $pattern    = '^([\w\.\-]+)\s*\\' . $self->{delimiter} . '\s*(.+)';

    # parsing every line from the config file, removing extra spaces
    while (<INF>) {
        chomp;
        s/^\s+?//;
        if (m/^\#/xsm) {
            $comment .= "$_\n";
        }
        else {
            s/\s+$//g;

            # if not inside of XML and if this is start of XML
            if ( !$xml_start && m/^\<\s*([\w\-]+)\b?[^\>]*\>/xsm ) {
                $xml_start = $1;
                $xml_config .= $_;
            }
            # elsif  inside of XML
            elsif ($xml_start) {
                if (m/^\<\/\s*($xml_start)\s*\>/xsm) {
                    $xml_config .= $_;
                    my $xml_cf =  XMLin( $xml_config, KeyAttr => {}, ForceArray => 1 );
                    $config{$xml_start}{value} = $self->_parseXML($xml_cf);
                    carp " Parsed XML fragment: "  . Dumper $config{$xml_start}{value}  if $self->{debug};
                    if ($comment) {
                        $config{$xml_start}{comment} = $comment;
                        $comment = '';
                    }
                    $config{$xml_start}{order} = $order++;
                    $xml_start = undef;
                }
                else {
                    $xml_config .= $_;
                }
            }

            # elsif  outside of XML, key=value
            elsif (m/$pattern/o) {
                my $key   = $1;
                my $value = $2;
                $config{$key}{value} = $self->_processKey( $key, $value );
                $config{$key}{order} = $order++;
                if ($comment) {
                    $config{$key}{comment} = $comment;
                    $comment = '';
                }
            }
            else {
                print(" ... Just a pattern:$pattern  a string: $_")
                  if $self->{debug};
            }
        }
    }
    close INF;
    print(" interpolating...\n") if $self->{debug};

    #  interpolate all values

    $self->{data} = $self->_interpolate( \%config );
    print( " Config data: \n" . Dumper $self->{data} ) if $self->{debug};
    return $self->{data};
}

#
#  interpolate all values, in case of XML fragments the name of the interpolated variable
#  MUST be set by key=value definition and not by the element from other XML block
#
#
sub _interpolate {
    my ( $self, $config, $scalars, $xml_root ) = @_;
    my @keys = $xml_root ? keys %{ $config->{value} } : keys %{$config};

    #  interpolate all values
    foreach my $key (@keys) {
        ### go for recursion in case of XML fragment
        if ( !$xml_root ) {
            $self->_interpolate( $config->{$key}, $config, $key )
              if ref( $config->{$key}{value} ) eq 'HASH';
            ### interpolate if its simple key=value definition
            my @sub_keys =
              $config->{$key}{value} =~ /[^\\]?\$\{?([a-zA-Z]+(?:\w+)?)\}?/xsmg;
            foreach my $sub_key (@sub_keys) {
                print(
                    " CHECK  " . $config->{$key}{value} . " -> $sub_key  \n" )
                  if $self->{debug};
                if ( $sub_key && $config->{"$sub_key"} ) {
                    my $subst = $config->{"$sub_key"}{value};
                    $config->{$key}{pre} =
                        $config->{$key}{pre}
                      ? $config->{$key}{pre}
                      : $config->{$key}{value};
                    $config->{$key}{value} =~ s/\$\{?$sub_key\}?/$subst/xsmg;
                    carp(  " interpolated "
                          . $config->{$key}{value}
                          . " -> $sub_key -> $subst \n" )
                      if $self->{debug};
                }
            }
        }
        else {
            ## XML keys located under the value key and its single size array in case of element and just scalar for attr
            my $xml_value =
              ref( $config->{value}{$key} ) eq 'ARRAY'
              ? $config->{value}{$key}->[0]
              : $config->{value}{$key};

            my @sub_keys =
              $xml_value =~ /[^\\]?\$\{?([a-zA-Z]+(?:\w+)?)\}?/xsmg;
            foreach my $sub_key (@sub_keys) {
                print( " CHECK  " . $xml_value . " -> $sub_key  \n" )
                  if $self->{debug};
                if ( $sub_key && $scalars->{"$sub_key"} ) {
                    my $subst = $scalars->{"$sub_key"}{value};
                    if ( ref( $config->{value}{$key} ) eq 'ARRAY' ) {
                        $config->{pre}{$key}->[0] =
                            $config->{pre}{$key}->[0]
                          ? $config->{pre}{$key}->[0]
                          : $config->{value}{$key}->[0];

                        $config->{value}{$key}->[0] =~
                          s/\$\{?$sub_key\}?/$subst/xsmg;
                    }
                    else {
                        $config->{pre}{$key} =
                            $config->{pre}{$key}
                          ? $config->{pre}{$key}
                          : $config->{value}{$key};

                        $config->{value}{$key} =~
                          s/\$\{?$sub_key\}?/$subst/xsmg;
                    }
                    carp(  " interpolated "
                          . $xml_value
                          . " -> $sub_key -> $subst \n" )
                      if $self->{debug};
                }
            }
        }
    }
    return $config;
}

#
#  enter prompt on the screen
#
#
sub _promptEnter {
    my $prompt = shift;
    print "$prompt\n";
    my $entered = <STDIN>;
    chomp $entered;
    $entered =~ s/\s+//g;
    return $entered;
}

#
#  recursive walk through the XML::Simple tree
#

sub _parseXML {
    my ( $self, $xml_cf ) = @_;

    foreach my $key ( keys %{$xml_cf} ) {
        if ( ref( $xml_cf->{$key} ) eq 'HASH' ) {
            $xml_cf->{$key} = $self->_parseXML( $xml_cf->{$key} );
        }
        elsif ( ref( $xml_cf->{$key} ) eq 'ARRAY' ) {
            $xml_cf->{$key}->[0] =
              $self->_processKey( $key, $xml_cf->{$key}->[0] );
        }
        else {
            $xml_cf->{$key} = $self->_processKey( $key, $xml_cf->{$key} );
        }
    }
    return $xml_cf;
}

#
#    keys normalization
#  'value' = > { 'key0' => ['value0'],  'key1' => { 'key12' =>   ['value12' ]}, 'key2' => { 'key22' =>   ['value22' ]}}
#

sub _normalize {
    my ( $data, $parent ) = @_;
    my %new_data = ();

    foreach my $key ( keys %{$data} ) {
        my $new_key = $parent ? "$parent\_$key" : $key;

        my $value = $data->{$key};
        if (   ref($value) eq 'HASH'
            && $value->{value}
            && ref( $value->{value} ) eq 'HASH' )
        {
            %new_data =
              ( %new_data,
                %{ _normalize( $data->{$key}->{value}, $new_key ) } );
        }
        elsif ( ref($value) eq 'ARRAY' ) {
            $new_data{$new_key} = $data->{$key}->[0];
        }
        elsif ( ref($value) eq 'HASH' && $value->{value} ) {
            $new_data{$new_key} = $value->{value};
        }
        elsif ( ref($value) eq 'HASH' && !$value->{value} ) {
            $new_data{$new_key} = 0;
        }
        else {
            $new_data{$new_key} = $value;
        }
    }
    return \%new_data;
}

#
#  processing each key entered from the screen
#
#

sub _processKey {
    my ( $self, $key, $value ) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    my $vpattern =
      ( $self->{validkeys} && $self->{validkeys}->{$key} )
      ? qr/$self->{validkeys}->{$key}/
      : undef;
    my $pkey =
      ( $self->{prompts} && $self->{prompts}->{$key} )
      ? $self->{prompts}->{$key}
      : undef;

    if ( $self->{dialog} && $pkey ) {
        my $entered = _promptEnter(
            "  Please enter the value for the $pkey (Default is $value)>");
        while ( $entered && ( $vpattern && $entered !~ $vpattern ) ) {
            $entered = _promptEnter(
"!!! Entered value is  not valid according to regexp: $vpattern , please re-enter>"
            );
        }
        $value = $entered ? $entered : $value;
    }
    if ( $vpattern && $value !~ $vpattern ) {
        croak(
"Parser failed, value:$value for $key is NOT VALID according to pattern:  $vpattern"
        );
    }

    return $value;

}

1;

 __END__


=head1 DEPENDENCIES

L<XML::Simple>, L<Carp>, L<Data::Dumper>


=head1 EXAMPLES 


For example this config file:

 
  # username
  USERNAME = user
  PASSWORD = pass
  #sql config
  <SQL production="1">
      <DB_DRIVER>
                mysql
      </DB_DRIVER>
      <DB_NAME>
                database
      </DB_NAME>
  </SQL>

=head1 SEE ALSO

L<Config::General>

=head1 AUTHOR

Maxim Grigoriev <maxim |AT| fnal.gov>, 2007-2008, Fermilab

=head1 COPYRIGHT

Copyright(c) 2007-2008, Fermi Reasearch Alliance (FRA)   

=head1 LICENSE

You should have received a copy of the Fermitools license 
with this software.  If not, see L<http://fermitools.fnal.gov/about/terms.html>

=cut
