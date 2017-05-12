package Benchmark::Serialize::Library;

use strict;
use warnings;

use UNIVERSAL::require qw();
use Carp;

=head1 NAME

Benchmark::Serialize::Library - Library of serialization modules

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Benchmark::Serialize::Library;

    Benchmark::Serialize::Library->register(
        MyModule => {
            deflate => sub { MyModule::deflate( $_[0] ) },
            inflate => sub { MyModule::inflate( $_[0] ) },
        }
    );

    my %benchmarks = Benchmark::Serialize::Library->load( ":all" );

=head1 DESCRIPTION

This module contains a library of serialization routines for use with Benchmark::Serialize

=cut

my $benchmarks = {
    'AnyMongo::BSON' => {
        deflate => sub { AnyMongo::BSON::bson_encode( $_[0] )    },
        inflate => sub { AnyMongo::BSON::bson_decode( $_[0] )    },
    },
    'Bencode' => {
        deflate  => sub { Bencode::bencode($_[0])                },
        inflate  => sub { Bencode::bdecode($_[0])                }
    },    
    'Convert::Bencode' => {
        deflate  => sub { Convert::Bencode::bencode($_[0])       },
        inflate  => sub { Convert::Bencode::bdecode($_[0])       }
    },
    'Convert::Bencode_XS' => {
        deflate  => sub { Convert::Bencode_XS::bencode($_[0])    },
        inflate  => sub { Convert::Bencode_XS::bdecode($_[0])    }
    },
    'Data::asXML' => {
        deflate  => sub { Data::asXML->new(pretty=>0)->encode($_[0])->toString },
        inflate  => sub { Data::asXML->new(pretty=>0)->decode($_[0]) },
        xml      => 1,
    },
    'Data::Dumper' => {
        deflate  => sub { Data::Dumper->Dump([ $_[0] ])          },
        inflate  => sub { my $VAR1; eval $_[0]                   },
        default  => 1,
        core     => 1,
    },
    'Data::MessagePack' => {
        deflate  => sub { Data::MessagePack->pack($_[0])         },
        inflate  => sub { Data::MessagePack->unpack($_[0])       },
    },
    'Data::Taxi' => {
        deflate  => sub { Data::Taxi::freeze($_[0])              },
        inflate  => sub { Data::Taxi::thaw($_[0])                },
        xml      => 1,
    },
    'Data::Pond' => {
        deflate  => sub { Data::Pond::pond_write_datum($_[0])    },
        inflate  => sub { Data::Pond::pond_read_datum($_[0])     },
    },
    'Data::Pond,eval' => {
        deflate  => sub { Data::Pond::pond_write_datum($_[0])    },
        inflate  => sub { eval($_[0])                            },
        packages => ['Data::Pond'],
    },
    'FreezeThaw' => {
        deflate  => sub { FreezeThaw::freeze($_[0])              },
        inflate  => sub { FreezeThaw::thaw($_[0])                },
        default  => 1
    },
    'JSON::PP' => {
        deflate  => sub { JSON::PP::encode_json($_[0])           },
        inflate  => sub { JSON::PP::decode_json($_[0])           },
        default  => 1,
        json     => 1
    },
    'JSON::XS' => {
        deflate  => sub { JSON::XS::encode_json($_[0])           },
        inflate  => sub { JSON::XS::decode_json($_[0])           },
        default  => 1,
        json     => 1
    },
    'JSON::XS,pretty' => {
        deflate  => sub { $_[1]->encode( $_[0] ) },
        inflate  => sub { $_[1]->decode( $_[0] ) },
        args     => sub { JSON::XS->new->pretty(1)->allow_blessed(1)->convert_blessed(1)->canonical(1) },
        json     => 1,
        packages => ['JSON::XS'],
    },
    'JSON::DWIW' => {
        deflate  => sub { JSON::DWIW->to_json($_[0])             },
        inflate  => sub { JSON::DWIW::deserialize($_[0])         },
        json     => 1,
    },
    'JSYNC' => {
        deflate  => sub { JSYNC::dump($_[0])                     },
        inflate  => sub { JSYNC::load($_[0])                     },
    },
    'Storable' => {
        deflate  => sub { Storable::nfreeze($_[0])               },
        inflate  => sub { Storable::thaw($_[0])                  },
        default  => 1,
        core     => 1,
    },
    'PHP::Serialization' => {
        deflate  => sub { PHP::Serialization::serialize($_[0])   },
        inflate  => sub { PHP::Serialization::unserialize($_[0]) }
    },
    'PHP::Serialization::XS' => {
        deflate  => sub { PHP::Serialization::XS::serialize($_[0])   },
        inflate  => sub { PHP::Serialization::XS::unserialize($_[0]) }
    },
    'RPC::XML' => {
        deflate  => sub { RPC::XML::response->new($_[0])->as_string         },
        inflate  => sub { RPC::XML::ParserFactory->new->parse($_[0])->value },
        packages => ['RPC::XML', 'RPC::XML::ParserFactory'],
        xml      => 1,
    },
    'YAML::Old' => {
        deflate  => sub { YAML::Old::Dump($_[0])                 },
        inflate  => sub { YAML::Old::Load($_[0])                 },
        default  => 1,
        yaml     => 1
    },
    'YAML::XS' => {
        deflate  => sub { YAML::XS::Dump($_[0])                  },
        inflate  => sub { YAML::XS::Load($_[0])                  },
        default  => 1,
        yaml     => 1
    },
    'YAML::Tiny' => {
        deflate  => sub { YAML::Tiny::Dump($_[0])                },
        inflate  => sub { YAML::Tiny::Load($_[0])                },
        default  => 1,
        yaml     => 1
    },
    'XML::Simple' => {
        deflate  => sub { XML::Simple::XMLout($_[0])             },
        inflate  => sub { XML::Simple::XMLin($_[0])              },
        default  => 1,
        xml      => 1,
    },
    'XML::TreePP' => {
        deflate => sub { XML::TreePP->new()->write( $_[0] )      },
        inflate => sub { XML::TreePP->new()->parse( $_[0] )      },
        xml     => 1,
    },
};

=head2 Library methods

This class provides the following methods

=over 5

=item register( NAME => SPECIFICATION )

Registers a new benchmarkable form of serialization. A specification is a 
hashref containing the following fields:

=over 5

=item deflate (required)

A coderef taking one argument (a perl structure) and returns the serialized
structure

=item inflate (required)

A coderef taking one argument (a serialized structure) and returns the
perl structure

=item packages (optional)

A array reference containing modules to be loaded. The default value is the
name of the benchmark.

=item args (optional)

A coderef returning a list of aditional arguments for the deflate and inflate
routines. Only run once during initialization of benchmark.

=back

All additional fields are interpreted as tags used for selecting benchmarks.

=cut

sub register {
    my $class     = shift;
    my $name      = shift;
    my $benchmark = shift;

    croak "Missing deflate and/or inflate field"
        unless exists $benchmark->{deflate} && $benchmark->{inflate};

    croak "Existing benchmark"
	if exists $benchmarks->{$name};

    $benchmarks->{$name} = $benchmark;
    return 1;
}   

=item load NAME|TAG|BENCHMARK ...

Loads and initializes a number of benchmarks. Arguments can be either
registered names, registered tags, or unregistered benchmarks following the
same format as the C<register> method.

Returns a list of benchmarks

=cut

sub load {
    my $class = shift;

    my %benchmark;
    for my $spec (@_) {
        if ( ref $spec eq "HASH" ) {
            $benchmark{ $spec->{name} } = $spec; 

        } elsif ( $spec eq "all" or $spec eq ":all" ) {
            $benchmark { $_ } = $benchmarks->{ $_ } for keys %{ $benchmarks };
        
        } elsif ( $spec eq "default" ) {
            $benchmark{ $_ } = $benchmarks->{ $_ } for grep { $benchmarks->{ $_ }->{default} } keys %{ $benchmarks };
        
        } elsif ( $spec =~ /^:(.*)/ ) {
            $benchmark{ $_ } = $benchmarks->{ $_ } for grep { $benchmarks->{ $_ }->{$1} } keys %{ $benchmarks };
        
        } elsif ( exists $benchmarks->{ $spec } ) {
            $benchmark{ $spec } = $benchmarks->{ $spec }
        
        } else {
            warn "Unknown benchmark '$spec'.";
        }
    }

    my @list;
    BENCHMARK:
    foreach my $name ( keys %benchmark ) {

        my $benchmark = $benchmark{$name};
        my @packages  = ( exists($benchmark->{packages}) ? @{ $benchmark->{packages} } : $name );
        
        $_->require or next BENCHMARK for @packages;

        $benchmark->{args} = [ $benchmark->{args}->() ] if exists $benchmark->{args}
                                                        && ref $benchmark->{args} eq "CODE";

	$benchmark->{name}    = $name;
        $benchmark->{version} = $packages[0]->VERSION;

	push @list, bless $benchmark, "Benchmark::Serialize::Benchmark";
    }

    return @list;
}

=item list

Returns a list of all available benchmarks. For each benchmark both the name
and the version is returned in a array ref.

=cut

sub list {
    return map { [ $_->name, $_->version ] } Benchmark::Serialize::Library->load(":all");
} 

=back

=cut

package Benchmark::Serialize::Benchmark;

=head2 Benchmark methods

Each benchmark is represented by a object with the following mathods

=over 5

=item deflate

Takes a perl structure as argument and returns the serialized form

=cut

sub deflate {
    $_[0]->{deflate}->($_[1], @{ $_[0]->{args} } );
}

=item inflate

Takes a serialized form as argument and returns the perl structure.

=cut

sub inflate {
    $_[0]->{inflate}->($_[1], @{ $_[0]->{args} } );
}

=item name

Returns the name of the benchmark

=cut

sub name {
    my $self = shift;

    return $self->{name};
}

=item version

Returns the module version of the benchmark. For benchmark needing multiple
loaded modules, the first in the specification list is used.

=cut

sub version {
    my $self = shift;

    return $self->{version};
}

=back

=head2 Known tags

The following tags are usec in the standard library

=over 5

=item :all     - All modules with premade benchmarks

=item :default - A default set of serialization modules

=item :core    - Serialization modules included in core

=item :json    - JSON modules

=item :yaml    - YAML modules

=item :xml     - XML formats

=back


=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-serialize at
rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Serialize>.  I will
be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This module started out as a script written by Christian Hansen, see 
http://idisk.mac.com/christian.hansen/Public/perl/serialize.pl

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Peter Makholm.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
