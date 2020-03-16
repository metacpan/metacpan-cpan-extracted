#
# (C) 1998 Mike Shoyher <msh@corbina.net>, <msh@apache.lexa.ru>

package Authen::TacacsPlus;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	TACPLUS_CLIENT
);
$VERSION = '0.28';

sub new
{
my $class = shift;
my %h;
my $self = {};
bless $self, $class;
$self->{'servers'} = [];
if (ref $_[0] eq 'ARRAY') {
    %h = @{ $_[0] };
    shift @_;
    push @{ $self->{'servers'} }, @_;
} else {
    %h = @_;
}
my $res=-1;
$self->{'timeout'} = $h{'Timeout'} ? $h{'Timeout'} : 15;
$self->{'port'} = $h{'Port'} ? $h{'Port'} : 'tacacs';
$self->{'host'} = $h{'Host'};
$self->{'key'} = $h{'Key'};
$res=init_tac_session($self->{'host'},$self->{'port'},
	$self->{'key'},$self->{'timeout'});
if ($res<0) {
    my $s = $self->{'servers'};
    while ($s->[0]) {
        my %h = @{ $s->[0] };
        shift @{ $s };
        $res=init_tac_session( $h{'Host'},
                               $h{'Port'} ? $h{'Port'} : 'tacacs',
                               $h{'Key'},
                               $h{'Timeout'} ? $h{'Timeout'} : 15
                              );
        last if ($res >= 0);
    }
}
$self->{'open'} = 1 if ($res >= 0);
undef $self if ($res < 0);
$self;
}

# Third arg authen_type is optional, defaults to 
# TAC_PLUS_AUTHEN_TYPE_ASCII
sub authen
{
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $authen_type = shift || &Authen::TacacsPlus::TAC_PLUS_AUTHEN_TYPE_ASCII;
    my $res=make_auth($username,$password,$authen_type);
    unless ($res || errmsg() =~ /Authentication failed/) {
        my $s = $self->{'servers'};
        while ($s->[0]) {
            my %h = @{ $s->[0] };
            shift @{ $s };
            my $ret=init_tac_session( $h{'Host'},
                                      $h{'Port'} ? $h{'Port'} : 'tacacs',
                                      $h{'Key'},
                                      $h{'Timeout'} ? $h{'Timeout'} : 15
                                    );
            next if ($ret < 0);
            $res=make_auth($username,$password,$authen_type);
            last if $res;
        }

    }
    $res;
}

sub close
{
    my ($self) = @_;

    if ($self->{'open'})
    {
	deinit_tac_session();
	$self->{'open'} = 0;
    }
}

sub DESTROY
{
    my ($self) = @_;

    $self->close();
}


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Authen::TacacsPlus macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Authen::TacacsPlus $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Authen::TacacsPlus - Perl extension for authentication using tacacs+ server

=head1 SYNOPSIS

  use Authen::TacacsPlus;

  $tac = new Authen::TacacsPlus(Host=>$server,
			Key=>$key,
			Port=>'tacacs',
			Timeout=>15);

  or

  $tac = new Authen::TacacsPlus(
     [ Host=>$server1, Key=>$key1, Port=>'tacacs', Timeout=>15 ],
     [ Host=>$server2, Key=>$key2, Port=>'tacacs', Timeout=>15 ],
     [ Host=>$server3, Key=>$key3, Port=>'tacacs', Timeout=>15 ],
     ...  );

  $tac->authen($username,$passwords);

  Authen::TacacsPlus::errmsg(); 

  $tac->close();


=head1 DESCRIPTION

Authen::TacacsPlus allows you to authenticate using tacacs+ server.

  $tac = new Authen::TacacsPlus(Host=>$server,      
 	                Key=>$key,          
                        Port=>'tacacs',   
                        Timeout=>15);     

Opens new session with tacacs+ server on host $server, encrypted
with key $key. Undefined object is returned if something wrong
(check errmsg()).

With a list of servers the order is relevant. It checks the availability
of the Tacacs+ service using the order you defined.


  Authen::TacacsPlus::errmsg();

Returns last error message.  

  $tac->authen($username,$password,$authen_type);

Tries an authentication with $username and $password. 1 is returned if
authenticaton succeded and 0 if failed (check errmsg() for reason).

$authen_type is an optional argument that specifies what type
of authentication to perform. Allowable options are:
Authen::TacacsPlus::TAC_PLUS_AUTHEN_TYPE_ASCII (default)
Authen::TacacsPlus::TAC_PLUS_AUTHEN_TYPE_PAP
Authen::TacacsPlus::TAC_PLUS_AUTHEN_TYPE_CHAP

ASCII uses Tacacs+ version 0, and will authenticate against 
the "login" or "global" password on the Tacacs+ server. If no
authen_type is specified, it defaults to this type of authentication.

PAP uses Tacacs+ version 1, and will authenticate against 
the "pap" or "global" password on the Tacacs+ server.

CHAP uses Tacacs+ version 1, and will authenticate against 
the "chap" or "global" password on the Tacacs+ server. With CHAP,
the password if formed by the concatenation of
  chap id + chap challenge + chap response

There is example code in test.pl

If you use a list of servers you can continue using $tac->authen if
one of them goes down or become unreachable.


  $tac->close();

Closes session with tacacs+ server.

=head1 EXAMPLE

  use Authen::TacacsPlus;                                             
                                                              
                                                              
  $tac = new Authen::TacacsPlus(Host=>'foo.bar.ru',Key=>'9999');  
  unless ($tac){                                              
          print "Error: ",Authen::TacacsPlus::errmsg(),"\n";          
          exit(1);                                            
  }                                                           
  if ($tac->authen('john','johnpass')){                   
          print "Granted\n";                                  
  } else {                                                    
          print "Denied: ",Authen::TacacsPlus::errmsg(),"\n";         
  }                                                           
  $tac->close();                                              
  


=head1 AUTHOR

Mike Shoyher, msh@corbina.net, msh@apache.lexa.ru

Mike McCauley, mikem@airspayce.com

=head1 BUGS

only authentication is supported

only one session may be active (you have to close one session before
opening another one)

=head1 SEE ALSO

perl(1).

=cut
