package CGI::Application::Plugin::FormValidator::Simple;

use strict;
use vars qw($VERSION @EXPORT);
use warnings;
use FormValidator::Simple;

require Exporter;

@EXPORT = qw(
  validator
  form
);
sub import { goto &Exporter::import }

$VERSION = '0.03';

sub validator {
    my $self = shift;
    my %params = @_;

    my $plugins = $params{plugins};
    FormValidator::Simple->import(@$plugins) if $plugins;

    my $options = $params{options};
    $self->{validator} = FormValidator::Simple->new(%$options);
    
    if (exists $params{messages}){
	FormValidator::Simple->set_messages($params{messages});
      }
    
    return $self->{validator};
}


sub form {
    my $self = shift;
    if ($_[0]) {
        my $form = $_[1] ? [@_] : $_[0];
	$self->validator() unless $self->{validator};
        $self->{form} = $self->{validator}->check($self->query, $form);
    }
    return $self->{form};
}


1;
__END__

=head1 NAME

CGI::Application::Plugin::FormValidator::Simple - Validator for CGI::Application with FormValidator::Simple

=head1 SYNOPSIS

    use CGI::Application::Plugin::FormValidator::Simple;
    
    $self->validator(
        plugins => [ 'Japanese', 'Number::Phone::JP' ],
        options => {
            charset => 'euc',
        },
        messages => {
            user => {
                param1 => {
                    NOT_BLANK => 'Input name!',
                    ASCII     => 'Input name with ascii code!',
                },
                mail1 => {
                    DEFAULT   => 'email is wrong.!',
                    NOT_BLANK => 'input email.!'
                },
            },
            company => {
                param1 => {
                    NOT_BLANK => 'Input name!',
                },
            },
        },
    );

    $self->form(
        param1 => [qw/NOT_BLANK ASCII/, [qw/LENGTH 4 10/]],
        param2 => [qw/NOT_BLANK/, [qw/JLENGTH 4 10/]],
        mail1  => [qw/NOT_BLANK EMAIL_LOOSE/],
        mail2  => [qw/NOT_BLANK EMAIL_LOOSE/],
        { mail => [qw/mail1 mail2/] } => ['DUPLICATION'],
    );

    print $self->form->valid('param1');

    if ( some condition... ) {
        $self->form(
            other_param => [qw/NOT_INT/],
        );
    }

    if ( $self->form->has_missing || $self->form->has_invalid ) {
        if ( $self->form->missing('param1') ) {
            ...
        }

        if ( $self->form->invalid( param1 => 'ASCII' ) ) {
            ...
        }

        if ( $self->form->invalid( param3 => 'MY_ERROR' ) ) {
            ...
        }

    }

=head1 DESCRIPTION

This plugin for CGI::Application allows you to validate request parameters with FormValidator::Simple.
See L<FormValidator::Simple> for more information.

=head1 SEE ALSO

L<FormValidator::Simple>

L<Catalyst::Plugin::FormValidator::Simple>

L<CGI::Application>

=head1 AUTHOR

Gosuke Miyashita, E<lt>gosukenator@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Gosuke Miyashita

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
