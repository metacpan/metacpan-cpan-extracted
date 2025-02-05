##
## Copyright (c) 1998-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use strict;
use warnings;
package Crypt::Random::Generator; 
use Crypt::Random qw(makerandom makerandom_itv makerandom_octet);
use Carp;

our $VERSION = '1.56';

my @PROVIDERS = qw(devrandom devurandom Win32API egd rand);
my %STRENGTH  = ( 0 => [ qw(egd Win32API rand) ], 1 => [ qw(devrandom devurandom Win32API rand) ] );

sub new { 

    my ($class, %params) = @_;
  
    my $self = { _STRENGTH => \%STRENGTH, _PROVIDERS => \@PROVIDERS  };

    $$self{Strength} = defined $params{Strength} ? $params{Strength} : 1;
    $$self{Uniform} = $params{Uniform} || 0;
    $$self{Provider} = $params{Provider} || "";  
    $$self{ProviderParams} = $params{ProviderParams} || ();

    bless $self, $class;

    unless ($$self{Provider}) { 
        SELECT_PROVIDER: for ($self->strength_order($$self{Strength})) { 
            my $pname = $_; my $fqpname = "Crypt::Random::Provider::$pname";
            if (eval "use $fqpname; $fqpname->available()") { 
                if (grep { $pname eq $_ } $self->providers) { 
                    $$self{Provider} = $pname; 
                    last SELECT_PROVIDER; 
                }
            }
        } 
    }
    croak "No provider available.\n" unless $$self{Provider};
    return $self;

}


sub providers { 

    my ($self, @args) = @_;
    if (@args) { $$self{_PROVIDERS} = [@args] }
    return @{$$self{_PROVIDERS}};

}


sub strength_order { 

    my ($self, $strength, @args) = @_;
    if (@args) { $$self{_STRENGTH}{$strength} = [@args] }
    return @{$$self{_STRENGTH}{$strength}}

}


sub integer { 

    my ($self, %params) = @_;
    if ($params{Size}) { 
        return makerandom ( 
                Size => $params{Size}, 
                Provider => $$self{Provider}, 
                Verbosity => $params{Verbosity} || $$self{Verbosity},
                Uniform => $params{Uniform} || $$self{Uniform},
                %{$$self{ProviderParams}},
        )
    } elsif ($params{Upper}) {
         return makerandom_itv ( 
                Lower => $params{Lower} || 0,
                Upper => $params{Upper},
                Provider => $$self{Provider}, 
                Verbosity => $params{Verbosity} || $$self{Verbosity},
                Uniform => $params{Uniform} || $$self{Uniform},
                %{$$self{ProviderParams}},
        )
    }

} 


sub string { 

    my ($self, %params) = @_;
    return makerandom_octet ( 
        %params, 
        Provider => $$self{Provider}, 
        Verbosity => $params{Verbosity} || $$self{Verbosity},
        %{$$self{ProviderParams}},
    )    

}


