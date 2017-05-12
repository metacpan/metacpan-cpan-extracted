package Data::Serializer::Raw;

use warnings;
use strict;
use vars qw($VERSION);
use Carp;

$VERSION = '0.02';

#Global cache of modules we've loaded
my %_MODULES;

my %_fields = (
                serializer => 'Data::Dumper',
                options    => {},
              );
sub new {
        my ($class, %args) = @_;
        my $dataref = {%_fields};
        foreach my $field (keys %_fields) {
                $dataref->{$field} = $args{$field} if exists $args{$field};
        }
        my $self = $dataref;
        bless $self, $class;

	#initialize serializer
	$self->_serializer_obj();

        return $self;
}

sub serializer {
        my $self = (shift);
        my $return = $self->{serializer};
        if (@_) {
                $self->{serializer} = (shift);
		#reinitialize serializer object
		$self->_serializer_obj(1);
        }
        return $return;
}

sub options {
        my $self = (shift);
        my $return = $self->{options};
        if (@_) {
                $self->{options} = (shift);
		#reinitialize serializer object
		$self->_serializer_obj(1);
        }
        return $return;
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


sub _module_loader {
        my $self = (shift);
        my $module_name = (shift);
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

sub _serializer_obj {
        my $self = (shift);
	#if anything is passed in remove previous obj so we will regenerate it
	if (@_) {
		delete $self->{serializer_obj};
	}
	#Return cached serializer object if it exists
	return $self->{serializer_obj} if (exists $self->{serializer_obj});

	my $method = $self->{serializer};
	$self->_module_loader($method,"Data::Serializer");    #load in serializer module if necessary

  	$self->{serializer_obj}->{options} = $self->{options};
	bless $self->{serializer_obj}, "Data::Serializer::$method";
}

sub serialize {
  my $self = (shift);
  my @input = @_;

  return $self->_serializer_obj->serialize(@input);
}


sub deserialize {
  my $self = (shift);
  my $input = (shift);

  return $self->_serializer_obj->deserialize($input);
}

1;
__END__

=pod

=head1 NAME
                
Data::Serializer::Raw - Provides unified raw interface to perl serializers
                
=head1 SYNOPSIS
                
  use Data::Serializer::Raw;
                
  $obj = Data::Serializer::Raw->new();
                
  $obj = Data::Serializer::Raw->new(serializer => 'Storable');

  $serialized = $obj->serialize({a => [1,2,3],b => 5});
  $deserialized = $obj->deserialize($serialized);

  print "$deserialized->{b}\n";

=head1 DESCRIPTION

Provides a unified interface to the various serializing modules
currently available.  

This is a straight pass through to the underlying serializer,
nothing else is done. (no encoding, encryption, compression, etc)
    
=head1 EXAMPLES

=over 4

=item  Please see L<Data::Serializer::Cookbook(3)>

=back

=head1 METHODS

=over 4

=item B<new> - constructor

  $obj = Data::Serializer::Raw->new();


  $obj = Data::Serializer::Raw->new(
                         serializer => 'Data::Dumper',
                           options  => {},
                        );


B<new> is the constructor object for Data::Serializer::Raw objects.

=over 4

=item

The default I<serializer> is C<Data::Dumper>

=item

The default I<options> is C<{}> (pass nothing on to serializer)

=back

=item B<serialize> - serialize reference
        
  $serialized = $obj->serialize({a => [1,2,3],b => 5});
                
This is a straight pass through to the underlying serializer,
nothing else is done. (no encoding, encryption, compression, etc)

=item B<deserialize> - deserialize reference

  $deserialized = $obj->deserialize($serialized);
        
This is a straight pass through to the underlying serializer,
nothing else is done. (no encoding, encryption, compression, etc)

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


=item B<options> - pass options through to underlying serializer

Currently is only supported by L<Config::General(3)>, and L<XML::Dumper(3)>.

  my $obj = Data::Serializer::Raw->new(serializer => 'Config::General',
                                  options    => {
                                             -LowerCaseNames       => 1,
                                             -UseApacheInclude     => 1,
                                             -MergeDuplicateBlocks => 1,
                                             -AutoTrue             => 1,
                                             -InterPolateVars      => 1
                                                },
                                              ) or die "$!\n";

  or

  my $obj = Data::Serializer::Raw->new(serializer => 'XML::Dumper',
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

http://neil-neely.blogspot.com/

=head1 BUGS

Please report all bugs here:

http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Serializer


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Neil Neely.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


See http://www.perl.com/language/misc/Artistic.html

=head1 ACKNOWLEDGEMENTS

Peter Makholm took the time to profile L<Data::Serializer(3)> and pointed out the value
of having a very lean implementation that minimized overhead and just used the raw underlying serializers.

=head1 SEE ALSO

perl(1), Data::Serializer(3).

=cut

