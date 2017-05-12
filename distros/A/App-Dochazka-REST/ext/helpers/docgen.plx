#!/usr/bin/perl
# ************************************************************************* 
# Copyright (c) 2014, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# App::Dochazka::REST server executable
#
# -------------------------------------------------------------------------

use 5.014;
use strict;
use warnings;

use App::CELL qw( $site );
use App::Dochazka::REST;
use App::Dochazka::REST::Dispatch;
use Data::Dumper;
use Web::MREST;
use Web::MREST::Dispatch;
use Web::MREST::InitRouter qw( $resources );

my $dispatch_object = bless {}, 'App::Dochazka::REST::Dispatch';

sub init {
    my $status = Web::MREST::init( distro => 'App-Dochazka-REST' );
    die $status->text unless $status->ok;

    my $status = Web::MREST::init( 
        distro => 'App-Dochazka-REST', 
        sitedir => '/etc/dochazka-rest', 
    );
    return $status;
}

sub print_usage {
    print "Usage: perl bin/docgen.plx\n";
    print "(must be run from within App::Dochazka::REST distribution)\n";
}

sub print_documentation {
    my ( $fh, $resource ) = @_;

    my %no_expand_map = map { ( $_ => '' ) } @Web::MREST::InitRouter::non_expandable_properties;
    my $r = $resources->{$resource};

    print $fh "\n", "=head2 C<< $resource >>", "\n\n"; 
    
    # get allowed methods
    #
    my @am;
    foreach my $prop ( keys %$r ) {
        next if exists $no_expand_map{ $prop };
        push @am, $prop;
    }   

    print $fh $r->{'description'}, "\n";
    print $fh "=over\n\n";
    print $fh "Allowed methods: " . join( ', ', sort( @am ) ) . "\n\n";
    my $docs = $r->{'documentation'};
    $docs =~ s/=pod\n\n//;
    print $fh $docs, "\n";
    print $fh "\n=back\n";

    return;
}

my $dest = './lib/App/Dochazka/REST/Docs';
if ( ! -e $dest ) {
   print_usage();
   exit 0;
}

print "App::Dochazka::REST version $App::Dochazka::REST::VERSION\n";
print "Initializing\n";
my $status = init();
print $status->text unless $status->ok;
$dispatch_object->init_router;
print "Log messages will be written to " . $site->DOCHAZKA_REST_LOG_FILE .  "\n";

# open file for writing
my $fp = "$dest/Resources.pm";
print "Generating $fp\n";
open( my $fh, ">", $fp );

# copyright notice, preamble
print $fh $site->DOCHAZKA_DOCGEN_COPYRIGHT_NOTICE, "\n";
print $fh $site->DOCHAZKA_DOCGEN_PREAMBLE;

# version section
print $fh <<"EOH";
1;
__END__
EOH

print $fh "\n", $site->DOCHAZKA_DOCGEN_POD_PREAMBLE, "\n";

sub walk {
    my $resource = shift;

    print_documentation( $fh, $resource );

    my @children = grep { $resources->{$_}->{'parent'} eq $resource } sort keys( %$resources );

    foreach my $child ( @children ) {
        walk( $child );
    }
}

# recursively walk the tree, starting from the root resource
walk( '/' );

print $fh "\n", $site->DOCHAZKA_DOCGEN_EPITAPH;

print "Done.\n";
