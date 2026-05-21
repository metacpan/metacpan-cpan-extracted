package Conf::Libconfig;

use 5.006001;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '1.1.2';

require XSLoader;
XSLoader::load('Conf::Libconfig', $VERSION);

use constant {
    CONFIG_FORMAT_DEFAULT => 0,
    CONFIG_FORMAT_HEX     => 1,
    CONFIG_FORMAT_BIN     => 2,
    CONFIG_FORMAT_OCT     => 3,

    CONFIG_OPTION_AUTOCONVERT                     => 0x01,
    CONFIG_OPTION_SEMICOLON_SEPARATORS            => 0x02,
    CONFIG_OPTION_COLON_ASSIGNMENT_FOR_GROUPS     => 0x04,
    CONFIG_OPTION_COLON_ASSIGNMENT_FOR_NON_GROUPS => 0x08,
    CONFIG_OPTION_OPEN_BRACE_ON_SEPARATE_LINE     => 0x10,
    CONFIG_OPTION_ALLOW_SCIENTIFIC_NOTATION       => 0x20,
    CONFIG_OPTION_FSYNC                           => 0x40,
    CONFIG_OPTION_ALLOW_OVERRIDES                 => 0x80,
};

our @EXPORT_OK = qw(
    CONFIG_FORMAT_DEFAULT CONFIG_FORMAT_HEX CONFIG_FORMAT_BIN CONFIG_FORMAT_OCT
    CONFIG_OPTION_AUTOCONVERT
    CONFIG_OPTION_SEMICOLON_SEPARATORS
    CONFIG_OPTION_COLON_ASSIGNMENT_FOR_GROUPS
    CONFIG_OPTION_COLON_ASSIGNMENT_FOR_NON_GROUPS
    CONFIG_OPTION_OPEN_BRACE_ON_SEPARATE_LINE
    CONFIG_OPTION_ALLOW_SCIENTIFIC_NOTATION
    CONFIG_OPTION_FSYNC
    CONFIG_OPTION_ALLOW_OVERRIDES
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

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
  my $value = $self->value("abc.edf");
  my $value = $self->lookup_value("abc.edf"); // deprecated
  print $value;

  use Data::Dumper;
  my $arrayref = $self->fetch_array("cdef.abcd.arrayref");
  print Dumper $arrayref;
  my $hashref = $self->fetch_hashref("cdef.abcd.hashref");
  print Dumper $hashref;

  $self->set_boolean_value("key", "value");
  $self->set_value("key", "value");
  $self->set_value("key", 12.34); // can modify the key
  my $svalue = { "a" => 123 };
  $self->set_value("abcde", $svalue); // can use reference
  $self->add("fghj.rtyu", "binarykey", "0b1");
  $self->add_boolscalar("fghj.rtyu", "binarykey", 0);

  # 1.8.x new features
  $self->set_options(CONFIG_OPTION_FSYNC | CONFIG_OPTION_ALLOW_OVERRIDES);
  $self->set_float_precision(4);
  $self->set_default_format(CONFIG_FORMAT_HEX);
  my $err = $self->error_text();
  my $line = $self->error_line();
  $self->clear();

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

=head2 $self->set_value ($path, $value)

automatically check and set value, the value can be a I<scalar value> or I<reference value>, suggest use it.

=head2 $self->set_boolean_value($path, $value)

automatically check and set boolean value, the value can be a I<scalar value> or I<string value>(B<True>/B<False>), suggest use it.

=head2 $self->value ($path)

automatically check and get value from config file, suggest use it.

=head2 $self->lookup_value ($path)

automatically check and get value from config file, the API will be deprecated.

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

add array value to handle and return true if add successfully, but the elements must all be scalar values of the same type.

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

=head2 $self->set_options($options)

set multiple options at once (libconfig >= 1.8). Combine options with bitwise OR, e.g. C<CONFIG_OPTION_FSYNC | CONFIG_OPTION_ALLOW_OVERRIDES>.

=head2 $self->get_options()

get the current options bitmask (libconfig >= 1.8).

=head2 $self->set_option($option, $flag)

set or clear a single option (libconfig >= 1.8).

=head2 $self->get_option($option)

get the current flag for a single option (libconfig >= 1.8).

=head2 $self->set_auto_convert($flag)

enable or disable automatic type conversion (libconfig >= 1.8).

=head2 $self->get_auto_convert()

get the current auto-convert flag (libconfig >= 1.8).

=head2 $self->set_float_precision($digits)

set the number of decimal digits for float output (libconfig >= 1.8). B<$digits> is an unsigned short (0-65535).

=head2 $self->get_float_precision()

get the current float precision (libconfig >= 1.8).

=head2 $self->set_tab_width($width)

set the tab width for indentation in output (libconfig >= 1.8).

=head2 $self->get_tab_width()

get the current tab width (libconfig >= 1.8).

=head2 $self->set_default_format($format)

set the default format for integer output. Valid formats: C<CONFIG_FORMAT_DEFAULT>, C<CONFIG_FORMAT_HEX>, C<CONFIG_FORMAT_BIN>, C<CONFIG_FORMAT_OCT>.

=head2 $self->get_default_format()

get the current default integer format.

=head2 $self->set_hook($hook)

set a custom hook pointer on the config object.

=head2 $self->get_hook()

get the custom hook pointer.

=head2 $self->clear()

clear all configuration contents without destroying the config object (libconfig >= 1.8).

=head2 $self->error_text()

get the last error text message.

=head2 $self->error_file()

get the file name where the last error occurred.

=head2 $self->error_line()

get the line number where the last error occurred.

=head2 $self->error_type()

get the last error type: 0 = none, 1 = file I/O, 2 = parse error.

=head2 $self->getversion()

get current libconfig version.

=head2 $self->set_include_func($func)

set a custom include function callback (libconfig >= 1.8).

=head2 $self->set_destructor($func)

set a custom destructor callback for the config object.

=head2 $self->set_fatal_error_func($func)

set a global fatal error handler callback. This is a class method -- it affects all config instances (libconfig >= 1.8).

=head2 $setting->lookup ($path)

lookup a setting by path from this setting (libconfig >= 1.8).

=head2 $setting->lookup_int ($name)

lookup an int value by name from this setting (libconfig >= 1.8).

=head2 $setting->lookup_int64 ($name)

lookup an int64 value by name from this setting (libconfig >= 1.8).

=head2 $setting->lookup_bool ($name)

lookup a bool value by name from this setting (libconfig >= 1.8).

=head2 $setting->lookup_float ($name)

lookup a float value by name from this setting (libconfig >= 1.8).

=head2 $setting->lookup_string ($name)

lookup a string value by name from this setting (libconfig >= 1.8).

=head2 $setting->get_int_safe ()

safely get int value, returns 0 on type mismatch (libconfig >= 1.8).

=head2 $setting->get_int64_safe ()

safely get int64 value, returns 0 on type mismatch (libconfig >= 1.8).

=head2 $setting->get_float_safe ()

safely get float value, returns 0.0 on type mismatch (libconfig >= 1.8).

=head2 $setting->get_bool_safe ()

safely get bool value, returns 0 on type mismatch (libconfig >= 1.8).

=head2 $setting->get_string_safe ()

safely get string value, returns empty string on type mismatch (libconfig >= 1.8).

=head2 $setting->set_format ($format)

set the numeric format for this setting (libconfig >= 1.8). See C<CONFIG_FORMAT_*> constants.

=head2 $setting->get_format ()

get the numeric format of this setting (libconfig >= 1.8).

=head2 $setting->is_scalar ()

returns true if this setting is a scalar type (int, int64, float, bool, string).

=head2 $setting->is_aggregate ()

returns true if this setting is an aggregate type (group, array, list).

=head2 $setting->is_group ()

returns true if this setting is a group.

=head2 $setting->is_array ()

returns true if this setting is an array.

=head2 $setting->is_list ()

returns true if this setting is a list.

=head2 $setting->is_number ()

returns true if this setting is a numeric type (int, int64, float).

=head2 $setting->name ()

get the name of this setting.

=head2 $setting->parent ()

get the parent setting, or NULL for root.

=head2 $setting->is_root ()

returns true if this setting is the root.

=head2 $setting->index ()

get the index of this setting within its parent.

=head2 $setting->source_line ()

get the source file line number where this setting was defined.

=head2 $setting->source_file ()

get the source file name where this setting was defined.

=head2 $setting->set_hook ($hook)

set a custom hook pointer on this setting (libconfig >= 1.4).

=head2 $setting->get_hook ()

get the custom hook pointer from this setting (libconfig >= 1.4).

=head2 $setting->length ()

return count of setting resource.

=head2 $setting->get_item ($i)

return value of the $i item.

=head2 $setting->get_elem ($idx)

return the child setting at index $idx as a Settings object.

=head2 $setting->get_type ()

return value type of setting resource.

=head2 $self->lookup_bool ($path)

only get value type of bool from config file, please use B<value> replace it.

=head2 $self->lookup_int ($path)

only get value type of long int from config file, please use B<value> replace it.

=head2 $self->lookup_int64 ($path)

only get value type of long long int from config file, please use B<value> replace it.

=head2 $self->lookup_float ($path)

only get value type of float from config file, please use B<value> replace it.

=head2 $self->lookup_string ($path)

only get value type of string from config file, please use B<value> replace it.

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
