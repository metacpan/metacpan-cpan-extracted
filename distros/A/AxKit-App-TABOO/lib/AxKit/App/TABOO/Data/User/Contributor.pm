package AxKit::App::TABOO::Data::User::Contributor;
use strict;
use warnings;
use Carp;

use AxKit::App::TABOO::Data;
use AxKit::App::TABOO::Data::User;
use vars qw/@ISA/;
@ISA = qw(AxKit::App::TABOO::Data::User);

use DBI;


our $VERSION = '0.21';


=head1 NAME

AxKit::App::TABOO::Data::User::Contributor - Contributor Data objects for TABOO

=head1 SYNOPSIS

  use AxKit::App::TABOO::Data::User::Contributor;
  $user = AxKit::App::TABOO::Data::User::Contributor->new(@dbconnectargs);
  $user->load(what => '*', limit => {'username' => 'kjetil'});
  my $fullname = $user->load_authlevel('kjetil');

=head1 DESCRIPTION

This Data class subclasses L<AxKit::App::TABOO::Data::User> to add an
authentication level and optional biographical information for a
contributor to a site.


=cut

AxKit::App::TABOO::Data::User::Contributor->dbfrom("users INNER JOIN contributors ON (users.username = contributors.username)");
AxKit::App::TABOO::Data::User::Contributor->dbtable("users,contributors");
AxKit::App::TABOO::Data::User::Contributor->elementorder("username, name, email, uri, passwd, bio, authlevel");

=head1 METHODS

This class implements two methods, the rest is inherited from
L<AxKit::App::TABOO::Data::User>.

=over

=item C<new(@dbconnectargs)>

The constructor. Makes sure that we inherit the data members from our
superclass. Apart from that, nothing special.

=cut

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self = $class->SUPER::new(@_);
    $self->{authlevel} = 0;
    $self->{bio} = undef;
    bless($self, $class);
    return $self;
}



# We reimplement the load method with no changes to the API. Actually,
# the reason is to preserve the API, we need to do it because we're
# getting data from two tables, and they both have a username field.

sub load {
  my ($self, %args) = @_;
  my $tmp = $args{'limit'}{'username'};
  if ($tmp) {
    delete $args{'limit'}{'username'};
    $args{'limit'}{'users.username'} = $tmp;
  }

  my $data = $self->_load(%args);
  if ($data) {
    ${$self}{'ONFILE'} = 1;
  } else {
    return undef;
  }
  foreach my $key (keys(%{$data})) {
    ${$self}{$key} = ${$data}{$key}; 
  }
  return $self;
}



=item C<load_authlevel($username)>

This is an ad hoc method to retrieve the authorization level of a
user, and it takes a C<$username> key to identify whose level to
retrieve. It will return a number that may be used to decide whether
or not to grant access to an object or a data member. It will also
populate the corresponding data fields of the object. You may
therefore call C<write_xml> on the object afterwards and have markup
for the username and level.

=cut

sub load_authlevel {
    my $self = shift;
    my $username = shift;
    my $dbh = DBI->connect($self->dbconnectargs());
    my $sth = $dbh->prepare("SELECT authlevel FROM contributors WHERE username=?");
    $sth->execute($username);
    my ($data) = $sth->fetchrow_array;
    if ($data) {
      ${$self}{'ONFILE'} = 1;
    }
    ${$self}{'authlevel'} = $data;
    ${$self}{'username'} = $username;
    return ${$self}{'authlevel'};
}



=item C<save()>

The C<save()> method has been reimplemented in this class. It is less
generic than the method of the grandparent class, but it saves data to
two different tables, and should do its job well. It takes no
parameters.


=cut

sub save {
  my $self = shift;
  my $dbh = DBI->connect($self->dbconnectargs());
  my $seq_id;
  my (@fields, @confields);
  my $i=0;
  my $j=0;
  foreach my $key (keys(%{$self})) {
      next if ($key =~ m/[A-Z]/); # Uppercase keys are not in db
      next unless defined(${$self}{$key}); # No need to insert something that isn't there
      if (($key eq 'bio') || ($key eq 'authlevel')) {
	# TODO: This is too ad-hoc, should have a better way to split the keys
	push(@confields, $key);
	$j++;
      } elsif (($key eq 'username') && (! ${$self}{'ONFILE'})) {
	push(@confields, $key);
	$j++;
	push(@fields, $key);
	$i++;
      } else {
	push(@fields, $key);
	$i++;
      }
    }
    if (($i == 0) && ($j == 0)) {
      carp "No data fields with anything to save";
    } else {
      my ($sth1, $sth2, $query);
      if (${$self}{'ONFILE'}) {
	$sth1 = $dbh->prepare("UPDATE users SET " . join('=?,', @fields) . "=? WHERE username=?");
	$sth2 = $dbh->prepare("UPDATE contributors SET " . join('=?,', @confields) . "=? WHERE username=?");
      } else {
	($seq_id) = $dbh->selectrow_array("SELECT NEXTVAL('users_id_seq')");
	$sth1 = $dbh->prepare("INSERT INTO users (" . join(',', @fields) . ",ID) VALUES (" . '?,' x $i . '?)');
	$query = "INSERT INTO contributors (" . join(',', @confields) . ",Users_ID) VALUES (" . '?,' x $j . '?)';
  	$sth2 = $dbh->prepare($query);
      }
#      warn "QUERY: $query";
      my $k=1;
      foreach my $key (@fields) {
	$sth1->bind_param($k, ${$self}{$key});
	$k++;
      }
      if (${$self}{'ONFILE'}) {
	  $sth1->bind_param($k, ${$self}{'username'});
      } else {
	$sth1->bind_param($k, $seq_id);
      }
      $k=1;
      foreach my $key (@confields) {
	$sth2->bind_param($k, ${$self}{$key});
	$k++;
      }
      if (${$self}{'ONFILE'}) {
	  $sth2->bind_param($k, ${$self}{'username'});
      } else {
	$sth2->bind_param($k, $seq_id);
      }
      if ($i > 0) {
	$sth1->execute();
      }
      if ($j > 0) {
	$sth2->execute();
      }
  }
  return $self;
}



=back

=head1 STORED DATA

The data is stored in named fields, and for certain uses, it is good
to know them. If you want to subclass this class, you might want to
use the same names, see the documentation of
L<AxKit::APP::TABOO::Data> for more about this.

In addition to the names of the
L<parent|AxKit::APP::TABOO::Data::User>, this class adds the following
fields:


=over

=item * authlevel

An integer representing the authorization level of a user. In the
present implementation, it is a signed two-byte integer. It is
intended to be used to decide whether or not to grant access to an
object or a data member.

=item * bio

The contributors biographical information. 

=back

This is likely to be extended in future versions. 

=head1 BUGS/TODO

You cannot use the save method in this class to save an object in the
case where there is a record for the parent class, but lacks one for
this class.


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut

1;
