package Crypt::License::Util;
require Exporter;
use vars qw($VERSION $ptr2_License @ISA @EXPORT);
@ISA		= qw(Exporter);
@EXPORT		= qw( license4server path2License chain2next chain2prevLicense exportNext2 
		     requireLicense4 requirePrivateLicense4 modules4privateList);
$VERSION	= do { my @r = (q$Revision: 2.00 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
$ptr2_License	= {'next' => ''};

sub license4server {
  die "user $> may not access Server License" if $>;
  die "Server License missing" unless defined $main::ptr2_License;
  my $m = caller;
    unless (defined ($p = ${"${m}::ptr2_License"})) {
    $p = &_createPointer2License($m);
  }
  $p->{path} = $main::ptr2_License->{path};
}
sub path2License {
  my($n) = @_;
  $n = 'README.LICENSE' unless $n;
  my ($m,$f) = caller;
  my $p;
  unless (defined ($p = ${"${m}::ptr2_License"})) {
    $p = &_createPointer2License($m);
  }
  $p->{path} = (getpwuid((stat($f))[4]))[7] .'/'.$n;
}
sub chain2next {
  my($p2L) = @_;
  $p2L->{next} = caller(1);
}
sub chain2prevLicense {
  my $m = caller;
  my $p;
  unless (defined ($p = ${"${m}::ptr2_License"})) {
    $p = &_createPointer2License($m);
  }
  $p->{next} = caller(1);
}
sub exportNext2 {
#  my @c1 = caller(1);
#  my $c = (@c1 && $c1[3] =~ /useLicense4$/) 
#	? $c1[0] : caller;
  my $c = caller;
  my $rv = 0;
  foreach my $m (@_) {
    next if defined ${"${m}::ptr2_License"};
    ++$rv;
    &_createPointer2License($m)->{next} = $c;
  }
  return $rv;
}
sub requireLicense4 {
  $ptr2_License->{next} = caller;
  my @m = @_;
  foreach my $m ( @m ) {
    ($m .= '.pm') =~ s#::#/#g; 
    require $m;
  }
  goto &exportNext2;
}
sub requirePrivateLicense4 {
  my $c = caller;
  $ptr2_License->{next} = $c;
  &_array2privateList($c,@_);
  my @m = @_;
  foreach $m ( @m ) {
    ($m .= '.pm') =~ s#::#/#g;
    require $m;
  }
  goto &exportNext2;
}
sub modules4privateList {
  my $c = caller;
  return &_array2privateList($c,@_);
}
sub _array2privateList {
  my ($m, @m) = @_;
  my $p;
  if (defined ($p = ${"${m}::ptr2_License"})) {
    if (exists $p->{private}) {
      push(@m, split(',',$p->{private}));
      my @dups = sort @m;
      @m = ();
      foreach $m (@dups) {
	next if @m && $m eq $m[0];
	unshift(@m,$m);
      }
    }
  } else {
    $p = _createPointer2License($m);
  }
  $p->{private} = join(',',@m);
}
sub _createPointer2License {
  my ($m) = @_;
    %{"${m}::_ptr2_LicenseHash"} = ();
    ${"${m}::ptr2_License"} = \%{"${m}::_ptr2_LicenseHash"};
  }
1;
__END__

=head1 NAME

Crypt::License::Util - Perl extension to examine a license file.

=head1 USEAGE

	use Crypt::License::Util

=head1 SYNOPSIS

	use Crypt::License::Util

	$file_path = license4server;
	$file_path = path2License([optional lic file name]);
deprecated $callr_pkg = chain2next($ptr2_License_hash);
	$prev_module = chain2prevLicense;
	$rv=exportNext2(Package::Name,[next::name],[...]);
	$rv=requireLicense4(Package::Name,[next::name],[...]);
	$rv=modules4privateList(Package::Name,[next::name],[...]);
	$rv=requirePrivateLicense4(Package::Name,[next::name],[...]);


=head1 DESCRIPTION

=over 2

=item $file_path = license4server;

  Creates $ptr2_License in calling module if necessary.

  Sets:	'path' => '/web/server/license/path/README.LICENSE'

  ONLY for the root user. Dies otherwise.

=item $file_path = path2License([optional lic file]);

  Creates $ptr2_License in calling module if necessary.

  Sets the following:
  $ptr2_License = {
	'path' => '/user/home/README.LICENSE'
	}; 
	as the default or to 
	'path' => '/user/home/some/path/optional.name'
	if a relative file path/name is supplied

  In both cases the absolute /file/path is returned.

=item $callr_pkg = chain2next($ptr2_License_hash);

DEPRECATED

  Sets the following in the calling (current) package:
  $ptr2_License = {'next' => 'previous caller package name';
	and returns this value. This is a convenience and is
	not currently use for anything. IT MAY CHANGE!

=item $prev_module = chain2prevLicense;

  Creates $ptr2_License in calling module if necessary.

  Sets the following:
	$ptr2_License = {
	'next' => 'previous module name'
	};

=item $rv=exportNext2(Package::Name,[next::name],[...]);

  Sets the following in the target Package::Name:
  $ptr2_License = {'next' => 'this (current) package name'};
  if $ptr2_License does not exist in the target package;

  returns # of exports to modules with no $ptr2_License.
  returns 0 if no exports were needed

=item $rv=requireLicense4(Package::Name,[next::name],[...]);

  The same as:
	require Package::Name;
	$rv += exportNext2(Package::Name);
	repeated for list.....

To achive the equivalent of something like:

	use Package::Name

you can try:

	require Package::Name;
	import Package::Name  qw(list of args);
	exportNext2(Package::Name);

however, this construct does not work for some packages, notably the ones
using the  Class::Struct module. A better approach for modules that are
not encrypted but that need a $ptr2_License is to simple 'use' them in the
normal fashion and call the exportNext2 method later.

=item $rv=modules4privateList(Package::Name,[next::name],[...]);

Creates the entry:

	$ptr2_License = {
	 'private' => 'Package::Name,[next::name],[...]'
	};

..in the calling module. Returns the hash value string.

=item $rv=requirePrivateLicense4(Package::Name,[next::name],[...]);

  The same as:
	require Package::Name;
	exportNext2(Package::Name);
	repeated for list....
  followed by:
	$rv=modules4privateList(Package::Name,[next::name],[...])

=back

By default the LICENSE file must be located in the users home directory and
the calling file uid must belong to that user. If this is not the case,
create B<$ptr2_License> manually rather than using the module call.

=head1 HOWTO

Every module that imports a licensed module must contain a HASH pointer for
the License object. The pointer and object may be created manually or using
the Crypt::License::Util tool set. The License object may contain one or more
of the following entries:

 use vars qw( $ptr2_License );
 $ptr2_License = {
      'private'   => 'name1, name2,...',  # use private key 
                                          # module name
      'path'      => 'path to License file',
      'next'      => 'caller module name',
      'expires    => 'seconds until expiration',
      'warn'      => 'warning messages',  # not implemented
  };

In addition there are other keys that are used by the
Crypt::License::Notice module including but not limited to:

      'ACTION'    => 'mailer action',
      'TMPDIR'    => 'path to writable tmp dir',
      'INTERVALS' => 'reporting intervals',
      'TO'        => 'notice delivery email target',

A module which will call a Licensed module must provide a HASH pointer and
key/value pairs for a either B<next> or B<path> (and B<private> if required)
in order to successfuly import the module. The HASH pointer must be
instantiated from within the module, not assumed from a prior export from a
parent module. The following Crypt::License::Util routines instantiate the
HASH pointer '$ptr2_License':

  license4server	 {path} => useable only by root
  path2License		 {path} => /user/home/README.LICENSE
  chain2next		DEPRECATED
  chain2prevLicense	 {next} => caller module name

Exports of the HASH pointer are useful for Licensed modules
which provide subprocesses to non-Licensed modules such as the handlers for
Apache-AuthCookie. The following Crypt::License::Util routines export
the HASH pointer '$ptr2_License' automatically:

  exportNext2		 {next} => caller module name
  requireLicense4	 {next} => caller module name
  requirePrivateLicense4 {next} => caller module name

For Licensed module calls of usr Private modules, the B<private> key must be
set with the module names. The following Crypt::License::Util routines will
automatically instantiate the private key:

  modules4private	 {private} => module,name,scalar
  requirePrivateLicense4 {private} => module,name,scalar

EXAMPLES:
  example 1:
  Parent module	XYZ
	package XYZ;
	use Crypt::License::Util;
	path2License;
	requireLicense4('Module::A','Module::B');
	requirePrivateLicense4('User::X','User::Y');

  This is the same as:
	package XYZ;
	use vars qw($ptr2_License);
	$ptr2_License = {
		'path' => '/usr/homedir/README.LICENSE'};
	require Module::A;
	require Module::B;
	$Module::A::ptr2_License = 
		\%Module::A::{'next' => 'XYZ'};
	$Module::B::ptr2_License = 
		\%Module::B::{'next' => 'XYZ'};
	$ptr_License->{private} = 'User::X,User::Y';
	require User::X;
	require User::Y;
	$User::X::ptr2_License = 
		\%User::X::{'next' => 'XYZ'};
	$User::Y::ptr2_License = 
		\%User::Y::{'next' => 'XYZ'};

  example 2:
	package Module::A;
	use Time::Local;
	use Crypt::License::Util;
	exportNext2('Time::Local');
	chain2prevLicense;
	requireLicense4('Delta::Module');

  This is the same as:
	package Module::A;
	use Time::Local
	use vars qw($ptr2_License);
	$Time::Local::ptr2_License = 
		\%Time::Local::{'next' => 'Module::A'};
	$ptr2_License = {'next' => 'XYZ'};
	require Delta::Module;
	$Delta::Module::ptr2_License =
		\%Delta::Module::{'next' => 'Module::A'};

  To notify YOU of License expiration, add the 
  following to module XYZ:
	....
	use Crypt::License::Notice;
	if ( exists $ptr2_License->{expires} ) {
		require Crypt::License::Notice;
		Crypt::License::Notice->check($ptr2_License);
	}

		
  example 3: This is for an apache web server.

  In B<startup.pl>
	....
	use lib qw(/usr/local/apache/libhandlers);
	$main::ptr2_License = {
		'path' => '/usr/local/apache/README.LICENSE'
	};
	
  In handlers called from PerlRequire or PerlHandler
	package Lmnop;
	....
	Apache::AuthCookie;
	use Crypt::License::Util;
	license4server;
	requireLicense4('WhatEver::Module');
	exportNext2('Apache::AuthCookie');

  This is the same as:
	package Lmnop;
	....
	use Apache::AuthCookie;
	use vars qw($ptr2_License);
	$ptr2_License = {
		'/usr/local/apache/README.LICENSE'
	};
	require WhatEver::Module;
	$WhatEver::Module::ptr2_License =
		\%WhatEver::Module::{'next' = 'Lmnop'};
	$Apache::AuthCookie::ptr2_License =
		\%Apache::AuthCookie::{'next' = 'Lmnop'};

  ... continuing calling Lmnop from user space...
	package User::Space;
	use Crypt::License::Util;
	path2License;
	..... 
	# Lmnop loaded by mod_perl handler
	# sees User::Space as it's caller
	&Lmnop->function1(args);

  This is the same as:
	package User::Space;
	use vars qw($ptr2_License);
	$ptr2_License = {
		'path' => '/user/home/README.LICENSE');
	
	&Lmnop->function1(args);

=head1 EXPORTS

  license4server
  path2License 
  chain2next 
  chain2prevLicense
  exportNext2
  requireLicense4
  modules4private
  requirePrivateLicense4

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 COPYRIGHT

Copyright 2001 Michael Robinton, BizSystems.
All rights reserved.

=head1 SEE ALSO

L<perl(1)>, L<Crypt::License(3)>

=cut

