package MyPageKit::MyModel;

# $Id $

use vars qw(@ISA);
@ISA = qw(MyPageKit::Common);

use strict;

# this is just a testcase, it counts a counter in a session
# and redirect to the index page.
# delete it in your application
sub create_and_redirect {
  my $model = shift;
  $model->session->{counter}++;
  $model->pkit_redirect('/index');
}

# customize site look-and-feel
sub customize {
  my $model = shift;
  my $session = $model->session;
  my $change_flag;
  for (grep /color$/, $model->input){
    $session->{$_} = $model->input($_);
    $model->output($_ => $model->input($_));
    $change_flag = 1;
  }
  $model->pkit_gettext_message("Your changes have been made.") if $change_flag;
}

sub error_report {
  warn "test warning message";
}

sub form_validation_done {
  my $model = shift;
  my $input_profile = {
		       required => [ qw( email phone likes ) ],
		       optional => [ qw( toppings ) ],
		       constraints => {
				       email => "email",
				       phone => "phone",
				      },
		       messages => {
				    email => "The E-mail address, <b>%%VALUE%%</b>, is invalid.",
				    phone => "The phone number, <b>%%VALUE%%</b>, is invalid.",
				   },
		 };
  # validate user input
  unless($model->pkit_validate_input($input_profile)){
    $model->pkit_internal_redirect('form_validation');
    return;
  }
  $model->pkit_redirect('index');
}

sub index {
  my $model = shift;

  my $session_id = $model->pkit_get_session_id || '[Session not set]';
  $model->output(session_id => $session_id);

  my $pkit_server_id = $model->pkit_get_server_id;
  $model->output(pkit_server_id => $pkit_server_id);
}

sub language {
  my $model = shift;

  my $pkit_lang = $model->pkit_lang;

  $model->output(model_pkit_lang => $pkit_lang);
}

sub media {
  my $model = shift;

  # just for laughs, we display the process number
  $model->output(process_number => $$);
}

sub media_xslt {
  return shift->media;
}

sub newacct2 {
  my $model = shift;

  my $dbh = $model->dbh;

  my $input_profile = {
		  required => [ qw( email login passwd1 passwd2 ) ],
		  constraints => {
				  email => "email",
				  login => { constraint => sub {
					       my ($new_login) = @_;

					       # check to make sure login isn't already used
					       my $sql_str = "SELECT login FROM pkit_user WHERE login = ?";
					       # login is used, return false
					       return 0 if $dbh->selectrow_array($sql_str,{},$new_login);
					       # login isn't used, return true
					       return 1;
					     },
					     params => [ qw( login )]
					   },
				  passwd1 => { constraint => sub { return $_[0] eq $_[1]; },
					       params => [ qw( passwd1 passwd2 ) ]
					     },
				  passwd2 => { constraint => sub { return $_[0] eq $_[1]; },
					       params => [ qw( passwd1 passwd2 ) ]
					     },
				 },
		  messages => {
			       login => "The login, <b>%%VALUE%%</b>, has already been used.",
			       email => "The E-mail address, <b>%%VALUE%%</b>, is invalid.",
			       phone => "The phone number you entered is invalid.",
			       passwd1 => "The passwords you entered do not match.",
			      },
		 };
  # validate user input
  unless($model->pkit_validate_input($input_profile)){
    $model->pkit_internal_redirect('newacct1');
    return;
  }

  my $login = $model->input('login');
  my $passwd = $model->input('passwd1');

  # page to return to after user is logged in
  my $pkit_done = $model->input('pkit_done');

  # make up userID
  my $user_id = substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time(). {}. rand(). $$)), 0, 8);

  my $sql_str = "INSERT INTO pkit_user (user_id,email,login,passwd) VALUES (?,?,?,?)";
  $dbh->do($sql_str, {}, $user_id, $model->input('email'),
				$login, $passwd);

  # example of pkit_message being passed along with pkit_redirect
  $model->pkit_gettext_message("This message was passed throught pkit_redirect");
  $model->pkit_gettext_message("Another message passed throught pkit_redirect");

  $model->pkit_gettext_message("This ERROR message was passed throught pkit_redirect",
		      is_error => 1);

  $model->pkit_redirect("/?login=$login&passwd=$passwd&pkit_done=$pkit_done&pkit_login=1");
}

1;

__END__

=head1 NAME

MyPageKit::MyModel - Example Derived Model Class implementing Backend Code for pagekit.org website

=head1 DESCRIPTION

This module provides a example of a Derived Model component
(Business Logic) of a PageKit website.

It is also the code used for old the http://www.pagekit.org/ web site.  It contains
two methods, one for customizing the look and feel for the website, and
another for processing new account sign ups.

It is a good starting point for building your backend for your PageKit website.

=head1 AUTHORS

T.J. Mather (tjmather@thoughtstore.com)

Boris Zentner (bzm@2bz.de)

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005 AnIdea Corp.  All rights Reserved.  PageKit is a trademark
of AnIdea, Corp.

=head1 LICENSE

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Ricoh Source Code Public License for more details.

You can redistribute this module and/or modify it only under the terms of the Ricoh Source Code Public License.

You should have received a copy of the Ricoh Source Code Public License along with this program;
if not, obtain one at http://www.pagekit.org/license
