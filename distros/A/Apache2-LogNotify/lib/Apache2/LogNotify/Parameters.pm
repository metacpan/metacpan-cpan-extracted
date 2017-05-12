package Apache2::LogNotify::Parameters;

use strict;
use warnings FATAL => 'all';
use Apache2::CmdParms ();

use Apache2::Const qw( :override :common :log :cmd_how :http HTTP_BAD_REQUEST );
use Apache2::Module;
use Apache2::Directive();

my @directives = (
		  {
		      name => 'ErrorType',
		      func => __PACKAGE__.'::ErrorType',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::ITERATE,
		      errmsg => 'ErrorType: ERROR: type not allowed, you must only use Apache error codes.'
		      },
		  {
		      name => 'LogError',
		      func => __PACKAGE__.'::LogError',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::TAKE1,
		      errmsg => 'LogError: ERROR: Only On or Off allowed as values.'
		      },
		  {
		      name => 'NotifyMode',
		      func => __PACKAGE__.'::NotifyMode',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::TAKE1,
		      errmsg => __PACKAGE__.' Only All, Admin, or AppOwners allowed.'
		      },
		  {
		      name => 'ErrorTimeOut',
		      func => __PACKAGE__.'::ErrorTimeOut',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::TAKE1,
		      errmsg => __PACKAGE__.' This must be an integer number indicating the number of seconds.'
		      },
		  {
		      name => 'Admins',
		      func => __PACKAGE__.'::Admins',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::ITERATE,
		      errmsg => __PACKAGE__.' You must enter a valid e-mail address. If none is entered then the default admin is used.'
		      },
		  {
		      name => 'AppOwners',
		      func => __PACKAGE__.'::AppOwners',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::ITERATE,
		      errmsg => __PACKAGE__.' You must enter a valid e-mail address. Or leave blank if no one.'
		      },
		  {
		      name => 'NotifyOptions',
		      func => __PACKAGE__.'::NotifyOptions',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::ITERATE,
		      errmsg => __PACKAGE__.' You must specify Email option.'
		      },
		  {
		      name => 'Debug',
		      func => __PACKAGE__.'::Debug',
		      req_override => Apache2::Const::ACCESS_CONF | Apache2::Const::OR_LIMIT,
		      args_how => Apache2::Const::TAKE1,
		      errmsg => 'LogError: ERROR: Only On or Off allowed as values.'
		      }
		  );

&Apache2::Module::add( __PACKAGE__ ,  \@directives);


sub ErrorType {
    my ( $self, $params, $args ) = @_;
    push( @{ $self->{ErrorType} } , $args);
}

sub LogError {
    my ( $self, $params, @args ) = @_;
    $self->{LogError} = \@args;
    return undef unless ( $self->{LogError} =~ /^[Oo][Nn]$/ || $self->{LogError} =~ /^[Oo][Ff][Ff]$/ );
}

sub NotifyMode {
    my ( $self, $params, @args ) = @_;
    $self->{NotifyMode} = \@args;
}

sub ErrorTimeOut {
    my ( $self, $params, @args ) = @_;
    $self->{ErrorTimeOut} = \@args;
}


sub Admins {
    my ( $self, $params, $args ) = @_;
    push( @{ $self->{Admins} } , $args);
}

sub AppOwners {
    my ( $self, $params, $args ) = @_;
    push( @{ $self->{AppOwners} } , $args);
}

sub NotifyOptions {
    my ( $self, $params, @args ) = @_;
    $self->{NotifyOptions} = \@args;
}

sub Debug {
    my ( $self, $params, $args ) = @_;
    $self->{Debug} = $args;
    return undef unless ( $self->{Debug} =~ /^[Oo][Nn]$/ || $self->{Debug} =~ /^[Oo][Ff][Ff]$/ );
}

1;
