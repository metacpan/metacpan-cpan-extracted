package App::OpenMbox::Test;

use 5.006;
use strict;
use warnings;
use POSIX;
use App::OpenMbox::Client;

=head1 NAME

App::OpenMbox::Test - Auto delivery test for OpenMbox.net

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

This module sends test email to those big providers for checking delivery capacity.

    use App::OpenMbox::Test;

    # test openmbox
    my $test = App::OpenMbox::Test->new('user@openmbox.net','some.pass');
    $test->deliver;

    # or test pobox
    my $test = App::OpenMbox::Test->new('user@pobox.com','some.pass');
    $test->deliver(host=>'smtp.pobox.com',
                   port=>465,
                   ssl=>1,
                   debug=>1,
                   );


=head1 SUBROUTINES/METHODS

=head2 new

New the instance by providing username and password. In fact you can send test mails with any smtp servers like gmail's.

See App::OpenMbox::Client for more details.

=cut

sub new {
  my $class = shift;
  my $user = shift;
  my $pass = shift;

  bless {user=>$user, pass=>$pass}, $class;
}

=head2 deliver

It will send mails to the following providers, see __DATA__ section.

    - Gmail
    - Yahoo/AOL
    - Outlook/Hotmail
    - ProtonMail
    - GMX/Web.de
    - Vodafone
    - T-online
    - Freenet.de
    - Yandex
    - Mail.ru

Please note OpenMbox has the rate limit of 10 messages per minute, so you can't send too much at once.

After delivery you can check provider's inbox for new message. If it didn't reach, check Postfix's mail.log for details.

=cut

sub deliver {
  my $self = shift;
  my %args = @_;

  my @rec;

  while(<DATA>) {
    next if /^$/;
    chomp;
    push @rec,$_;
  }

  my $recepients = join ',',@rec;
  my $time = strftime("%D %T",localtime);

  my $client = App::OpenMbox::Client->new($self->{user},$self->{pass});
  $client->sendmail(recepients => $recepients,
                  type => 'text/plain',
                  subject => 'Auto delivery test',
                  body => "This is just a test message, sent by App::OpenMbox::Test on $time",
                  host => $args{host},
                  port => $args{port},
                  ssl => $args{ssl},
                  debug => $args{debug},
                 );
}


=head1 AUTHOR

Henry R, C<< <support at openmbox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-openmbox-test at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-OpenMbox-Test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::OpenMbox::Test


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-OpenMbox-Test>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-OpenMbox-Test>

=item * Search CPAN

L<https://metacpan.org/release/App-OpenMbox-Test>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Henry R.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::OpenMbox::Test


__DATA__
openmboxer@gmail.com
openmbox@outlook.com
openmbox-openmbox@yahoo.com
openmbox@protonmail.com
openmbox@gmx-topmail.de
openmbox@vodafone.de
openmbox@t-online.de
openmbox@freenet.de
rwbox@yandex.com
wonder@internet.ru
