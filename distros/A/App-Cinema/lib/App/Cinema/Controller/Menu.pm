package App::Cinema::Controller::Menu;
use Moose;
use namespace::autoclean;
use Mail::Mailer;
use HTTP::Date qw/time2iso/;

BEGIN {
	extends qw/Catalyst::Controller::FormBuilder/;
	our $VERSION = $App::Cinema::VERSION;
}

sub home : Local {
	my ( $self, $c ) = @_;
	my $result =
	  $c->model('MD::Item')
	  ->search( undef, { rows => 1, order_by => { -desc => 'release_date' } } );
	$c->stash->{items} = $result;
	my $news =
	  $c->model('MD::News')
	  ->search( undef, { rows => 1, order_by => { -desc => 'release_date' } } );
	$c->stash->{news} = $news;
}

sub search : Local {
	my ( $self, $c ) = @_;

	my $genre = $c->req->params->{sel};
	my $str = $c->req->params->{txt};

	my $uri = '';
	my @fields = undef;	

	if ( $genre eq 'item' ) {		
		$uri    = '/item/view';
		@fields = qw/title plot year/;
	}
	elsif ( $genre eq 'news' ) {
		$uri    = '/news/view';
		@fields = qw/title content/;
	}
	elsif ( $genre eq 'event' ) {
		$uri    = '/user/history';
		@fields = qw/target content/;
	}
	elsif ( $genre eq 'user' ) {
		$uri    = '/user/view';
		@fields = qw/first_name last_name email_address username/;
	}

	my @tokens = $str;
	@fields = cross( \@fields, \@tokens );
	$c->session->{query} = \@fields;
	#$c->session->{str} = $str;
	$c->session->{genre} = $genre;
	$c->res->redirect( $c->uri_for($uri) );
}

sub cross {
	my $columns = shift || [];
	my $tokens  = shift || [];
	map { s/%/\\%/g } @$tokens;
	my @result;
	foreach my $column (@$columns) {
		push @result, ( map +{ $column => { -like => "%$_%" } }, @$tokens );
	}
	return @result;
}

sub about : Local {
	my ( $self, $c ) = @_;
	$c->stash->{error} = $c->config->{need_login_errmsg}
	  unless $c->user_exists();
}

sub howto : Local {
}

sub email : Local Form {
	my ( $self, $c ) = @_;

	unless ( $c->user_exists ) {
		$c->flash->{error} = $c->config->{need_login_errmsg};
		$c->res->redirect( $c->uri_for('/menu/howto') );
		return;
	}
	
	if ( $c->check_user_roles(qw/vipuser/) ) {
		$c->flash->{error} = "You're already a vipuser";
		$c->res->redirect( $c->uri_for('/menu/howto') );
		return;
	}

	my $form = $self->formbuilder;

	if ( $form->submitted && $form->validate ) {
		my $email = $c->user->obj->email_address;
		if ( !$email ) {
			$c->stash->{error} = $c->config->{email_null_errmsg};
			return;
		}
		my $subject =
		    "Upgrade to vipuser:"
		  . $c->user->obj->username . ':'
		  . time2iso(time);
		my $mailer = Mail::Mailer->new("sendmail");
		$mailer->open(
			{
				From    => $email,
				To      => $c->config->{SYSEMAIL},
				Subject => $subject,
			}
		) or die "Can't open: $!\n";
		my $body = $form->field('reason');
		print $mailer $body;
		$mailer->close();

		my $e = App::Cinema::Event->new();
		$e->uid( $c->user->obj->username );
		$e->desc(' request vipuser');
		$e->target('');
		$e->insert($c);

		$c->flash->{message} = 'Your email was sent to sysadmin.';
		$c->res->redirect( $c->uri_for('/menu/howto') );
	}
}

1;

=head1 NAME

App::Cinema::Controller::Menu - A controller that handles the request for the MENU link.

=head1 SYNOPSIS

You can call its actions in any template files either

    <a HREF="[% Catalyst.uri_for('/menu') %]">MENU</a>
    
or

    <a HREF="[% base %]menu">MENU</a>

You can also use them in any other controller modules like this:

    $c->res->redirect( $c->uri_for('/menu') );
		
=head1 DESCRIPTION

This is a controller that handles the request for the MENU link.

=head2 Methods

=over 12

=item C<index>

This private action is used to retrieve the data of News and Item from database, choose suitable template,
and then propagate to view module.

=back

=head1 AUTHOR

Jeff Mo - <mo0118@gmail.com>
