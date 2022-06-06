=begin comment

Copyright (c) 2019 Aspose Pty Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=end comment

=cut

package AsposeSlidesCloud::Configuration;

use strict;
use warnings;
use utf8;

sub new {
	my ($self, %p) = (shift,@_);

	# authentication setting
	$p{app_sid} //= "";
	$p{app_key} //= "";

	$p{access_token} //= "";

	# base_url
        $p{base_url} //= 'https://api.aspose.cloud';
        $p{auth_base_url} //= 'https://api.aspose.cloud';
        $p{version} //= 'v3.0';

	# class/static variables
	$p{timeout} //= 0;
	$p{http_request_timeout} //= 3000;
	$p{debug} //= 0;
	$p{custom_headers} //= {};

	return bless \%p => $self;
}

1;
