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

plan tests => 4;

my @required = qw(client_token client_secret access_token);

sub test_missing {
    my $missing = shift;
    my %args = map { $_ => 'xxx' } grep { $_ ne $missing } @required;
    eval {
        new Akamai::Edgegrid(%args); 
    };
    if ($@) {
        my $msg = $@;
        like($msg, qr/^missing required argument $missing/, "missing $missing");
    }
}

eval {
    new Akamai::Edgegrid();
};
if ($@) {
    my $msg = $@;
    like($msg, qr/^missing required argument/, 'missing all');
}

for my $a (@required) {
    test_missing($a);
}

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
