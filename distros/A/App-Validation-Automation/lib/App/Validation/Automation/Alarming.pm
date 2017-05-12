package App::Validation::Automation::Alarming;

use Carp;
use Moose::Role;
use Mail::Sendmail;
use Data::Dumper;

=head1 NAME

App::Validation::Automation::Alarming - Role App::Validation::Automation

Notifies of a potential issue via email and/or text page

=head1 Attributes 

=cut

requires qw( config log_file_handle );

has 'mail_msg' => (
    is       => 'rw',
    isa      => 'Str',
    clearer  => 'clear_mail_msg',
);

has 'page_msg' => (
    is       => 'rw',
    isa      => 'Str',
    clearer  => 'clear_page_msg',
);

=head1 METHODS

=head2 mail

Notifies recipients mentioned in config file via email.All parameters can be passed arguments except a few which can be a part of config as they don't change.

=cut

sub mail {
    my ( %mail, $msg ,$ret);
    my $self       = shift;
    $mail{Subject} = shift;
    $mail{Message} = shift;
    $mail{To}      = shift || $self->config->{'COMMON.MAIL_TO'};
    $mail{From}    = shift || $self->config->{'COMMON.FROM'};
    $mail{smtp}    = shift || $self->config->{'COMMON.SMTP'};

    $ret = sendmail %mail
           || confess "couldn't mail : $Mail::Sendmail::error\n".Dumper(\%mail);
    if( $ret ) {
        $msg = "Mail sent with following details:\n".Dumper( \%mail );
        $self->mail_msg( $msg );
        return 1;
    }
 
    return 0;
 
}

=head2 page

Notifies recipients mentioned in config file via text page.page is a separate method as text messages should be short and crisp as we get charged for the service.This method can be over-ridden or tweaked to shorten the message.

=cut

sub page {
    my ( %mail, $msg ,$ret);
    my $self       = shift;
    $mail{Subject} = shift;
    $mail{Message} = shift;
    $mail{To}      = shift || $self->config->{'COMMON.PAGE_TO'};
    $mail{From}    = shift || $self->config->{'COMMON.FROM'};
    $mail{smtp}    = shift || $self->config->{'COMMON.SMTP'};

    $ret = sendmail %mail
           || confess "couldn't page : $Mail::Sendmail::error\n".Dumper(\%mail);
    if( $ret ) {
        $msg = "Page sent with following details:\n".Dumper( \%mail );
        $self->page_msg( $msg );
        return 1;
    }

    return 0;

 }


1;
