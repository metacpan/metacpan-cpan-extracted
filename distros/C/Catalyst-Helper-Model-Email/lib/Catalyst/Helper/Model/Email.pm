package Catalyst::Helper::Model::Email;
use strict;
use warnings;

use 5.008_008;

our $VERSION = '0.04';

sub mk_compclass {
    my ( $class, $helper, @mailer_args ) = @_;
    my %args;
    @args{qw/mailer host username password/} = @mailer_args;
    $helper->render_file( 'compclass', $helper->{file}, \%args );
    return;
}

=head1 NAME

Catalyst::Helper::Model::Email - Helper for Mail::Builder::Simple

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 ./script/myapp_create.pl model Email1 Email SMTP smtp.host.com usr passwd

=head1 DESCRIPTION

Using the command line above, Catalyst::Helper::Model::Email will create C<MyApp::Model::Email1> that looks like:

 package MyApp::Model::Email1;
 use strict;
 use warnings;
 use base 'Catalyst::Model::Factory';
 
 __PACKAGE__->config(
   class       => 'Mail::Builder::Simple',
   args => {
     mail_client => {
       mailer => 'SMTP',
       mailer_args => {
         host => 'smtp.host.com',
         username => 'usr',
         password => 'passwd',
       },
     },
   },
 );

 1;

And you will be able to send email with this model, using the following code in your controllers:

 $c->model("Email1"->send(
   from => 'me@host.com',
   to => 'you@yourhost.com',
   subject => 'The subject with UTF-8 chars',
   plaintext => "Hello\n\nHow are you?\n\n",
 );

But you will be also able to send more complex email messages like:

 $c->model("Email1"->send(
   from => ['me@host.com', 'My Name'],
   to => ['you@yourhost.com', 'Your Name'],
   subject => 'The subject with UTF-8 chars',
   plaintext => "Hello\n\nHow are you?\n\n",
   htmltext => "<h1>Hello</h1> <p>How are you?</p>",
   attachment => ['file', 'filename.pdf', 'application/pdf'],
   image => ['logo.png', 'image_id_here'],
   priority => 1,
   mailer => 'My Emailer 0.01',
   'X-Special-Header' => 'My special header',
 );

...or even more complex messages, using templates.

=head1 SUBROUTINES/METHODS

=head2 mk_compclass

=head1 CONFIGURATION AND ENVIRONMENT

 ./script/myapp_create.pl model <model_name> Email <mailer_args>

You need to specify the C<model_name> (the name of the model you want to create), and all other elements are optional.

For the <mailer_args> you should add the mailer_args parameters required by the mailer you want to use.

If you want to use an SMTP server, you need to add just SMTP and the address of the SMTP server.

If you want to use an SMTP server that requires authentication, you need to add SMTP, the address of the server, the username and the password, like in the exemple given above.

The module supports the mailers supported by L<Mail::Builder::Simple|Mail::Builder::Simple>. Mail::Builder::Simple uses L<Email::Sender|Email::Sender> for sending email, so check the modules under L<Email::Sender::Transport|Email::Sender::Transport> for finding the parameters you might need to use for each type of mailer.

This helper can add in the model just the mailer type, the hostname, the username and the password, but you can add manually other parameters like a different port than the default, or the option for using SSL when connecting to the SMTP server.

You can add to the generated model any other parameters you can use for sending email, for example the C<From:> field, and you won't need to specify those parameters when sending each email.

You can also put the configuration variables in the application's main configuration file (myapp.conf), using something like:

 <Model::Email1>
   class Mail::Builder::Simple
   <args>
     <mail_client>
       mailer SMTP
       <mailer_args>
         host smtp.host.com
         username myuser
         password mypass
       </mailer_args>
     </mail_client>
     from me@host.com
   </args>
 </Model::Email1>

=head1 DIAGNOSTICS

=head1 DEPENDENCIES

L<Catalyst|Catalyst>, L<Mail::Builder::Simple|Mail::Builder::Simple>, L<Email::Sender|Email::Sender>, L<Mail::Builder|Mail::Builder>

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 BUGS AND LIMITATIONS

No known bugs. If you find some, please announce.

=head1 AUTHOR

Octavian Rasnita C<orasnita@gmail.com>

=head1 LICENSE AND COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

No copyright claim is asserted over the generated code.

=cut

1;

__DATA__

__compclass__
package [% class %];
use strict;
use warnings;
use base 'Catalyst::Model::Factory';

__PACKAGE__->config(
  class       => 'Mail::Builder::Simple',
  args => {
    mail_client => {
      mailer => '[% mailer %]',
[% IF (mailer == 'SMTP' || mailer == 'SMTP::Persistent') && username && password -%]
      mailer_args => {
        host => '[% host %]',
        username => '[% username %]',
        password => '[% password %]',
      },
[% ELSIF mailer == 'SMTP' || mailer == 'SMTP::Persistent' -%]
      mailer_args => {host => '[% host %]'},
[% END -%]
    },
  },
);

1;
