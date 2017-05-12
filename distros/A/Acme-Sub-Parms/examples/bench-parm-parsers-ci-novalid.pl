#!/usr/bin/perl

package My;

use strict;

use Acme::Sub::Parms qw(:no_validation :normalize);
use Class::ParmList qw (simple_parms parse_parms);
use Params::Validate qw (validate);
use Benchmark qw(cmpthese);
$Params::Validate::NO_VALIDATION = 1;
print "Bench case insensitive parameter parsing without validation\n";
cmpthese(500000, {
            'bindparms'     => sub { sub_parms_bind_parms( handle => 'Test', 'thing' => 'something')},
#            'std_args'            => sub { standard_args( handle => 'Test', 'thing' => 'something')},
            'caseflat_std_args'   => sub { caseflat_standard_args( handle => 'Test', 'thing' => 'something')},
#            'one_step_args'    => sub { one_step_args( handle => 'Test', 'thing' => 'something')},
            'positional_args'  => sub { positional_args( 'Test', 'something')},
            'null_sub'         => sub { null_sub( handle => 'Test', 'thing' => 'something')},
            'simple_parms'     => sub { simple_parms_args( handle => 'Test', 'thing' => 'something')},
            'parse_parms'     => sub { parse_parms_no_valid( handle => 'Test', 'thing' => 'something')},
            'params_validate'  => sub { params_validate( handle => 'Test', 'thing' => 'something')},
        }
);
exit;

############################################################################

sub params_validate {
    my ($handle, $thing) = @{(validate(@_, { handle => 1, thing => 1 }))}{'handle','thing'};
}

sub sub_parms_bind_parms {
    BindParms : (
        my $handle : handle;
        my $thing  : thing;
    )
}

sub simple_parms_args {
    my ($handle, $thing) =  simple_parms(['handle','thing'], @_);
}

sub parse_parms_no_valid {
	my ($handle, $thing) = parse_parms({ -parms    =>  \@_ })->get('handle','thing');
}

sub positional_args {
    my ($handle, $thing) =  @_;
}
sub one_step_args {
    my ($handle, $thing) =  @{{@_}}{'handle','thing'};
}

sub caseflat_standard_args {
    my %args;
    {
        my %raw_args = @_;
        %args = map { lc($_) => $raw_args{$_} } keys %raw_args;
    }

    my ($handle, $thing) =  @args{'handle','thing'};
}

sub standard_args {
    my %args = @_;
    my ($handle, $thing) =  @args{'handle','thing'};
}
sub null_sub { }
