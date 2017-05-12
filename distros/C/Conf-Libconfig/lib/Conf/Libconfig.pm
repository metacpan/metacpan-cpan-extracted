package Conf::Libconfig;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Conf::Libconfig', $VERSION);

sub add {
   my ($self, $path, $key, $item) = @_;
   return unless defined $item;
   my $ref = ref $item;
   my $subpath = join '.', grep { $_ ne '' } $path, $key;
   if (!$ref) {
	  $item !~ m'^0b0?[0-1]$' ?  $self->add_scalar($path, $key, $item)
		  : $self->add_boolscalar($path, $key, eval $item);
   }
   elsif ($ref eq 'ARRAY') {
      $self->add_list($path, $key, []);
      for my $ii (0 .. $#{$item}) {
         $self->add($subpath, "[$ii]", $item->[$ii]);
      }
   }
   elsif ($ref eq 'HASH') {
      $self->add_hash($path, $key, {});
      for my $subkey (keys %$item) {
         $self->add($subpath, $subkey, $item->{$subkey});
      }
   }
   else {
      return;
   }
   return 1;
}

1;
__END__

=head1 NAME

Conf::Libconfig - Perl extension for libconfig

=head1 SYNOPSIS

  use Conf::Libconfig;
  my $self = new Conf::Libconfig;
  $self->read_file($cfg);
  $self->read_string("test:{key = \"only for test!\";};");
  my $value = $self->lookup_value("abc.edf");
  print $value;

  use Data::Dumper;
  my $arrayref = $self->fetch_array("cdef.abcd.arrayref");
  print Dumper $arrayref;
  my $hashref = $self->fetch_hashref("cdef.abcd.hashref");
  print Dumper $hashref;

  $self->add("fghj.rtyu", "binarykey", "0b1");
  $self->add_boolscalar("fghj.rtyu", "binarykey", 0);

  # if program is over, DESTROY can auto exit, and you can ignore function delete. 
  $self->delete();

=head1 DESCRIPTION

You can use C<Conf::Libconfig> for perl config, and support Scalar, Array and Hash data structures etc.
like C or C++ function. C<Conf::Libconfig> could reduce your config file and quote by C/C++ transportability.

=head2 EXPORT

None by default.

=head2 $self->new()

construct.

=head2 $self->delete()

destruct.

=head2 $self->DESTROY()

destruct and auto release memory.

=head2 $self->getversion()

get current libconfig version.

=head2 $self->read($buffer)

read a handle buffer.

=head2 $self->read_file ($file)

read from a config file.

=head2 $self->read_string ($string)

read from a string, require libconfig version > 1.4.

=head2 $self->write($buffer)

write to a handle buffer.

=head2 $self->write_file($filename)

write to a file.

=head2 $self->get_include_dir()

get a include directory, like @include './conf/config.cfg', and get a absolute path, require libconfig version > 1.4.

=head2 $self->set_include_dir($path)

set a include directory, you can search the content of @include in $path, require libconfig version > 1.4.

=head2 $self->lookup_value ($path)

automatically check and get value from config file, suggest use it.

=head2 $self->setting_lookup ($path)

return setting resource.

=head2 $self->fetch_array ($path)

return array list from path.

=head2 $self->fetch_hashref ($path)

return hash reference from path.

=head2 $self->add($path, $key, $item)

add a struct data for $key.

=head2 $self->add_boolscalar($path, $key, $boolvalue)

add a bool value for $key.

=head2 $self->add_scalar ($path, $key, $value)

add a pair of key and value node to handle and return true if add successfully.

=head2 $self->modify_scalar ($path, $value)

modify new value to handle and return true if add successfully.

=head2 $self->modify_boolscalar ($path, $value)

modify new bool value to handle and return true if add successfully.

=head2 $self->add_array ($path, $key, \@array)

add array value to handle and return true if add successfully.

=head2 $self->add_list ($path, $key, \@list)

the same as B<add_array>, add list value to handle and return true if add successfully.

=head2 $self->add_hash ($path, $key, \%hash)

add hash value to handle and return true if add successfully.

=head2 $self->add_boolhash ($path, $key, \%hash)

add bool hash value to handle and return true if add successfully.

=head2 $self->delete_node ($path)

return true if delete node of path successfully.

=head2 $self->delete_node_key ($path, $key)

return true if delete node key of path successfully.

=head2 $self->delete_node_elem ($path, $idx)

return true if delete node element of path successfully.

=head2 $setting->length ()

return count of setting resource.

=head2 $setting->get_item ($i)

return value of the $i item.

=head2 $setting->get_type ()

return value type of setting resource.

=head2 $self->lookup_bool ($path)

only get value type of bool from config file, please use lookup_value replace it.

=head2 $self->lookup_int ($path)

only get value type of long int from config file, please use lookup_value replace it.

=head2 $self->lookup_int64 ($path)

only get value type of long long int from config file, please use lookup_value replace it.

=head2 $self->lookup_float ($path)

only get value type of float from config file, please use lookup_value replace it.

=head2 $self->lookup_string ($path)

only get value type of string from config file, please use lookup_value replace it.

=head1 PREREQUISITES

This module requires the libconfig library from
L<http://www.hyperrealm.com/libconfig/>.

=head1 SOURCE CONTROL

You can always get the latest Conf::Libconfig source from its
public Git repository:

    http://github.com/cnangel/Conf-Libconfig/tree/master

If you have a branch for me to pull, please let me know ;)

=head1 TO DO

=over

=item *

Support xml config and yaml config.

=back

=head1 SEE ALSO

You can compare this module L<Conf::Libconfig> to L<Config>, L<Config::General>, L<Config::JSON>.

http://my.huhoo.net/

=head1 AUTHOR

Cnangel, E<lt>cnangel@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This module as well as its programs are licensed under the BSD License.

Copyright (c) 2009, Alibaba Search Center, Alibaba Inc. All rights reserved.

Copyright (C) 2009 by cnangel

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

=over

=item *

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item *

Neither the name of the Alibaba Search Center, Alibaba Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

=head2 DISCLAIMER OF WARRANTY

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
