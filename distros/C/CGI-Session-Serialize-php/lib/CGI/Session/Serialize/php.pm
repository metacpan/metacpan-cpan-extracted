# Copyright (c) 2012 Ian McWilliam <kaosgnt@gmail.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package CGI::Session::Serialize::php;

use strict;
use warnings;
use CGI::Session::ErrorHandler;
use PHP::Session::Serializer::PHP;

# Debug
#use Data::Dumper;

@CGI::Session::Serialize::php::ISA = ('CGI::Session::ErrorHandler');
$CGI::Session::Serialize::php::VERSION = '1.1';

sub freeze {
	my $self = shift;
	my $data = shift;

	my $serializer = PHP::Session::Serializer::PHP->new();
	my $serialized_string = '';

	eval {$serialized_string = $serializer->encode($data)};

	if ($@) {
		$self->set_error('freeze(): Error decoding data : ' . "$@");
		return(undef);
	}

	# Debug
	#warn($serialized_string);

	return($serialized_string);
}

sub thaw {
	my $self = shift;
	my $string = shift;

	my $serializer = PHP::Session::Serializer::PHP->new();
	my $deserialized_data = {};

	eval {$deserialized_data = $serializer->decode($string)};

	if ($@) {
		$self->set_error('thaw(): Error decoding data : ' . "$@");
		return(undef);
	}

	# Debug
	#warn(Dumper($deserialized_data));

	return($deserialized_data);
}

1;

__END__;

=pod

=head1 NAME

CGI::Session::Serialize::php - PHP serializer for CGI::Session

=head1 DESCRIPTION

This library can be used by CGI::Session to serialize session data. It is a wrapper around 
the C<PHP::Session::Serializer::PHP>. Use of this serializer allows common session data 
storage when writing Web Applications in both Perl and PHP. NOTE: you will need to store the 
Session ID in your PHP session data structure as
$_SESSION['_SESSION_ID'] = session_id(); 
as the return from the C<thaw()> method is checked for it's existance. C<CGI::Session> will 
croak with the error "Invalid data structure returned from thaw()" if it is not seen. Be careful 
storing arrays as arrays look like hashes once serialized and deserialized. You will need extra 
logic to convert them back to arrays again.
Don't forget to add 'serializer:php' to your C<CGI::Session> initialization string.

=head1 METHODS

=over 4

=item freeze($class, \%session_data_hash)

Receives two arguments. First is the class name, the second is the session data to be serialized. 
Should return serialized string on success, undef on failure. 
Error message should be set using C<set_error()|CGI::Session::ErrorHandler/"set_error()">

=item thaw($class, $php_serialized_string)

Receives two arguments. First is the class name, second is the C<PHP> serialized data string.
Should return deserialized session data structure on success, undef on failure. 
Error message should be set using C<set_error()|CGI::Session::ErrorHandler/"set_error()">

=back

=head1 SEE ALSO

C<CGI::Session>, C<PHP::Session::Serializer::PHP>.

=cut