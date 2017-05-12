package Authen::Simple::IMAP;

use 5.8.6;
use warnings;
use strict;
use Carp;
use base 'Authen::Simple::Adapter';
#use Data::Dumper;
use Params::Validate qw(validate_pos :types);

our $VERSION = '0.1.2';

__PACKAGE__->options({
	host => {
		type     => Params::Validate::SCALAR,
		optional => 1,
		depends  => [ 'protocol' ],
	},
	protocol => {
		type     => Params::Validate::SCALAR,
		default  => 'IMAP',
		optional => 1,
		depends  => [ 'host' ],
	},
	imap => {
		type     => Params::Validate::OBJECT,
		can		 => ['login','errstr'],
		optional => 1,
	},
	timeout => {
		type 	=> Params::Validate::SCALAR,
		optional => 1,
	},
	escape_slash => {
		type 	 => Params::Validate::SCALAR,
		optional => 1,
		default  => 1,
	},
});

sub init {
	my ($self, $args) = @_;
	if ( $args->{log} ) {
		$self->log($args->{log});
	}
	$self->log->info("Starting init routine for Authen::Simple::IMAP");
	$self->log->debug("Starting init routine\n") if $self->log;
	my $is_user_provided_object;
	my @imap_args = $args->{host};
	if ( defined($args->{timeout}) ) {
		push(@imap_args, timeout => $args->{timeout});
	}
	if ( defined($args->{imap}) ) {
		$self->log->info("setting up with user provided IMAP object ".
			ref($args->{imap})."\n") if $self->log;
		$is_user_provided_object = 1;
	}
	elsif ( $args->{protocol} eq 'IMAPS' ) {
		require Net::IMAP::Simple::SSL;
	}
	elsif ( $args->{protocol} eq 'IMAP' ) {
		require Net::IMAP::Simple;
	}
	elsif ( defined($args->{protocol}) ) {
		croak "Valid protocols are 'IMAP' and 'IMAPS', not '".$args->{protocol}."'";
	}
	else { 
		croak "A protocol or an imap object is required";
	}
	my $obj = $self->SUPER::init($args);
	$obj->{imap_args} = \@imap_args;
	if ( $is_user_provided_object ) {
		$obj->{user_provided_object} = $args->{imap};
	}
	return $obj;
}

sub connect {
	my $self = shift;
	die 'Should never happen' if !defined($self->{imap_args});
	if ( $self->{user_provided_object} ) {
		$self->{imap} = $self->{user_provided_object};
		return;
	}
	my @imap_args = @{$self->{imap_args}};
	#warn 'imap args  '.join(", ",@imap_args)."\n";
	my $host = shift(@imap_args);
	my $args = { @imap_args };
	unshift(@imap_args,$host);

	local( $SIG{ALRM} ) = sub { croak "timeout while connecting to server" };
	if ( defined($args->{timeout}) ) {	
		alarm $args->{timeout};
	}
	else {
		alarm 90;
	}
	if ( defined($self->{imap}) ) {
		$self->log->info("already have a user provided IMAP object ".
			ref($self->{imap})."\n") if $self->log;
	}
	elsif ( $self->{protocol} eq 'IMAPS' ) {
		local( $SIG{ALRM} ) = sub { 
			croak "timeout while connecting to IMAPS server at $host" 
		};
		$self->log->info("connecting to ".$host." with IMAPS\n")
			 if $self->log;
		$self->{imap} = Net::IMAP::Simple::SSL->new(@imap_args) ||
			die "Unable to connect to IMAPS: $Net::IMAP::Simple::SSL::errstr\n";
	}
	elsif ( $self->{protocol} eq 'IMAP' ) {
		local( $SIG{ALRM} ) = sub { 
			croak "timeout while connecting to IMAP server at $host" 
		};
		$self->log->info("connecting to ".$host." with IMAP (no SSL)\n")
			 if $self->log;
		$self->{imap} = Net::IMAP::Simple->new(@imap_args) ||
			die "Unable to connect to IMAP: $Net::IMAP::Simple::errstr\n";
	}
	else { 
		croak 'This should never happen!';
	}
	alarm 0;
	return $self->{imap};
}


sub check {
	my @params = validate_pos(@_,
		{
			type => OBJECT,
			isa  => 'Authen::Simple::IMAP',
		},
		{
			type => SCALAR,
		},
		{
			type => SCALAR,
		},
	);
	my ($self,$username,$password) = @params;
	$self->log->debug("Starting check routine\n") if $self->log;
	#$self->log->debug("Username = '$username'");
	#$self->log->debug("Password = '$password'");
	
	if ( $self->escape_slash ) {
		$password =~ s[\\][\\\\]g;
	}
	#$self->log->debug("Password post escape_slash = '$password'");

	#delete($self->{imap}) if exists($self->{imap});

	$self->connect;

	$self->log->info('Attempting to authenticate user \''.$username.'\''."\n") 
		if $self->log;
	if ( $self->imap->login($username,$password) ) {
		$self->log->info("Successfully logged in '".$username."'\n") 
			if $self->log;
		$self->imap->quit() if  $self->imap->can('quit');
		$self->imap(undef);
		return 1;
	}
	my $fail = 'Failed to authenticate user \''.$username.'\'';
	$fail .= ': '.$self->imap->errstr if $self->imap->errstr;
	$self->log->info($fail) if $self->log;
	$self->imap->quit() if  $self->imap->can('quit');
	$self->imap(undef);
	return 0;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Authen::Simple::IMAP - Simple IMAP and IMAPS authentication

=head1 SYNOPSIS

    use Authen::Simple::IMAP;

    my $imap = Authen::Simple::IMAP->new(
        host => 'imap.example.com',
        protocol => 'IMAPS',
    );

    if ( $imap->authenticate( $username, $password ) ) {
           # successful authentication
    }

     # or as a mod_perl Authen handler

     PerlModule Authen::Simple::Apache
     PerlModule Authen::Simple::IMAP

    PerlSetVar AuthenSimplePAM_host     "imap.example.com"
    PerlSetVar AuthenSimplePAM_protocol "IMAPS"

     <Location /protected>
         PerlAuthenHandler Authen::Simple::IMAP
         AuthType          Basic
         AuthName          "Protected Area"
         Require           valid-user
    </Location>

=head1 DESCRIPTION

Authenticate against IMAP or IMAPS services. 

Requires Net::IMAP::Simple for IMAP and Net::IMAP::Simple::SSL for IMAPS.
These modules are loaded when the object is created, not at compile time.

=head1 METHODS 

=over 4

=item  * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * host

The hostname of the IMAP server

=item * protocol

Either 'IMAP' or 'IMAPS'.  Any other value causes an exception.
Selecting 'IMAPS' will cause an exception if Net::IMAP::Simple::SSL 
is not installed.

=item * log   

Any object that supports "debug", "info", "error" and "warn".

	log => Log::Log4perl->get_logger('Authen::Simple::PAM')

=item * escape_slash 

In some environments, a password containing a slash will fail unless the slash
is escaped. Set escape_slash to true to escape slashes in passwords, or false
to leave them unescaped.  This is true by default.

=item * imap

Any object that supports "login" and "errstr" methods.  The obvious choice
being a Net::IMAP::Simple object, but if you want to use something else, here's
how you can do it.  This is how I use a mock imap object for the unit tests.  

=back

=item * authenticate( $username, $password ) 

Returns true on success and false on failure.

=back

=head1 DEPENDENCIES

Net::IMAP::Simple is required, and Net::IMAP::Simple::SSL is required for IMAPS.
Net::IMAP::Simple::Plus adds some patches to the otherwise abandoned and broken Net::IMAP::Simple, so I recommend it.   

=head1 BUGS AND LIMITATIONS

=over 4

=item *

I've never tried this in mod_perl, so including the mod_perl example in 
the synopsis is pure hubris on my part.

=item *

The unit tests are pretty sparse.  They don't include any tests against real 
IMAP servers.  They just do a successful and failed password against a mock
imap server object.

=item * 

This module uses Net::IMAP::Simple, which is broken and abandoned.  I should
either use something else or implement the IMAP stuff myself.  I wound up
wrapping the Net::IMAP::Simple stuff in an alarm+eval block to get it to behave.

=back

=head1 SEE ALSO

=over 4

=item Authen::Simple

=item Authen::Simple::Adapter

=item Net::IMAP::Simple

=item Net::IMAP::Simple::SSL

=back

=head1 CREDITS

=over 4

=item *

I pretty much ripped the best parts of this doc out of Christian Hansen's 
Authen::Simple::PAM and replaced "pam" with "imap" in a few places.  The 
lousy parts are my own.

=back

=head1 AUTHOR

Dylan Martin  C<< <dmartin@sccd.ctc.edu> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Dylan Martin C<< <dmartin@sccd.ctc.edu> >> and Seattle
Central Community College.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
