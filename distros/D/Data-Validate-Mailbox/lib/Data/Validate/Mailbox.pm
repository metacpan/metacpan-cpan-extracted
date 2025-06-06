package Data::Validate::Mailbox;

use 5.006;
use strict;
use Net::DNS;
use Net::SMTP;

=head1 NAME

Data::Validate::Mailbox - Verify if the given mailbox exists

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';


=head1 SYNOPSIS

Verify if the given mailbox exists.


    use Data::Validate::Mailbox;

    my $mbx = Data::Validate::Mailbox->new;

    # or,
    my $mbx = Data::Validate::Mailbox->new(debug => 1,
                                           localhost => 'your-domain.org',
                                           localuser => 'user@your-domain.org',
                                          );

    my $res = $mbx->validate('user123@gmx.de'); # or
    my $res = $mbx->validate('user123@gmail.com'); # or
    my $res = $mbx->validate('user123@hotmail.com'); # or 
    ...

    # 1 means existing, 0 means non-existing
    print $res;


Please note,

1. This module uses `Net::SMTP` to attempt delivering messages to the peer MTA. If the recipient's mailbox does not exist, the peer MTA will typically respond with an error message like "mailbox unavailable."

2. However, not all providers behave this way. For example, Yahoo and AOL do not provide such responses, so this module will not function correctly with them.


=head1 SUBROUTINES/METHODS

=head2 new

New the object.

Please note, for many email providers, you have to provide the correct local hostname/username for sending email to them. 

The local hostname refers to the hostname of the machine you use to connect to other MTAs, and it corresponds to the parameter of the HELO command in the SMTP session. The local username refers to the email address you use to send messages to external systems, and it corresponds to the parameter of the MAIL FROM command in the SMTP session.

The hostname must match the following conditions.

1. It is your valid domain/hostname.

2. The hostname has an IP address, and a correct PTR for this IP (PTR match back to hostname).

3. The sender domain has valid MX records and/or SPF records.

4. The IP has good reputation (not listed in any DNSBL).

If you can't send messages to external providers (either the program dies or it gets 0 always), please setup your right localhost and localuser options in new() method.


=head2 validate

Validate if the given mailbox exists. Return 1 for existing, 0 for non-existing.


=cut

sub new {
  my $class = shift;
  my %args = @_;

  bless \%args,$class;
}

sub validate {
  my $self = shift;
  my $mailbox = shift;

  my $debug     = defined $self->{debug}     ? $self->{debug}     : 0;
  my $localhost = defined $self->{localhost} ? $self->{localhost} : 'sender.org';
  my $localuser = defined $self->{localuser} ? $self->{localuser} : 'user'. int(rand(999)) . '@' . $localhost;

  my (undef,$domain) = split/\@/,$mailbox;

  # Use your own resolver object.
  my $res = Net::DNS::Resolver->new;
  my @mx  = mx($res, $domain);

  #The list will be sorted by preference. Returns an empty list if the query failed or no MX record was found.
  if (@mx) {
    my $exchange = $mx[0]->exchange;

    my $smtp = Net::SMTP->new($exchange,
                       Hello => $localhost,
                       Timeout => 30,
                       Debug   => $debug,
                      ) or die "can't make smtp connection to remote host";

    $smtp->mail($localuser) or die $smtp->message();

	  my $status = $smtp->to($mailbox) ? 1 : 0;
	  $smtp->quit;

    return $status;

  }else {
    die "query failed or no MX record was found";
  }
}


=head1 AUTHOR

Y Peng, C<< <ypeng at t-online.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-validate-mailbox at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-Mailbox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::Mailbox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validate-Mailbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Validate-Mailbox>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Data-Validate-Mailbox>

=item * Search CPAN

L<https://metacpan.org/release/Data-Validate-Mailbox>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Y Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Data::Validate::Mailbox
