
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::SendMail;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw( SendMail NotifyAdmin );

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.7';

BEGIN # Work-around for Bug in Net::Config 1.00 line# 40 under Win32
{
    if (($^O =~ /Win32/i) &&
        !(defined $ENV{'HOME'}) &&
         (defined $ENV{'HOMEDRIVE'}) &&
         (defined $ENV{'HOMEPATH'}))
    {
        $ENV{'HOME'} = $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'};
    }
}

##############
## Imports: ##
##############

use Config::Manager::Base qw( GetList );
use Config::Manager::Report qw(:all);
use Net::SMTP;

#######################################
## Internal configuration constants: ##
#######################################

my @SMTP_SERVER  = ('SMTP', 'Server');
my @SMTP_CLIENT  = ('SMTP', 'Client');
my @SMTP_TIMEOUT = ('SMTP', 'Timeout');

my @ADMIN_FROM   = ('SMTP', 'Admin_From');
my @ADMIN_TO     = ('SMTP', 'Admin_To');

########################
## Private functions: ##
########################

sub Quit
{
    my($smtp,$server) = @_;

    unless ($smtp->quit())
    {
        Config::Manager::Report->report
        (
            @WARN,
            "SMTP error while closing the connection to '$server'!"
        );
    }
}

#######################
## Public functions: ##
#######################

sub SendMail
{
    my($from) = shift;
    my($to)   = shift;
    my($subj) = shift;
    my($server,$client,$timeout,$smtp,$item);
    my(@mail);

    return undef unless (($server,$client,$timeout) =
        &GetList(\@SMTP_SERVER,\@SMTP_CLIENT,\@SMTP_TIMEOUT));
    unless ($smtp = Net::SMTP->new( $server,
                                    'Hello'   => $client,
                                    'Timeout' => $timeout))
    {
        Config::Manager::Report->report
        (
            @ERROR,
            "Can't connect to SMTP server '$server'",
            "coming from client '$client'!"
        );
        return undef;
    }
    $from =~ s!^\s+!!;
    $from =~ s!\s+$!!;
    unless ($smtp->mail( $from ))
    {
        Config::Manager::Report->report
        (
            @ERROR,
            "The SMTP server '$server' rejects sender '$from'!"
        );
        &Quit($smtp,$server);
        return undef;
    }
    foreach $item ( split( /,/, $to ) )
    {
        $item =~ s!^\s+!!;
        $item =~ s!\s+$!!;
        unless ($smtp->to( $item ))
        {
            Config::Manager::Report->report
            (
                @ERROR,
                "The SMTP server '$server' rejects recipient '$item'!"
            );
            &Quit($smtp,$server);
            return undef;
        }
    }
    unless ($smtp->data())
    {
        Config::Manager::Report->report
        (
            @ERROR,
            "SMTP 'data' error while talking to '$server'!"
        );
        &Quit($smtp,$server);
        return undef;
    }
    @mail = ();
    foreach $item (@_)
    {
        push( @mail, split(/\n/, $item, -1) );
    }
    unshift
    (
        @mail,
        "From: $from",
        "To: $to",
        "Subject: $subj",
        "X-Mailer: " . __PACKAGE__ . "::SendMail()",
        ""
    );
    foreach $item (@mail)
    {
        $item =~ s![\x00-\x1F\x7F]+!!;
        $item =~ s!\s+$!!;
        unless ($smtp->datasend( "$item\n" ))
        {
            Config::Manager::Report->report
            (
                @ERROR,
"SMTP 'datasend' error while talking to '$server' in the following line:",
                $item
            );
            &Quit($smtp,$server);
            return undef;
        }
    }
    unless ($smtp->dataend())
    {
        Config::Manager::Report->report
        (
            @ERROR,
"SMTP error while terminating data transmission to '$server'!"
        );
        &Quit($smtp,$server);
        return undef;
    }
    &Quit($smtp,$server);
    return 1;
}

sub NotifyAdmin
{
    my($from,$to);

    Config::Manager::Report->trace() unless
        ((($from,$to) = &GetList(\@ADMIN_FROM,\@ADMIN_TO)) &&
        (defined &SendMail($from,$to,@_)));
    Config::Manager::Report->clr_hold();
}

1;

__END__

=head1 NAME

Config::Manager::SendMail - Simple SMTP CLient

=head1 SYNOPSIS

  use Config::Manager::SendMail qw( SendMail );

  use Config::Manager::SendMail qw(:all);

  &SendMail($from,$to,$subject,@text);

  &NotifyAdmin($subject,@text);

=head1 DESCRIPTION

Dieses Modul stellt die Basisfunktionalitaet zur Verfuegung, um auf einfache
Art und Weise Mails zu verschicken. Dies kann z.B. genutzt werden, um sich bei
Prozessen, die im Hintergrund laufen und die nicht staendig kontrolliert
werden, im Fehlerfall eine entsprechende Meldung schicken zu lassen.

=over 2

=item *

C<&SendMail($from,$to,$subject,@text)>

Diese Funktion sendet eine Mail. Sie stuetzt sich dabei auf das (externe)
Modul "Net::SMTP" (aus dem "libnet"-Bundle von Graham Barr) ab, wodurch
auch die Portabilitaet fuer alle Plattformen gewaehrleistet ist.

 Parameter: $from    - Mailadresse des Absenders
            $to      - Mailadresse des oder der Empfaenger(s)
            $subject - Betreff der Mail
            @text    - Zeilen des Textes (ohne Newlines!)

 Rueckgabe: 1     - OK
            undef - Fehler

Mails koennen auch an mehrere Empfaenger gleichzeitig geschickt werden.
Dazu muessen die jeweiligen Mailadressen einfach nur hintereinander in
den String "C<$to>" geschrieben werden, durch Kommas voneinander getrennt.

"Carbon Copies" ("Cc:") oder "Blind Carbon Copies" ("Bcc:") werden von
dieser Funktion jedoch nicht unterstuetzt.

=item *

C<&NotifyAdmin($subject,@text)>

Diese Funktion sendet eine Mail an den Administrator. Dieser wird aus der
Konfiguration entnommen. Aufgerufen wird dann die Funktion "SendMail()"
(siehe oben).

Wichtig ist, dass auch der in der Konfiguration hinterlegte Name fuer den
Client-Rechner ein gueltiger Rechnername sein muss. Ist dies nicht der Fall
(z.B. auch dann, wenn dieser String ein "@"-Zeichen enthaelt!), kommt die
Fehlermeldung, dass die Verbindung zu dem SMTP-Server von diesem Client aus
nicht hergestellt werden konnte. (!)

Diese Fehlermeldung ist also etwas irrefuehrend.

 Parameter: $subject - Betreff der Mail
            @text    - Zeilen des Textes (ohne Newlines!)

 Rueckgabe: -

Falls das Verschicken der Mail fehlschlaegt, wird als Fallback ein Trace
dieser Funktion mit allen Aufrufparametern (also insbesondere dem Betreff
und dem Text der Mail) in die Default-Logdatei geschrieben.

Etwaige Warnungen oder Fehlermeldungen, die die Funktion "SendMail()" auf
Halde gelegt haben koennte, werden stets geloescht, indem bei Funktionsende
die komplette Halde geloescht wird - unabhaengig davon, ob das Verschicken der
Mail geklappt hat oder nicht.

Dies koennte moeglicherweise Fehlermeldungen oder Warnungen von anderen,
vorherigen Routinen loeschen, ohne dass dies gewollt ist. In diesem Fall ist
der Aufruf der Routine "clr_hold()" in dieser Funktion auszukommentieren.

=item *

C<&Quit($smtp,$server);>

Diese (private) Funktion ist ein Shortcut zum vorzeitigen Abbruch sowie dem
normalen Beenden der Verbindung mit dem SMTP-Server.

 Parameter: $smtp    - Referenz auf Net::SMTP-Objekt
            $server  - Rechnername der SMTP-Servers

 Rueckgabe: -

=back

=head1 SEE ALSO

Config::Manager(3),
Config::Manager::Base(3),
Config::Manager::Conf(3),
Config::Manager::File(3),
Config::Manager::PUser(3),
Config::Manager::Report(3),
Config::Manager::User(3).

=head1 VERSION

This man page documents "Config::Manager::SendMail" version 1.7.

=head1 AUTHORS

 Steffen Beyer <sb@engelschall.com>
 http://www.engelschall.com/u/sb/download/
 Gerhard Albers

=head1 COPYRIGHT

 Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.
 All rights reserved.

=head1 LICENSE

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for more details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

