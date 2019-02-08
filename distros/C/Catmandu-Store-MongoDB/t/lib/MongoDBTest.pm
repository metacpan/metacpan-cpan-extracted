#
#  Copyright 2009-2013 10gen, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

package MongoDBTest;

use strict;
use warnings;

use Exporter 'import';
use MongoDB;
use Test::More;

our @EXPORT_OK = ('$conn');
our $conn;

# set up connection if we can
BEGIN {
    eval {
        my $host = exists $ENV{MONGOD} ? $ENV{MONGOD} : 'localhost';
        $conn = MongoDB->connect(
            $host,
            {
                ssl                         => $ENV{MONGO_SSL},
                socket_timeout_ms           => 60000,
                server_selection_timeout_ms => 2000,
            }
        );
        my $topo = $conn->_topology;
        $topo->scan_all_servers;
        my $link;
        eval {$link = $topo->get_writable_link} or die "couldn't connect";
        $conn->get_database("admin")->run_command({serverStatus => 1})
            or die "Database has auth enabled\n";
        my $server = $link->server;
        if (  !$ENV{MONGOD}
            && $topo->type eq 'Single'
            && $server->type =~ /^RS/)
        {
            # direct connection to RS member on default, so add set name
            # via MONGOD environment variable for subsequent use
            $ENV{MONGOD}
                = "mongodb://localhost/?replicaSet=" . $server->set_name;
        }
    };

    if ($@) {
        (my $err = $@) =~ s/\n//g;
        if ($err =~ /couldn't connect|connection refused/i) {
            $err = "no mongod on " . ($ENV{MONGOD} || "localhost:27017");
            $err .= ' and $ENV{MONGOD} not set' unless $ENV{MONGOD};
        }
        plan skip_all => "$err";
        exit 0;
    }
}

# clean up any detritus from failed tests
END {
    return unless $conn;
    $conn->get_database('test_database')->drop;
}

1;

