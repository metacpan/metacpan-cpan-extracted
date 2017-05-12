package Class::DBI::Factory::Mailer;

use strict;
use Carp qw();
use Email::Send;
use Data::Dumper;
use vars qw( $AUTOLOAD $VERSION );

$VERSION = "0.2";

=head1 NAME

Class::DBI::Factory::Mailer - a simple, replaceable email-sender

=head1 SYNOPSIS
    
	$mailer = Class::DBI::Factory::Mailer->new;
	$mailer->send_message({
		to => 'someone@there',
		from => 'someone@here',
		subject => 'ying tong iddle I po',
		as_html => 1,
		template => '/path/to/tt/template',
		message => 'or just pass through the message',
		person => $person,
		other_parameter => 17,
		error_message => 'hey!',
	});

	# or you can skip the constructor if you're in a hurry:
	
	Class::DBI::Factory::Mailer->send_message( $hashref );

=head1 INTRODUCTION

Class::DBI::Factory::Mailer is a very simple class whose only real purpose is to get the mail-sending functionality out of Class::DBI::Factory so that you can replace it or skip it economically. It can use TT2 but doesn't have to: you can pass through a message body or a template parameter.

(the template parameter will take precedence over the message parameter if both are supplied.)

If you're using a template, then the hashref of parameters you supply to send_message will be passed on through to the template processor, so to make values available on the template, just pass them to send_message.

=head1 METHODS 

To use your own mailer class rather than this one, override the mailer_class() method in Class::DBI::Factory. Your mailer only needs to provide new() and send_message() methods that behave like those here.

=head2 new()

Idiot constructor: just blesses a hashref. Can accept named C<mta> and C<smtp> parameters:

	$mailer = Class::DBI::Factory::Mailer->new(
		mta => 'Qmail',
	);

=cut

sub new {
	my ($class, %param) = @_;
	return bless { %param }, $class;
}

=head2 factory_class() factory() config() tt()

Same as all the other CDF components. factory() calls the instance method of the class name returned by factory_class, to get the locally active factory (for some definition of local). config() and tt() provide shortcuts to the configuration and template-processing objects held by the factory.

=head2 debug

Passes messages to the factory's debugging machinery, as usual.

=cut

sub factory_class { "Class::DBI::Factory" }
sub factory { return shift->factory_class->instance; }
sub config { shift->factory->config(@_); }
sub tt { shift->factory->tt(@_); }

=head2 mta()

Mutator for the name of the sender used by Email::Send. This defaults to the value specified in the 'default_mailer' configuration parameter, but you can supply any other name, either from the standard Email::Send set or of your own construction.

=head2 mta_parameters()

Mutator for the parameters that will be passed to Email::Send::Whatever. Usually this is the address of the smtp relay that will be used if Email::Send is using smtp (ie if mta() returns 'SMTP'): itdefaults to the value specified in the 'smtp_relay' configuration parameter.

(You can also use this to set any other secondary parameter that an Email::Send transport is expecting, such as the file or socket for an IO send. It's a pretty ugly way round, but I only use it for the tests so it doesn't matter yet.)

=cut

sub mta {
	my $self = shift;
	return $self->{mta} = $_[0] if $_[0];
	return $self->{mta} ||= $self->config->get('default_mailer') || 'Sendmail';
}

sub mta_parameters {
	my $self = shift;
	return $self->{smtp} = $_[0] if $_[0];
	return $self->{smtp} ||= $self->config->get('smtp_relay');
}

=head2 send_message( parameter_hashref )

Sends email (using Email::Send). The hashref of parameters must include at least 'to' and 'subject' or we'll bail silently. It can also include either a 'message' parameter containing the text of the message, or a 'template' parameter containing the address of the TT template that should be used to produce the message. The whole parameter hashref will be passed on to the template, so any other variables you want to make available can just be included there.

If both message and template parameters are supplied, we will use the template and hope that it has a [% message %] somewhere. If neither is supplied, the result will be an empty message with the subject and address you supply (which might be all that's required).

Parameter names are all lower-case, but remember to capitalise the From, To and Subject in message templates.

If you're having trouble with this, check your configuration's 'default_mailer' parameter, and compare against the documentation for L<Email::Send>. It has probably defaulted to Sendmail.

=cut

sub send_message {
	my ( $self, $instructions ) = @_;
	$self = $self->new unless ref $self;
	return unless $instructions->{subject} && $instructions->{to};
    $instructions->{from} ||= $self->config->get('mail_from');
	$instructions->{'content-type'} ||= ($instructions->{as_html}) ? 'text/html; charset="iso-8859-1"' : 'text/plain';

	my $message;
	my $header = join("\n", map("$_: " . $instructions->{lc($_)}, qw(To From Subject Content-Type)));
	$header .= "\n\n";
	
	if ($instructions->{template}) {
        $self->tt->process( $instructions->{template}, {
            factory => $self->factory,
            config => $self->config,
            date => $self->factory->now,
    		%$instructions,
        }, \$message );

	} else {
        $message = $instructions->{message};

	}
	
	$self->debug(4, "sending message '$$instructions{subject}' to $$instructions{to}", 'email');
	my $mta = $self->mta;
	my $via =  $self->mta_parameters if $mta eq 'SMTP' || $mta eq 'IO';
	send $mta => $header . $message, $via;
}

=head2 email_admin( parameter_hashref )

A shortcut that will send a message to the configured admin address. This is mostly useful for error messages, which can be as simple as:

  $factory->email_admin({
    subject => 'uh oh',
    message => 'Something terrible has happened.',
  };

=cut

sub email_admin {
	my ( $self, $instructions ) = @_;
    $instructions->{to} = $self->config->get('admin_email');
    $self->send_message($instructions);
}

=head2 debug()

hands over to L<Class::DBI::Factory>'s centralised debugging message thing.

=cut

sub debug {
    shift->factory->debug(@_);
}

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::Factory> L<Class::DBI::Factory::Config> L<Class::DBI::Factory::Handler> L<Class::DBI::Pager>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2001-5 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
