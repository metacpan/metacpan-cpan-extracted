package AxKit::App::TABOO::Data::User;
use strict;
use warnings;
use Carp;
use Encode;

use AxKit::App::TABOO::Data;
use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data);

use DBI;

our $VERSION = '0.3';


=head1 NAME

AxKit::App::TABOO::Data::User - User Data objects for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::User;
  $user = AxKit::App::TABOO::Data::User->new(@dbconnectargs);
  $user->load(what => '*', limit => {username => 'kjetil'});
  my $fullname = $user->load_name('kjetil');

=head1 DESCRIPTION

This Data class contains basic user information, such as name, e-mail
address, an encrypted password, and so on.

=cut

AxKit::App::TABOO::Data::User->dbfrom("users");
AxKit::App::TABOO::Data::User->dbtable("users");
AxKit::App::TABOO::Data::User->dbprimkey("username");
AxKit::App::TABOO::Data::User->elementorder("username, name, email, uri, passwd");

=head1 METHODS

This class implements two methods, the rest is inherited from
L<AxKit::App::TABOO::Data>.

=over

=item C<new(@dbconnectargs)>

The constructor. Nothing special.

=cut

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self = {
	username => undef,
	name => undef,
	email => undef,
	uri => undef,
	passwd => undef,
	DBCONNECTARGS => \@_,
	XMLELEMENT => 'user',
	XMLPREFIX => 'user',
	XMLNS => 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output',
	ONFILE => undef,
    };
    bless($self, $class);
    return $self;
}

=item C<load_name($username)>

This is an ad hoc method to retrieve the full name of a user, and it
takes a C<$username> key to identify the user to retrieve. It will
return a string with the full name, but it will also populate the
corresponding data fields of the object. You may therefore call
C<write_xml> on the object afterwards and have markup for the username
and name.

=cut

sub load_name {
    my $self = shift;
    my $username = shift;
    my $dbh = DBI->connect($self->dbconnectargs());
    my $sth = $dbh->prepare("SELECT name FROM users WHERE username=?");
    $sth->execute($username);
    my @data = $sth->fetchrow_array;
    if (@data) {
      ${$self}{'ONFILE'} = 1;
    }
    ${$self}{'name'} = Encode::decode_utf8(join('', @data));
    ${$self}{'username'} = $username;
    return ${$self}{'name'};
}

=item C<load_passwd($username)>

This is an ad hoc method to retrieve the encrypted password of a user,
and it takes a C<$username> key to identify the user to retrieve. It
will return a string with the encrypted password, but it will also
populate the corresponding data fields of the object. You may
therefore call C<write_xml> on the object afterwards and have markup
for the username and passwd.

=cut

sub load_passwd {
    my $self = shift;
    my $username = shift;
    my $dbh = DBI->connect($self->dbconnectargs());
    my $sth = $dbh->prepare("SELECT passwd FROM users WHERE username=?");
    $sth->execute($username);
    my @data = $sth->fetchrow_array;
    if (@data) {
      ${$self}{'ONFILE'} = 1;
    }
    ${$self}{'passwd'} = join('', @data);
    ${$self}{'username'} = $username;
    return ${$self}{'passwd'};
}

=back

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::App::TABOO::Data> for more about this.

It is natural to subclass this as TABOO grows: One may record more
information about contributors to the site, or customers for a
webshop. For an example, see
L<AxKit::App::TABOO::Data::User::Contributor>

These are the names of the stored data of this class:

=over

=item * username

A simple word containing a unique name and identifier for the
category. Usually known as a username...

=item * name

The person's full name.

=item * email

The person's e-mail address. 

=item * uri

In the Semantic Web you'd like to identify things and their
relationships with URIs. So, we try to record URIs for everybody. For
those who have stable home page, it may be convenient to use that URL,
but for others, we may just have to come up with something smart.

=item * passwd

The user's encrypted password. Allthough it I<is> encrypted, you may
not want to throw it around too much. Perhaps it should have been
stored somewhere else entirely. YMMV.

=back

=head1 XML representation

The C<write_xml()> method, implemented in the parent class, can be
used to create an XML representation of the data in the object. The
above names will be used as element names. The C<xmlelement()>,
C<xmlns()> and C<xmlprefix()> methods can be used to set the name of
the root element, the namespace URI and namespace prefix
respectively. Usually, it doesn't make sense to change the default
namespace or prefix, that are


=over

=item * C<user>

=item * C<http://www.kjetil.kjernsmo.net/software/TABOO/NS/User/Output>

=item * C<user>

=back



=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;
