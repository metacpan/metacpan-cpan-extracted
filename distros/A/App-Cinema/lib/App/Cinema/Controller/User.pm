package App::Cinema::Controller::User;
use Moose;
use namespace::autoclean;
use Captcha::reCAPTCHA;
use Mail::Mailer;
require App::Cinema::Event;
use HTTP::Date qw/time2iso/;

BEGIN {
	extends qw/Catalyst::Controller::FormBuilder/;
	our $VERSION = $App::Cinema::VERSION;
}

sub captcha : Local {
	my ( $self, $c ) = @_;
	my $challenge = $c->req->param('recaptcha_challenge_field');
	my $response  = $c->req->param('recaptcha_response_field');
	my $rc        = Captcha::reCAPTCHA->new;
	my $pub_key   = $c->config->{PUB_KEY};

	$c->session->{human} = undef;

	# Check response
	if ($challenge) {
		my $result = $rc->check_answer(
			$c->config->{PRI_KEY},
			$c->config->{REMOTE_IP},
			$challenge, $response
		);
		if ( $result->{is_valid} ) {
			$c->session->{human} = 1;
			$c->res->redirect( $c->uri_for('/user/login') );
			return;
		}
		else {
			$c->stash->{err} = $result->{error};
		}
	}
	$c->stash->{key} = $pub_key;
	$c->stash->{rc}  = $rc;
}

sub login : Local Form {
	my ( $self, $c ) = @_;

	if ( !$c->session->{human} ) {
		$c->res->redirect( $c->uri_for('/user/captcha') );
		return;
	}

	my $form = $self->formbuilder;

	# Get the username and password from form
	my $uid = $form->field('username') || "";
	my $pwd = $form->field('password') || "";

	# If the username and password values were found in form
	if ( $form->submitted && $form->validate ) {
		my $status = $c->authenticate(
			{
				username => $uid,
				password => $pwd,
				active   => 1
			}
		);
		if ($status) {    # If successful, then let them use the application
			$c->flash->{message} = "Welcome back, " . $uid;
			$c->res->redirect( $c->uri_for('/menu/home') );
			return;
		}
		else {
			$c->flash->{error} = "Bad username or password.";
		}
	}
}

sub logout : Local {
	my ( $self, $c ) = @_;

	# Clear the user's state
	$c->logout();
	$c->flash->{message} = 'Log out successfully.';

	# Send the user to the starting point
	$c->res->redirect( $c->uri_for('/menu/home') );
}

sub history : Local {
	my ( $self, $c ) = @_;
	if ( !$c->user_exists ) {
		$c->stash->{error}    = $c->config->{need_login_errmsg};
		$c->stash->{template} = 'result.tt2';
		return;
	}
	my $rs = $c->model('MD::Event')->search( $c->session->{query},
		{ rows => 10, order_by => { -desc => 'e_time' } } );
	unless ( $c->check_user_roles(qw/sysadmin/) ) {
		$rs = $rs->search( { uid => $c->user->obj->username } );
	}

	#page navigation
	my $page = $c->req->param('page');
	$page               = 1 if ( $page !~ /^\d+$/ );
	$rs                 = $rs->page($page);
	$c->stash->{pager}  = $rs->pager();
	$c->stash->{events} = $rs;
}

sub add : Local Form {
	my ( $self, $c ) = @_;
	my $form = $self->formbuilder;
	if ( $form->submitted && $form->validate ) {
		eval {
			my $row = $c->model('MD::Users')->create(
				{
					first_name    => $form->field('fname'),
					last_name     => $form->field('lname'),
					email_address => $form->field('email'),
					username      => $form->field('uid'),
					password      => $form->field('pwd'),
					active        => 1,
					user_roles    => [ { role_id => $form->field('role') } ]
				}
			);
			my $e = App::Cinema::Event->new();
			$e->uid( $row->username );
			$e->desc(' created account : ');
			$e->target( $row->username );
			$e->insert($c);

			$c->flash->{message} = 'Added ' . $row->first_name;
			$c->res->redirect( $c->uri_for('/user/login') );
		};
		if ($@) {
			$c->stash->{error} = $@;
		}
		return;
	}
}

sub edit_sys : Local Form {
	my ( $self, $c, $id ) = @_;
	my $form  = $self->formbuilder;
	my $user  = $c->model('MD::Users')->find( { username => $id } );
	my $email = $user->email_address;

	unless ($email) {
		$c->flash->{error} = $c->config->{email_null_errmsg};
		$c->res->redirect( $c->uri_for('view') );
		return;
	}

	if ( $form->submitted && $form->validate ) {
		unless ( $form->submitted eq 'Save' ) {
			$c->res->redirect( $c->uri_for('/user/view') );
			return;
		}

		$c->model('MD::UserRoles')->search( { user_id => $user->username } )
		  ->delete();

		foreach ( $form->field('role') ) {
			$user->create_related( 'user_roles', { role_id => $_ } );
		}
		$user->update_or_insert();

		my $subject = "Change Roles:" . time2iso(time);
		my $mailer  = Mail::Mailer->new("sendmail");
		$mailer->open(
			{
				From    => $c->config->{SYSEMAIL},
				To      => $email,
				Subject => $subject,
				CC      => $c->config->{SYSEMAIL},
			}
		) or die "Can't open: $!\n";

		my $str = "";
		foreach ( $user->roles ) {
			$str = $str . $_->role . ',';
		}

		my $fn = $user->first_name;
		print $mailer <<EO_SIG;
Hi $fn,

Your account has been changed by sysadmin. Your new roles are:
$str

Please let us know if you have any question.

Thank,
JandC
EO_SIG
		close($mailer);

		$user->update_or_insert();

		my $e = App::Cinema::Event->new();
		$e->desc(' edited account : ');
		$e->target($id);
		$e->insert($c);

		$c->flash->{message} = 'Edited ' . $user->first_name;
		$c->res->redirect( $c->uri_for('/user/view') );
		return;
	}

	my @ids = ();
	foreach ( $user->user_roles ) {
		push @ids, $_->role_id;
	}

	$c->stash->{message} = $id;

	$form->field(
		name  => 'role',
		type  => 'checkbox',
		value => \@ids,
	);
	if ( $c->check_user_roles(qw/sysadmin/) ) {
		$form->field(
			name    => 'role',
			options => [
				[ 1 => 'user' ],
				[ 2 => 'vipuser' ],
				[ 3 => 'admin' ],
				[ 4 => 'sysadmin' ],
			]
		);
		return;
	}
	if ( $c->check_user_roles(qw/vipuser/) ) {
		$form->field(
			name => 'role',
			options =>
			  [ [ 1 => 'user' ], [ 2 => 'vipuser' ], [ 3 => 'admin' ], ]
		);
		return;
	}
	if ( $c->check_any_user_role(qw/user admin/) ) {
		$form->field(
			name    => 'role',
			options => [ [ 1 => 'user' ], [ 3 => 'admin' ], ]
		);
		return;
	}
}

sub edit : Local Form {
	my ( $self, $c, $id ) = @_;
	my $form = $self->formbuilder;
	my $user = $c->model('MD::Users')->find( { username => $id } );

	unless ( $user->username eq $c->user->obj->username() ) {
		$c->res->redirect( $c->uri_for('edit_sys') . "/" . $id );
		return;
	}

	if ( $form->submitted && $form->validate ) {
		unless ( $form->submitted eq 'Save' ) {
			$c->res->redirect( $c->uri_for('/user/view') );
			return;
		}
		my %attrs = { user_id => $user->username };

		$c->model('MD::UserRoles')->search( { user_id => $user->username } )
		  ->delete();

		$user->first_name( $form->field('fname') );
		$user->last_name( $form->field('lname') );
		$user->email_address( $form->field('email') );
		$user->password( $form->field('pwd') );

		foreach ( $form->field('role') ) {
			$user->create_related( 'user_roles', { role_id => $_ } );
		}

		$user->update_or_insert();

		my $e = App::Cinema::Event->new();
		$e->desc(' edited account : ');
		$e->target($id);
		$e->insert($c);

		$c->flash->{message} = 'Edited ' . $user->first_name;
		$c->res->redirect( $c->uri_for('/user/view') );
		return;
	}

	$form->field(
		name  => 'fname',
		value => $user->first_name,
	);
	$form->field(
		name  => 'lname',
		value => $user->last_name,
	);
	$form->field(
		name  => 'email',
		value => $user->email_address,
	);
	$form->field(
		name  => 'pwd',
		value => $user->password,
	);

	my @ids = ();
	foreach ( $user->user_roles ) {
		push @ids, $_->role_id;
	}

	$form->field(
		name  => 'role',
		type  => 'checkbox',
		value => \@ids,
	);
	if ( $c->check_user_roles(qw/sysadmin/) ) {
		$form->field(
			name    => 'role',
			options => [
				[ 1 => 'user' ],
				[ 2 => 'vipuser' ],
				[ 3 => 'admin' ],
				[ 4 => 'sysadmin' ],
			]
		);
		return;
	}
	if ( $c->check_user_roles(qw/vipuser/) ) {
		$form->field(
			name => 'role',
			options =>
			  [ [ 1 => 'user' ], [ 2 => 'vipuser' ], [ 3 => 'admin' ], ]
		);
		return;
	}
	if ( $c->check_any_user_role(qw/user admin/) ) {
		$form->field(
			name    => 'role',
			options => [ [ 1 => 'user' ], [ 3 => 'admin' ], ]
		);
		return;
	}
}

sub view : Local {
	my ( $self, $c, $uid ) = @_;
	if ( !$c->user_exists ) {
		$c->stash->{error}    = $c->config->{need_login_errmsg};
		$c->stash->{template} = 'result.tt2';
		return;
	}
	if ( $c->check_any_user_role(qw/sysadmin/) ) {
		$c->stash->{users} =
		  $c->model('MD::Users')->search( $c->session->{query} );
	}
	else {
		$c->stash->{users} =
		  $c->model('MD::Users')
		  ->search( username => $c->user->obj->username() );
	}
}

sub activate_do : Local {
	my ( $self, $c, $id ) = @_;

	eval { $c->assert_user_roles(qw/sysadmin/); };
	if ($@) {
		$c->flash->{error} = $c->config->{need_auth_msg};
		$c->res->redirect( $c->uri_for('/user/view') );
		return;
	}
	my $user = $c->model('MD::Users')->find($id);
	$user->active(1);
	$user->update_or_insert();

	my $e = App::Cinema::Event->new();
	$e->desc(' activated account : ');
	$e->target($id);
	$e->insert($c);

	$c->flash->{message} = "User is activated";
	$c->res->redirect( $c->uri_for('/user/view') );
}

sub deactivate_do : Local {
	my ( $self, $c, $id ) = @_;

#	eval { $c->assert_user_roles(qw/sysadmin/); };
#	if ($@) {
#		$c->flash->{error} = $c->config->{need_auth_msg};
#		$c->res->redirect( $c->uri_for('/user/view') );
#		return;
#	}
	my $user = $c->model('MD::Users')->find($id);
	$user->active(0);
	$user->update_or_insert();

	my $e = App::Cinema::Event->new();
	$e->desc(' deactivated account : ');
	$e->target($id);
	$e->insert($c);

	$c->flash->{message} = "User \'$id\' is deactivated";

	if ( $id eq $c->user->obj->username ) {
		$c->res->redirect( $c->uri_for('/user/logout') );
		return;
	}

	$c->res->redirect( $c->uri_for('/user/view') );
}

1;

=head1 NAME

App::Cinema::Controller::User - A controller that handles a user's actions.

=head1 SYNOPSIS

You can call its actions in any template files either

					  < a HREF =
					  "[% Catalyst.uri_for('/user/add') %]" > Admin </a>

					  or

					  <a HREF="[% base %]user/add"> Admin </a>

					  You can also
					  use them in any other controller modules like this
					:

					  $c->res->redirect( $c->uri_for('/user/edit') );

=head1 DESCRIPTION

This is a controller that will handle every action of a user.

=head2 Methods

=over 12

=item C<add>

This action is used to add a user.

=item C<delete_do>

This action is used to delete a user.

=item C<edit>

This action is used to modify a user.

=item C<history>

This action is used to display what does a user do during its session.

=item C<view>

This action is used to display all users in this system. 

=back

=head1 AUTHOR

Jeff Mo - <mo0118@gmail.com>
