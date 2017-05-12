package CGI::Application::Plugin::Eparam;

#=====================================================================
# CGI::Application::Plugin::Eparam
#---------------------------------------------------------------------
# make    : 2005/06/22 aska
#---------------------------------------------------------------------
# $Id$
#=====================================================================
use 5.004;
use strict;
use Carp;

$CGI::Application::Plugin::Eparam::VERSION = '0.04';

sub import {
	my $class = shift;
	my $caller = caller;
	
	$CGI::Application::Plugin::Eparam::debug = undef;
	$CGI::Application::Plugin::Eparam::econv = undef;
	$CGI::Application::Plugin::Eparam::icode = undef;
	$CGI::Application::Plugin::Eparam::ocode = undef;

	$CGI::Application::Plugin::Eparam::temp_econv = undef;
	$CGI::Application::Plugin::Eparam::temp_icode = undef;
	$CGI::Application::Plugin::Eparam::temp_ocode = undef;
	
	no strict 'refs';
	*{$caller.'::eparam'} = \&eparam;
	
}

#=====================================================================
# Get Value
#---------------------------------------------------------------------
# args     :key
# return   :convert value
# example  :my $val = $self->eparam('key');
#=====================================================================
sub eparam {
	my $self = shift;
	
	unless ( $CGI::Application::Plugin::Eparam::econv ) {
		if ( $Encode::VERSION ) {                              # Encode.pm
			$CGI::Application::Plugin::Eparam::econv = 
				sub { Encode::from_to(${$_[0]},$_[2],$_[1] );};
		} elsif ( $Jcode::VERSION ) {                          # Jcode.pm
			$CGI::Application::Plugin::Eparam::econv = 
				sub { Jcode::convert( $_[0], $_[1], $_[2] ); };
		} else {
			croak "You must be use Encode or use Jcode or set econv.";
		}
	}
	
	my $debug = $CGI::Application::Plugin::Eparam::debug;
	
	my $icode = $CGI::Application::Plugin::Eparam::temp_icode || $CGI::Application::Plugin::Eparam::icode;
	my $ocode = $CGI::Application::Plugin::Eparam::temp_ocode || $CGI::Application::Plugin::Eparam::ocode;
	my $econv = $CGI::Application::Plugin::Eparam::temp_econv || $CGI::Application::Plugin::Eparam::econv;
	
	carp "icode:".$icode if $debug;
	carp "ocode:".$ocode if $debug;
	carp "econv:".$econv if $debug;
	
	if ( !wantarray ) {
		my $val = $self->query->param(@_);
		$econv->(\$val, $ocode, $icode) if defined $val && $icode ne $ocode;
		carp "value:".$val if $debug;
		return $val;
	} else {
		my @val = $self->query->param(@_);
		map { $econv->(\$_, $ocode, $icode) } @val if scalar(@val) && $icode ne $ocode;
		carp "value:".join(',', @val) if $debug;
		return @val;
	}
}

1;

=pod

=head1 Name

CGI::Application::Plugin::Eparam

=head1 SYNOPSIS

    package WebApp
    use Jcode;# or use Encode or $CGI::Application::Plugin::Eparam::econv = sub { ... }
    use CGI::Application::Plugin::Eparam;
    sub cgiapp_init {
            $CGI::Application::Plugin::Eparam::icode = 'sjis';   # input code
            $CGI::Application::Plugin::Eparam::ocode = 'euc-jp'; # want  code
    }
    package WebApp::Pages::Public
    sub page1 {
            my $self = shift;
            my $data = $self->eparam('data');               # convert data
            my $natural_data = $self->query->param('data'); # data
    }

=head1 Example

=head2 Get Value

    package WebApp::Pages::Public
    sub page1 {
            my $self = shift;
            my $data = $self->eparam('data');               # convert data
            my $natural_data = $self->query->param('data'); # data
    }

=head2 in Application

    package WebApp
    use Jcode;# or use Encode or $CGI::Application::Plugin::Eparam::econv = sub { ... }
    use CGI::Application::Plugin::Eparam;
    sub cgiapp_init {
            $CGI::Application::Plugin::Eparam::icode = 'sjis';   # input code
            $CGI::Application::Plugin::Eparam::ocode = 'euc-jp'; # want  code
    }

=head2 in SubClass

    package WebApp::Pages::Public
    sub setup {
            $CGI::Application::Plugin::Eparam::icode = 'sjis';
            $CGI::Application::Plugin::Eparam::ocode = 'euc-jp';
    }
    package WebApp::Pages::Admin
    sub setup {
            $CGI::Application::Plugin::Eparam::icode = 'euc-jp';
            $CGI::Application::Plugin::Eparam::ocode = 'euc-jp';
    }

=head2 in Method

    package WebApp::Pages::User::Mailform
    sub mailform {

            # this case is no convert
            $CGI::Application::Plugin::Eparam::icode = 'jis';
            $CGI::Application::Plugin::Eparam::ocode = 'jis';

            # The thing used for the character-code conversion before Mail Sending can be done. 
            $CGI::Application::Plugin::Eparam::icode = 'sjis';
            $CGI::Application::Plugin::Eparam::ocode = 'jis';

    }

=head2 in Part

    package Myapplication::Pages::User::Mailform
    sub mailform {

            # temp_ocode are given to priority more than ocode.
            $CGI::Application::Plugin::Eparam::temp_icode = 'sjis';
            $CGI::Application::Plugin::Eparam::temp_ocode = 'jis';
            my $val_jis = $self->eparam('val');
            # It returns it.
            undef $CGI::Application::Plugin::Eparam::temp_icode;
            undef $CGI::Application::Plugin::Eparam::temp_ocode;
            my $val_sjis = $self->eparam('val');

    }

=head2 Convert Logic Customize

    # It is very effective.
    $CGI::Application::Plugin::Eparam::econv = sub {
            my $textref = shift; 
            my $ocode = shift;   # output character code
            my $icode = shift;   # input  character code
            # some logic
            Encode::from_to($$textref, 'Guess', $ocode);
    };
    # It is temporarily effective.
    $CGI::Application::Plugin::Eparam::temp_econv = sub {
            my $textref = shift; 
            my $ocode = shift;   # output character code
            my $icode = shift;   # input  character code
            # some logic
            Encode::from_to($$textref, 'Guess', $ocode);
    };
    # It returns to the processing of the standard.
    undef $CGI::Application::Plugin::Eparam::temp_econv;

=head1 SEE ALSO

L<CGI::Application>

=head1 AUTHOR

Shinichiro Aska

=cut