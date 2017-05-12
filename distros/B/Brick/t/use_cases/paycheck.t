#!/usr/bin/perl

use Test::More;

use_ok( 'Brick' );
use_ok( 'Brick::Bucket' );

package Brick::Bucket;
use strict;
use warnings;

use Test::More 'no_plan';

=head1 NAME


=head1 SYNOPSIS


=head1 DESCRIPTION

This use case considers the complicated decision of trying to validate
the employment start date in a complicated situation. There are different
employee types, and within each type there are different pay bases. Some
pay bases have additional criteria. Here's the tree for this situation:

                                    Worker
                                    /   \
                    Faculty        /     \    Professional
               +------+------------       +-------+---------+----------+
              /        \                  |       |         |          |                               
             /          \               Hourly  Salary  Contractor   Extra                              
         Fall &        Fall,              /      /          |          |                                            
         Spring      Spring, &           /      /          /           |                   
          /           Summer            /      /          /            |                       
         /              \              /      /          /            /                
        /                \            /      /          /            /       
   Semester     	      \    Any valid    /          /            /                                   
    Start                  +---   Date ----+----------+            /                                          
    Date                                  \                       /                       
                                           \                     /                          
                                            \                +---+                           
                                             \              /                                                                                                                                                                                            
                                              \            /                                                                                                                                                                                               
                                               \           |                                                                                                                                                                                               
                                                |          |                                                                                                                                                                                                
                                            One-shot       |                                                                                                                                                                                                        
                                                |          |                                                                                                                                                                                               
                             -+-------+---------+----------+                           
                             /        \                                                    
                            /          \                                                   
                           /            \                                                  
                       Quarterly        Semi                                               
                        /              Annual                                           
                       /                   \                                          
                      /                     \                                          
                 Quarterly                   \                                         
                  Payroll                 Semi-Annual                                        
                   Date                     Payroll                                        
                                              date                                        


The input is the worker type, their pay basis, and a date. From there
the validator has to give a yes-or-no answer about the validity of the
date for that combination.


=head2 Writing the building block validators




=cut

my $bucket = Brick::Bucket->new;

=head3 Payroll dates

You have to start your job on the boundary of a payroll period. For
teachers that's a valid date for the start of a school term, although
there are three periods: Fall, Spring, and Summer. Some teachers get
paid just for Fall and Spring and some get paid for all three. For
full-time professionals that's any valid date, and for contractors
that's one of the semiannual or quarterly payroll dates. Contractors
who only get one check can start on any valid date. Some professional
workers can also be contractors by taking on extra projects.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_valid_semester_date {
	my( $bucket, $setup ) = @_;
	
	$bucket->add_to_bucket( {
		name        => '_is_valid_semester_date',
		description => 'Semester date validator',
		code        => sub {
			print STDERR "Running _is_valid_semester_date with $_[0]->{effective_date}\n" if $ENV{DEBUG};  
			$_[0]->{effective_date} =~ m/\d\d\d\d0(1|6|9)01/ 
				or die { 
					handler => '_is_valid_semester_date',
					message => 'Not a valid semester date' 
					};
			}
		} );
	}

{
my $sub = $bucket->_is_valid_semester_date( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { effective_date => 19700101 } ), "valid semester works" );
ok(   $sub->( { effective_date => 19700601 } ), "valid semester works" );
ok(   $sub->( { effective_date => 19700901 } ), "valid semester works" );
ok( ! eval { $sub->( { effective_date => 19700801 } ) }, "invalid semester doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_valid_fall_or_spring_date {
	my( $bucket, $setup ) = @_;
	
	$bucket->add_to_bucket( {
		name        => '_is_valid_fall_or_spring_date',
		description => 'Spring or Fall semester date validator',
		handler     => '_is_valid_fall_or_spring_date',
		code        => sub {
			print STDERR "Running _is_valid_fall_or_spring_date with $_[0]->{effective_date}\n" if $ENV{DEBUG};  
			$_[0]->{effective_date} =~ m/\d\d\d\d0(1|9)01/ 
				or die { 
					handler => '_is_valid_fall_or_spring_date',
					message => 'Not a valid semester date' 
					};
			}
		} );
	}

{
my $sub = $bucket->_is_valid_fall_or_spring_date( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { effective_date => 19700101 } ), "valid semester works" );
ok(   $sub->( { effective_date => 19700901 } ), "valid semester works" );
ok( ! eval { $sub->( { effective_date => 19700601 } ) }, "Summer isn't Fall or Spring" );
ok( ! eval { $sub->( { effective_date => 19700801 } ) }, "August isn't Fall or Spring" );
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_valid_paydate {
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => '_is_valid_paydate',
		description => 'Paydate validator',
		code        => sub {
			print STDERR "Running _is_valid_semester_date with $_[0]->{effective_date}\n" if $ENV{DEBUG};  
			$_[0]->{effective_date} =~ m/\d\d\d\d(0[1-9]|1[0-2])\d\d/
				or die { message => 'Not a valid pay date' };
			}
		} );
	}

{
my $sub = $bucket->_is_valid_paydate( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { effective_date => 19700101 } ), "valid paydate works" );
ok(   $sub->( { effective_date => 19700615 } ), "valid paydate works" );
ok(   $sub->( { effective_date => 19700801 } ), "valid paydate works" );
ok( ! eval { $sub->( { effective_date => 1970080 } ) },  "invalid paydate doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_semiannual_payroll_date {
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => '_is_semiannual_payroll_date',
		description => 'Semiannual date selector',
		code        => sub {
			print STDERR "Running _is_semiannual_payroll_date with $_[0]->{effective_date}\n" if $ENV{DEBUG};  
			$_[0]->{effective_date} =~ m/\d\d\d\d0(1|6)01/
				or die { message => 'Not a valid semiannual pay date' };
			}
		} );
	}

{
my $sub = $bucket->_is_semiannual_payroll_date( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { effective_date => 19700101 } ), "valid semiannual works" );
ok(   $sub->( { effective_date => 19700601 } ), "valid semiannual works" );
ok( ! eval { $sub->( { effective_date => 19700801 } ) },  "invalid semiannual doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_quarterly_payroll_date {
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => '_is_quarterly_payroll_date',
		description => 'Quarterly date selector',
		code        => sub {
			print STDERR "Running _is_quarterly_payroll_date with $_[0]->{effective_date}\n" if $ENV{DEBUG};  
			$_[0]->{effective_date} =~ m/\d\d\d\d(01|04|07|10)01/
				or die { message => 'Not a valid quarterly pay date' };
			}
		} );
	}

{
my $sub = $bucket->_is_quarterly_payroll_date( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { effective_date => 19700101 } ), "valid quarterly works" );
ok(   $sub->( { effective_date => 19700401 } ), "valid quarterly works" );
ok(   $sub->( { effective_date => 19700701 } ), "valid quarterly works" );
ok(   $sub->( { effective_date => 19701001 } ), "valid quarterly works" );
ok( ! eval { $sub->( { effective_date => 19700801 } ) },  "invalid semiannual doesn't work" );
}

=head3 Worker type selectors

These validation routines return true if they match the pay basis and
undef otherwise. When they return undef, they can prune the traversal
of the tree.

Selectors should never return 0, which would indicate a hard failure
of the validation instead of a "don't go this way" failure.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_faculty
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_faculty',
		description => 'Faculty selector',
		code        => sub  { $_[0]->{worker_type} eq "Faculty" ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_faculty( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { worker_type => 'Faculty'      } ), "valid worker type works" );
ok( ! $sub->( { worker_type => 'Professional' } ), "invalid worker type doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_professional
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_professional',
		description => 'Faculty selector',
		code        =>  sub { $_[0]->{worker_type} eq "Professional" ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_professional( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { worker_type => 'Professional' } ), "valid worker type works" );
ok( ! $sub->( { worker_type => 'Faculty'      } ), "invalid worker type doesn't work" );
}
	
=head3 Pay basis type selectors

These validation routines return true if they match the pay basis and
undef otherwise.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_faculty_21
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_faculty_21',
		description => 'Faculty 21 selector',
		code        => sub { $_[0]->{pay_basis} eq "Faculty 21" ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_faculty_21( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { pay_basis => 'Faculty 21'      } ), "valid pay basis works" );
ok( ! $sub->( { pay_basis => 'Faculty 26' }      ), "invalid pay basis doesn't work" );
ok( ! $sub->( { pay_basis => 'Faculty' }         ), "invalid pay basis doesn't work" );
}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_faculty_26
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_faculty_26',
		description => 'Faculty 26 selector',
		code        => sub { $_[0]->{pay_basis} eq "Faculty 26" ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_faculty_26( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { pay_basis => 'Faculty 26'      } ), "valid pay basis works" );
ok( ! $sub->( { pay_basis => 'Faculty 21' }      ), "invalid pay basis doesn't work" );
ok( ! $sub->( { pay_basis => 'Faculty' }         ), "invalid pay basis doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_hourly
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_hourly',
		description => 'Hourly selector',
		code        => sub { $_[0]->{pay_basis} eq "Hourly"     ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_hourly( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { pay_basis => 'Hourly'     } ), "valid pay basis works" );
ok( ! $sub->( { pay_basis => 'Faculty 21' } ), "invalid pay basis doesn't work" );
ok( ! $sub->( { pay_basis => 'Salary'     } ), "invalid pay basis doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_salary
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_salary',
		description => 'Salary selector',
		code        => sub { $_[0]->{pay_basis} eq "Salary"     ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_salary( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { pay_basis => 'Salary'     } ), "valid pay basis works" );
ok( ! $sub->( { pay_basis => 'Faculty 21' } ), "invalid pay basis doesn't work" );
ok( ! $sub->( { pay_basis => 'Fee'        } ), "invalid pay basis doesn't work" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_fee_based
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_fee_based',
		description => 'Fee selector',
		code        => sub { $_[0]->{pay_basis} eq "Fee"        ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_fee_based( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { pay_basis => 'Fee'        } ), "valid pay basis works" );
ok( ! $sub->( { pay_basis => 'Hourly'     } ), "invalid pay basis doesn't work" );
ok( ! $sub->( { pay_basis => 'Extra'      } ), "invalid pay basis doesn't work" );
}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_extra_service
	{
	my( $bucket, $setup ) = @_;

	$bucket->add_to_bucket( {
		name        => 'is_extra_service',
		description => 'Extra service selector',
		code        => sub { $_[0]->{pay_basis} eq "Extra"      ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_extra_service( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { pay_basis => 'Extra'      } ), "valid pay basis works" );
ok( ! $sub->( { pay_basis => 'Faculty 26' } ), "invalid pay basis doesn't work" );
ok( ! $sub->( { pay_basis => 'Fee'        } ), "invalid pay basis doesn't work" );
}
	
=head3 Pay frequency selectors

These validation routines return true if they match the pay frequnecy
and undef otherwise.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_quarterly
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->add_to_bucket( {
		name        => 'is_quarterly',
		description => 'Quarterly selector',
		code   => sub { $_[0]->{payments} eq "Quarterly" ? 1 : () },
		} );	
	}

{
my $sub = $bucket->_is_quarterly( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { payments => 'Quarterly'     } ), "valid payment frequency works" );
ok( ! $sub->( { payments => 'Semi-annually' } ), "invalid payment frequency doesn't work" );
ok( ! $sub->( { payments => 'Single'        } ), "invalid payment frequency doesn't work" );
}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_semiannually
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->add_to_bucket( {
		name        => 'is_semiannually',
		description => 'Semiannually selector',
		code        => sub { $_[0]->{payments} eq "Semi-annually"  ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_semiannually( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { payments => 'Semi-annually' } ), "valid payment frequency works" );
ok( ! $sub->( { payments => 'Quarterly'     } ), "invalid payment frequency doesn't work" );
ok( ! $sub->( { payments => 'Single'        } ), "invalid payment frequency doesn't work" );
}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _is_single_payment
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->add_to_bucket( {
		name        => 'is_single_payment',
		description => 'Single payment selector',
		code        => sub { $_[0]->{payments} eq "Single" ? 1 : () },
		} );
	}

{
my $sub = $bucket->_is_single_payment( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( { payments => 'Single'        } ), "valid payment frequency works" );
ok( ! $sub->( { payments => 'Semi-annually' } ), "invalid payment frequency doesn't work" );
ok( ! $sub->( { payments => 'Quarterly'     } ), "invalid payment frequency doesn't work" );
}

=head2 Composing the selectors and validators

First, I compose the lowest level selectors and their date validators. These
will become part of the larger traversal tree and the selector will be able
to signal the traverser to not follow a branch. Use __compose_pass_or_stop
as the composer, which stops evaluating its subroutines at the first failure.
Since the selector does not die and simply returns undef, it won't stop the
validation. Instead, it allows the next higher level to continue with its
work.

I use __compose_pass_or_stop when I want to ignore the rest of the subroutines
in the composition if one of them doesn't pass (but without die-ing).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _faculty_21_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_faculty_21( $setup ), 
		$bucket->_is_valid_fall_or_spring_date( $setup ),
		);
	}

{
my $sub = $bucket->_faculty_21_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	worker_type    => 'Faculty',
	pay_basis      => 'Faculty 21', 
	effective_date => '19700101', 
	} ), 
	"Faculty 21 valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	worker_type    => 'Faculty',
	pay_basis      => 'Faculty 21', 
	effective_date => '19700201', 
	} ) };
my $at = $@;

ok( ! $result, "Faculty 21 invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _faculty_26_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_faculty_26( $setup ), 
		$bucket->_is_valid_paydate( $setup ),
		);
	}

{
my $sub = $bucket->_faculty_26_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok( $sub->( 
	{ 
	worker_type    => 'Faculty',
	pay_basis      => 'Faculty 26', 
	effective_date => '19700515', 
	} ), 
	"Faculty 26 valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	worker_type    => 'Faculty',
	pay_basis      => 'Faculty 26', 
	effective_date => '1970020', 
	} ) };
my $at = $@;
	
ok( ! $result, "Faculty 26 invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _hourly_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_hourly( $setup ), 
		$bucket->_is_valid_paydate( $setup ),
		);
	}

{
my $sub = $bucket->_hourly_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	worker_type    => 'Professional',
	pay_basis      => 'Hourly', 
	effective_date => '19700515', 
	} ), 
	"Hourly valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	worker_type    => 'Professional',
	pay_basis      => 'Hourly', 
	effective_date => '1970020', 
	} ) };
my $at = $@;
	
ok( ! $result, "Hourly invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _salary_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_salary( $setup ), 
		$bucket->_is_valid_paydate( $setup ),
		);
	}

{
my $sub = $bucket->_salary_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	worker_type    => 'Professional',
	pay_basis      => 'Salary', 
	effective_date => '19700515', 
	} ), 
	"Hourly valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	worker_type    => 'Professional',
	pay_basis      => 'Salary', 
	effective_date => '1970020', 
	} ) };
my $at = $@;
	
ok( ! $result, "Salary invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _fee_based_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_fee_based( $setup ), 
		$bucket->_is_valid_paydate( $setup ),
		);
	}

{
my $sub = $bucket->_fee_based_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	worker_type    => 'Professional',
	pay_basis      => 'Fee', 
	effective_date => '19700515', 
	} ), 
	"Hourly valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	worker_type    => 'Professional',
	pay_basis      => 'Fee', 
	effective_date => '1970020', 
	} ) };
my $at = $@;
	
ok( ! $result, "Fee invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}


=pod

The extra service fee based ones are special and require an extra level. Once
I compose the pay frequency with the date validator for it, I compose all of
those with the __compose_pass_or_skip.

I use __compose_pass_or_skip when I want to try several subroutines until I
find one that works.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _quarterly_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_quarterly( $setup ), 
		$bucket->_is_quarterly_payroll_date( $setup ),
		);
	}

{
my $sub = $bucket->_quarterly_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(  $sub->( 
	{ 
	payments	   => 'Quarterly',
	effective_date => '19700101', 
	} ), 
	"Quarterly valid effective date works" 
	);

#print Data::Dumper->Dump( [$@], [qw(@)] );
#print Data::Dumper->Dump( [$result], [qw(result)] );

my $result = eval { $sub->( 
	{ 
	payments	   => 'Quarterly',
	effective_date => '19700201', 
	} ) };
my $at = $@;
	
ok( ! $result, "Quarterly invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _semi_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_semiannually( $setup ), 
		$bucket->_is_semiannual_payroll_date( $setup ), 
		);
	}

{
my $sub = $bucket->_semi_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	payments       => 'Semi-annually',
	effective_date => '19700601', 
	} ), 
	"Semi-annually valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	payments       => 'Semi-annually',
	effective_date => '19700201', 
	} ) };
my $at = $@;
	
ok( ! $result, "Semi-annually invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _single_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop( 
		$bucket->_is_single_payment( $setup ), 
		$bucket->_is_valid_paydate( $setup ),
		);
	}

{
my $sub = $bucket->_single_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	payments       => 'Single',
	effective_date => '19700714', 
	} ), 
	"Single valid effective date works" 
	);

my $result = eval { $sub->( 
	{ 
	payments       => 'Single',
	effective_date => '1700201', 
	} ) };
my $at = $@;
	
ok( ! $result, "Single invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _extra_pass_or_skip
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_skip( 
		$bucket->_quarterly_pass_or_stop( $setup ),
		$bucket->_semi_pass_or_stop( $setup ),
		$bucket->_single_pass_or_stop( $setup ),	
		);
	}

{
my $sub = $bucket->_extra_pass_or_skip( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{ 
	pay_basis      => 'Extra',
	payments       => 'Single',
	effective_date => '19700714', 
	} ), 
	"Extra, Single valid effective date works" 
	);

ok(   $sub->( 
	{ 
	pay_basis      => 'Extra',
	payments       => 'Quarterly',
	effective_date => '197000401', 
	} ), 
	"Extra, Quarterly valid effective date works" 
	);
	
ok(   $sub->( 
	{ 
	pay_basis      => 'Extra',
	payments       => 'Semi-annually',
	effective_date => '19700601', 
	} ), 
	"Extra, Semi-annually valid effective date works" 
	);
	
my $result = eval { $sub->( 
	{ 
	pay_basis      => 'Extra',
	payments       => 'Single',
	effective_date => '1700201', 
	} ) };
my $at = $@;
	
ok( ! $result, "Single invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _extra_pass_or_stop
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_stop(
		$bucket->_is_extra_service( $setup ),
		$bucket->_extra_pass_or_skip( $setup ),
		);
	}

{
my $sub = $bucket->_extra_pass_or_stop( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{
	pay_basis      => 'Extra',
	payments       => 'Single',
	effective_date => '19700714', 
	} ), 
	"Single valid effective date works" 
	);

ok( ! $sub->( 
	{
	pay_basis      => 'Hourly',
	payments       => 'Single',
	effective_date => '19700714', 
	} ), 
	"hourly pay_basis doesn't work for Extra type" 
	);
	
my $result = eval { $sub->( 
	{ 
	pay_basis      => 'Extra',
	payments       => 'Quarterly',
	effective_date => '1700201', 
	} ) };
my $at = $@;
	
ok( ! $result, "Single invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

=head3 Composing the pay basis types

Next, I take all of the composed subs for each pay basis type and compose
them into a single subroutine for that worker type.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _faculty_composed
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_skip(
		$bucket->_faculty_21_pass_or_stop( $setup ),
		$bucket->_faculty_26_pass_or_stop( $setup ),
		);
	}

{
my $sub = $bucket->_faculty_composed( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{
	pay_basis      => 'Faculty 21',
	effective_date => '19700901', 
	} ), 
	"Faculty 21 Fall semester date works" 
	);

ok(   $sub->( 
	{
	pay_basis      => 'Faculty 26',
	effective_date => '19700601', 
	} ), 
	"Faculty 26 Summer semester date works" 
	);

ok( ! eval {  $sub->( 
	{
	pay_basis      => 'Faculty 21',
	effective_date => '19700601', 
	} ) }, 
	"Faculty 21 Summer semester date doesn't work" 
	);
	
ok( ! eval { $sub->( 
	{
	pay_basis      => 'Hourly',
	payments       => 'Single',
	effective_date => '19700714', 
	} ) }, 
	"hourly pay_basis doesn't work for Faculty type" 
	);
	
my $result = eval { $sub->( 
	{ 
	pay_basis      => 'Faculty 21',
	effective_date => '1700201', 
	} ) };
my $at = $@;

ok( ! $result, "Single invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _professional_composed
	{
	my( $bucket, $setup ) = @_;
	
	$bucket->__compose_pass_or_skip(
		$bucket->_hourly_pass_or_stop( $setup ),
		$bucket->_salary_pass_or_stop( $setup ),
		$bucket->_extra_pass_or_stop( $setup ),
		$bucket->_fee_based_pass_or_stop( $setup ),
		);
	}


{
my $sub = $bucket->_professional_composed( {} );
isa_ok( $sub, ref sub {} );
ok(   $sub->( 
	{
	pay_basis      => 'Hourly',
	effective_date => '19700901', 
	} ), 
	"Hourly Fall semester date works" 
	);

ok(  $sub->( 
	{
	pay_basis      => 'Hourly',
	effective_date => '19700714', 
	} ), 
	"Hourly Bastille Day date works" 
	);

ok(  $sub->( 
	{
	pay_basis      => 'Salary',
	effective_date => '19700704', 
	} ), 
	"Salary 4th of July date works" 
	);

ok(  ! eval { $sub->( 
	{
	pay_basis      => 'Extra',
	payments       => 'Quarterly',
	effective_date => '19411207', 
	} ) }, 
	"Extra Pearl Harbor Day doesn't work" 
	);
	
my $result = eval { $sub->( 
	{ 
	pay_basis      => 'Extra',
	payments       => 'Quarterly',
	effective_date => '1700201', 
	} ) };
my $at = $@;
	
ok( ! $result, "Single invalid effective date doesn't work" );
isa_ok( $at, ref {} );
ok( exists $at->{message}, "Key 'message' exists in error hash" );
}

=head3 Composing the worker types

Next, I take all of the composed subs for each worke type and compose
them into a single subroutine for that for a grand subroutine.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub effective_date
	{
	my( $bucket, $setup ) = @_;
	
	my $grand_composed = $bucket->__compose_pass_or_skip(
		$bucket->_faculty_composed( $setup ),
		$bucket->_professional_composed( $setup ),
		);

	$bucket->__make_constraint( $grand_composed, $setup );
	}
	
{
my $sub = $bucket->effective_date( {} );
isa_ok( $sub, ref sub {} );
}

my $brick = Brick->new;

my $Input   = {
	worker_type    => 'Faculty',
	pay_basis      => 'Faculty 21',
	effective_date => 1970091,
	};
	
my $setup    = {
	required_fields => [ qw(worker_type pay_basis effective_date) ],
	};

my $Profile = [
	[ required_input => required_fields => $setup ],
	[ effective_date => effective_date  => $setup ],
	];
	
my $lint = $brick->profile_class->lint( $Profile );
is( $lint, 0, "Profile passes lint" );

my $profile = $brick->profile_class->new( $brick, $Profile );
isa_ok( $profile, $brick->profile_class );

print STDERR $profile->explain if $ENV{DEBUG};


my $results = $brick->apply( $profile, $Input );
print STDERR Data::Dumper->Dump( [$results], [qw(results)] ) if $ENV{DEBUG};

isa_ok( $results, ref [], "Results is an array reference" );
is( scalar @$results, scalar @$Profile, 
	"Results has same number of elements as profile" );
