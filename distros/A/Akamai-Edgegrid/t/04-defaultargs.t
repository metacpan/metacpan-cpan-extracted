#!perl -T

#
# Original author: Jonathan Landis <jlandis@akamai.com>
#
# for more info visit https://developer.akamai.com
#

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Akamai::Edgegrid;

plan tests=>2;

my $ua = new Akamai::Edgegrid(client_token=>'xxx', client_secret=>'xxx',
    access_token=>'xxx');

is($ua->{max_body},131072 , 'default max_body=131072');
is_deeply($ua->{headers_to_sign}, [], 'default headers_to_sign=[]');

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Akamai Technologies, Inc. All rights reserved

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut
