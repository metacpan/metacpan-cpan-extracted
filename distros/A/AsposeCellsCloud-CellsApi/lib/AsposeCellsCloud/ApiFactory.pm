=begin comment

Copyright (c) 2026 Aspose.Cells Cloud
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

package AsposeCellsCloud::ApiFactory;

use strict;
use warnings;
use utf8;

use Carp;
use Module::Find;

usesub AsposeCellsCloud::Object;

use AsposeCellsCloud::ApiClient;

=head1 Name

	AsposeCellsCloud::ApiFactory - constructs APIs to retrieve AsposeCellsCloud objects

=head1 Synopsis

	package My::Petstore::App;

	use AsposeCellsCloud::ApiFactory;

	my $api_factory = AsposeCellsCloud::ApiFactory->new( ... ); # any args for ApiClient constructor

	# later...
	my $pet_api = $api_factory->get_api('Pet');  

	# $pet_api isa AsposeCellsCloud::PetApi

	my $pet = $pet_api->get_pet_by_id(pet_id => $pet_id);

	# object attributes have proper accessors:
	printf "Pet's name is %s", $pet->name;

	# change the value stored on the object:
	$pet->name('Dave'); 

=cut

# Load all the API classes and construct a lookup table at startup time
my %_apis = map { $_ =~ /^AsposeCellsCloud::(.*)$/; $1 => $_ } 
			grep {$_ =~ /Api$/} 
			usesub 'AsposeCellsCloud';

=head1 new($api_client)

	create a new AsposeCellsCloud::ApiFactory instance with the given AsposeCellsCloud::ApiClient instance.

=head1 new(%parameters)

	Any parameters are optional, and are passed to and stored on the api_client object.

	See L<AsposeCellsCloud::ApiClient> and L<AsposeCellsCloud::Configuration> for valid parameters

=cut	

sub new {
    my ($class) = shift;

    my $api_client;
    if ($_[0] && ref $_[0] && ref $_[0] eq 'AsposeCellsCloud::ApiClient' ) {
        $api_client = $_[0];
    } else {
        $api_client = AsposeCellsCloud::ApiClient->new(@_);
    }
    bless { api_client => $api_client }, $class;
}

=head1 get_api($which)

	Returns an API object of the requested type. 

	$which is a nickname for the class: 

		FooBarClient::BazApi has nickname 'Baz'

=cut

sub get_api {
	my ($self, $which) = @_;
	croak "API not specified" unless $which;
	my $api_class = $_apis{"${which}Api"} || croak "No known API for '$which'";
	return $api_class->new($self->api_client); 
}

=head1 api_client()

	Returns the api_client object, should you ever need it.

=cut

sub api_client { $_[0]->{api_client} }

=head1 apis_available()
=cut 

sub apis_available { return map { $_ =~ s/Api$//; $_ } sort keys %_apis }

=head1 classname_for()
=cut

sub classname_for {
	my ($self, $api_name) = @_;
	return $_apis{"${api_name}Api"};
}


1;
