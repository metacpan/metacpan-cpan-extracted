package Configd::Language::postfix;
$Configd::Language::postfix::VERSION = '0.005';
#ABSTRACT: main.cf and master.cf, which postfix has never had a conf.d for.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use parent qw{Configd::Language};


# The parameters where two fragments each naming something both meant it.  This
# is the list postfix's own documentation describes as taking "a comma and/or
# space separated list of domain names" and friends -- setting one of these from
# two places is the case this whole distribution exists for.
#
# Deliberately not here: the *_restrictions parameters.  They are lists too, but
# ordered ones where the meaning depends on which check comes first and a
# permit_ in the wrong place opens a relay.  Joining two of them end to end
# produces something that parses and is not what either fragment meant, so they
# stay a value a later fragment replaces, and disagreeing about one is something
# somebody should have to notice.
my %ACCUMULATES = map { $_ => 1 } qw{
  mydestination
  myhostname_aliases
  masquerade_domains
  mynetworks
  relay_domains
  virtual_alias_domains
  virtual_mailbox_domains
  local_recipient_maps
  virtual_alias_maps
  virtual_mailbox_maps
  transport_maps
  sender_bcc_maps
  recipient_bcc_maps
  header_checks
  body_checks
  mime_header_checks
  nested_header_checks
  alias_maps
  alias_database
  sender_dependent_relayhost_maps
  smtpd_sender_login_maps
  smtp_sasl_password_maps
  smtp_tls_policy_maps
  smtpd_milters
  non_smtpd_milters
  inet_interfaces
  proxy_read_maps
};


sub files {
    return (
        { path => '/etc/postfix/main.cf',   owner => 'root:root', mode => 0o644 },
        { path => '/etc/postfix/master.cf', owner => 'root:root', mode => 0o644 },
    );
}

sub units {

    # The templated unit rather than postfix.service: on Debian and Ubuntu
    # postfix.service is a oneshot whose ExecStart is /bin/true, and the daemon
    # that actually reads these files is an instance of postfix@.service --
    # postfix@-.service being the default one.  Naming the template covers every
    # instance, including ones somebody adds later.
    return ('postfix@.service');
}

sub services {

    # Not the template: systemctl refuses to restart one, because a template is
    # not a thing that runs.  postfix.service is the wrapper the package enables
    # and every instance is PartOf it, so restarting it takes the instances with
    # it -- which is what the packaging intends you to do.
    return ('postfix.service');
}


sub accumulates {
    my ( $self, $key ) = @_;
    return $ACCUMULATES{$key} // 0;
}


sub combine {
    my ( $self, $key, @items ) = @_;
    return 'all' if $key eq 'inet_interfaces' && grep { $_ eq 'all' } @items;
    return @items;
}


sub parse {
    my ( $self, $text ) = @_;
    return $self->_is_master($text) ? $self->_parse_master($text) : $self->_parse_main($text);
}

# A master.cf row is a service name followed by its type, and nothing in main.cf
# looks like that -- every setting there is `name = value`.
sub _is_master {
    my ( $self, $text ) = @_;

    foreach my $line ( split( qq{\n}, $text ) ) {
        next     if $line =~ m/\A\s*(?:#|\z)/;
        return 0 if $line =~ m/\A\S+\s*=/;
        return 1 if $line =~ m/\A\S+\s+(?:inet|unix|unix-dgram|fifo|pass)\s/;
    }

    return 0;
}

sub _parse_main {
    my ( $self, $text ) = @_;

    my @directives;
    foreach my $line ( split( qq{\n}, $text ) ) {

        # Postfix continues a value onto any following line that begins with
        # whitespace.  It belongs to the parameter above it, so it cannot be
        # merged on its own and has to travel with it.
        if ( $line =~ m/\A\s+\S/ && @directives && defined $directives[-1]{key} ) {
            my $continued = $line =~ s/\A\s+|\s+\z//gr;

            # `param =` with the value on the lines below it is how postfix's
            # own main.cf writes the long ones, so the first continuation of an
            # empty value must not arrive with a space in front of it.
            $directives[-1]{value} =
              length $directives[-1]{value}
              ? "$directives[-1]{value} $continued"
              : $continued;
            next;
        }

        if ( $line =~ m/\A\s*(?:#.*)?\z/ ) {
            push @directives, { text => $line };
            next;
        }

        if ( $line =~ m/\A(\S+?)\s*=\s*(.*?)\s*\z/ ) {
            push @directives, { key => $1, value => $2 };
            next;
        }

        # Not a comment, not a setting, and postfix would refuse to start on it.
        die "Cannot parse postfix main.cf line: $line\n";
    }

    return \@directives;
}

sub _parse_master {
    my ( $self, $text ) = @_;

    my @directives;
    foreach my $line ( split( qq{\n}, $text ) ) {

        # Same continuation rule, and here it is how a service's command line
        # gets its -o overrides, one per line.
        if ( $line =~ m/\A\s+\S/ && @directives && defined $directives[-1]{key} ) {
            push @{ $directives[-1]{continuation} }, ( $line =~ s/\s+\z//r );
            next;
        }

        if ( $line =~ m/\A\s*(?:#.*)?\z/ ) {
            push @directives, { text => $line };
            next;
        }

        my @columns = split( /\s+/, $line );
        die "Cannot parse postfix master.cf line (wanted 8 columns, got " . scalar(@columns) . "): $line\n"
          if @columns < 8;

        # A service is identified by its name and its type together: smtp has
        # both an inet entry and a unix one, and they are different services.
        my ( $service, $type ) = @columns[ 0, 1 ];
        push @directives, {
            key          => "$service/$type",
            columns      => [ @columns[ 0 .. 6 ] ],
            value        => join( q{ }, @columns[ 7 .. $#columns ] ),
            continuation => [],
        };
    }

    return \@directives;
}


sub emit {
    my ( $self, $directives ) = @_;

    my $is_master = scalar( grep { _is_master_key( $_->{key} ) } @$directives );
    return $is_master ? $self->_emit_master($directives) : $self->_emit_main($directives);
}

# A master.cf directive is keyed on the service and its type together, which is
# the one key in either file with a slash in it: main.cf parameter names are
# word characters and underscores.
sub _is_master_key {
    my ($key) = @_;
    return defined $key && index( $key, q{/} ) >= 0;
}

sub _emit_main {
    my ( $self, $directives ) = @_;

    my $out = q{};
    foreach my $directive (@$directives) {
        if ( !defined $directive->{key} ) {
            $out .= ( $directive->{text} // q{} ) . "\n";
            next;
        }
        $out .= "$directive->{key} = $directive->{value}\n";
    }

    return $out;
}

sub _emit_master {
    my ( $self, $directives ) = @_;

    my $out = q{};
    foreach my $directive (@$directives) {
        if ( !defined $directive->{key} ) {
            $out .= ( $directive->{text} // q{} ) . "\n";
            next;
        }

        # master.cf is read by column position, so the columns are padded to the
        # widths postfix's own file uses rather than joined with single spaces.
        my @columns = @{ $directive->{columns} };
        $out .= sprintf( "%-14s %-6s %-7s %-7s %-7s %-7s %-7s %s\n", @columns, $directive->{value} );
        $out .= "$_\n" for @{ $directive->{continuation} // [] };
    }

    return $out;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Language::postfix - main.cf and master.cf, which postfix has never had a conf.d for.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Configd();

    Configd->adopt('postfix');    # main.cf and master.cf become generated
    Configd->build('postfix');    # which is what the systemd drop-in then runs

From a shell, which is how it is actually used:

=over 4

=item C<configd adopt postfix>

=item C<< printf 'mydestination = example.com\n' > /etc/postfix/main.cf.d/50-example.cf >>

=item C<systemctl restart postfix>

=back

=head1 DESCRIPTION

Postfix has C<postconf -e> and nothing else.  It sets a parameter by rewriting
C<main.cf>, which is fine for a person at a terminal and wrong for anything
automated: two things configuring the same server cannot both set
C<mydestination>, because the second one to run replaces what the first wrote
rather than adding to it.  Hosting two domains on one mail server is enough to
hit it, and the failure is quiet -- mail for the first domain simply stops being
local.

So C<main.cf> and C<master.cf> become generated files with C<main.cf.d> and
C<master.cf.d> beside them, and each domain drops in a fragment naming itself.
The parameters that are lists are merged as lists; see L</ACCUMULATING PARAMETERS>.

=head2 What the fragments look like

Exactly like the file they add to, because that is the point -- anything you
would have written in C<main.cf> is a fragment:

    # /etc/postfix/main.cf.d/50-example.com.cf
    mydestination = example.com
    virtual_mailbox_domains = example.com
    virtual_mailbox_maps = hash:/etc/postfix/virtual/maps

=head1 NAME

Configd::Language::postfix - main.cf and master.cf, which postfix has never had
a conf.d for.

=head1 ACCUMULATING PARAMETERS

C<sender_dependent_relayhost_maps> and C<smtpd_sender_login_maps> are here for
the same reason as the rest and were missed the first time, which is worth
naming because the second one fails dangerously.  It is what
C<reject_authenticated_sender_login_mismatch> reads, so a host where it does not
accumulate ends up naming one domain's table -- and every other domain's users,
whose addresses are then owned by nobody, are refused when they try to send.

C<smtp_sasl_password_maps> and C<smtp_tls_policy_maps> were missed the same
way.  A host that sends each domain's mail through a relay of its own, with
C<smtp_sender_dependent_authentication>, names a table per domain in each.
Where they do not accumulate, the mail of every domain but the last goes to
its relay with no login and no TLS policy, and the relay refuses it.

The parameters postfix documents as comma-or-space separated lists, where two
fragments each naming a domain, a map or a milter both meant it:
C<mydestination>, C<mynetworks>, C<relay_domains>, the C<virtual_*> family, the
C<*_maps> and C<*_checks> families, C<smtpd_milters> and C<inet_interfaces>
among them.  Anything else is a value, and a later fragment replaces it.

The C<*_restrictions> parameters are deliberately B<not> accumulated even though
they are lists.  They are ordered, the order is what they mean, and joining two
of them end to end gives something that parses and that neither fragment asked
for -- a C<permit_> landing ahead of a check that was supposed to run first is
an open relay.  Two fragments disagreeing about a restriction list is something
a person should look at.

=head1 WHAT THIS DOES NOT REACH: THE LOOKUP TABLES

main.cf is full of paths, and none of them are this language's business.
C<virtual_mailbox_maps> names a file of addresses; C<header_checks> names a file
of patterns; C<check_recipient_access> names one from inside a restriction list.
Adopting main.cf merges the parameters that B<name> those tables and does
nothing whatever to the tables themselves, which is worth saying out loud
because the parameter merging cleanly is exactly what makes it easy to believe
the problem is solved.

Where the parameter accumulates the tables come along for free, because postfix
searches a list of them in order.  Two domains each writing their own file and
each naming it is enough:

    # 50-first.example.com
    virtual_mailbox_maps = hash:/etc/postfix/virtual/first.example.com

    # 50-second.example.com
    virtual_mailbox_maps = hash:/etc/postfix/virtual/second.example.com

That is the whole answer for C<virtual_mailbox_maps>, C<virtual_alias_maps>,
C<transport_maps>, C<header_checks> and the rest of the accumulating list, and
it needs nothing from this distribution.

It is B<not> available for a table named from inside a restriction list.
C<check_recipient_access pcre:/etc/postfix/recipient_access> lives inside
C<smtpd_recipient_restrictions>, which does not accumulate and must not, so the
path in it is whatever the last fragment to mention that parameter said.  Every
domain therefore shares one table, and the second one provisioned overwrites the
first one's -- the same failure adopting main.cf was meant to end, one level
down and out of reach.

Two things follow, and both are the caller's rather than this language's:

=over 4

=item * A shared table has to be B<assembled> rather than merged, because these
are ordered files.  A pcre or regexp table is read top to bottom and the first
match wins, so a catch-all belongs at the end and concatenating two domains'
tables puts one in the middle.  Numeric prefixes on the fragments, and the
catch-all last, is the shape that works -- the same shape configd gives a config
file, which is not a coincidence but is not implemented here either.

=item * Before building any of that, check whether the table is needed at all.
Postfix rejects a recipient in a virtual mailbox domain that is absent from
C<virtual_mailbox_maps> by itself -- "User unknown in virtual mailbox table" --
and one in a local domain absent from C<local_recipient_maps> likewise, so an
access table written to reject unknown recipients is often restating a check
postfix already makes, and is only load-bearing because the configuration has a
domain in two address classes at once.  L<https://www.postfix.org/ADDRESS_CLASS_README.html>
is the page; C<VIRTUAL_README> is blunter about it: "NEVER list a virtual
MAILBOX domain name as a mydestination domain!"

=back

=head1 METHODS

=head2 files()

C<main.cf> and C<master.cf>.

=head2 units()

C<postfix@.service>, the templated unit.

=head2 services()

C<postfix.service>, which is what can actually be restarted.

=head2 accumulates($key)

True for the list parameters above.  Never true of a master.cf entry, which is a
row rather than a list: two fragments configuring one service disagree about it,
and the later one wins.  The base class's comma is therefore the only separator
this language ever needs.

=head2 @items = $language->combine($key, @items)

C<all> alone for an C<inet_interfaces> that has C<all> among its items,
because postfix refuses C<all> beside an address, and C<all> already listens
on every address.  C<@items> as they are for anything else.

=head2 parse($text)

Read a fragment of either file.

Which one is worked out from the text rather than from a filename, because a
C<main.cf> line and a C<master.cf> line cannot be mistaken for each other: the
first has an C<=> and the second is a row of columns.

=head2 emit($directives)

Write the file back.  Which file, again, from what is in it.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Language>

=item *

L<https://www.postfix.org/postconf.5.html>, L<https://www.postfix.org/master.5.html>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
