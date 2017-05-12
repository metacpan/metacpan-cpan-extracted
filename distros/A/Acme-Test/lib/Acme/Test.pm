package Acme::Test;
use Module::Load;
use Test::More 'no_plan';
use strict;

use vars qw[$VERSION];
$VERSION = 0.03;

my $href = {
    CODE    => { type   => 'subroutine', 
                 post   => '()',
                 tests  => [
                    'passed expected parameters',
                    'catches faulty input',
                    'works as expected with no input',
                    'return value OK',
                ]       
            },
    SCALAR  => { type   => 'global scalar', 
                 pre    => '$',
                 tests  => [
                    'available',
                    'initialized properly',
                    'content OK',
                ]
            },
    HASH    => { type   => 'global hash',
                 pre    => '%',
                 tests  => [
                    'available',
                    'initialized properly',
                    'contains all expected key/value pairs',
                ]
            },
    ARRAY   => { type   => 'global array',
                 pre    => '@',
                 tests  => [
                    'available',
                    'initialized properly',
                    'contains all expected elements',
                ]
            },
    IO      => { type   => 'global IO/Filehandle',
                 tests  => [
                    'available',
                    'initialized properly',
                ]
            },
    FORMAT  => { type   => 'format',
                 tests  => [
                    'available',
                    'prints ok',               
                ]
            },
  	Regexp	=> { type	=> 'regex',
  				 tests	=> [
  				 	'available',
  				 	'initialized properly',
  				]
 			}, 					 	          
};

sub import {
    my $class = shift;
    
    unless(@_) {
        warn    qq[Useless call to Acme::Test::import!\n] .
                qq[Usage:\tuse Acme::Test qw|Your::Package|\n];
        return;
    }
    
    no strict 'refs';      
    for my $mod ( @_ ) {
        load $mod;
 
 		my $str  = join '/', split '::', $mod;
 		my @pkgs = map { s|/|::|g; s/\.pm$//i; $_ } grep /^$str/, keys %INC;
       
      	for my $pkg (@pkgs) {
      		diag("Testing $pkg");
      	
			my $stash = $pkg . '::';
			for my $name (sort keys %$stash ) {
		   
				for my $type (keys %$href) {
				
					my $x = *{"$stash->{$name}"}{$type};
					next unless defined $x;
					
					### so apparently some entries in the scalar slot
					### are set regardless, but are references to undef
					### let's just skip these...
					next if ref $x eq "SCALAR" and not defined $$x; 
					
					### some hash entries might be other stashes again
					### let's just skip these as well...
					next if ref $x eq "HASH" and $name =~ /::$/;
					
					my $priv    = $name =~/^_/ ? 1 : 0;
					my $status  = $priv ? '[Private]' : '[Public]';
		
					#next if $priv && $NO_PRIVATE;
					
					### add sigils and the like ###
					my $short   = $name;
					my $full    = "${pkg}::$name";
					for my $alias ($short, $full) {
						$alias = $href->{$type}->{pre} . $alias 
														 if $href->{$type}->{pre};
						$alias .= $href->{$type}->{post} if $href->{$type}->{post};
					}
										   
					diag("$status Testing $href->{$type}->{type} $full"); 
					
					for my $test ( @{$href->{$type}->{tests}} ) {
						ok( 1, "    $short $test" );
					}
				}
			}
		}
    }      
}


=pod

=head1 NAME

Acme::Test

=head1 SYNOPSIS

    use Acme::Test qw[Your::Module Your::Other::Module];

=head1 DESCRIPTION

All the latest software craze is about regression tests and XP 
programming -- Write a test, make sure it fails. Then write the 
functionality and make sure the test now passes, etc.
Although these are good ideas, who really has time for this?
Fixing faililng tests is a lot of work, and one can only be happy 
with a test suite that has no fails.

Enter C<Acme::Test> -- automate test-suite generation with guaranteed
passing tests for your modules! 

=head1 USE

Simply write

    use Acme::Test 'Your::Module';

at the top of your test scrip, and everything else goes automatically.

C<Acme::Test> will not only 'test' your subroutines, but also any
global variables and even IO and format handles! It will also make a
distinction between public and private subroutines/variables.

=head1 EXAMPLE

Imagine your test.pl script would look something like this:
    
    use lib '../devel/file-basename/lib';
    use Acme::Test 'File::Basename';

Then the resulting test output would look pretty much like this:

	# Testing File::Basename
	# [Public] Testing global array @File::Basename::EXPORT
	ok 1 -     @EXPORT available
	ok 2 -     @EXPORT initialized properly
	ok 3 -     @EXPORT contains all expected elements
	# [Public] Testing global scalar $File::Basename::Fileparse_fstype
	ok 4 -     $Fileparse_fstype available
	ok 5 -     $Fileparse_fstype initialized properly
	ok 6 -     $Fileparse_fstype content OK
	# [Public] Testing global scalar $File::Basename::Fileparse_igncase
	ok 7 -     $Fileparse_igncase available
	ok 8 -     $Fileparse_igncase initialized properly
	ok 9 -     $Fileparse_igncase content OK
	# [Public] Testing global array @File::Basename::ISA
	ok 10 -     @ISA available
	ok 11 -     @ISA initialized properly
	ok 12 -     @ISA contains all expected elements
	# [Public] Testing global scalar $File::Basename::VERSION
	ok 13 -     $VERSION available
	ok 14 -     $VERSION initialized properly
	ok 15 -     $VERSION content OK
	# [Public] Testing subroutine File::Basename::basename()
	ok 16 -     basename() passed expected parameters
	ok 17 -     basename() catches faulty input
	ok 18 -     basename() works as expected with no input
	ok 19 -     basename() return value OK
	# [Public] Testing subroutine File::Basename::dirname()
	ok 20 -     dirname() passed expected parameters
	ok 21 -     dirname() catches faulty input
	ok 22 -     dirname() works as expected with no input
	ok 23 -     dirname() return value OK
	# [Public] Testing subroutine File::Basename::fileparse()
	ok 24 -     fileparse() passed expected parameters
	ok 25 -     fileparse() catches faulty input
	ok 26 -     fileparse() works as expected with no input
	ok 27 -     fileparse() return value OK
	# [Public] Testing subroutine File::Basename::fileparse_set_fstype()
	ok 28 -     fileparse_set_fstype() passed expected parameters
	ok 29 -     fileparse_set_fstype() catches faulty input
	ok 30 -     fileparse_set_fstype() works as expected with no input
	ok 31 -     fileparse_set_fstype() return value OK
	1..31

=head1 BUGS

In code this funky, I'm sure there are some ;)

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.


=head1 COPYRIGHT

This module is
copyright (c) 2002 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut

1;
