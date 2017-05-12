package FriendsPhotos;
use base 'CGI::Application';
use strict;

use lib ('../../lib','/usr/share/perl5');
use CGI::Application::ValidateRM;
use CGI::Uploader;

sub setup {
	my $self = shift;

	$self->start_mode('add_form');

	$self->run_modes([qw/
			add_form
			add_process

			edit_form
			edit_process

		/]);
	my $uploader_args  = $self->param('uploader_args') || die "must pass uploader PARAM";
	my $u = CGI::Uploader->new(%$uploader_args);
	$self->param('uploader',$u);

}

sub add_form {
	my $self = shift;
	my $t = $self->load_tmpl('photo-add.html');
	return $t->output;

};

sub add_process {
	my $self = shift;

	my $q = $self->query;
	my $query_hash = $q->Vars;
	my $dbh = $self->param('dbh');
	my $u   = $self->param('uploader');

	my ($results, $err_page) = $self->check_rm('add_form', {
			required => [qw/full_name photo/],
			msgs => { prefix => 'err_' },
	 });
 	return $err_page if $err_page;
	my $valid = $results->valid;

	my $friend;
	eval {
		 $dbh->{RaiseError} = 1;

		 $valid->{friend_id} = $dbh->selectrow_array("SELECT nextval('friend_id_seq')");
		 $friend = $u->store_uploads($valid);

		 require SQL::Abstract;
		 my $sql = SQL::Abstract->new;
		 my($stmt, @bind) = $sql->insert('address_book',$friend);

		 $dbh->do($stmt,{},@bind);
	};
	if ($@) {
		return "failure: $@";
	}
	else {
		my $new_q = CGI->new({
				success => 1,
				rm  => 'edit_form',
				friend_id => $friend->{friend_id}
			}
			);
		$self->header_type('redirect');
		$self->header_props( -url=> $ENV{SCRIPT_NAME}.'?'.$new_q->query_string );
	}
}

sub edit_form {
	my $self = shift;
	my $msgs = shift;

	my $q = $self->query;
	my $dbh = $self->param('dbh');
	my $friend_id = $q->param('friend_id');

	die "no friend_id found" unless $friend_id;

	my $t = $self->load_tmpl('photo-edit.html',die_on_bad_params=>0,);
	$t->param($msgs) if $msgs;
	$t->param(msg => $q->param('msg'));

	my $friend = $dbh->selectrow_hashref("SELECT * FROM address_book WHERE friend_id = ?",{},$friend_id);

	if ($friend->{photo_id}) {
		my $u   = $self->param('uploader');
		my $href = $u->fk_meta(
			table => 'address_book',
			where => { friend_id => $friend_id },
			prefixes => [qw/photo photo_thumbnail/]);
		$t->param($href);
	}

	require HTML::FillInForm;
	my $fif = HTML::FillInForm->new();
	return $fif->fill(scalarref=>\$t->output,fdat=>$friend);

}

sub edit_process {
	my $self = shift;

	my ($results, $err_page) = $self->check_rm('edit_form', {
			require_some => {
				photo_or_photo_id => [qw/photo photo_id/],
			},
			required => [qw/full_name friend_id/],
			msgs => { prefix => 'err_' },
	 });
 	return $err_page if $err_page;

	my $dbh = $self->param('dbh');
	my $q = $self->query;
	my $u   = $self->param('uploader');
	my $friend = $results->valid;

	eval {
		$dbh->{RaiseError} = 1;
		my @fk_names = $u->delete_checked_uploads;
		map { $friend->{$_} = undef } @fk_names;
		delete $friend->{photo_delete};

		$friend = $u->store_uploads($friend);
		require SQL::Abstract;
		my $sql = SQL::Abstract->new();
		my ($stmt,@bind) = $sql->update('address_book',$friend, { friend_id => $friend->{friend_id} });
		$dbh->do($stmt,{},@bind);
	};
	if ($@) {
		return "Failure: $@";
	}
	else {
		my $new_q = CGI->new({
				success => 1,
				rm  => 'edit_form',
				friend_id => $friend->{friend_id}
			}
		);
		$self->header_type('redirect');
		$self->header_props( -url=> $ENV{SCRIPT_NAME}.'?'.$new_q->query_string );
	}
}

1;
