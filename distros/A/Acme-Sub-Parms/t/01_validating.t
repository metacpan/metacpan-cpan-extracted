#!/usr/bin/perl -w

use strict;

use lib ('./blib','./lib','../blib','../lib');
use Acme::Sub::Parms;

my @tests_list = (
     { -code => \&bind_parms_test,          -desc => 'BindParms (validating, non-normalized) ' },
);

my $counter   = 1;
my $do_tests  = [];
my $test_subs = {};
foreach my $test (@tests_list) {
    $test_subs->{$counter} = $test;
    push (@$do_tests, $counter++);
}

run_tests($test_subs,$do_tests);

exit;

###########################################################################################

sub run_tests {
    my ($test_subs,$do_tests) = @_;

    print @$do_tests[0],'..',@$do_tests[$#$do_tests],"\n";
    print STDERR "\n";
    my $n_failures = 0;
    foreach my $test (@$do_tests) {
        my $sub  = $test_subs->{$test}->{-code};
        my $desc = $test_subs->{$test}->{-desc};
        my $failure = '';
        eval { $failure = &$sub; };
        if ($@) {
            $failure = $@;
        }
        if ($failure ne '') {
            chomp $failure;
            print "not ok $test\n";
            print STDERR "    $desc - $failure\n";
            $n_failures++;
        } else {
            print "ok $test\n";
            print STDERR "    $desc - ok\n";

        }
    }
    
    print "END\n";
}

###########################################################################################

sub _current_time {
    my ($field_name, $field_value, $args_hash) = @_;
    $args_hash->{$field_name} = time;
    return 1;
}

sub _is_integer {
    my ($field_name, $field_value, $args_hash) = @_;
    unless (defined ($field_value))            { return (0, 'Not defined');    }
    unless (int($field_value) eq $field_value) { return (0, 'Not an integer'); }
    return 1;
}

sub bind_parms_test {
    my $result = eval {
        @_ = ( 
                'handle' => Acme::Sub::Parms::TestObject->new,
                 'thing' => Acme::Sub::Parms::TestObject->new,
                'another' => \"example",
                'yathing' => 1,
               );
        BindParms : (
            my $handle         : handle   [required, is_defined, can=param];
            my $thing          : thing    [optional, isa=Acme::Sub::Parms::TestObject];
            my $another_thing  : another  [optional, type=SCALAR];
            my $yathing        : yathing  [optional, is_defined, callback=_is_integer];
            my $calltime       : calltime [callback=_current_time];
            my $defaulted      : dthing   [optional, default="help me"];

        )

        unless (defined($handle) and defined($thing)) {
            return 'failed to parse named parameters';
        }
        return '';
    };
    if (not defined $result) {
        $result = "fatal error $@";
    }

    return $result;
}

###

package Acme::Sub::Parms::TestObject;

sub param {
    1;
}

sub new {
    my $self = bless {}, 'Acme::Sub::Parms::TestObject';
    return $self;
}


