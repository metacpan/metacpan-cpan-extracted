package App::OpenMbox::Client;

use 5.006;
use strict;
use warnings;
use MIME::Lite;
use MIME::Words qw(encode_mimewords);
use MIME::Base64;
use Authen::SASL;

=head1 NAME

App::OpenMbox::Client - A perl client to send simple email via OpenMbox's smtp server

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

This module can send simple email via smtp server provided by OpenMbox or any others.

Before installation you should have Net::SSLeay pre-installed, which can be fetched by this way on Ubuntu.

    sudo apt install libnet-ssleay-perl

You can send email with OpenMbox's smtp server, which accepts smtp connection on port 587. Also you can use other provider's smtp servers, for example, gmail, pobox etc. They generally require connection to port 465 with SSL enabled.

    use App::OpenMbox::Client;

    my $client = App::OpenMbox::Client->new('user@openmbox.net','some.pass');

    # sending a plain text
    $client->sendmail(recepients => 'xx@a.com,xx@b.com',
                      type => 'text/plain',
                      subject => 'greetings',
                      body => 'how are you doing today?',
                     );

    # sending a jpeg image
    $client->sendmail(recepients => 'xx@a.com,xx@b.com',
                      type => 'image/jpeg',
                      subject => 'a picture',
                      path => '/tmp/aaa.jpeg',
                     );

    # sending with pobox's smtp server
    my $client = App::OpenMbox::Client->new('user@pobox.com','some.pass');

    $client->sendmail(recepients => 'xx@a.com,xx@b.com',
                      host => 'smtp.pobox.com',
                      port => 465,
                      ssl  => 1,
                      debug => 1,
                      type => 'text/plain',
                      subject => 'hello',
                      body => 'how are you!',
                     );

=head1 EXPORT


=head1 SUBROUTINES/METHODS

=head2 new

New the instance by providing email account and password.

=cut

sub new {
  my $class = shift;
  my $user = shift;
  my $pass = shift;

  bless {user=>$user,pass=>$pass}, $class;
}

=head2 sendmail

Send email with specified arguments. The argument names can be,

    recepients - the recepient addresses, multi-ones splitted by ","
    host - smtp host, optional, default to 'mail.openmbox.net'
    port - smtp port, optional, default to 587
    ssl - optional, default 0 for non-SSL connection
    debug - optional, default 0 for no debug mode
    type - mime type such as text/plain, text/html etc, see MIME::Lite
    subject - message subject
    body - message body
    path - path to get the attachment such as 'image/jpeg'
    

=cut

sub sendmail {
  my $self = shift;
  my %args = @_;

  my $user = $self->{'user'};
  my $pass = $self->{'pass'};
  my $recepients = $args{'recepients'} || die "no recepients provided";

  my $host = $args{'host'} ? $args{'host'} : 'mail.openmbox.net';
  my $port = $args{'port'} ? $args{'port'} : 587;
  my $ssl = $args{'ssl'} ? 1 : 0;
  my $debug = $args{'debug'} ? 1 : 0;
  my $type = $args{'type'} ? $args{'type'} : 'text/plain';
  my $subject = exists($args{'subject'}) ? $args{'subject'} : undef;
  my $body = exists($args{'body'}) ? $args{'body'} : undef;
  my $path= exists($args{'path'}) ? $args{'path'} : undef;

  $subject = encode_mimewords($subject,'Charset','UTF-8');

  my $msg = MIME::Lite->new (
        From     => $user,
        To       => $recepients,
        Subject  => $subject,
        Type     => $type,
        Data     => $body,
        Path     => $path,
        Encoding => 'base64',
  ) or die "create container failed: $!";

  $msg->attr('content-type.charset' => 'UTF-8');
  $msg->send( 'smtp',
              $host,
		          Port     => $port,
              AuthUser => $user,
              AuthPass => $pass,
              SSL      => $ssl,
              Debug    => $debug,
            );

}

=head1 AUTHOR

Henry R, C<< <support at openmbox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-openmbox-client at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-OpenMbox-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::OpenMbox::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-OpenMbox-Client>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-OpenMbox-Client>

=item * Search CPAN

L<https://metacpan.org/release/App-OpenMbox-Client>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Henry R.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::OpenMbox::Client
