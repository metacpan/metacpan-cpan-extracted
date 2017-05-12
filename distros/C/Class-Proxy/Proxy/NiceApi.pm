package Class::NiceApi;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';
our $DEBUG = 0;

use Class::Maker;
use IO::Extended qw(:all);

	# ThisRoutine to this_routine

	# ThisRoutine to this_routine
		
	# THISRoutTINE to thisroutine

my $callbacks =
{
	to_lc => sub 
	{ 
		use Data::Dumper;
		
		#print Dumper \@_;
		
		my ( $this, $e, $m ) = @_; 
		
		printfln "method '%s' event", ${ $m }; 
		
		${ $m } = lc ${ $m };
	},
	
	with_underscore => sub
	{
		my ( $this, $e, $m ) = @_; 
		
		printfln "method '%s' event", ${ $m }; 
		
		${ $m } =~ s/([a-z])([A-Z])/$1_$2/;
		
		${ $m } = lc ${ $m };
	},
	
	custom => sub
	{
			my ( $this, $e, $m, $victim, $args ) = @_;

				# table contains special translations
				
			my $table = $this->table;
		
			if( exists $table->{${$m}} )
			{
				${$m} = $table->{${$m}};
			}
			else
			{
					# here we translate bla to Bla and bla_bla to BlaBla
					
				if( my @parts = split /_/, ${$m} )
				{										
					${$m} = join '', map { my @chars = split //, $_; $chars[0] = uc $chars[0]; join( '',@chars ) } @parts;
				}
				else
				{
					my @chars = split //, ${$m}; 
					
					$chars[0] = uc $chars[0]; 
					
					${$m} = join( '',@chars );
				}
			}
	},
};	

package Class::NiceApi;

Class::Maker::class 
{
	isa => [qw( Class::Proxy )],

	public => 
	{
		hash => [qw( table )],
	},
	
	private =>
	{
		string => [qw( style )],
	},
	
	default => 
	{
		events => 
		{
			method => $callbacks->{to_lc},
		},
	},
};

sub style : method 
{
	my $this = shift;
	my $key = shift;
	
		die "unknown style '$key' requested" unless exists $callbacks->{$key};
		
		$this->_style = $key;
		
		$this->events->{method} = $callbacks->{$key};
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::NiceApi - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Class::Proxy::NiceApi;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Class::Proxy::NiceApi, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 SEE ALSO

L<perl>.

=cut
