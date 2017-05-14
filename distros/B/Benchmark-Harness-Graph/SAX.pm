package Benchmark::Harness::SAX;
use XML::SAX;
use strict;

use vars qw(@ISA $PreferredParser);
## #################################################################################
sub import {
    my $cls = shift;
my @acceptableParsers = @_;
   @acceptableParsers = qw(XML::SAX::ExpatXS XML::LibXML::SAX::Parser XML::LibXML::SAX XML::SAX::PurePerl)
            unless @acceptableParsers;

    # Scan the list of available parsers and pick our preferred one.
    my $parsers = XML::SAX->parsers();
    PICK_PARSER:
    for ( @acceptableParsers ) {
        for my $parser ( @$parsers ) {
            if ( $parser->{Name} eq $_ ) {
                if ( $parser->{Features}->{'http://xml.org/sax/features/namespaces'} ) {
                    eval "require $parser->{Name}";
                    if ( $@ ) {
                        warn "Preferred SAX parser $parser->{Name} not found, even though it's in XML::SAX list of parsers: $@\n";
                    } else {
                        $PreferredParser = $parser;
                        last PICK_PARSER;
                    }
                }
            }
        }
    }
    unless ( $PreferredParser ) {
        my $searchedFor = join ', ',@acceptableParsers;
        my $found = join ', ',map { $_->{Name}; } @$parsers;
        warn <<EOT;
Benchmark::Harness::SAX can not find an acceptable SAX parser.

Searched for: $searchedFor
Found only: $found
XML::SAX::PurePerl is the minimal requirement, or
specify an existing one in your 'use', as in
    use Benchmark::Harness::SAX qw(your::SAX::Parser);

EOT
    }
}
## #################################################################################
## #################################################################################
## #################################################################################

## #################################################################################
sub new {
    my $self = bless {
             'error' => undef
            ,'subroutines' => []
        }, shift;
    for my $arg ( @_ ) {
        map { $self->{$_} = $arg->{$_} } keys %$arg
            if ( ref($arg) eq 'HASH' );
    }

    if ( ref($PreferredParser) ) {
        eval "require $PreferredParser->{Name}; \@ISA = qw($PreferredParser->{Name});";
        if ( $@ ) {
            $self->{error} = $@;
            die $self->{error};
        };
    } else {
        $self->{error} = "No preferred parser found in Benchmark::Harness::SAX\n";
        die $self->{error};
    }

    return $self;
}

## #################################################################################
## This guy captures the standard element(s) <ID> and its attributes
sub start_element {
    my ($self, $saxElm) = @_;

    my $tagName = $saxElm->{LocalName};
    if ( $tagName eq 'ID' ) {
        my $subroutines = {};
        my $attrs = $saxElm->{Attributes};
        for (qw(name type package modifiers)) {
            $subroutines->{$_} = $attrs->{'{}'.$_}->{Value};
        };
        push @{$self->{subroutines}}, $subroutines;
        return undef; # Signal to sub-class that we've already captured this element.
    } else {
        return \$tagName; # convenience to sub-class - already grabbed tag-name once.
    }
}

1;