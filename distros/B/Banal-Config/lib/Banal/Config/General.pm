#===============================================
package Banal::Config::General;

use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

use Config::General;
our @ISA = qw(Config::General);

# Apparently, on debian with perl > 5.8.4 croak() doesn't work anymore without this.
# There seems to be some require statement which apparently dies 'cause it can't find Carp::Heavy,
use Carp::Heavy;
use Carp;

use Banal::DateTime;


our $STASH;

#-----------------------------------------------
sub new  {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $opts	= $class->determine_options(@_);
	
	
	print STDERR "\n========= " . __PACKAGE__ . " :   New ...\n" if 0;		# For debugging.
	
	my $self	= $class->SUPER::new(%$opts);
	
 	$class->_bless_into_appropriate_class($self, $opts);
 	
 	return $self;
}


#-----------------------------------------------
# Class method.
# 	-- may be overridden.
#-----------------------------------------------
sub extended_config_class {
	return __PACKAGE__ ."::Extended";
}


#-----------------------------------------------
# Class method.
# 	-- may be overridden.
#-----------------------------------------------
sub default_options {
	return {		
       	-InterPolateVars 		=> 1,
		-InterPolateEnv			=> 1,
		-ExtendedAccess			=> 1,
		-StrictObjects			=> 0,
 		-UseApacheInclude   	=> 1,
 		-IncludeRelative    	=> 1,
 		-IncludeDirectories 	=> 1,
 		-IncludeGlob        	=> 1,
		-UTF8					=> 1,
		-SaveSorted				=> 1,
		-AutoTrue				=> 1,
		-MergeDuplicateBlocks	=> 1,
		-MergeDuplicateOptions	=> 1,
		-LowerCaseNames			=> 1,
		
# 'Banal' options
		-Banal_UsePredefinedVars	=> 1,
		-Banal_StashKind			=> 'normal',		# Could have also been 'global' 
	};
}


#-----------------------------------------------
# Class method.
# 	-- may be overridden, but you better know what you are doing!
#-----------------------------------------------
sub forced_default_options {
	return {		
		-StrictObjects			=> 0,
#		-Plug 					=> { pre_read => *_debug_hook_pre_read }
	};
}


#-----------------------------------------------
# Class method.
# 	-- may be overridden, but you should not need to do that normally. 
#-----------------------------------------------
sub determine_options {
	my $proto 		= shift;
	my $class		= ref($proto) || $proto;
	my $stash		= $class->build_stash();

	# Preserve a global copy of the very first stash we ever build, hopefully when the process first starts.  
	$STASH	||= $stash;	
	
	my $default_opts		= $class->default_options(@_);
	my $forced_default_opts	= $class->forced_default_options(@_);
	
	# Make sure the options passed by the user (i.e. caller) override the defaults.
	# In between, force a few defaults on options. They can still be overriden by user passed options.
	# In the end, make sure we have ExtendedAccess.
	my $opts			= 	{	
								%$default_opts, 
								%$forced_default_opts,
								@_,
								-ExtendedAccess			=> 1,
							};
	
	# Do the right thing, if we are told to use predefined variables (like NOW, TODAY, ...)
	if ($opts->{-Banal_UsePredefinedVars}) {	
		$stash = $STASH  if ($opts->{-Banal_StashKind} =~ /global/i);
	
		# Yes, a copy is needed. Don't just assign the reference. Otherwise, the global STASH will be polluted. 
		my $dc = {%$stash};		
	
		# If there is already a default config, merge it with the stash.
		if ($opts->{-DefaultConfig}) {
			my $odc = $opts->{-DefaultConfig};
					
			if (ref($odc) eq 'HASH') {		
      			$dc = {%$dc, %$odc};
    		} else {
    			croak "Banal::Config::General: Error: Currently, '-DefaultConfig' can only be a reference to a HASH when used in conjunction with '-Banal_UsePredefinedVars'. Let go of one or the other, or both.\n";
    		}
		}
		
		$opts->{-DefaultConfig} = $dc;
	}
	
	return $opts;
}
	
 
#================================
# class method
#================================
sub build_stash {
	my $class	= shift;
	my $stash	= {};
	
	my $now 					= $stash->{'BNL.NOW.OBJ'} 					= Banal::DateTime->now();
	my $today					= $stash->{'BNL.TODAY.OBJ'} 				= $now->clone()->truncate( to => 'day' );
	my $yesterday				= $stash->{'BNL.YESTERDAY.OBJ'} 			= $today->clone()->subtract( days => 1 );
	my $day_before_yesterday	= $stash->{'BNL.DAY_BEFORE_YESTERDAY.OBJ'} 	= $yesterday->clone()->subtract( days => 1 );
		
	my $tomorrow				= $stash->{'BNL.TOMORROW.OBJ'} 				= $today->clone()->add( days => 1 );
	my $day_after_tomorrow		= $stash->{'BNL.DAY_AFTER_TOMORROW.OBJ'} 	= $tomorrow->clone()->add( days => 1 );
	
	$stash->{'BNL.NOW.STR.ISO'} 					= $now->iso8601();
	$stash->{'BNL.TODAY.STR.ISO'} 					= $today->ymd('-');
	$stash->{'BNL.YESTERDAY.STR.ISO'} 				= $yesterday->ymd('-');
	$stash->{'BNL.DAY_BEFORE_YESTERDAY.STR.ISO'}	= $day_before_yesterday->ymd('-');
	$stash->{'BNL.TOMORROW.STR.ISO'} 				= $tomorrow->ymd('-');
	$stash->{'BNL.DAY_AFTER_TOMORROW.STR.ISO'} 		= $day_after_tomorrow->ymd('-');
	
	$stash->{'BNL.NOW.STR'} 						= $now->ymd('') . 'T' . $now->hms('');
	$stash->{'BNL.TODAY.STR'} 						= $today->ymd('');
	$stash->{'BNL.YESTERDAY.STR'} 					= $yesterday->ymd('');
	$stash->{'BNL.DAY_BEFORE_YESTERDAY.STR'}		= $day_before_yesterday->ymd('');
	$stash->{'BNL.TOMORROW.STR'} 					= $tomorrow->ymd('');
	$stash->{'BNL.DAY_AFTER_TOMORROW.STR'} 			= $day_after_tomorrow->ymd('');
	
	$stash->{'BNL.THIS_YEAR'} 						= $now->year();
	$stash->{'BNL.THIS_YEAR.STD'} 					= $now->year_std();

	$stash->{'BNL.THIS_MONTH'} 						= $now->month();
	$stash->{'BNL.THIS_MONTH.STD'} 					= $now->month_std();
	
	$stash->{'BNL.THIS_DAY_OF_MONTH'} 				= $now->day();
	$stash->{'BNL.THIS_DAY_OF_MONTH.STD'} 			= $now->day_std();
	
	my $extra_vars									= $class->extra_predefined_vars(@_);
	$stash 											= {%$stash, %$extra_vars};
	
	return $stash;
} 


#================================
# class method
#    -- Feel free to override
#		Should return a hashable list.
#================================
sub extra_predefined_vars {
	return;
} 





#*************************************************************************
# Private stuff.
#*************************************************************************

# Note that this is a class method!
# Note also that "class" parameter comes before "object".
sub _bless_into_appropriate_class {
  #
  # bless into ::Extended if necessary
  my $class		= shift;
  my $object 	= shift;
  my $opts		= shift;
  
  if ($object->{ExtendedAccess} || $opts->{-ExtendedAccess} || UNIVERSAL::isa($object, "Config::General::Extended")) {	
  	# we are blessing here again, to get into the ::Extended namespace
    # for inheriting the methods available over there, which we don't necessarily have.
    
    my $extended_class = $class->extended_config_class(@_) || $class . "::Extended";
    
    unless (UNVERSAL::isa($object, $extended_class)) {
    	bless $object, $extended_class;
    	eval { require $extended_class; };
    	if ($@) {
      		croak "Banal::Config::General: " . $@;
    	}
    }
  }else { 
	bless $object, $class;
  } 
  
  return $object;
}
 
 
 
#================================
# A pre-read hook for debugging purposes.
#================================
 sub _debug_hook_pre_read {
 	my $fh 		= shift;
 	my $text 	= join ('', @_);
 	my $retval	= 1;
 	
 	print STDERR "\n========= ". __PACKAGE__ . " :   Reading a config file ...\n";
 	
 	my @lines = split ("\n", $text);
 
  	return ($retval, $fh, @lines);
  
 }

1;


__END__


=head1 NAME

Banal::Config::General - A wrapper around Config::General that provides semsible defaults as well as a stash. 


=head1 SYNOPSIS

Here's a snippet.

    use Banal::Config::General;

    my $foo = Banal::Config::General->new(-ConfigFile=>"path/to/config/file");
    
    # The resulting object is blessed into "Banal::Config::General::Extended".
    
    my $v = $foo->value('the-key');
    
    ...

=head1 EXPORT

None.

=head1 EXPORT_OK

None.

=head1 CONSTRUCTORS

=head2 new()

The new() constructor is overriden in order to take into account the default options for this particular class. Other than that, it's essentially a call to SUPER::new. 


=head1 CLASS METHODS

=head2 extended_config_class()

=head2 default_options()  

=head2 forced_default_options()

=head2 extra_predefined_vars()

=head2 build_stash()

=head1 METHODS

=head2 determine_options()



=head1 AUTHOR

"aulusoy", C<< <"dev (at) ulusoy.name"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-banal-config at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Banal-Config>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Banal::Config::General


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Banal-Config>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Banal-Config>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Banal-Config>

=item * Search CPAN

L<http://search.cpan.org/dist/Banal-Config/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 "aulusoy".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Banal::Config::General


