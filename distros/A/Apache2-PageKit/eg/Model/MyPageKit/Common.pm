package MyPageKit::Common;

# $Id: Common.pm,v 1.29 2004/05/06 09:55:56 borisz Exp $

use strict;

use vars qw(@ISA);
use Apache2::PageKit::Model;
@ISA = qw(Apache2::PageKit::Model);

use Apache2::Const qw(OK REDIRECT DECLINED);

use Digest::MD5 ();
use DBI;

no strict 'refs';
${ __PACKAGE__ . '::secret_md5' } = 'you_should_place_your_own_md5_string_here';
use strict 'refs';

use MyPageKit::MyModel;

sub pkit_dbi_connect {
  # this line should be replaced with a DBI->connect(...) statement
  # for your database
  my $pkit_root = shift->pkit_root;
  return DBI->connect_cached("dbi:SQLite:dbname=$pkit_root/dbfile","","")
	|| die "$DBI::errstr";
}

sub pkit_session_setup {
  my $model = shift;
  my $dbh = $model->dbh;

  my %session_setup = (
        session_store_class     => 'MySQL',
	session_lock_class      => 'Null',
	session_serialize_class => 'Base64',
	session_args => {
                         Handle => $dbh,
        },
  );
  return \%session_setup;
}

sub pkit_common_code {
  my $model = shift;

  # put code that is common to all pages here
  my $session = {};

  # only create new session if pkit_admin is set
  if ($model->pkit_get_session_id || $model->input('pkit_admin')) {
    $session = $model->session;
  }

  # for the pagekit.org website, we control the colors based on the
  # values the user selected, stored in the session.
  $model->output(link_color => $session->{'link_color'} || '#ff9933');
  $model->output(text_color => $session->{'text_color'} || '#000000');
  $model->output(bgcolor => $session->{'bgcolor'} || '#dddddd');
  $model->output(mod_color => $session->{'mod_color'} || '#ffffff');

  # toggle on-line editing tools
  if($model->input('pkit_admin')) {
    $session->{'pkit_admin'} = $model->input('pkit_admin') eq 'on' ? 1 : 0;
  }
  $model->output(pkit_admin => $session->{'pkit_admin'});
}

sub pkit_auth_credential {
  my ($model) = @_;
  my $dbh = $model->dbh;
  my $login = $model->input('login');
  my $passwd = $model->input('passwd');

  unless ( $login && $passwd ){
    $model->pkit_gettext_message("You did not fill all of the fields.  Please try again.",
		 is_error => 1);
    return;
  }
  my $epasswd = crypt $passwd, "pk";

  my $sql_str = "SELECT user_id, passwd FROM pkit_user WHERE login=?";

  my ($user_id, $dbpasswd) = $dbh->selectrow_array($sql_str, {}, $login);

  unless ($user_id && $dbpasswd && $epasswd eq crypt($dbpasswd,$epasswd)){
    $model->pkit_gettext_message("Your login/password is invalid. Please try again.",
		is_error => 1);
    return;
  }

  no strict 'refs';
  my $hash = Digest::MD5::md5_hex(join ':', ${ __PACKAGE__ . '::secret_md5' }, $user_id, $epasswd);
  use strict 'refs';

  my $ses_key = {
		 'user_id'   => $user_id,
		 'hash'    => $hash
		};

  return $ses_key;
}

sub pkit_auth_session_key {
  my ($model, $ses_key) = @_;

  my $dbh = $model->dbh;

  my $user_id = $ses_key->{user_id} or return;

  my $sql_str = "SELECT login, passwd FROM pkit_user WHERE user_id=?";

  my ($login, $epasswd) = $dbh->selectrow_array($sql_str,{},$user_id);
  
  return unless $login;

  # create a new hash and verify that it matches the supplied hash
  # (prevents tampering with the cookie)
  no strict 'refs';
  my $newhash = Digest::MD5::md5_hex(join ':', ${ __PACKAGE__ . '::secret_md5' }, $user_id, crypt($epasswd,"pk"));
  use strict 'refs';

  return unless $newhash eq $ses_key->{'hash'};

  $model->output(pkit_user => $user_id);

  $model->output('pkit_login',$login);

  # the second variable return is the session_id, which in this application
  # is the same as the user_id
  return ($user_id, $user_id);
}

1;

__END__

=head1 NAME

MyPageKit::Common - Model class containing code common across site.

=head1 DESCRIPTION

This class contains methods that are common across the site, such
as authentication and session key generation.  This particular class
is an example class that is used for the old pagekit.org website.
It is derived from Apache2::PageKit::Model and a base class for
the Model classes for the pagekit.org site.

It is a good starting point for building your own base class for your
Model classes.

=head1 AUTHORS

T.J. Mather (tjmather@anidea.com)

Boris Zentner (bzm@2bz.de)

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005 AnIdea, Corp.  All rights Reserved.  PageKit is a trademark
of AnIdea Corp.

=head1 LICENSE

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Ricoh Source Code Public License for more details.

You can redistribute this module and/or modify it only under the terms of the Ricoh Source Code Public License.

You should have received a copy of the Ricoh Source Code Public License along with this program;
if not, obtain one at http://www.pagekit.org/license
