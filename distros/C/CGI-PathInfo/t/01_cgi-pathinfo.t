#!/usr/bin/perl -w

use strict;
use lib ('./blib','../blib','../lib','./lib');
use CGI::PathInfo;

# General info for writing test modules: 
#
# When running as 'make test' the default
# working directory is the one _above_ the 
# 't/' directory. 

my @do_tests=(1..4);

my $test_subs = { 
       1 => { -code => \&instantation,       -desc => ' instantation                   ' },
       2 => { -code => \&bad_initialization, -desc => ' bad initialization             ' },
       3 => { -code => \&test1,              -desc => ' parameter list                 ' },
       4 => { -code => \&test2,              -desc => ' values lists                   ' },
};

print $do_tests[0],'..',$do_tests[$#do_tests],"\n";
print STDERR "\n";
my $n_failures = 0;
foreach my $test (@do_tests) {
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
exit;

########################################
# Instantation                         #
########################################
sub instantation {
    $ENV{'PATH_INFO'} = '/test1a-value1/test1b-value2/fake.html';

    my $path_info;
    eval {
        $path_info     = CGI::PathInfo->new;
    };
    if ($@ or (not $path_info)) {
        return 'failed standard instantation';
    }

    eval {
        $path_info     = CGI::PathInfo->new( 'stripleadingslash' => 1 );
    };
    if ($@ or (not $path_info)) {
        return 'failed standard instantation with list parameters';
    }

    eval {
        $path_info     = CGI::PathInfo->new({ 'stripleadingslash' => 1 });
    };
    if ($@ or (not $path_info)) {
        return 'failed standard instantation with anon hash parameters';
    }

    eval {
        $path_info     = CGI::PathInfo::new;
    };
    if ($@ or (not $path_info)) {
        return 'failed class method instantation';
    }

    eval {
        $path_info     = new CGI::PathInfo;
    };
    if ($@ or (not $path_info)) {
        return 'failed indirect instantation';
    }

    eval {
        $path_info     = CGI::PathInfo->new->new;
    };
    if ($@ or (not $path_info)) {
        return 'failed instance constructor instatation'
    }

    eval {
        local $ENV{'PATH_INFO'};
        $path_info     = CGI::PathInfo->new;
        my @parms = $path_info->param;
        if (@parms > 0) {
            die ("mis-decoded undef PATH_INFO");
        }
    };
    if ($@ or (not $path_info)) {
        return "failed instance constructor instatation $@";
    }


    return '';
}

########################################
# Bad initialization parameters        #
########################################
sub bad_initialization {
    $ENV{'PATH_INFO'} = '/test1a-value1/test1b-value2/fake.html';
    eval {
        my $path_info     = CGI::PathInfo->new([ stripleadingslash => 0,
                                            striptrailingslash => 0,
                                               ]);
    };
    unless ($@) {
        return 'failed to detect passing of bad parameters';
    }

    eval {
        my $path_info     = CGI::PathInfo->new( stripleadingslash => 1,
                                                      stlingslash => 1,
                                              );
    };
    unless ($@) {
        return 'failed to detect passing of invalid parameters';
    }

    eval {
        my $path_info     = CGI::PathInfo->new({ stripleadingslash => 1,
                                            stlingslash => 1,
                                              });
    };
    unless ($@) {
        return 'failed to detect passing of invalid parameters';
    }

    eval {
        my $path_info     = CGI::PathInfo->new('a');
    };
    unless ($@) {
        return 'failed to detect passing of odd number of parameters';
    }

    eval {
        my $path_info     = CGI::PathInfo->new( stripleadingslash => 1,
                                            striptrailingslash => 1,
                                            'a',
                                              );
    };
    unless ($@) {
        return 'failed to detect passing of odd number of parameters';
    }

    eval {
        my $path_info     = CGI::PathInfo->new( stripingslash => 1,);
    };
    unless ($@) {
        return 'failed to detect passing of undefined parameter';
    }
    return '';
}

########################################
# Number of returned parameters        #
########################################
sub test1 {

    { 
        $ENV{'PATH_INFO'} = '/test1a-value1/test1b-value2/fake.html';
        my $path_info     = CGI::PathInfo->new({ stripleadingslash => 0,
                                                striptrailingslash => 0,
                                           });
        my @parms         = $path_info->param;
        if ($#parms != 1) {
            return 'Incorrect parse of PATH_INFO - wrong number of parameters returned';
        }
        my @expected = ( 'test1a', 'test1b' );
        for (my $count = 0; $count <= $#expected; $count++) {
            if($expected[$count] ne $parms[$count]) {
                return "Unexpected key of '$parms[$count]' was found";    
            }
        }
    }

    { 
        $ENV{'PATH_INFO'} = '/test1a-value1/test1a-value2/fake.html';
        my $path_info     = CGI::PathInfo->new({ stripleadingslash => 0,
                                                striptrailingslash => 0,
                                           });
        my @parms         = $path_info->param;
        if ($#parms != 0) {
            return 'Incorrect parse of PATH_INFO - wrong number of parameters returned';
        }
        my @expected = ( 'test1a' );
        for (my $count = 0; $count <= $#expected; $count++) {
            if($expected[$count] ne $parms[$count]) {
                return "Unexpected key of '$parms[$count]' was found";    
            }
        }
        my @values = $path_info->param('test1a');
        unless (2 == @values) {
            return 'Incorrect parse of PATH_INFO - wrong number of values returned for multivalue';
        }
    }

    return '';
}

########################################
# Number of returned values            #
########################################
sub test2 {
    $ENV{'PATH_INFO'} = '/test2b-value1/test2a-value2/test2a-value3/test2a-value4/fake.html';
    my $path_info     = CGI::PathInfo->new;
    my $expected_results = { 'test2a' => [qw(value1)],
                             'test2a' => [qw(value2 value3 value4)],
                           };
    foreach my $test_key (keys %$expected_results) {
        my (@values) = $path_info->param($test_key);
        if ($#values != $#{$expected_results->{$test_key}}) {
            return "Incorrect parse of PATH_INFO - wrong number of values returned for '$test_key'";
        }
        foreach my $test_value (@{$expected_results->{$test_key}}) {
            if ($#values != $#{$expected_results->{$test_key}}) {
                return "Incorrect parse of PATH_INFO - unexpected values returned for '$test_key'";
            }
        }
    }
    my @no_such = $path_info->param('no such parm');
    unless (0 == @no_such) {
        return 'found a param that should not have existed';
    }

    return '';
}
