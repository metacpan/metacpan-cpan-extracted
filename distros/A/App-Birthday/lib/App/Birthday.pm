package App::Birthday;
our @EXPORT = qw/usage version send_mails verify_mails/;# Symbols to autoexport (:DEFAULT tag)
use base qw/Exporter/;
use Mail::Sender;

our $VERSION = '0.4';

sub send_mails {
    my ($name, $in_hr, $cfg_hr, $in_file) = @_;
    my @to      = ();
    my $me      = $$cfg_hr{maintainer};
    my $subject = $in_file.' config file. You sent a birtday mail for: '; # subject only for maintainer

    # prepare sender - initiate transport parameters
    my $sender = new Mail::Sender{
        smtp => $$cfg_hr{transport}{host},
        port => $$cfg_hr{transport}{port},
        from => $$cfg_hr{from}
    };

    # send E-Mail to all friends of birthday child
    if (${$$in_hr{$name}{friends}{names}}[0] == "others"){
        push @to, $$in_hr{$_}{email}.',' for (grep { $_ ne $name } keys %$in_hr); # all - name
    } else {
        push @to, $$in_hr{$_}{email}.',' for (@{$in_hr{$$in_hr{$name}{friends}{names}}});
    }

    if (@to) {
        $sender->MailMsg({
            to      => "@to",
            subject => $$in_hr{$name}{friends}{subject}
            });
    }

    # congratulations E-Mail to birthday child
    $sender->MailMsg({
        to      => $$in_hr{$name}{email},
        subject => $$in_hr{$name}{subject},
        msg     => $$in_hr{$name}{text}
        });

    # secret E-Mail only to me, as a reminder
    $sender->MailMsg({
        to      => $me,
        subject => $subject.$$in_hr{$name}{email},
        msg     => $$in_hr{$name}{text}
        });
}

sub verify_mails {
    my ($name, $in_hr, $cfg_hr, $in_file) = @_;
    my @to      = ();
    my $me      = $$cfg_hr{maintainer};
    my $subject = $in_file.' config file. You sent a birtday mail for: '; # subject only for maintainer
    # send E-Mail to all friends of birthday child
    if (${$$in_hr{$name}{friends}{names}}[0] == "others"){
        push @to, $$in_hr{$_}{email}.',' for (grep { $_ ne $name } keys %$in_hr); # all - name
    } else {
        push @to, $$in_hr{$_}{email}.',' for (@{$in_hr{$$in_hr{$name}{friends}{names}}});
    }

    print "[*] Configuration:\n";
    printf "\t [-] smtp: %s\n", $$cfg_hr{transport}{host};
    printf "\t [-] port: %s\n", $$cfg_hr{transport}{port};
    printf "\t [-] from: %s\n", $$cfg_hr{from};

    print "[*] Mail to birthday child:\n";
    printf "\t [-] to: %s\n", $$in_hr{$name}{email};
    printf "\t [-] subject: %s\n", $$in_hr{$name}{subject};
    printf "\t [-] msg: %s\n", $$in_hr{$name}{text};

    print "[*] Mail to friends:\n";
    printf "\t [-] to: %s\n", "@to";
    printf "\t [-] subject: %s\n", $$in_hr{$name}{friends}{subject};

    print "[*] Reminder Mail to me:\n";
    printf "\t [-] to: %s\n", $me;
    printf "\t [-] subject: %s\n", $subject.$$in_hr{$name}{email};
    printf "\t [-] msg: %s\n", $$in_hr{$name}{text};
}

sub usage { system("perldoc $0"); exit 0; }
sub version { print "Version: $VERSION\n"; exit 0; }
1; # End of App::Birthday
__END__

=head1 NAME

App::Birthday - sends birthday e-mails to your friends, on their anniversary date.

This module is the helper library for `birthday`. No user-serviceable
parts inside. Use `birthday` only.

For a complete documentation of `birthday`, see its POD.

=head1 VERSION

Version 0.4

=cut

=head1 SYNOPSIS

    use App::Birthday;
    send_mails();
    ...

=head1 EXPORT

usage version send_mails

=head1 SUBROUTINES/METHODS

=head2 send_mails

Main function, send mail due to a F<birthday.json> file and a given
configuration file

=cut

=head2 verify_mails

It verifies configuration and input entries. It sends no mail but prints
all output to STDOUT.

=cut

=head2 usage

description and examples of usage

=cut

=head2 version

print-out of current version of script

=cut

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 

C<bug-app-birthday at rt.cpan.org>, 

or through the web interface at 

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Birthday>. 

I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Birthday

    or 

    perldoc birthday

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Birthday>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Birthday>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Birthday>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Birthday/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
