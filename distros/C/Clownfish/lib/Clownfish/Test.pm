# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Clownfish::Test;
use Clownfish;
our $VERSION = '0.006003';
$VERSION = eval $VERSION;

sub dl_load_flags { 1 }

BEGIN {
    require DynaLoader;
    our @ISA = qw( DynaLoader );
    bootstrap Clownfish::Test '0.6.3';
}

sub run_tests {
    my $class_name = shift;
    my $formatter  = Clownfish::TestHarness::TestFormatterTAP->new();
    my $suite      = Clownfish::Test::create_test_suite();

    return $suite->run_batch(
        class_name => $class_name,
        formatter  => $formatter,
    );
}

1;

__END__


