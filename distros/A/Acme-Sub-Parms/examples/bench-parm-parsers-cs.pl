#!/usr/bin/perl

package My;

use strict;

use Acme::Sub::Parms;
use Class::ParmList qw (simple_parms);
use Params::Validate qw (validate);
use Benchmark qw(cmpthese);
print "Bench case sensitive parameter parsing with validation (as applicable)\n";
cmpthese(1000000, {
            'bindparms'     => sub { sub_parms_bindparms( handle => 'Test', 'thing' => 'something')},
            'std_args (*)'            => sub { std_args( handle => 'Test', 'thing' => 'something')},
#            'caseflat_args'   => sub { caseflat_std_args( handle => 'Test', 'thing' => 'something')},
            'one_step_args (*)'    => sub { one_step_args( handle => 'Test', 'thing' => 'something')},
            'positional_args (*)'  => sub { positional_args( 'Test', 'something')},
            'simple_parms'     => sub { simple_parms_args( handle => 'Test', 'thing' => 'something')},
            'validate'  => sub { params_validate( handle => 'Test', 'thing' => 'something')},
            'null_sub'         => sub { null_sub( handle => 'Test', 'thing' => 'something')},
        }
);

print "'starred' entries are not performing validation\n";
exit;

############################################################################

sub params_validate {
    my ($handle, $thing) = @{(validate(@_, { handle => 1, thing => 1 }))}{'handle','thing'};
}

sub sub_parms_bindparms {
    BindParms : (
        my $handle : handle;
        my $thing  : thing;
    )
}

sub simple_parms_args {
    my ($handle, $thing) =  simple_parms(['handle','thing'], @_);
}

sub positional_args {
    my ($handle, $thing) =  @_;
}

sub one_step_args {
    my ($handle, $thing) =  @{{@_}}{'handle','thing'};
}

sub caseflat_std_args {
    my %args;
    {
        my %raw_args = @_;
        %args = map { lc($_) => $raw_args{$_} } keys %raw_args;
    }

    my ($handle, $thing) =  @args{'handle','thing'};
}

sub std_args {
    my %args = @_;
    my ($handle, $thing) =  @args{'handle','thing'};
}
sub null_sub { }
