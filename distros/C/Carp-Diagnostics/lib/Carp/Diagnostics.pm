
package Carp::Diagnostics ;

use strict;
use warnings ;

my $WIN32_CONSOLE ;

BEGIN 
{
use English qw( -no_match_vars ) ;
use Sub::Exporter -setup => { exports => [ qw(carp cluck croak confess UseLongMessage) ] } ;
    
use vars qw ($VERSION);
$VERSION = '0.05' ;

#-------------------------------------------------------------------------------

if($OSNAME ne 'MSWin32')
	{
	eval "use Term::Size;" ; ## no critic
	Carp::croak $EVAL_ERROR if $EVAL_ERROR;
	}
else
	{
	eval "use Win32::Console;" ; ## no critic
	Carp::croak $EVAL_ERROR if $EVAL_ERROR ;
	
	$WIN32_CONSOLE= new Win32::Console;
	}
}

#-------------------------------------------------------------------------------

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw() ;

use IO::String ;
use Pod::Text ;

=head1 NAME

Carp::Diagnostics - Carp with a diagnostic message

=head1 SYNOPSIS

	use Carp::Diagnostics qw(cluck carp croak confess) ;
	
	CroakingSub() ;
	
	#---------------------------------------------------------------------------
	
	sub CroakingSub
	{
	
	=head2 CroakingSub
	
	An example of how to use Carp::Diagnostics.
	
	=head3 Diagnostics
	
	=cut
	
	my ($default_rule_name, $name) = ('c_objects', 'o_cs_meta') ;
	
	confess
		(
		"Default rule '$default_rule_name', in rule '$name', doesn't exist.\n",
		
		<<END_OF_POD,
	
	=over
	
	=item Default rule '$default_rule_name', in rule '$name', doesn't exist!
	
	The default rule of a I<FirstAndOnlyOneOnDisk> B<META_RULE> must be registrated before
	the B<META_RULE> definiton. Here is an example of declaration:
	
	 AddRule 'c_o', [ '*/*.o' => '*.c' ], \&C_Builder ;
	 AddRule 'cpp_o', [ '*/*.o' => '*.cpp' ], \&CPP_Builder ;
	 
	 AddRule [META_RULE], 'o_cs_meta',
		[\&FirstAndOnlyOneOnDisk, ['cpp_o', 'c_o' ], 'c_o'] ;
					  ^- slave rules -^    ^-default
	
	=back
	
	=cut
	
	END_OF_POD
		) ;
		
	}

=head1 DESCRIPTION

This module overrides the subs defined in L<Carp> to allow you to give informative diagnostic messages.

=head1 DOCUMENTATION

Perl Best Practices recommends to have a B<DIAGNOSTIC> section, in your B<POD>, where all your warnings and errors are
explained in details. Although I like the principle, I dislike its proposed implementation. Why should we display
cryptic messages at run time that the user have to lookup in the documentation? I also dislike to have the 
diagnostics grouped far from where the errors are generated, they never get updated.

This modules implements the four subs exported by the Carp module (carp, croak, cluck, confess). The new
subs take zero, one or two arguments.

=head2 No argument

=over 2

=item * No message

=back

=head2 One argument

=over 2

=item * A message

=back

=head2 Two arguments

=over 2

=item * A short message

=item * A diagnostic message

The long message is a diagnostic and is the one normally displayed.

You can direct B<Carp::Diagnostics> to display the short message; this is useful when developing modules.
You, the module author, understand short warnings. See L<UseLongMessage>.

=back

Having the possibility to pass one argument or two gives you the possibility to drop-in B<Car::Diagnostics> in your module
without having to modify all the call to the carping subs. if you decide to add Diagnostics to any of your subs, just add the
second argument to, your already existing, carp call. 

The I<podification> functionality is always on.

B<Carp> is used internally so you get an identical functionality.

=head2 POD: Eating your cake and having it too.

The good news is that you are going to do two things in one shot. You'll be giving better diagnostics to your users
and you'll be documenting your modules too.

If the long message (diagnostic) is B<POD> (the first non space character is an '=' at the start of the line), B<Carp::Diagnostics>
will convert the pod to text and pass it to B<Carp::>.

 $ perl cd_test.pl 
 
     Default rule 'c_objects', in rule 'o_cs_meta', doesn't exist!
        The default rule of a *FirstAndOnlyOneOnDisk* META_RULE must be registrated before the
        META_RULE definiton. Here is an example of declaration:
 
          AddRule 'c_o', [ '*/*.o' => '*.c' ], \&C_Builder ;
          AddRule 'cpp_o', [ '*/*.o' => '*.cpp' ], \&CPP_Builder ;
 
          AddRule [META_RULE], 'o_cs_meta',
	     [\&FirstAndOnlyOneOnDisk, ['cpp_o', 'c_o' ], 'c_o'] ;
                                        ^- slave rules -^    ^-default
 
	at cd_test.pl line 26
	   main::CroakingSub() called at cd_test.pl line 11					   

Since the diagnostic is valid pod, it will be extracted when you generate your documentation.

 $ pod2text cd_test.pl 
 
  CroakingSub
    An example of how to use Carp::Diagnostics.
 
   Diagnostics
     Default rule '$default_rule_name', in rule '$name', doesn't exist!
        The default rule of a *FirstAndOnlyOneOnDisk* META_RULE must be
        registrated before the META_RULE definiton. Here is an example of
        declaration:
 
          AddRule 'c_o', [ '*/*.o' => '*.c' ], \&C_Builder ;
          AddRule 'cpp_o', [ '*/*.o' => '*.cpp' ], \&CPP_Builder ;
 
          AddRule [META_RULE], 'o_cs_meta',
	     [\&FirstAndOnlyOneOnDisk, ['cpp_o', 'c_o' ], 'c_o'] ;
                                        ^- slave rules -^    ^-default

=head1 SUBROUTINES/METHODS

=cut

{
my $use_long_message = 1 ;

sub UseLongMessage
{

=head2 UseLongMessage

Give I<0> as argument if you want to display the short message. The only reason to use this
is when developing modules which use B<Carp::Diagnostics>. Even then it's not a very good reason
for not displaying a complete diagnostic.

This setting is global.

=cut

$use_long_message = $_[0] if defined $_[0] ;
return($use_long_message) ;
}

}

#-------------------------------------------------------------------------------

sub croak  
{

=head2 croak

=head3 arguments

=over 2

=item short_message

=item diagnostic (long message)

=back

if the diagnostic is POD, it will be converted to text.

Calls Carp::croak to display the message.

=cut

local $Carp::CarpLevel = 1; ## no critic

Carp::croak
	(
	Podify
		(
		@_ == 1 || (! UseLongMessage()) 
			? $_[0] # user wants short message or there is only one message
			: $_[1]
		)
	) ;


return ;
}

#-------------------------------------------------------------------------------

sub confess
{

=head2 confess

=head3 arguments

=over 2

=item short_message

=item diagnostic (long message)

=back

if the diagnostic is POD, it will be converted to text.

Calls Carp::confess to display the message.

=cut

local $Carp::CarpLevel = 1; ## no critic
Carp::confess
	(
	Podify
		(
		@_ == 1 || (! UseLongMessage()) 
			? $_[0] # user wants short message or there is only one message
			: $_[1]
		)
	) ;

return ;
}

#-------------------------------------------------------------------------------

sub carp
{

=head2 carp

=head3 arguments

=over 2

=item short_message

=item diagnostic (long message)

=back

if the diagnostic is POD, it will be converted to text.

Calls Carp::carp to display the message.

=cut

local $Carp::CarpLevel = 1; ## no critic
Carp::carp
	(
	Podify
		(
		@_ == 1 || (! UseLongMessage()) 
			? $_[0] # user wants short message or there is only one message
			: $_[1]
		)
	) ;

return ;
}

#-------------------------------------------------------------------------------

sub cluck
{

=head2 cluck

=head3 arguments

=over 2

=item short_message

=item diagnostic (long message)

=back

if the diagnostic is POD, it will be converted to text.

Calls Carp::cluck to display the message.

=cut

local $Carp::CarpLevel = 1; ## no critic
Carp::cluck
	(
	Podify
		(
		@_ == 1 || (! UseLongMessage()) 
			? $_[0] # user wants short message or there is only one message
			: $_[1]
		)
	) ;

return ;
}

#-------------------------------------------------------------------------------

sub Podify
{

=head2 Podify

Transforms the passed string from B<POD> to text if it looks like POD. Returns the string. Transformed or not.

This is used internally by this module.

=cut

my ($message) = @_ ;

if(defined $message)
	{
	if($message =~ /\A\s*^=/xsm)
		{
		my ($in, $out) = (IO::String->new($message), IO::String->new());

		Pod::Text->new (width => GetTerminalWidth() - 2 )->parse_from_filehandle($in, $out) ;
		
		return(${$out->string_ref()}) ;
		}
	else
		{
		return($message) ;
		}
	}
else
	{
	return ;
	}
}

#-------------------------------------------------------------------------------

sub GetTerminalWidth
{

=head2 GetTerminalWidth

Return the terminal width or 78 if it can't compute the width (IE: redirected to a file).

This is used internally by this module.

=cut

my ($columns, $rows) ;

if($OSNAME ne 'MSWin32')
	{
	eval "(\$columns, \$rows) = Term::Size::chars *STDOUT{IO} ;" ; ## no critic
	}
else
	{
	($columns, $rows) = $WIN32_CONSOLE->Size();
	}

$columns = 78 if($columns eq $EMPTY_STRING) ;
	
return($columns) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Carp::Diagnostics

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carp-Diagnostics>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-carp-diagnostics@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Carp-Diagnostics>

=back

=head1 SEE ALSO

Perl Best Practice by Damian Conway ISBN: 0-596-00173-8, a tremendous job.

=cut
