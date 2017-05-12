package MyApplication::State;

use strict;
use base 'Apache::Action::State';

# Not a DB object!

sub user {
	my ($self) = @_;
	unless (exists $self->{User}) {
		my $user_id = $self->{Session}->{user_id};
		if ($user_id) {
			my $user = retrieve Anarres::DesignDB::User($user_id);
			if ($user) {
				$self->{User} = $user;
			}
			else {
				delete $self->{Session}->{user_id};
			}
		}
	}
	return $self->{User};
}

sub set_user {
	my ($self, $user) = @_;
	if ($user) {
		$self->{Session}->{user_id} = $user->id;
		$self->{User} = $user;
	}
	else {
		delete $self->{Session}->{user_id};
		delete $self->{User};
	}
	return $self->{User};
}

sub category {
	my ($self) = @_;
	unless (exists $self->{Category}) {
		my $t = $self->{Request}->parms;	# Apache::Table;
		$self->{Session}->{category_id} = $t->{category}
						if exists $t->{category};
		my $cat = retrieve Anarres::DesignDB::Category(
						$self->{Session}->{category_id}
							)
						if $self->{Session}->{category_id};
		unless ($cat) {
			delete $self->{Session}->{category_id};
			delete $t->{category};
			$cat = retrieve Anarres::DesignDB::Category(1)
		}
		$self->{Category} = $cat;
		$self->{Session}->{RecentCategories}->{$cat->id} = 1;
	}
	return $self->{Category};
}

sub set_category {
	my ($self, $cat) = @_;
	$self->{Category} = $cat;
	$self->{Session}->{RecentCategories}->{$cat->id} = 1;
	$self->{Session}->{category_id} = $cat->id;
	return $self->{Category};
}

# etc etc (this came from a real application)

1;
