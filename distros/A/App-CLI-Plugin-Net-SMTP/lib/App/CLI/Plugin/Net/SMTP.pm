package App::CLI::Plugin::Net::SMTP;

=pod

=head1 NAME

App::CLI::Plugin::Net::SMTP - for App::CLI::Extension mail module

=head1 VERSION

1.3

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # extension method
  __PACKAGE__->load_plugins(qw(Net::SMTP));
  __PACKAGE__->config(net_smtp => { Host => "localhost", Port => 25, Timeout => 30 });
  
  1;
  
  # MyApp/Mailer.pm
  package MyApp::Hello;
  use strict;
  use feature ":5.10.0";
  use base qw(App::CLI::Command);
  use Encode qw(encode decode);
  use MIME::Entity;
  our $VERSION = '1.0';

  sub options {
      return (
         "from|f=s"    => "from",
         "to|t=s"      => "to",
         "subject|s=s" => "subject"
      );
  }
  
  sub run {
  
      my($self, @args) = @_;
      my @messages = <STDIN>;
      my $entity = MIME::Entity->build(
                                From        => $self->{from},
                                To          => $self->{to},
                                Subject     => encode("MIME-Header", decode("utf8", $self->{subject})),
                                Type        => "text/plain",
                                "X-Mailier" => sprintf("%s V%s", __PACKAGE__, $VERSION),
                                Charset     => "utf-8",
                                Data        => \@messages
                             );
      $self->smtp_open;
      $self->smtp->mail($self->{from});
      $self->smtp->to($self->{to});
      $self->smtp->data;
      $self->smtp->datasend($entity->stringify);
      $self->smtp->datasend;
      $self->smtp->quit;
  }
  
  # myapp
  #!/usr/bin/perl
  
  use strict;
  use MyApp;
  
  MyApp->dispatch;
  
  # execute
  [kurt@localhost ~] cat <<EOL | ./myapp mailer -f "me@localhost" -t "you@remotehost" -s "mail subject"
  pipe heredoc> this is myapp mailer message.
  pipe heredoc> I sent you?
  pipe heredoc> EOL
  
=head1 DESCRIPTION

App::CLI::Extension Net::SMTP plugin module

smtp method setting

  __PACKAGE__->config( net_smtp => {%net_smtp_option} );

=cut

use strict;
use base qw(Class::Accessor::Grouped);
use Net::SMTP;

__PACKAGE__->mk_group_accessors("smtp");
our $VERSION = '1.3';

=pod

=head1 METHOD

=head2 smtp_open

initialize Net::SMTP

=cut

sub smtp_open {

	my($self, $smtp_option) = @_;
	if (ref($smtp_option) ne "HASH") {
		$smtp_option = $self->config->{net_smtp};
	}
	if (!defined $smtp_option) {
		die "net_smtp option is always required";
	}

	if( (exists $ENV{APPCLI_SMTP_STARTTLS} && defined $ENV{APPCLI_SMTP_STARTTLS}) ||
		(exists $smtp_option->{StartTLS} && defined $smtp_option->{StartTLS}) ||
		(exists $self->{starttls} && defined $self->{starttls}) ){
		require IO::Socket::SSL;
		unshift @Net::SMTP::ISA, "IO::Socket::SSL";
	}

	$self->smtp(Net::SMTP->new(%{$smtp_option}) or die $!);
}

=head2 smtp

return Net::SMTP object. Environment variable APPCLI_SMTP_STARTTLS, net_smtp to StartTLS, the script runs starttls option, you specify one, IO::Socket::SSL If you have installed on your system, SMTPS can make a connection with.

But even then one way, net_smtp option of the Port is defined as SMTPS to specify the port number

Example1 APPCLI_SMTP_STARTTLS:

  # if your shell is bash...
  export APPCLI_SMTP_STARTTLS=1

Example2 StartTLS config:

  # in MyApp.pm
  __PACKAGE__->config(
                net_smtp => {
                        Host     => "localhost",
                        Timeout  => 30,
                        Port     => 465,
                        StartTLS => 1
                      }
              );

Example3 starttls option:

  echo "hello" | ./myapp mailer -f "me@localhost" -t "you@remotehost" -s "mail subject" --starttls

Advance

  # in MyApp/Mailer.pm
  
  sub options {
      return (
         "starttls"      => "starttls",
         "from|f=s"      => "from",
         "to|t=s"        => "to",
         "subject|s=s"   => "subject"
      );
  }
  
starttls option like that you define

=cut


1;

__END__

=head1 SEE ALSO

L<App::CLI::Extension> L<Class::Accessor::Grouped> L<Net::SMTP>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Copyright (C) 2009 Akira Horimoto

=cut

