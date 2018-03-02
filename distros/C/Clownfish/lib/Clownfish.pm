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

use strict;
use warnings;

package Clownfish;

use 5.008003;

our $VERSION = '0.006003';
$VERSION = eval $VERSION;
our $MAJOR_VERSION = 0.006000;

use Exporter 'import';
BEGIN {
    our @EXPORT_OK = qw( to_clownfish );
}

# On most UNIX variants, this flag makes DynaLoader pass RTLD_GLOBAL to
# dl_open, so extensions can resolve the needed symbols without explicitly
# linking against the DSO.
sub dl_load_flags { 1 }

BEGIN {
    require DynaLoader;
    our @ISA = qw( DynaLoader );
    # This loads a large number of disparate subs.
    bootstrap Clownfish '0.6.3';
}

sub error {$Clownfish::Err::error}

{
    package Clownfish::Obj;
    our $VERSION = '0.006003';
    $VERSION = eval $VERSION;
    use Carp qw( confess );
    # Clownfish objects are not thread-safe.
    sub CLONE_SKIP { 1; }
    sub STORABLE_freeze {
        my $class_name = ref(shift);
        confess("Storable serialization not implemented for $class_name");
    }
    sub STORABLE_thaw {
        my $class_name = ref(shift);
        confess("Storable serialization not implemented for $class_name");
    }
}

{
    package Clownfish::Class;
    our $VERSION = '0.006003';
    $VERSION = eval $VERSION;

    sub _find_parent_class {
        my $package = shift;
        no strict 'refs';
        for my $parent ( @{"$package\::ISA"} ) {
            return $parent if $parent->isa('Clownfish::Obj');
        }
        return;
    }

    sub _fresh_host_methods {
        my $package = shift;
        no strict 'refs';
        my $stash = \%{"$package\::"};
        my $methods
            = Clownfish::Vector->new( capacity => scalar keys %$stash );
        while ( my ( $symbol, $entry ) = each %$stash ) {
            # A subroutine is stored in the CODE slot of a typeglob. Since
            # Perl 5.28 it may also be stored as a coderef.
            next unless ref($entry) eq 'CODE'
                        || ( ref(\$entry) eq 'GLOB' && *$entry{CODE} );
            $methods->push( Clownfish::String->new($symbol) );
        }
        return $methods;
    }

    sub _register {
        my ( $singleton, $parent ) = @_;
        my $singleton_class = $singleton->get_name;
        my $parent_class    = $parent->get_name;
        if ( !$singleton_class->isa($parent_class) ) {
            no strict 'refs';
            push @{"$singleton_class\::ISA"}, $parent_class;
        }
    }

    no warnings 'redefine';
    sub CLONE_SKIP { 0; }
    sub DESTROY { }    # leak all
}

{
    package Clownfish::Method;
    our $VERSION = '0.006003';
    $VERSION = eval $VERSION;
    no warnings 'redefine';
    sub CLONE_SKIP { 0; }
    sub DESTROY { }    # leak all
}

{
    package Clownfish::Err;
    our $VERSION = '0.006003';
    $VERSION = eval $VERSION;
    sub do_to_string { shift->to_string }
    use Scalar::Util qw( blessed );
    use Carp qw( confess longmess );
    use overload
        '""'     => \&do_to_string,
        fallback => 1;

    sub new {
        my ( $either, $message ) = @_;
        my ( undef, $file, $line ) = caller;
        $message .= ", $file line $line\n";
        return $either->_new( mess => Clownfish::String->new($message) );
    }

    sub do_throw {
        my $err      = shift;
        my $longmess = longmess();
        $longmess =~ s/^\s*/\t/;
        $err->cat_mess($longmess);
        die $err;
    }

    our $error;
    sub set_error {
        my $val = $_[1];
        if ( defined $val ) {
            confess("Not a Clownfish::Err")
                unless ( blessed($val)
                && $val->isa("Clownfish::Err") );
        }
        $error = $val;
    }
    sub get_error {$error}
}

{
    package Clownfish::Boolean;
    our $VERSION = '0.006003';
    $VERSION = eval $VERSION;
    use Exporter 'import';
    our @EXPORT_OK = qw( $true_singleton $false_singleton );
    our $true_singleton  = Clownfish::Boolean->singleton(1);
    our $false_singleton = Clownfish::Boolean->singleton(0);
}

1;

