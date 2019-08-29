# This file is part of Config::Parser::ldap                   -*- perl -*-
# Copyright (C) 2019 Sergey Poznyakoff <gray@gnu.org>
#
# Config::Parser::ldap is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# Config::Parser::ldap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Config::Parser::ldap.  If not, see <http://www.gnu.org/licenses/>.

package Config::Parser::ldap;
use strict;
use warnings;
use parent 'Config::Parser';
use Carp;

our $VERSION = '1.00';

=head1 NAME

Config::Parser::ldap - configuration file parser for ldap.conf

=head1 SYNOPSIS

    $cfg = new Config::Parser::ldap($filename);

    $base = $cfg->get('base');


=head1 DESCRIPTION

A parser for F<ldap.conf> and similar files.

The syntax of F<ldap.conf> configuration file is very simple.  Each statement
occupies one physical line and consists of a keyword and its value separated
by one or more space characters.  Keywords are case-insensitive.  A value
starts with the first non-blank character after the keyword, and terminates
at the end of the line, or at the last sequence of blanks before the end of
the line.

Blank lines and lines beginning with a hash mark are ignored.

=head1 CONSTRUCTOR

=head2 $cfg = new Config::Parser::ldap(%opts);

Parses the supplied configuration file and creates a new object for
manipulating its settings.  Keyword arguments I<%opts> are:

=over 4

=item filename

Name of the file to parse.  The file must exist.

=item line

Optional line where the configuration starts in I<$filename>. It is used
to keep track of statement location in the file for correct diagnostics.
If not supplied, 1 is assumed.

=item fh

File handle to read from. If it is not supplied, new handle will be
created by using open on the supplied I<$filename>.

=item lexicon

Dictionary of configuration statements that are allowed in the file. You
will most probably not need this parameter. It is listed here for completeness
sake. Refer to the L<Config::AST> constructor for details.

=back

=cut

sub new {
    my ($class, %args) = @_;
    $class->SUPER::new(%args, ci => 1);
}

=head1 METHODS

All methods for accessing the configuration settings are inherited from
L<Config::AST>.

If you wish to use this class as a base class, please refer to
L<Config::Parser> for implementation details.

=head1 EXAMPLE

The following simplified example shows how to use this module to connect
and bind to a LDAP server.

    use Config::Parser::ldap;
    use Net::LDAP;

    # Parse configuration file
    $cf = new Config::Parser::ldap(filename => '/etc/ldap.conf');

    # Connect to server.
    $ldap = Net::LDAP->new($cf->uri->value);

    # Start TLS if required
    $args{capath} = $cf->get('tls_cacertdir');
    $args{cafile} = $cf->get('tls_cacert');
    $args{clientcert} = $cf->get('tls_cert');
    $args{clientkey} = $cf->get('tls_key');
    $args{ciphers} = $cf->get('tls_cipher_suite');
    if ($reqcert = $cf->get('tls_reqcert')) {
	my %tab = (
	    none => 'never',
	    allow => 'optional',
	    demand => 'require',
	    hard => 'require',
	    try => 'optional'
	);
	$args{verify} = $tab{$reqcert}
	    or die "unrecognized tls_reqcert: $reqcert";
    }
    $mesg = $ldap->start_tls(%args);
    $mesg->code && die $mesg->error;

    # Bind
    @bindargs = ();
    if (my $v = $cf->get('binddn')) {
	push @bindargs, $v
    }
    if (my $v = $cf->get('bindpw')) {
	push @bindargs, password => $v;
    }
    $mesg = $ldap->bind(@bindargs);
    $mesg->code && die $mesg->error;

=cut

sub parse {
    my $self = shift;
    my $filename = shift // confess "No filename given";
    local %_ = @_;
    my $fh = delete $_{fh};
    unless ($fh) {
	open($fh, "<", $filename)
	    or croak "can't open $filename: $!";
    }
    my $line = delete $_{line} // 0;

    while (<$fh>) {
	++$line;
	chomp;
	s/^\s+//;
	s/\s+$//;
	s/#.*//;
	next if $_ eq "";
	my ($kw, $val) = split /\s+/, $_, 2;
	my $locus = new Text::Locus($filename, $line);
	if (defined($kw) && defined($val)) {
	    $self->add_value([$kw], $val, $locus);
	} else {
	    $self->error("malformed line", locus => $locus);
	    $self->{_error_count}++;
	}
    }
    return $self;
}

=head1 SEE ALSO

L<Config::AST>.

L<Config::Parser>.

=cut

1;
