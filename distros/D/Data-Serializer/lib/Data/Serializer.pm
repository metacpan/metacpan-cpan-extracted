package Data::Serializer;

use warnings;
use strict;
use vars qw($VERSION);

use Carp;
require 5.004 ;

$VERSION = '0.65';

#Global cache of modules we've loaded
my %_MODULES;

my %_fields = (
                serializer => 'Data::Dumper',
                digester   => 'SHA-256',
                cipher     => 'Blowfish',
                encoding   => 'hex',
                compressor => 'Compress::Zlib',
                secret     => undef,
                portable   => '1',
                compress   => '0',
                raw        => '0',
                options    => {},
          serializer_token => '1',
              );
sub new {
	my ($class, %args) = @_;
	my $dataref = {%_fields};
	foreach my $field (keys %_fields) {
		$dataref->{$field} = $args{$field} if exists $args{$field};
	}
	my $self = $dataref;
	bless $self, $class;

	#preintitialize serializer object
  	$self->_serializer_obj();
	return $self;
}

sub _serializer_obj {
        my $self = (shift);
	my $method = (shift);
	my $reset = (shift);

	my $serializer = $self->{serializer};

	#remove cache if asked to
	if ($reset) {
                delete $self->{serializer_obj};
	}

	#If we're given the same method that we are already using, nothing to change
	if (defined $method && $method ne $serializer) {
		$serializer = $method;
	} else {
		#safe to return our cached object if we have it
        	return $self->{serializer_obj} if (exists $self->{serializer_obj});
	}

        $self->_module_loader($serializer,"Data::Serializer");    #load in serializer module if necessary
	my $serializer_obj = {};
        $serializer_obj->{options} = $self->{options};
        bless $serializer_obj, "Data::Serializer::$serializer";

	#Cache it for later retrieval only if this is the default serializer for the object
	#ugly logic to support legacy token method that would allow the base to have a different serializer
	#than what it is reading

	if ($serializer eq $self->{serializer}) {
		$self->{serializer_obj} = $serializer_obj;
	}
	return $serializer_obj;

}

sub _persistent_obj {
        my $self = (shift);
        return $self->{persistent_obj} if (exists $self->{persistent_obj});
  	$self->_module_loader('Data::Serializer::Persistent');	
        my $persistent_obj = { parent => $self };
        bless $persistent_obj, "Data::Serializer::Persistent";
        $self->{persistent_obj} = $persistent_obj;
        return $persistent_obj;
                
}



sub serializer {
	my $self = (shift);
	my $return = $self->{serializer};
	if (@_) {
		$self->{serializer} = (shift);
		#Reinitialize object
  		$self->_serializer_obj($self->{serializer}, 1);
	}
	return $return;
}

sub digester {
	my $self = (shift);
	my $return = $self->{digester};
	if (@_) {
		my $value = (shift);
		$self->{digester} = $value;
	}
	return $return;
}

sub cipher {
	my $self = (shift);
	my $return = $self->{cipher};
	if (@_) {
		$self->{cipher} = (shift);
	}
	return $return;
}

sub compressor {
	my $self = (shift);
	my $return = $self->{compressor};
	if (@_) {
		$self->{compressor} = (shift);
	}
	return $return;
}

sub secret {
	my $self = (shift);
	my $return = $self->{secret};
	if (@_) {
		$self->{secret} = (shift);
	}
	return $return;
}

sub encoding {
	my $self = (shift);
	my $return = $self->{encoding};
	if (@_) {
		$self->{encoding} = (shift);
	}
	return $return;
}

sub portable {
	my $self = (shift);
	my $return = $self->{portable};
	if (@_) {
		$self->{portable} = (shift);
	}
	return $return;
}

sub options {
	my $self = (shift);
	my $return = $self->{options};
	if (@_) {
		$self->{options} = (shift);
		#Reinitialize object
  		$self->_serializer_obj($self->{serializer}, 1);
	}
	return $return;
}

sub compress {
	my $self = (shift);
	my $return = $self->{compress};
	if (@_) {
		$self->{compress} = (shift);
	}
	return $return;
}

sub raw {
	my $self = (shift);
	my $return = $self->{raw};
	if (@_) {
		$self->{raw} = (shift);
	}
	return $return;
}

sub serializer_token {
	my $self = (shift);
	my $return = $self->{serializer_token};
	if (@_) {
		$self->{serializer_token} = (shift);
	}
	return $return;
}

sub _module_loader {
	my $self = (shift);
	my $module_name = (shift);
	unless (defined $module_name) {
		confess "Something wrong - module not defined! $! $@\n";
	}
	return if (exists $_MODULES{$module_name});
	if (@_) {
		$module_name = (shift) . "::$module_name";
	}
	my $package = $module_name;
	$package =~ s|::|/|g;
	$package .= ".pm";
	eval { require $package };
	if ($@) {
		carp "Data::Serializer error: " . 
		 "Please make sure $package is a properly installed package.\n";
		return undef;
	}
	$_MODULES{$module_name} = 1;
}





sub _serialize {
  my $self = (shift);
  my @input = @{(shift)};#original @_
  my $method = (shift);
  $self->_module_loader($method,"Data::Serializer");	#load in serializer module if necessary
  my $serializer_obj = $self->_serializer_obj($method);
  return $serializer_obj->serialize(@input);
}

sub _compress {
  my $self = (shift);
  $self->_module_loader($self->compressor);	
  if ($self->compressor eq 'Compress::Zlib') {
    return Compress::Zlib::compress((shift));
  } elsif ($self->compressor eq 'Compress::PPMd') {
    my $compressor = Compress::PPMd::Encoder->new();
    return $compressor->encode((shift));
  }
}
sub _decompress {
  my $self = (shift);
  $self->_module_loader($self->compressor);	
  if ($self->compressor eq 'Compress::Zlib') {
    return Compress::Zlib::uncompress((shift));
  } elsif ($self->compressor eq 'Compress::PPMd') {
    my $compressor = Compress::PPMd::Decoder->new();
    return $compressor->decode((shift));
  }
}

sub _create_token {
  my $self = (shift);
  return '^' . join('|', @_) . '^';
}
sub _get_token {
  my $self = (shift);
  my $line = (shift);
  #Should be anchored to beginning
  #my ($token) =  $line =~ /\^([^\^]+?)\^/;
  my ($token) =  $line =~ /^\^([^\^]{1,120}?)\^/;
  return $token;
}
sub _extract_token {
  my $self = (shift);
  my $token = (shift);
  return split('\|',$token);
}
sub _remove_token {
  my $self = (shift);
  my $line = (shift);
  $line =~ s/^\^[^\^]{1,120}?\^//;
  return $line;
}
sub _deserialize {
  my $self = (shift);
  my $input = (shift);
  my $method = (shift);
  $self->_module_loader($method,"Data::Serializer");	#load in serializer module if necessary
  my $serializer_obj = $self->_serializer_obj($method);
  $serializer_obj->deserialize($input);
}

sub _encrypt {
  my $self = (shift);
  my $value = (shift);
  my $cipher = (shift);
  my $digester = (shift);
  my $secret = $self->secret;
  croak "Cannot encrypt: No secret provided!" unless defined $secret;
  $self->_module_loader('Crypt::CBC');	
  my $digest = $self->_endigest($value,$digester);
  my $cipher_obj = Crypt::CBC->new($secret,$cipher);
  return $cipher_obj->encrypt($digest);
}
sub _decrypt {
  my $self = (shift);
  my $input = (shift);
  my $cipher = (shift);
  my $digester = (shift);
  my $secret = $self->secret;
  croak "Cannot encrypt: No secret provided!" unless defined $secret;
  $self->_module_loader('Crypt::CBC');	
  my $cipher_obj = Crypt::CBC->new($secret,$cipher);
  my $digest = $cipher_obj->decrypt($input);
  return $self->_dedigest($digest,$digester);
}
sub _endigest {
  my $self = (shift);
  my $input = (shift);
  my $digester = (shift);
  $self->_module_loader('Digest');	
  my $digest = $self->_get_digest($input,$digester);
  return "$digest=$input";
}
sub _dedigest {
  my $self = (shift);
  my $input = (shift);
  my $digester = (shift);
  $self->_module_loader('Digest');	
  #my ($old_digest) = $input =~ /^([^=]+?)=/;
  $input =~ s/^([^=]+?)=//;
  my $old_digest = $1;
  return undef unless (defined $old_digest);
  my $new_digest = $self->_get_digest($input,$digester);
  return undef unless ($new_digest eq $old_digest);
  return $input;
}
sub _get_digest {
  my $self = (shift);
  my $input = (shift);
  my $digester = (shift);
  my $ctx = Digest->new($digester);
  $ctx->add($input);
  return $ctx->hexdigest;
}
sub _enhex {
  my $self = (shift);
  return join('',unpack 'H*',(shift));
}
sub _dehex {
  my $self = (shift);
  return (pack'H*',(shift));
}

sub _enb64 {
  my $self = (shift);
  $self->_module_loader('MIME::Base64');	
  my $b64 = MIME::Base64::encode_base64( (shift), '' );
  return $b64;
}


sub _deb64 {
  my $self = (shift);
  $self->_module_loader('MIME::Base64');	
  return MIME::Base64::decode_base64( (shift) );
}

# do all 3 stages
sub freeze { (shift)->serialize(@_); }
sub thaw { (shift)->deserialize(@_); }

sub serialize {
  my $self = (shift);
  my ($serializer,$cipher,$digester,$encoding,$compressor) = ('','','','','');

  if ($self->raw) {
    return $self->raw_serialize(@_);
  }

  #we always serialize no matter what.

  #define serializer for token
  $serializer = $self->serializer;
  my $value = $self->_serialize(\@_,$serializer);

  if ($self->compress) {
    $compressor = $self->compressor;
    $value = $self->_compress($value);
  }

  if (defined $self->secret) {
    #define digester for token
    $digester = $self->digester;
    #define cipher for token
    $cipher = $self->cipher;
    $value = $self->_encrypt($value,$cipher,$digester);
  }
  if ($self->portable) {
    $encoding = $self->encoding;
    $value = $self->_encode($value);
  }
  if ($self->serializer_token) {
    my $token = $self->_create_token($serializer,$cipher, $digester,$encoding,$compressor);
    $value = $token . $value;
  }
  return $value;
}

sub store {
	my $self = (shift);
	my $persistent = $self->_persistent_obj();
	$persistent->_store(@_);
}

sub retrieve {
	my $self = (shift);
	my $persistent = $self->_persistent_obj();
	$persistent->_retrieve(@_);
}

sub raw_serialize {
  my $self = (shift);
  my $serializer = $self->serializer;
  return $self->_serialize(\@_,$serializer);
}

sub _encode {
  my $self = (shift);
  my $value = (shift);
  my $encoding = $self->encoding;
  if ($encoding eq 'hex') {
    return $self->_enhex($value);
  } elsif ($encoding eq 'b64') {
    return $self->_enb64($value);
  } else {
    croak "Unknown encoding method $encoding\n";
  }
}

sub _decode {
  my $self = (shift);
  my $value = (shift);
  my $encoding = (shift);
  if ($encoding eq 'hex') {
    return $self->_dehex($value);
  } elsif ($encoding eq 'b64') {
    return $self->_deb64($value);
  } elsif ($encoding !~ /\S/) {
    #quietly ignore empty encoding
    return $value;
  } else {
    croak "Unknown encoding method $encoding\n";
  }
}

sub raw_deserialize {
  my $self = (shift);
  my $serializer = $self->serializer;
  return $self->_deserialize((shift),$serializer);
}

sub deserialize {
  my $self = (shift);

  if ($self->raw) {
    return $self->raw_deserialize(@_);
  }

  my $value = (shift);
  my $token = $self->_get_token($value);
  my ($serializer,$cipher, $digester,$encoding, $compressor); 
  my $compress = $self->compress;
  if (defined $token) {
    ($serializer,$cipher, $digester,$encoding, $compressor) = $self->_extract_token($token); 

    #if compressor is defined and has a value then we must decompress it
    $compress = 1 if ($compressor);
    $value = $self->_remove_token($value);
  } else {
    $serializer = $self->serializer;
    $cipher = $self->cipher;
    $digester = $self->digester;
    $compressor = $self->compressor;
    if ($self->portable) {
      $encoding = $self->encoding;
    }
  }
  if (defined $encoding) {
    $value = $self->_decode($value,$encoding);
  } 
  if (defined $self->secret) {
    $value = $self->_decrypt($value,$cipher,$digester);
  }
  if ($compress) {
    $value = $self->_decompress($value);
  }
  #we always deserialize no matter what.
  my @return = $self->_deserialize($value,$serializer);
  return wantarray ? @return : $return[0];
}

1;
__END__

#Documentation follows

=pod

=head1 NAME

Data::Serializer:: - Modules that serialize data structures

=head1 SYNOPSIS

  use Data::Serializer;
  
  $obj = Data::Serializer->new();

  $obj = Data::Serializer->new(
                          serializer => 'Storable',
                          digester   => 'MD5',
                          cipher     => 'DES',
                          secret     => 'my secret',
                          compress   => 1,
                        );

  $serialized = $obj->serialize({a => [1,2,3],b => 5});
  $deserialized = $obj->deserialize($serialized);
  print "$deserialized->{b}\n";

=head1 DESCRIPTION

Provides a unified interface to the various serializing modules
currently available.  Adds the functionality of both compression
and encryption. 

By default L<Data::Serializer(3)> adds minor metadata and encodes serialized data
structures in it's own format.  If you are looking for a simple unified
pass through interface to the underlying serializers then look into L<Data::Serializer::Raw(3)> 
that comes bundled with L<Data::Serializer(3)>.

=head1 EXAMPLES

=over 4

=item  Please see L<Data::Serializer::Cookbook(3)>

=back

=head1 METHODS

=over 4

=item B<new> - constructor

  $obj = Data::Serializer->new();


  $obj = Data::Serializer->new(
                         serializer => 'Data::Dumper',
                         digester   => 'SHA-256',
                         cipher     => 'Blowfish',
                         secret     => undef,
                         portable   => '1',
                         compress   => '0',
                   serializer_token => '1',
                           options  => {},
                        );


B<new> is the constructor object for L<Data::Serializer(3)> objects.  

=over 4

=item

The default I<serializer> is C<Data::Dumper>

=item

The default I<digester> is C<SHA-256>

=item

The default I<cipher> is C<Blowfish>

=item

The default I<secret> is C<undef>

=item

The default I<portable> is C<1>

=item

The default I<encoding> is C<hex>

=item

The default I<compress> is C<0>

=item

The default I<compressor> is C<Compress::Zlib>

=item

The default I<serializer_token> is C<1>

=item

The default I<options> is C<{}> (pass nothing on to serializer)

=back

=item B<serialize> - serialize reference

  $serialized = $obj->serialize({a => [1,2,3],b => 5});

Serializes the reference specified.  

Will compress if compress is a true value.

Will encrypt if secret is defined.

=item B<deserialize> - deserialize reference

  $deserialized = $obj->deserialize($serialized);

Reverses the process of serialization and returns a copy 
of the original serialized reference.

=item B<freeze> - synonym for serialize

  $serialized = $obj->freeze({a => [1,2,3],b => 5});

=item B<thaw> - synonym for deserialize

  $deserialized = $obj->thaw($serialized);

=item B<raw_serialize> - serialize reference in raw form

  $serialized = $obj->raw_serialize({a => [1,2,3],b => 5});

This is a straight pass through to the underlying serializer,
nothing else is done. (no encoding, encryption, compression, etc)

If you desire this functionality you should look at L<Data::Serializer::Raw(3)> instead, it is 
faster and leaner.

=item B<raw_deserialize> - deserialize reference in raw form

  $deserialized = $obj->raw_deserialize($serialized);

This is a straight pass through to the underlying serializer,
nothing else is done. (no encoding, encryption, compression, etc)

If you desire this functionality you should look at L<Data::Serializer::Raw(3)> instead, it is 
faster and leaner.

=item B<secret> - specify secret for use with encryption

  $obj->secret('mysecret');

Changes setting of secret for the L<Data::Serializer(3)> object.  Can also be set
in the constructor.  If specified than the object will utilize encryption.

=item B<portable> - encodes/decodes serialized data

Uses B<encoding> method to ascii armor serialized data

Aids in the portability of serialized data. 

=item B<compress> - compression of data

Compresses serialized data.  Default is not to use it.  Will compress if set to a true value
  $obj->compress(1);

=item B<raw> - all calls to serializer and deserializer will automatically use raw mode

Setting this to a true value will force serializer and deserializer to work in raw mode 
(see raw_serializer and raw_deserializer).  The default is for this to be off.

If you desire this functionality you should look at L<Data::Serializer::Raw(3)> instead, it is 
faster and leaner.

=item B<serializer> - change the serializer

Currently supports the following serializers: 

=over 4

=item L<Bencode(3)>

=item L<Convert::Bencode(3)>

=item L<Convert::Bencode_XS(3)>

=item L<Config::General(3)>

=item L<Data::Denter(3)>

=item L<Data::Dumper(3)>

=item L<Data::Taxi(3)>

=item L<FreezeThaw(3)>

=item L<JSON(3)>

=item L<JSON::Syck(3)>

=item L<PHP::Serialization(3)>

=item L<Storable(3)>

=item L<XML::Dumper(3)>

=item L<XML::Simple(3)>

=item L<YAML(3)>

=item L<YAML::Syck(3)>

=back

Default is to use Data::Dumper.



Each serializer has its own caveat's about usage especially when dealing with
cyclical data structures or CODE references.  Please see the appropriate
documentation in those modules for further information.

=item B<cipher> - change the cipher method

Utilizes L<Crypt::CBC(3)> and can support any cipher method that it supports.

=item B<digester> - change digesting method

Uses L<Digest(3)> so can support any digesting method that it supports.  Digesting
function is used internally by the encryption routine as part of data verification.

=item B<compressor> - changes compresing module

Currently L<Compress::Zlib(3)> and L<Compress::PPMd(3)> are the only options

=item B<encoding> - change encoding method

Encodes data structure in ascii friendly manner.  Currently the only valid options
are hex, or b64. 

The b64 option uses Base64 encoding provided by L<MIME::Base64(3)>, but strips out newlines.

=item B<serializer_token> - add usage hint to data

L<Data::Serializer(3)> prepends a token that identifies what was used to process its data.
This is used internally to allow runtime determination of how to extract serialized
data.  Disabling this feature is not recommended.   (Use L<Data::Serializer::Raw(3)> instead).

=item B<options> - pass options through to underlying serializer

Currently is only supported by L<Config::General(3)>, and L<XML::Dumper(3)>.  

  my $obj = Data::Serializer->new(serializer => 'Config::General',
                                  options    => {
                                             -LowerCaseNames       => 1,
                                             -UseApacheInclude     => 1,
                                             -MergeDuplicateBlocks => 1,
                                             -AutoTrue             => 1,
                                             -InterPolateVars      => 1
                                                },
                                              ) or die "$!\n";

  or

  my $obj = Data::Serializer->new(serializer => 'XML::Dumper',
                                  options    => { dtd => 1, }
                                  ) or die "$!\n";

=item B<store> - serialize data and write it to a file (or file handle)

  $obj->store({a => [1,2,3],b => 5},$file, [$mode, $perm]);

  or 

  $obj->store({a => [1,2,3],b => 5},$fh);


Serializes the reference specified using the B<serialize> method
and writes it out to the specified file or filehandle.  

If a file path is specified you may specify an optional mode and permission as the
next two arguments.  See L<IO::File> for examples.

Trips an exception if it is unable to write to the specified file.

=item B<retrieve> - read data from file (or file handle) and return it after deserialization 

  my $ref = $obj->retrieve($file);

  or 

  my $ref = $obj->retrieve($fh);

Reads first line of supplied file or filehandle and returns it deserialized.

=back

=head1 AUTHOR

Neil Neely <F<neil@neely.cx>>.

Feature requests are certainly welcome. 

http://neil-neely.blogspot.com/

=head1 BUGS

Please report all bugs here:

http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Serializer

=head1 TODO

Extend the persistent framework.  Perhaps  L<Persistent::Base(3)> framework
would be useful to explore further.  Volunteers for putting this together
would be welcome.



=head1 COPYRIGHT AND LICENSE

Copyright (c) 2001-2020 Neil Neely.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


See http://www.perl.com/language/misc/Artistic.html

=head1 ACKNOWLEDGEMENTS 

Gurusamy Sarathy and Raphael Manfredi for writing L<MLDBM(3)>,
the module which inspired the creation of L<Data::Serializer(3)>.

And thanks to all of you who have provided the feedback 
that has improved this module over the years.

In particular I'd like to thank Florian Helmberger, for the 
numerous suggestions and bug fixes.

=head1 DEDICATION

This module is dedicated to my beautiful wife Erica. 

=head1 REPOSITORY

L<http://github.com/neilneely/Data-Serializer/>

=head1 SEE ALSO

=over 4

=item L<Bencode(3)>

=item L<Convert::Bencode(3)>

=item L<Convert::Bencode_XS(3)>

=item L<Config::General(3)>

=item L<Data::Denter(3)>

=item L<Data::Dumper(3)>

=item L<Data::Taxi(3)>

=item L<FreezeThaw(3)>

=item L<JSON(3)>

=item L<JSON::Syck(3)>

=item L<PHP::Serialization(3)>

=item L<Storable(3)>

=item L<XML::Dumper(3)>

=item L<XML::Simple(3)>

=item L<YAML(3)>

=item L<YAML::Syck(3)>

=item L<Compress::Zlib(3)>

=item L<Compress::PPMd(3)>

=item L<Digest(3)>

=item L<Digest::SHA(3)>

=item L<Crypt::CBC(3)>

=item L<MIME::Base64(3)>

=item L<IO::File(3)>

=item L<Data::Serializer::Config::Wrest(3)> - adds supports for L<Config::Wrest(3)>

=back

=cut
