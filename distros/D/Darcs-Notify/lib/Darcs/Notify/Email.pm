#  Copyright (c) 2007-2009 David Caldwell,  All Rights Reserved.

package Darcs::Notify::Email; use base 'Darcs::Notify::Base'; use strict; use warnings;

use Mail::Send;
sub notify($$$$) {
  my ($self, $notify, $new, $unpull) = @_;

  my @group = @{$self->{to}};
  if (scalar @$unpull) {
    my $msg = new Mail::Send Subject=>"[Unpulled patches]";
    $msg->to(@group);
    #$ENV{MAILADDRESS} = $p->author;
    $msg->set("Reply-To", @group);
    $msg->set("Content-Type", ' text/plain; charset="utf-8"');
    $msg->set("X-Darcs-Notify", $notify->repo_name);
    my $fh = $msg->open('smtp', Server=>$self->{smtp_server} || 'localhost') or die "$!";
    #my $fh = $msg->open('testfile') or die "$!";
    print $fh "Unpulled:\n\n";
    print $fh join "\n", map { $_->as_string } @$unpull;
    $fh->close or die "no mail!";
    print "Sent unpull mail to @group\n";
  }

    # New patches each get their own email:
    foreach my $p (@$new) {
        my $name = ($p->undo?"UNDO: ":"").$p->name;
        my $msg = new Mail::Send Subject=>$name;
        $msg->to(@group);
        $ENV{MAILADDRESS} = $p->author;
        $msg->set("Reply-To", @group);
        $msg->set("Content-Type", ' text/plain; charset="utf-8"');
        $msg->set("X-Darcs-Notify", $notify->repo_name);
        my $fh = $msg->open('smtp', Server=>$self->{smtp_server} || 'localhost') or die "$!";
        #my $fh = $msg->open('testfile') or die "$!";
        print $fh "$p\n";
        print $fh $p->diffstat,"\n";
        print $fh $p->diff,"\n";
        $fh->close or die "no mail!";
        print "Sent $name to @group\n";
    }
}

1;
__END__

=head1 NAME

Darcs::Notify::Email - Send email notifications when patches are added
or removed from a Darcs repo.

=head1 SYNONPSIS

 use Darcs::Notify;
 Darcs::Notify->new(Email => { to => ["user1@example.com",
                                      "user2@example.com"],
                               smtp_server => "smtp.example.com" })
     ->notify;

=head1 DESCRIPTION

This module is meant to be passed as a the "Email" option to B<<
L<Darcs::Notify>->new >>.  This module sends email notifications of a
Darcs repository's new and unpulled patches to a list of recipients
using an SMTP server.

Normal users will probably just want to use the command line script
L<darcs-notify>, which is a front end to L<Darcs::Notify::Email>.

=head1 FUNCTIONS

=over 4

=item B<< C<< new() >> >>

This is called by B<< L<Darcs::Notify>->new >> when passed the "Email"
hash-style option. The value of the option should be a reference to a
hash with the following parameters:

=over 4

=item B<smtp_server> => "smtp.example.com"

The smtp server to send the emails through. If not specified it
defaults to `localhost'.

=item B<to> => ["email@example.com", "email2@example.com"]

This is reference to an array of recipient email addresses. This
option is required.

=back

=item B<< C<< $notify->notify() >> >>

This function sends the email notifications. It is automatically
invoked by B<< L<Darcs::Notify>->notify >> (assuming the "Email"
option was passed to B<< L<Darcs::Notify>->new >>), so you shouldn't
have to call it yourself.

=back

=head1 SEE ALSO

L<darcs-notify>, L<Darcs::Notify>, L<Darcs::Notify::Base>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2007-2009 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut
