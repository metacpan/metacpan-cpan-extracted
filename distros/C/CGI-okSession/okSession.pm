package CGI::okSession;

#use 5.008;
use strict;
#use warnings;
use Storable;
use Exporter;	#Export functions

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::okSession ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.02';

my @known_options = qw(
	dir
	timout
	app
	id
);

sub new {
	my $class = shift;
	my %config = (
		dir => '/tmp',
		timeout => 30*60,
		app => 'default'
		,@_
		);
	_remove_expired(%config);
	my $self;
	unless ($config{id}) {
		require Time::HiRes;
		require Digest::MD5;
		$config{id} = Digest::MD5::md5_hex(Time::HiRes::time());
	}
	if (-e "$config{dir}/$config{id}.sess") {
		$self = Storable::lock_retrieve("$config{dir}/$config{id}.sess");
	} else {
		$self->{___ID} = $config{id};
		$self->{___config} = \%config;
		Storable::lock_nstore($self,"$config{dir}/$config{id}.sess");
	}
	$self->{___ID} = $config{id};
	$self->{___expires} = time() + $config{timeout};
	$self->{___config} = \%config;
#	$self->DESTROY = DESTROY;
	_set_expiration_2_app($self->{___ID},$self->{___expires},%{$self->{___config}});
	return bless($self,$class);
}

sub get_ID {
	return shift->{___ID};
}

sub _remove_expired {
	my (%config) = @_;
	my $a;
	if (-e "$config{dir}/$config{app}") {
		$a = Storable::lock_retrieve("$config{dir}/$config{app}");
	} else {
		$a->{Application} = $config{app};
		Storable::lock_nstore($a,"$config{dir}/$config{app}");
		return;
	}
	unless ($a->{Sessions}) {
		return;
	}
	my $tim = time();
	my $t;
	foreach $t (keys %{$a->{Sessions}}) {
		if ($a->{Sessions}->{$t} < $tim) {
			unlink("$config{dir}/$t.sess") || die "Can't delete Session";
			delete $a->{Sessions}->{$t};
		}
	}
	Storable::lock_nstore($a,"$config{dir}/$config{app}");
}

sub expires {
	my $self = shift;
	return $self->{___expires};
}

sub expires_www {
	my $self = shift;
	my @t = gmtime($self->{___expires});
	return sprintf('%3.3s, %02d-%3.3s-%04d %02d:%02d:%02d GMT',("Sun","Mon","Tue","Wed","Thu","Fri","Sut","Sun")[$t[6]],$t[3],("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")[$t[4]],$t[5]+1900,$t[2],$t[1],$t[0]);
}

sub _set_expiration_2_app {
	my ($id,$tim,%config) = @_;
	my $a = undef;
	if (-e "$config{dir}/$config{app}") {
		$a = Storable::lock_retrieve("$config{dir}/$config{app}");
	}
	$a->{Sessions}->{$id} = $tim;
	Storable::lock_nstore($a,"$config{dir}/$config{app}");
}

DESTROY {
	my $self = shift;
	my(%s) = (%$self);
	Storable::lock_store(\%s,"$s{___config}->{dir}/$s{___config}->{id}.sess");
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CGI::okSession - Perl extension for CGI Sessions.

=head1 SYNOPSIS

  use CGI qw/:standard/;
  use CGI::okSession;
  my $AppName = 'MyApplication';
  my $SessionID = 'MyAppSessionID';
  my $timeout = 15*60 # 15 minutes session life time
  my $Session = new CGI::okSession(
	dir=>'/tmp',
	id=>cookie($SessionID),
	app=>$AppName
	);
  $Session->{registred} = 1;
  $Session->{client}->{Email} = 'some@email.com';
  $Session->{client}->{Name} = 'John Smith';
  my $cookie = cookie(
	-name=>$SessionID,
	-value=>$Session->get_ID,
	-expires=>$Session->expires_www
	);
  print header(-cookie=>$cookie);

=head1 DESCRIPTION

This package was created to have an easy and enough sessions tools for CGI scripts.
Sessions data are saved in the file. It does not work with DBs yet.

=head1 PACKAGE METHODS

=head2 new

 Creates Session object.

 Recevived parameters are:
 dir - directory where session data will be saved (must
     exist).
       Default: '/tmp'.
 timout - session life time in seconds.
       Default: 30*60
 app - application name. Application data has the list
     of sessions and an expiration time for each of
     sessions. (you can have different application
     names).
       Default: 'default'
 id - session ID. Session will be created if it does not
     exists. If this parameter is not defined then it
     will be generated. It's possible to get the session
     ID by method get_ID().

=head1 OBJECT METHODS

=head2 expires

 Returns expiration time of session in seconds.

=head2 expires_www

 Returns expiration time of session in HTTP format.

=head2 get_ID

 Returns ID of Session.


=head2 EXPORT

None by default.

=head1 SEE ALSO

Nothing yet.

=head1 AUTHOR

O. A. Kobyakovskiy, E<lt>ok@dinos.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by O. A. Kobyakovskiy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
