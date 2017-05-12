package Catalyst::Plugin::FormValidator::Simple::OwnCheck;
use strict;
use base qw/Catalyst::Plugin::FormValidator::Simple/;
#Just overload the setup method of parent module

use NEXT;
require FormValidator::Simple;

our $VERSION = '0.01';

sub setup {
    my $self = shift;
    $self->NEXT::setup(@_);
    my $setting = $self->config->{validator};
    my $plugins = $setting && exists $setting->{plugins_owncheck}
        ? $setting->{plugins_owncheck}
        : [];    

    FormValidator::Simple->load_plugin(@$plugins) if @$plugins;
}


1;

__END__


=head1 NAME

Catalyst::Plugin::FormValidator::Simple::OwnCheck - Validator for Catalyst with FormValidator::Simple

=head1 SYNOPSIS

    use Catalyst qw/FormValidator::Simple::OwnCheck FillInForm/;

    # set option
    MyApp->config->{validator} = {
        plugins 				=> ['CreditCard', 'Japanese'],
        plugins_owncheck 		=> ['MyApp::Checker'],
        options 				=> { charset => 'euc'},
    }

in  your Checker.pm

	package MyApp::Checker;
	use strict;
	use FormValidator::Simple::Exception;
	use FormValidator::Simple::Constants;
	
	our $VERSION = '0.01';
	
	sub NUMBER {
		my ( $self, $params, $args ) = @_;
	
		my $is_number = $params->[0] =~ m{^\d+$} ? 1 : 0;
		return $is_number ? TRUE : FALSE;	
	} 
	1;  

in your controller

    sub defaulti : Private {

        my ($self, $c) = @_;
	
	#this will check the param1 whether is NOT_BLANK and is NUMBER
        $c->form(
            param1 => [ qw/NOT_BLANK/, 'NUMBER' ],
        );
        
	#...
    
    }

=head1 DESCRIPTION

This plugin allows you to validate request parameters with a checker of your application namespace , no need to package your checker in the namespace of FormValidator::Simple.
See L<FormValidator::Simple> for more information.

This behaves like as L<Catalyst::Plugin::FormValidator>.



=head1 SEE ALSO

L<FormValidator::Simple>

L<Catalyst>

=head1 AUTHOR

ADONG <lt>dxluo83@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright(C) 2006 by ADONG

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

