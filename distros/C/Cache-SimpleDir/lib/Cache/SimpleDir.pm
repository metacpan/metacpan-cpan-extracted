# ABSTRACT: Cache time consuming subroutines, rest api calls
# George Bouras , george.mpouras@yandex.com
# Hellas/Athens , 06 Feb 2019

package	Cache::SimpleDir;
use B;
use File::Path::Tiny;
our $VERSION = '2.1.4';
our @ISA     = ();
our $ERROR   = undef;

#	Object constructor
#	__* properties are module privates
#	my $cache = Cache->new(cache_dir=>'/tmp', callback=>'Get_new_data', expire_sec=>3, verbose=>'False') or die "oups $Cache::ERROR\n";
sub new
{
my $class	= shift || __PACKAGE__;
my $self	={
error		=> 0,
error_msg	=> 'ok',
expire_sec	=> 3600,			# After how many seconds the record will be considered expired and a new one should cached using the callback
verbose		=> 'False',			# Verbose if TRUE or 1
callback	=> '__NEW_RECORD',	# Subroutine name that cache new data
cache_dir	=> $^O=~/(?i)MSWin/ ? (local $_="$ENV{TEMP}\\cache", s/\\/\//g, $_) : '/tmp/cache',
__dir 		=> undef,			# The subdirectory under the "cache_dir" of your cached files
__record	=> undef,
__tmp		=> undef};

# Define properties from the arguments. At @_ remain only the args that are not matching to a propery

	for (my($i,$j)=(0,1); $i < scalar(@_) - (scalar(@_) % 2); $i+=2,$j+=2) {

		if ( exists $self->{$_[$i]} ) {

			if ('__' eq substr $_[$i],0,2) {
			$ERROR = "You tried to set the internal private property \"$_[$i]\" to value \"$_[$j]\" , sorry this is not permitted. Valid user properties are : ". join(', ', sort grep /^[^_]/, keys %{$self});
			@{$self}{qw/error error_msg/}=(10,$ERROR);
			return undef
			}

		$self->{$_[$i]}=$_[$j]
		}
		else {		
		$ERROR = "You tried to define the invalid property \"$_[$i]\" to value \"$_[$j]\" , sorry this is not permitted . Valid proerties are : ". join(', ', sort grep /^[^_]/ , keys %{$self});
		@{$self}{qw/error error_msg/}=(11,$ERROR);
		return undef
		}
	}

$self->{verbose}	= $self->{verbose}=~/(?i)t|y|1/ ?1:0;
$self->{cache_dir}	=~s/[\/\\]*$//;



# Define the "__userclass" Class of the callback
# Check if the subroutine exists	$self->{callback}  
# You can call it as				$self->{__userclass}->can($self->{callback})->( 1547328808 )

	if ($self->{callback} eq '__NEW_RECORD') {
	$self->{__userclass} = $class
	}
	else {
	$self->{__userclass} = [caller]->[0];

		if (ref $self->{callback}) {

			if ('CODE' eq ref $self->{callback}) {
			$self->{__callbackname} = B::svref_2object($self->{callback})->GV->NAME;
			$self->{__dir} = "$self->{cache_dir}/$self->{__userclass}-$self->{__callbackname}"
			}
			else {
			$ERROR = "As callback you used a non CODE reference";
			@{$self}{qw/error error_msg/}=(12,$ERROR);
			return undef
			}
		}
		else {
		$self->{__dir} = "$self->{cache_dir}/$self->{__userclass}-$self->{callback}";

			if ('CODE' ne ref $self->{__userclass}->can($self->{callback}))	{	
			$ERROR = "Function \"$self->{__userclass}::$self->{callback}\" does not exist";
			@{$self}{qw/error error_msg/}=(13,$ERROR);
			return undef
			}
		}
	}

# Create and clear the top cache directory if missing

	if (-d $self->{__dir}) {

		if (-f "$self->{__dir}/lock" ) {

			if ( $^O=~/(?i)MSWin/ ) {
			print "Removing lock file : $self->{__dir}/lock\n" if $self->{verbose};

				unless ( unlink "$self->{__dir}/lock" ) {
				$ERROR = "Could not remove lock \"$self->{__dir}/lock\" because \"$!\"";
				@{$self}{qw/error error_msg/}=(14,$ERROR);
				return undef
				}
			}
			else {

				if (open __LOCK, '<', "$self->{__dir}/lock") {
				$self->{__tmp} = readline __LOCK;
				close __LOCK;

					unless (-d "/proc/$self->{__tmp}") {
					print "Removing lock file \"$self->{__dir}/lock\" of non existing process \"$self->{__tmp}\"\n" if $self->{verbose};

						unless ( unlink "$self->{__dir}/lock" ) {
						$ERROR = "Could not remove lock \"$self->{__dir}/lock\" of non existing process \"$self->{__tmp}\" because \"$!\"";
						@{$self}{qw/error error_msg/}=(15,$ERROR);
						return undef
						}							
					}
				}
				else {
				$ERROR = "Could not read lock file \"$self->{__dir}/lock\" because \"$!\"\n";
				@{$self}{qw/error error_msg/}=(16,$ERROR);
				return undef
				}
			}
		}

	unless (opendir CACHE, $self->{__dir}) {$ERROR="Could not read cache directory \"$self->{__dir}\" because \"$!\""; @{$self}{qw/error error_msg/}=(17,$ERROR); return undef}

		while (my $node = readdir CACHE) {
			if ((-d "$self->{__dir}/$node") && ($node=~/^\d+$/)) {
			$self->{__record} = $node;
			last
			}
		}

	closedir CACHE
	}
	else {

		unless ( File::Path::Tiny::mk $self->{__dir} ) {
		$ERROR = "Could not create the top cache directory \"$self->{__dir}\" because \"$!\"";
		@{$self}{qw/error error_msg/}=(18,$ERROR);
		return undef
		}
	}

bless $self, $class
}



#	Called automatically when a subroutine called functional instead of OO
sub __NOT_AN_OBJECT
{
my ($class,$method)	= shift =~/^(.*?)::(.*)/;
my $user = $ENV{USERNAME} // [getpwuid $>]->[0];
my $args = join ', ', @_;

print STDOUT<<STOP;
Hello $user,

$class\::$method method did not called as an object, change your code similar to

  use $class;
  my \$obj = $class->new( ... );
     \$obj->$method($args);

STOP
exit 20
}



#	Put new data at the cache if the previous is expired
#	This subroutine is called automatically as needed
#	On error make it return undef of 0
#	Its first called with the 2 guaranteed arguments
#
#	$_[0]  The cache directory to put your data (automatically created)
#
#   And any other arguments you passed at the    $foo->data('a', 'b', ...)
#
sub __NEW_RECORD
{
my $dir = shift;
open  FILE,'>',"$dir/example.txt" or return undef;
print FILE 'A callback example using arguments : '. join(',', @_);
close FILE
}



#	Insert to cache new data using the function $obj->{callback}
#	It is called automatically as needed
#	On success returns the record
#
sub __CACHE_DATA
{
my $obj = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
my $time= time;

	unless (-d "$obj->{__dir}/$time") {

		if (-f "$obj->{__dir}/lock") {

			if (open __LOCK, '<', "$obj->{__dir}/lock") {
			$obj->{__tmp} = readline __LOCK;
			close __LOCK;
			$ERROR = "An other process \"$obj->{__tmp}\" is trying to get new cache data write now\n";
			@{$obj}{qw/error error_msg/}=(2000,$ERROR);
			return undef
			}
			else {
			$ERROR = "Could not read lock file \"$obj->{__dir}/lock\" because \"$!\"\n";
			@{$obj}{qw/error error_msg/}=(20,$ERROR);
			return undef
			}
		}
		else {

			# Create lock file
			if (open __LOCK, '>', "$obj->{__dir}/lock") {
			print __LOCK $$;
			close __LOCK
			}
			else {
			$ERROR = "Could not create lock file: $obj->{__dir}/lock\n";
			@{$obj}{qw/error error_msg/}=(21,$ERROR);
			return undef
			}
		}

		# Create cache record subdirectory
		unless (mkdir "$obj->{__dir}/$time") {
		$ERROR = "Could not create cache record directory : $obj->{__dir}/$time\n";
		@{$obj}{qw/error error_msg/}=(22,$ERROR);
		return undef
		}

		if ( 'CODE' eq ref $obj->{callback} ) {

			unless ( $obj->{callback}->("$obj->{__dir}/$time", @_) ) {
			$ERROR = "Cache new data fuction $obj->{__userclass}::$obj->{__callbackname} return a false value";
			@{$obj}{qw/error error_msg/}=(24,$ERROR);
			return undef
			}
		}
		else {

			unless ( $obj->{__userclass}->can($obj->{callback})->("$obj->{__dir}/$time", @_) ) {
			$ERROR = "Cache new data fuction $obj->{__userclass}::$obj->{callback} return a false value";
			@{$obj}{qw/error error_msg/}=(25,$ERROR);
			return undef
			}
		}

	unlink "$obj->{__dir}/lock"
	}

$time
}



#	Returns the cache record. If it is expired or not exists get new data using the __CACHE_DATA
sub get
{
my $obj = ((exists $_[0]) && (__PACKAGE__ eq ref $_[0])) ? shift : __NOT_AN_OBJECT([caller 0]->[3],@_);
	
	if (defined $obj->{__record}) {

		if ($obj->{expire_sec} > time - $obj->{__record}) {
		print 'use existing '.(time - $obj->{__record}) ."/$obj->{expire_sec}\n" if $obj->{verbose};
		"$obj->{__dir}/$obj->{__record}"
		}
		else {
		print "New get\n" if $obj->{verbose};
		$obj->{__tmp} = $obj->__CACHE_DATA(@_);

			if ($obj->{__tmp}) {

				unless (File::Path::Tiny::rm "$obj->{__dir}/$obj->{__record}") {
				$ERROR = "Could not remove expired cache directory \"$obj->{__dir}/$obj->{__record}\" because \"$!\"";
				@{$obj}{qw/error error_msg/}=(30,$ERROR);
				return undef
				}

			$obj->{__record} = $obj->{__tmp};
			"$obj->{__dir}/$obj->{__record}"
			}
			else {

				if ($obj->{error}==2000) {
				"$obj->{__dir}/$obj->{__record}"
				}
				else {
				undef
				}
			}
		}
	}
	else {
	print "new, was empty \n" if $obj->{verbose};
	$obj->{__record} = $obj->__CACHE_DATA(@_);

		if ($obj->{__record}) {
		"$obj->{__dir}/$obj->{__record}"
		}
		else {
		undef
		}
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cache::SimpleDir - Cache time consuming subroutines, rest api calls

=head1 VERSION

version 2.1.4

=head1 SYNOPSIS

  #!/usr/bin/perl
  use Cache::SimpleDir;

  my $key1   =  Cache::SimpleDir->new(
  callback   => 'GetWeather',
  cache_dir  => '/tmp',
  expire_sec => 1800,
  verbose    => 'false') or die $Cache::SimpleDir::ERROR;

  my $key2   =  Cache::SimpleDir->new(
  callback   => \&GetCountryInfo,
  cache_dir  => '/tmp',
  expire_sec => 2592000,
  verbose    => 'true') or die $Cache::SimpleDir::ERROR;

  my $where_are_my_data = $key1->get('a','b','c') or die $Cache::SimpleDir::ERROR;
  print "data are at: $where_are_my_data\n";

  #     How to get and cache new data
  sub   GetWeather {
  my    $dir = shift;
  open  FILE, '>', "$dir/file.txt" or return undef;
  print FILE 'Example of callback. Arguments: ', join ',', @_;
  close FILE
  }

  sub   GetCountryInfo {
  my    $dir = shift;
  ...
  }

=head1 DESCRIPTION

Every time you use the B<get> method, it returns only
the cache directory where your files are stored.
It is up to your code, to do something with these files.
Read them, copy them or whatever.

If the cache data are older than I<expire_sec> then the 
I<callback> subroutine is called automatically;
new data are cached, while the old are deleted.
So there is no need for a B<set> method.

Write at the I<callback> subroutine the code, that generate new data.
Its first argument is always the directory that you should write your cached files.
Any optional argument used at the B<get> is passed at the I<callback>

It is thread safe.

=head1 ABSTRACT

Cache time consuming subroutines or paid api calls

=head1 ERROR HANDLING

On error B<get> returns FALSE. Sets the error message at the variable $Cache::SimpleDir::ERROR
and at the property $obj->error_msg while the error code is at $obj->error

=head1 METHODS

=head2 new

Generate and return a new cache object, while it initialize/overwrite the default properties

B<cache_dir>  I<The root cache directory of your key>

B<callback>   I<Name or code reference, of the subroutine that caches new data>

B<expire_sec> I<After how many seconds the record will be considered expired and a new one should cached using the callback>

B<verbose>    I<Verbose operation if TRUE or 1>

There is not support for multiple cache keys at the same object.
This is by design, because it must be fast and simple.
If you want multiple keys, then create multiple objects with different properties e.g.

  my $key1 = SimpleDir->new(callback=>'Sub1', cache_dir=>'/tmp', expire_sec=>300);
  my $key2 = SimpleDir->new(callback=>'Sub2', cache_dir=>'/tmp', expire_sec=>800);
  ...

=head2 get

Returns the cache directory where your files/dirs are stored.
If the the files/dirs are older than I<expire_sec> seconds then
are deleted and new one are cached by calling automatically the subroutine
defined at the I<callback>

If your code at the B<callback> encount an error then you must return with FALSE.
On success, at the end, your code must return TRUE.

=head1 SEE ALSO

B<CGI::Cache> Perl extension to help cache output of time-intensive CGI scripts

B<File::Cache> Share data between processes via filesystem

B<Cache::FastMmap> Uses an mmap'ed file to act as a shared memory interprocess cache

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
