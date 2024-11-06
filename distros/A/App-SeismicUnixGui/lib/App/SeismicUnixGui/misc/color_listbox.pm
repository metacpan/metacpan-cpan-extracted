package App::SeismicUnixGui::misc::color_listbox;

=head1 DOCUMENTATION
=head2 SYNOPSIS 
 PERL PROGRAM NAME: color_listbox 
 AUTHOR: 	Juan Lorenzo
 DATE: 		December 19, 2020
 DESCRIPTION 
     Basic class with color_listbox attributes
 BASED ON:
=cut

=head2 USE
=head3 NOTES
=head4 Examples
=head2 CHANGES and their DATES
=cut 

=head2 Notes from bash
 
=cut 

use Moose;
#use namespace::autoclean;    # best-practices hygiene
our $VERSION = '0.0.1';

=head2 Import modules
=cut

extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::gui_history';
use aliased  'App::SeismicUnixGui::messages::message_director';

=head2 Instantiation
=cut

my $get               = L_SU_global_constants->new();
my $gui_history       = gui_history->new();
my $message_director  = message_director->new();

=head2 Declare Special Variables
=cut

my $var                       = $get->var();
my $empty_string              = $var->{_empty_string};
my $color_default             = $var->{_color_default};               #grey
my $reservation_color_default = $var->{_reservation_color_default};
my $false                     = $var->{_false};
my $no                        = $var->{_no};
my $true                      = $var->{_true};

=head2 Defaults
=cut

my $availability_start                       = $false;
my $color_start                              = $color_default;
my $my_dialog_box_cancel_default             = $no;
my $my_dialog_box_click_default              = $no;
my $my_dialog_box_ok_default                 = $no;
my $my_dialog_box_click_start                = $no;
my $my_dialog_cancel_click_start             = $no;
my $my_dialog_ok_click_start                 = $no;
my $flow_listbox_color_start                 = $color_default;
my $flow_listbox_color2check_start           = $color_default;
my $next_available_occupied_start            = $false;
my $next_available_vacancy_start             = $false;
my $next_available_flow_listbox_color_start  = $color_default;
my $occupied_start                           = $false;
my $flow_listbox_color_reservation_start     = $reservation_color_default;
my $prior_available_flow_listbox_color_start = $color_default;
my $vacant_start                             = $true;
my $yes                                      = $var->{_yes};

# initialization only
# must be populated fromt  the outside via set_hash_ref
my $color_listbox_href = $gui_history->get_defaults();

=head2 private anonymous array
=cut

my $color_listbox = {
	_is_flow_listbox_color_available => '',
	_is_flow_listbox_blue_w          => '',
	_is_flow_listbox_green_w         => '',
	_is_flow_listbox_grey_w          => '',
	_is_flow_listbox_pink_w          => '',

	#	_is_next_available_flow_listbox_blue     => '',
	_is_next_available_flow_listbox_color => '',

	#	_is_next_available_flow_listbox_green    => '',
	#	_is_next_available_flow_listbox_grey     => '',
	#	_is_next_available_flow_listbox_pink     => '',
	_my_dialog_cancel_click => $my_dialog_box_cancel_default,
	_my_dialog_box_click    => $my_dialog_box_click_default,
	_my_dialog_ok_click     => $my_dialog_box_ok_default,
	_this_package           => '',
};

sub BUILD {
	my ($this_package_address) = @_;

	$color_listbox->{_this_package} = $this_package_address;

}

#print("2. color_listbox, color_listbox->{_my_dialog_box_click}=$color_listbox->{_my_dialog_box_click}\n");

=head2 private anonymous hashes 
containing history
=cut

=head2 initialize arrays
=cut

=head2 sub _default_flow_listbox_color_availability_aref 
Initialize array of listbox availability across an array
of colored listboxes
indicators show whether listbox may be available.
=cut

sub _default_flow_listbox_color_availability_aref {

	my ($self) = @_;

	my @availability_listbox_color = (
		$availability_start,
		$availability_start,
		$availability_start,
		$availability_start
	);

	my $flow_listbox_color_availability_aref = \@availability_listbox_color;
	return ($flow_listbox_color_availability_aref);

}

=head2 sub default_next_available_occupied_listbox_aref
Initialize array of next_available occupied-flow-listbox-array
indicators that indicate which listbox will next be
used
=cut

sub _default_next_available_occupied_listbox_aref {

	my ($self) = @_;

	my @next_available_occupied_listbox = (
		$next_available_occupied_start,
		$next_available_occupied_start,
		$next_available_occupied_start,
		$next_available_occupied_start
	);

	my $flow_listbox_next_available_occupancy_aref = \@next_available_occupied_listbox;
	return ($flow_listbox_next_available_occupancy_aref);

}

=head2 sub default_occupied_listbox_aref
Initialize array of occupied-flow-listbox-array
indicators
=cut

sub _default_occupied_listbox_aref {

	my ($self) = @_;

	my @occupied_listbox = (
		$occupied_start,
		$occupied_start,
		$occupied_start,
		$occupied_start
	);

	my $flow_listbox_occupancy_aref = \@occupied_listbox;
	return ($flow_listbox_occupancy_aref);

}

=head2 sub default_next_available_vacancy_listbox_aref
Initialize array of next_available vacant-flow-listbox-array
indicators that indicate which listbox will next be
used
=cut

sub _default_next_available_vacancy_listbox_aref {

	my ($self) = @_;

	my @next_available_vacancy_listbox = (
		$next_available_vacancy_start,
		$next_available_vacancy_start,
		$next_available_vacancy_start,
		$next_available_vacancy_start
	);

	my $flow_listbox_next_available_vacancy_aref = \@next_available_vacancy_listbox;
	return ($flow_listbox_next_available_vacancy_aref);

}

=head2 sub _default_vacant_listbox_aref
Initialize array of empty-flow-listbox-array
indicators
=cut

sub _default_vacant_listbox_aref {

	my ($self) = @_;

	my @vacant_listbox = (
		$vacant_start,
		$vacant_start,
		$vacant_start,
		$vacant_start
	);

	my $flow_listbox_vacancy_aref = \@vacant_listbox;
	return ($flow_listbox_vacancy_aref);

}

=head2 Declare attributes
Check hat empty flows are marked vacant.
Mark occupied and vacant flows as available
for occupation or reoccupation, (potentially)
=cut

has 'flow_listbox_color_availability_aref' => (
	default => \&_default_flow_listbox_color_availability_aref,
	is      => 'ro',
	isa     => 'ArrayRef',
	reader  => 'get_flow_listbox_color_availability_aref',
	writer  => 'set_flow_listbox_color_availability_aref',
	trigger => \&_update_flow_listbox_color_availability_aref,

);

has 'flow_listbox_color2check' => (
	default => $flow_listbox_color2check_start,
	is      => 'rw',
	isa     => 'Str',
	writer  => 'set_flow_listbox_color2check',
	trigger => \&_flow_listbox_color2check,
);

has 'flow_listbox_color' => (
	default   => $flow_listbox_color_start,
	is        => 'rw',
	isa       => 'Str',
	reader    => 'get_flow_listbox_color',
	writer    => 'set_flow_listbox_color',
	predicate => 'has_flow_listbox_color',
	trigger   => \&_update_flow_listbox_color,
);

has 'flow_listbox_next_available_occupancyNvacancy_aref' => (
	default   => \&_default_next_available_occupied_listbox_aref,
	is        => 'ro',
	isa       => 'ArrayRef',
	reader    => 'get_flow_listbox_next_available_occupancyNvacancy_aref',
	writer    => 'set_flow_listbox_next_available_occupancyNvacancy_aref',
	predicate => 'has_flow_listbox_next_available_occupancyNvacancy_aref',
	trigger   => \&_update_flow_listbox_next_available_occupancyNvacancy_aref,
);

has 'flow_listbox_occupancy_aref' => (
	default   => \&_default_occupied_listbox_aref,
	is        => 'ro',
	isa       => 'ArrayRef',
	reader    => 'get_flow_listbox_occupancy_aref',
	writer    => 'set_flow_listbox_occupancy_aref',
	predicate => 'has_flow_listbox_occupancy_aref',

	# trigger method is not in use
);

has 'flow_listbox_vacancy_color' => (
	default => $color_start,
	is      => 'ro',
	isa     => 'Str',
	reader  => 'get_flow_listbox_vacancy_color',
);

has 'flow_listbox_vacancy_aref' => (
	default   => \&_default_vacant_listbox_aref,
	is        => 'ro',
	isa       => 'ArrayRef',
	reader    => 'get_flow_listbox_vacancy_aref',
	predicate => 'has_flow_listbox_vacancy_aref',
);

has 'next_available_flow_listbox_color' => (
	default => $next_available_flow_listbox_color_start,
	is      => 'rw',
	isa     => 'Str',
	reader  => 'get_next_available_flow_listbox_color',
	writer  => 'set_next_available_flow_listbox_color',
	trigger => \&_update_next_available_flow_listbox_color,
);
has my_dialog_cancel_click => (
	default => $my_dialog_cancel_click_start,
	is      => 'rw',
	isa     => 'Str',
	reader  => 'get_my_dialog_cancel_click',
	writer  => 'set_my_dialog_cancel_click',
	trigger => \&_update_my_dialog_cancel_click,
);
has my_dialog_ok_click => (
	default => $my_dialog_ok_click_start,
	is      => 'rw',
	isa     => 'Str',
	reader  => 'get_my_dialog_ok_click',
	writer  => 'set_my_dialog_ok_click',

	#	trigger => \&_update_my_dialog_ok_click,
);

has my_dialog_box_click => (
	default => $my_dialog_box_click_start,
	is      => 'rw',
	isa     => 'Str',
	reader  => 'get_my_dialog_box_click',
	writer  => 'set_my_dialog_box_click',
);

has 'flow_listbox_color_reservation' => (
	default => $flow_listbox_color_reservation_start,
	is      => 'ro',
	isa     => 'Str',
	reader  => 'get_flow_listbox_color_reservation',
	writer  => 'set_flow_listbox_color_reservation',
	trigger => \&_update_flow_listbox_color_reservation,

);

has 'prior_available_flow_listbox_color' => (
	default => $prior_available_flow_listbox_color_start,
	is      => 'rw',
	isa     => 'Str',
	reader  => 'get_prior_available_flow_listbox_color',
	writer  => 'set_prior_available_flow_listbox_color',
	trigger => \&_update_prior_available_flow_listbox_color,
);


=head2  sub _flow_listbox_color2check
=cut

sub _flow_listbox_color2check {
	my ( $color_listbox, $new_current_flow_listbox_color2check, $new_prior_flow_listbox_color2check ) = @_;

	my $check = $new_current_flow_listbox_color2check;

	#	print("color_listbox, _flow_listbox_color2check, check=$check\n");

	if (   length $check
		&& length $color_listbox
		&& length $color_listbox->get_flow_listbox_occupancy_aref()
		&& length $color_listbox->get_flow_listbox_vacancy_aref() ) {

		my @occupied_listbox = @{ $color_listbox->get_flow_listbox_occupancy_aref() };
		my @vacant_listbox   = @{ $color_listbox->get_flow_listbox_vacancy_aref() };

		#		print(" color_listbox,_flow_listbox_color2check,occupied_listbox=@occupied_listbox \n");
		#		print(" color_listbox,_flow_listbox_color2check,vacant_listbox=@vacant_listbox \n");

		if (   $check eq 'grey'
			&& $occupied_listbox[0] == $false
			&& $vacant_listbox[0] == $true ) {

			#						print("color_listbox, _flow_listbox_color2check, grey flow box is empty\n");
			#			print(
			#				"color_listbox, _flow_listbox_color2check, occupied_listbox=$occupied_listbox[0], vacant_listbox=$vacant_listbox[0]\n"
			#			);
			#			print(
			#				"color_listbox, _flow_listbox_color2check, color_listbox->{_is_flow_listbox_color_available}=$color_listbox->{_is_flow_listbox_color_available}\n"
			#			);
			$color_listbox->{_is_flow_listbox_color_available} = $true;

		} elsif ( $check eq 'pink'
			&& $occupied_listbox[1] == $false
			&& $vacant_listbox[1] == $true ) {

			#						print("color_listbox, _flow_listbox_color2check, pink flow box is empty\n");
			#			print(
			#				"color_listbox, _flow_listbox_color2check, occupied_listbox=$occupied_listbox[1], vacant_listbox=$vacant_listbox[1]\n"
			#			);
			$color_listbox->{_is_flow_listbox_color_available} = $true;

			#			print("color_listbox, _flow_listbox_color2check,color_listbox->{_is_flow_listbox_color_available}=$color_listbox->{_is_flow_listbox_color_available}\n");

			#			print(
			#				"color_listbox, _flow_listbox_color2check, color_listbox->{_is_flow_listbox_color_available}=$color_listbox->{_is_flow_listbox_color_available}\n"
			#			);

		} elsif ( $check eq 'green'
			&& $occupied_listbox[2] == $false
			&& $vacant_listbox[2] == $true ) {

			#						print("color_listbox, _flow_listbox_color2check, green flow box is empty\n");
			#			print(
			#				"color_listbox, _flow_listbox_color2check, occupied_listbox=$occupied_listbox[2], vacant_listbox=$vacant_listbox[2]\n"
			#			);
			$color_listbox->{_is_flow_listbox_color_available} = $true;

		} elsif ( $check eq 'blue'
			&& $occupied_listbox[3] == $false
			&& $vacant_listbox[3] == $true ) {

			#						print("color_listbox, _flow_listbox_color2check, blue flow box is empty\n");
			#			print(
			#				"color_listbox, _flow_listbox_color2check, occupied_listbox=$occupied_listbox[3], vacant_listbox=$vacant_listbox[3]\n"
			#			);
			$color_listbox->{_is_flow_listbox_color_available} = $true;

		} else {

			#			print("color_listbox, _flow_listbox_color2check, no flow box is available\n");
			$color_listbox->{_is_flow_listbox_color_available} = $false;

			#			print(
			#				"color_listbox, _flow_listbox_color2check, color_listbox->{_is_flow_listbox_color_available}=$color_listbox->{_is_flow_listbox_color_available}\n"
			#			);
		}

		my $result = $color_listbox->{_is_flow_listbox_color_available};
		&_set_flow_listbox_color_available($result);

		#		print("color_listbox, _flow_listbox_color2check, result =$result\n");
		return ();

	} else {

		# ans= NOT free
		print("color_listbox, colored box is already occupied\n");

		#NADA
	}
	return ();
}

=head2 sub _get_message_box_ok_click
=cut

sub _get_message_box_ok_click {

	my ($self) = @_;
	my $message_box_ok_click = $color_listbox->{_message_box_ok_click};

	#	print("color_listbox, _get_message_box_ok_click ,color_listbox->{_message_box_ok_click}\n");
	return ($message_box_ok_click);

}

=head2 sub _get_my_dialog_cancel_click
=cut

sub _get_my_dialog_cancel_click {
	my ($self) = @_;

	my $cancel_click = $color_listbox->{_my_dialog_cancel_click};
	return ($cancel_click);
}

=head2 sub _get_my_dialog_box_click
=cut

sub _get_my_dialog_box_click {
	my ($self) = @_;

	my $response = $color_listbox->{_my_dialog_box_click};

	#	print("color_listbox,_get_my_dialog_box_click, color_listbox->{_my_dialog_box_click} = $color_listbox->{_my_dialog_box_click}\n");
	return ($response);

}

=head2 sub _get_my_dialog_ok_click
=cut

sub _get_my_dialog_ok_click {
	my ($self) = @_;

	my $response = $color_listbox->{_my_dialog_ok_click};

	#	print("color_listbox,_get_my_dialog_ok_click, color_listbox->{_my_dialog_ok_click} = $color_listbox->{_my_dialog_ok_click}\n");
	return ($response);

}

=head2 sub _hide_dialog_box
=cut

sub _hide_dialog_box {
	my ($self) = @_;

	my $my_dialog_box = $color_listbox_href->{_my_dialog_box_w};
	$my_dialog_box->grabRelease;
	$my_dialog_box->withdraw;
}

=head2 sub _set_flow_listbox_color_available
Mark the listbox color in use
=cut

sub _set_flow_listbox_color_available {

	my ($ans) = @_;

	if ( length $ans ) {

		$color_listbox->{_is_flow_listbox_color_available} = $ans;

		#		print("color_listbox, _set_flow_listbox_color_available=\$color_listbox->{_is_flow_listbox_color_available}\n");

	} else {
		print("color_listbox, _set_flow_listbox_color_available, unexpected result\n");
	}

	return ();
}

=head2 sub _set_message_box_ok_click
=cut

sub _set_message_box_ok_click {
	my ($self) = @_;

	$color_listbox->{_message_box_ok_click} = $yes;

	#	print("color_listbox,_set_message_box_ok_click ,color_listbox->{_message_box_ok_click} = $yes \n");
}

=head2 sub _set_my_dialog_box_click
=cut

sub _set_my_dialog_box_click {
	my ($ans) = @_;
	my $self = shift;
	$color_listbox->{_my_dialog_box_click} = $ans;
	$color_listbox->{_this_package}->set_my_dialog_box_click($ans);

	#	print("color_listbox,_set_my_dialog_box_click ,color_listbox->{_my_dialog_box_click} = $ans \n");
}

=head2 sub _set_my_dialog_ok_click
=cut

sub _set_my_dialog_ok_click {
	my ($ans) = @_;

	$color_listbox->{_my_dialog_ok_click} = $ans;
	( $color_listbox->{_this_package} )->set_my_dialog_ok_click($ans);

	#	print("color_listbox,_set_my_dialog_ok_click ,color_listbox->{_my_dialog_ok_click} = $ans \n");
}

=head2 sub _set_my_dialog_cancel_click
=cut

sub _set_my_dialog_cancel_click {
	my ($ans) = @_;

	$color_listbox->{_my_dialog_cancel_click} = $ans;
	( $color_listbox->{_this_package} )->set_my_dialog_cancel_click($ans);

	#	print("color_listbox,_set_message_box_cancel_click ,color_listbox->{_my_dialog_cancel_click} = $ans \n");
}

=head2 sub _set_shared_wait1
=cut

sub _set_shared_wait1 {

	my ($self) = @_;

	#	my $ok_click = &_get_my_dialog_ok_click();

	&_set_my_dialog_ok_click('yes');
	&_set_my_dialog_box_click('yes');

	my $ok_click = &_get_my_dialog_ok_click();

	#	print("ok,=$ok_click\n");

	my $my_dialog_box = $color_listbox_href->{_my_dialog_box_w};

	#	my $ok_button  = $color_listbox_href->{_my_dialog_ok_button};
	#	print("color_list_set_shared_wait,ok_click=$ok_click \n");
	&_hide_dialog_box($my_dialog_box);

	return ();
}

=head2 sub _set_shared_wait2
=cut

sub _set_shared_wait2 {

	my ($self) = @_;

	&_set_my_dialog_cancel_click('yes');
	&_set_my_dialog_box_click('yes');

	my $cancel_click  = &_get_my_dialog_cancel_click();
	my $my_dialog_box = $color_listbox_href->{_my_dialog_box_w};

	#	print("color_listbox_set_shared_wait2,cancel_click=$cancel_click \n");
	&_hide_dialog_box($my_dialog_box);

	return ();
}

=head2 sub set_flow_listbox_availability
Update which listboxes (colors)  are possibly available
for re-occupancy
Also make sure that occupied listboxes are not empty
=cut

sub set_flow_listbox_availability {

	my ($self) = @_;

	my @listbox_colors      = ( "grey", "pink", "green", "blue" );
	my $number_of_listboxes = scalar @listbox_colors;
	my @number_of_programs;
	my @listbox_color_w;

	# all color listboxes are potentially available !!
	my @listbox_availability = ( 1, 1, 1, 1 );
	$color_listbox->{flow_listbox_color_availability_aref} = \@listbox_availability;

	my $color_listbox    = $color_listbox->{_this_package};
	my @vacant_listbox   = @{ $color_listbox->get_flow_listbox_vacancy_aref() };
	my @occupied_listbox = @{ $color_listbox->get_flow_listbox_occupancy_aref() };
	$color_listbox->{flow_listbox_color_availability_aref} = \@listbox_availability;

	$listbox_color_w[0] = $color_listbox_href->{_flow_listbox_grey_w};
	$listbox_color_w[1] = $color_listbox_href->{_flow_listbox_pink_w};
	$listbox_color_w[2] = $color_listbox_href->{_flow_listbox_green_w};
	$listbox_color_w[3] = $color_listbox_href->{_flow_listbox_blue_w};

	#	print("color_listbox,listbox_color_w= @listbox_color_w\n"); # widgets
	#print("color_listbox, number_of_listboxes = $number_of_listboxes\n"); # widgets

	for ( my $i = 0; $i < $number_of_listboxes; $i++ ) {

		$number_of_programs[$i] = ( $listbox_color_w[0] )->size();

		if ( $number_of_programs[$i] == 0 ) {

			$occupied_listbox[$i] = $false;
			$vacant_listbox[$i]   = $true;

		} elsif ( $number_of_programs[$i] > 0 ) {

			$occupied_listbox[$i] = $true;
			$vacant_listbox[$i]   = $false;

		} else {
			print("color_listbox,listbox_color_w, unexpected result\n");
		}

	}

	print("color_listbox, _set_flow_listbox_availability, occupied = @occupied_listbox\n");
	print("color_listbox, _set_flow_listbox_availability, vacant = @vacant_listbox\n");

	return ();

}

#=head2 sub _update_flow_listbox_color_availability_aref
#
#Update which listboxes (colors)  are possibly available
#for re-occupancy
#Also make sure that occupied listboxes are not empty
#
#=cut
#
#sub _update_flow_listbox_color_availability_aref {
#
#	my (
#		$color_listbox, $new_current_flow_listbox_availability_aref,
#		$new_prior_flow_listbox_availability_aref
#	) = @_;
#
#	my @vacant_listbox = @{ $color_listbox->get_flow_listbox_vacancy_aref() };
#	my @occupied_listbox= @{ $color_listbox->get_flow_listbox_occupancy_aref() };
#
#	# all color listboxes are potentially available !!
#	my @array = [1,1,1,1];
#	$color_listbox->{flow_listbox_color_availability_aref} = \@array;
#
#	print("color_listbox,_update_flow_listbox_color_availability_aref=$new_current_flow_listbox_availability_aref=@{$new_current_flow_listbox_availability_aref}\n");
#
#	my $length = scalar @vacant_listbox;
#
#    print("1. color_listbox,_update_flow_listbox_color_availability_aref\n");
#    $gui_history->view();
#
#	if ( @vacant_listbox ) {
#
##		for ( my $i = 0; $i < $length; $i++ ) {
##
##			$vacant_listbox[$i] = abs( @{$new_current_flow_listbox_availability_aref}[$i] - 1 );
##
##		}
#
##		_update_flow_listbox_vacancy_color($color_listbox);
#
#		print("color_listbox,_update_flow_listbox_availabilityNvacancy_aref vacant_listbox=@vacant_listbox\n");
#		#	    print("color_listbox,_update_flow_listbox_availabilityNvacancy_aref vacant_listbox, new_current_flow_listbox_availability_aref =@{$new_current_flow_listbox_availability_aref}\n");
#
#	} else {
#		print("color_listbox,_update_flow_listbox_occupancyNvacancy_aref, missing vacant listbox,\n");
#	}
#
#	return ();
#
#}

=head2 sub _update_flow_listbox_color
Mark the listbox color in use
=cut

sub _update_flow_listbox_color {

	my ( $color_listbox, $new_current_flow_listbox_color, $new_prior_flow_listbox_color ) = @_;

	if ( length $new_current_flow_listbox_color ) {

		if (   $new_current_flow_listbox_color eq 'grey'
			or $new_current_flow_listbox_color eq '' ) {

			$color_listbox->{_is_flow_listbox_grey_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

			#			print("1. color_listbox, _update_flow_listbox_color\n");

		} elsif ( $new_current_flow_listbox_color eq 'pink' ) {

			$color_listbox->{_is_flow_listbox_pink_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

			#			print("2. color_listbox, _update_flow_listbox_color\n");

		} elsif ( $new_current_flow_listbox_color eq 'green' ) {

			#			print("3. color_listbox, _update_flow_listbox_color\n");
			$color_listbox->{_is_flow_listbox_green_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

		} elsif ( $new_current_flow_listbox_color eq 'blue' ) {

			#			print("4. color_listbox, _update_flow_listbox_color\n");
			$color_listbox->{_is_flow_listbox_blue_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

		} else {
			print("color_listbox,_set_flow_listbox, missing color \n");
		}
	}
	return ();
}

=head2 sub _update_flow_listbox_color_reservation
Reserve a potential listbox color for later use
=cut

sub _update_flow_listbox_color_reservation {

	my ( $color_listbox, $new_current_flow_listbox_color_reservation, $new_prior_flow_listbox_color_reservation ) = @_;

	if ( length $new_current_flow_listbox_color_reservation ) {

		if (   $new_current_flow_listbox_color_reservation eq 'grey'
			or $new_current_flow_listbox_color_reservation eq '' ) {

			$color_listbox->{_is_flow_listbox_grey_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

			#			print("1. color_listbox, _update_flow_listbox_color_reservation\n");

		} elsif ( $new_current_flow_listbox_color_reservation eq 'pink' ) {

			$color_listbox->{_is_flow_listbox_pink_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

			#			print("2. color_listbox, _update_flow_listbox_color_reservation\n");

		} elsif ( $new_current_flow_listbox_color_reservation eq 'green' ) {

			#			print("3. color_listbox, _update_flow_listbox_color_reservation\n");
			$color_listbox->{_is_flow_listbox_green_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

		} elsif ( $new_current_flow_listbox_color_reservation eq 'blue' ) {

			#			print("4. color_listbox, _update_flow_listbox_color_reservation\n");
			$color_listbox->{_is_flow_listbox_blue_w} = $true;
			_update_flow_listbox_occupancyNvacancy_aref($color_listbox);
			_update_flow_listbox_vacancy_color($color_listbox);

		} else {
			print("color_listbox,_set_flow_listbox, missing color \n");
		}
	}
	return ();
}

=head2 sub _update_flow_listbox_next_available_occupancyNvacancy_aref
Update which listboxes (colors)  are in use (occupancy)
and which are not (vacancies)
=cut

sub _update_flow_listbox_next_available_occupancyNvacancy_aref {

	my (
		$color_listbox, $new_current_flow_listbox_next_available_occupancy_aref,
		$new_prior_flow_listbox_next_available_occupancy_aref
	) = @_;

	my @vacant_listbox;

	$color_listbox->{flow_listbox_occupancy_aref} = $new_current_flow_listbox_next_available_occupancy_aref;
	@vacant_listbox = @{ $color_listbox->get_flow_listbox_vacancy_aref() };
	my $length = scalar @vacant_listbox;

	if (@vacant_listbox) {

		for ( my $i = 0; $i < $length; $i++ ) {

			$vacant_listbox[$i] = abs( @{$new_current_flow_listbox_next_available_occupancy_aref}[$i] - 1 );

		}

		_update_flow_listbox_vacancy_color($color_listbox);

		#		print("color_listbox,_update_flow_listbox_next_available_occupancyNvacancy_aref vacant_listbox=@vacant_listbox\n");
		#	    print("color_listbox,_update_flow_listbox_next_available_occupancyNvacancy_aref vacant_listbox, new_current_flow_listbox_next_available_occupancy_aref =@{$new_current_flow_listbox_next_available_occupancy_aref}\n");

	} else {
		print("color_listbox,_update_flow_listbox_occupancyNvacancy_aref, missing vacant listbox,\n");
	}

	return ();

}

=head2 sub _update_flow_listbox_occupancyNvacancy_aref
=cut

sub _update_flow_listbox_occupancyNvacancy_aref {

	my ($color_listbox) = @_;

	#	print("1. color_listbox,_update_flow_listbox_occupancyNvacancy_aref\n");
	my @occupied_listbox = @{ $color_listbox->get_flow_listbox_occupancy_aref() };
	my @vacant_listbox   = @{ $color_listbox->get_flow_listbox_vacancy_aref() };

	if (@occupied_listbox) {

		if (   $color_listbox->get_flow_listbox_color() eq 'grey'
			or $color_listbox->get_flow_listbox_color() eq '' ) {

			$occupied_listbox[0] = $true;
			$vacant_listbox[0]   = $false;

			#			print("1. color_listbox,_update_flow_listbox_occupancyNvacancy_aref color:\n");

		} elsif ( $color_listbox->get_flow_listbox_color() eq 'pink' ) {

			$occupied_listbox[1] = $true;
			$vacant_listbox[1]   = $false;

			#			print("2. color_listbox,_update_flow_listbox_occupancyNvacancy_aref color:\n");

		} elsif ( $color_listbox->get_flow_listbox_color() eq 'green' ) {

			#			print("3. color_listbox,_update_flow_listbox_occupancyNvacancy_aref color:\n");
			$occupied_listbox[2] = $true;
			$vacant_listbox[2]   = $false;

		} elsif ( $color_listbox->get_flow_listbox_color() eq 'blue' ) {

			# print("L_SU,_set_flow_listbox, color:$color\n");
			$occupied_listbox[3] = $true;
			$vacant_listbox[3]   = $false;

		} elsif ( $color_listbox->get_flow_listbox_color() eq 'neutral' ) {

			# CASE perl flow selection when none of the listboxes are occupied
			# default to grey listbox
			$occupied_listbox[0] = $true;
			$vacant_listbox[0]   = $false;

		} else {
			print("color_listbox,_update_flow_listbox_occupancyNvacancy_aref,:bad flow color \n");
		}

		$color_listbox->{flow_listbox_occupancy_aref} = \@occupied_listbox;
		$color_listbox->{flow_listbox_vacancy_aref}   = \@vacant_listbox;

		#		my @ans = @{ $color_listbox->get_flow_listbox_occupancy_aref };
		#		print("color_listbox,_update_flow_listbox_occupancyNvacancy_aref,color_listbox->flow_listbox_occupancy_aref=...@ans...\n");
		#		@ans = @{ $color_listbox->get_flow_listbox_vacancy_aref };
		#		print("color_listbox,_update_flow_listbox_occupancyNvacancy_aref,color_listbox->flow_listbox_vacancy_aref=...@ans...\n");

	} else {
		print("color_listbox,_update_flow_listbox_occupancyNvacancy_aref, missing flow color, NADA\n");
	}

	return ();

}

=head2 sub _update_flow_listbox_vacancy_color 
Mark the next vacant color
=cut

sub _update_flow_listbox_vacancy_color {

	my ($color_listbox) = @_;
	my $color;

	if ($color_listbox) {

		my @occupied_listbox = @{ $color_listbox->{flow_listbox_occupancy_aref} };
		my @vacant_listbox   = @{ $color_listbox->{flow_listbox_vacancy_aref} };

		if ( $occupied_listbox[0] == $false ) {

			$color = 'grey';

			#			print("color_listbox, _update_flow_listbox_vacancy_color, color=$color\n");

		} elsif ( $occupied_listbox[1] == $false ) {

			$color = 'pink';

			#			print("color_listbox, _update_flow_listbox_vacancy_color, color=$color\n");

		} elsif ( $occupied_listbox[2] == $false ) {

			$color = 'green';

			#			print("color_listbox, _update_flow_listbox_vacancy_color, color=$color\n");

		} elsif ( $occupied_listbox[3] == $false ) {

			$color = 'blue';

			#			print("color_listbox, _update_flow_listbox_vacancy_color, color=$color\n");

		} else {

			#			print("color_listbox, _update_flow_listbox_vacancy_color, All boxes are empty\n");
			$color = 'grey';

			#			print("color_listbox, _update_flow_listbox_vacancy_color,default listbox opened =  $color \n");
		}

	} else {

		#		print("color_listbox, _update_flow_listbox_vacancy_color, unexpected error\n");
		$color = 'grey';

		#		print("color_listbox, _update_flow_listbox_vacancy_color, color=$color\n");
	}

	$color_listbox->{flow_listbox_vacancy_color} = $color;

	#	 print("color_listbox, _update_flow_listbox_vacancy_color , next vacant color =  $color \n");

	return ();
}

=head2 sub _update_flow_listbox_vacancy_aref 
Mark the listbox color in use
=cut

sub _update_flow_listbox_vacancy_aref {

	my ( $color_listbox, $new_current_flow_listbox_vacancy_aref, $new_prior_flow_listbox_vacancy_aref ) = @_;

	#		print("trigger on  vacancy\n");

	if ( length $new_current_flow_listbox_vacancy_aref ) {

		my $occupied_listbox_aref = $color_listbox->get_flow_listbox_occupancy_aref();
		my $vacant_listbox_aref   = $color_listbox->get_flow_listbox_vacancy_aref();

		my @occupied_listbox = @{$occupied_listbox_aref};
		my @vacant_listbox   = @{$vacant_listbox_aref};

		print("1. _update_flow_listbox_vacancy_aref , occupied_listbox=@occupied_listbox\n");
		print("2. _update_flow_listbox_vacancy_aref , vacant_listbox= @vacant_listbox \n");

		if (   $new_current_flow_listbox_vacancy_aref eq 'grey'
			or $new_current_flow_listbox_vacancy_aref eq '' ) {

			$occupied_listbox[0] = $true;
			$vacant_listbox[0]   = $false;

			#			print("1. L_SU,_set_flow_listbox, color:$color \n");

		} elsif ( $new_current_flow_listbox_vacancy_aref eq 'pink' ) {

			$occupied_listbox[1] = $true;
			$vacant_listbox[1]   = $false;

			# print("L_SU,_set_flow_listbox, color:$color\n");

		} elsif ( $new_current_flow_listbox_vacancy_aref eq 'green' ) {

			# print("L_SU,_set_flow_listbox, color:$color\n");
			$occupied_listbox[2] = $true;
			$vacant_listbox[2]   = $false;

		} elsif ( $new_current_flow_listbox_vacancy_aref eq 'blue' ) {

			# print("L_SU,_set_flow_listbox, color:$color\n");
			$occupied_listbox[3] = $true;
			$vacant_listbox[3]   = $false;

			# CASE perl flow selection when none of the listboxes are occupied
			# default to gray listbox
		} elsif ( $new_current_flow_listbox_vacancy_aref eq 'neutral' ) {

			$occupied_listbox[0] = $true;

		} else {
			print("color_listbox,_update_flow_listbox_vacancy_aref ,:bad flow color \n");
		}

		$color_listbox->set_flow_listbox_occupancy_aref( \@occupied_listbox );
		my @ans = @{ $color_listbox->get_flow_listbox_occupancy_aref };
		print("3.color_listbox,_update_flow_listbox_vacancy_aref , color_listbox->flow_listbox_occupied @ans \n");

		$color_listbox->set_flow_listbox_vacancy_aref( \@vacant_listbox );
		my @ans2 = @{ $color_listbox->get_flow_listbox_vacancy_aref };
		print("4. .color_listbox,_update_flow_listbox_vacancy_aref ,color_listbox->flow_listbox_vacancy= @ans2 \n");

	} else {
		print("color_listbox,_update_flow_listbox_vacancy_aref , missing flow color, NADA\n");
	}

	return ();

}

=head2 sub _update_next_available_flow_listbox_color
Mark the next_available listbox color to use
Mark next available color listbox vacant
Give preference to the next_available listbox
=cut

sub _update_next_available_flow_listbox_color {

	my ( $color_listbox, $new_current_next_available_flow_listbox_color, $new_prior_next_available_flow_listbox_color )
		= @_;

#	print( "color_listbox,_update_next_available_flow_listbox_color,new_current_next_available_flow_listbox_color=$new_current_next_available_flow_listbox_color, new_prior_next_available_flow_listbox_color=$new_prior_next_available_flow_listbox_color\n" );

	my $color;

	if ( $new_current_next_available_flow_listbox_color eq 'grey' ) {

		$color = 'grey';
		$color_listbox->{next_available_flow_listbox_color} = $color;

#		print("1. color_listbox,_update_next_available_flow_listbox_color, color:$color \n");

	} elsif ( $new_current_next_available_flow_listbox_color eq 'pink' ) {

		$color = 'pink';
		$color_listbox->{next_available_flow_listbox_color} = $color;

#		print("2. color_listbox,_update_next_available_flow_listbox_color, color:$color\n");

	} elsif ( $new_current_next_available_flow_listbox_color eq 'green' ) {

#		print("3. color_listbox,_update_next_available_flow_listbox_color, color: green\n");

		$color = 'green';
		$color_listbox->{next_available_flow_listbox_color} = $color;

	} elsif ( $new_current_next_available_flow_listbox_color eq 'blue' ) {

#		print("4. color_listbox,_update_next_available_flow_listbox_color, color:blue\n");
		$color = 'blue';
		$color_listbox->{next_available_flow_listbox_color} = $color;

	} else {
		print("color_listbox,_update_next_available_flow_listbox_color, missing color \n");
	}

	return ();
}

=head2 sub _update_my_dialog_ok_click
Get the user's answer to 
my dialog is yes or no
=cut

sub _update_my_dialog_ok_click {

	my ( $self, $new_current_my_dialog_ok_click, $new_prior_my_dialog_ok_click ) = @_;

	#	print("color_listbox, _update_my_dialog_ok_click,new_prior_my_dialog_ok_click=$new_prior_my_dialog_ok_click\n");
	#	print("color_listbox, _update_my_dialog_ok_click,new_current_my_dialog_ok_click=$new_current_my_dialog_ok_click\n");

	if ( length $new_current_my_dialog_ok_click ) {
		$color_listbox->{_my_dialog_ok_click} = $my_dialog_ok_click_start;

	} else {
		print("color_listbox,update_my_dialog_ok_click, unexpected values \n");
	}
	return ();
}

=head2 sub _update_my_dialog_cancel_click
Get the user's answer to 
my dialog is yes or no
=cut

sub _update_my_dialog_cancel_click {

	my ( $self, $new_current_my_dialog_cancel_click, $new_prior_my_dialog_cancel_click ) = @_;

	#	print("color_listbox, _update_my_dialog_cancel_click,new_prior_my_dialog_cancel_click=$new_prior_my_dialog_cancel_click\n"
	#	);
	#	print("color_listbox, _update_my_dialog_cancel_click,new_current_my_dialog_cancel_click=$new_current_my_dialog_cancel_click\n"
	#	);

	#	print("color_listbox, update_my_dialog_cancel_click\n");

	if ( length( $color_listbox->{_my_dialog_cancel_click} ) ) {

		$color_listbox->{_my_dialog_cancel_click} = $my_dialog_cancel_click_start;

	} else {
		print("color_listbox,get_my_dialog_cancel, unexpected values \n");
	}
	return ();
}

=head2 sub _update2prior_flow_listbox_vacancy_color 
Unmark the past vacant color
=cut

sub _update2prior_flow_listbox_vacancy_color {

	my ( $color_listbox, $prior_color ) = @_;

	if ($color_listbox) {

		my @occupied_listbox = @{ $color_listbox->{flow_listbox_occupancy_aref} };
		my @vacant_listbox   = @{ $color_listbox->{flow_listbox_vacancy_aref} };

		if ( $prior_color eq 'blue' ) {

			$vacant_listbox[3] = $true;

		} elsif ( $prior_color eq 'green' ) {

			$vacant_listbox[2] = $true;

		} elsif ( $prior_color eq 'pink' ) {

			$vacant_listbox[1] = $true;
#			print("color_listbox, _update2prior_flow_listbox_vacancy_color, after update $prior_color  is available\n");

		} elsif ( $prior_color eq 'grey' ) {

			$vacant_listbox[0] = $true;

		} else {
			print("color_listbox, _update2prior_flow_listbox_vacancy_color, All boxes are empty\n");
			$vacant_listbox[0] = $true;
		}

	} else {
		print("color_listbox, _update2prior_flow_listbox_vacancy_color, unexpected error\n");
	}

	$color_listbox->{flow_listbox_vacancy_color} = $prior_color;
#	print("color_listbox, _update2prior_flow_listbox_vacancy_color, after update $prior_color is available\n");

	return ();
}

=head2 sub _update2prior_flow_listbox_occupancyNvacancy_aref
=cut

sub _update2prior_flow_listbox_occupancyNvacancy_aref {

	my ( $color_listbox, $prior_color ) = @_;

#	print("1. color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref\n");
	my @occupied_listbox = @{ $color_listbox->get_flow_listbox_occupancy_aref() };
	my @vacant_listbox   = @{ $color_listbox->get_flow_listbox_vacancy_aref() };

	if (@occupied_listbox) {

		if (   $prior_color eq 'grey'
			or $prior_color eq '' ) {

			$occupied_listbox[0] = $false;
			$vacant_listbox[0]   = $true;

			#			print("1. color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref color:\n");

		} elsif ( $prior_color eq 'pink' ) {

			$occupied_listbox[1] = $false;
			$vacant_listbox[1]   = $true;

			#			print("2. color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref color:\n");

		} elsif ( $prior_color eq 'green' ) {

			#			print("3. color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref color:\n");
			$occupied_listbox[2] = $false;
			$vacant_listbox[2]   = $true;

		} elsif ( $prior_color eq 'blue' ) {

			# print("L_SU,_set_flow_listbox, color:$color\n");
			$occupied_listbox[3] = $false;
			$vacant_listbox[3]   = $true;

		} elsif ( $prior_color eq 'neutral' ) {

			# CASE perl flow selection when none of the listboxes are occupied
			# default to grey listbox
			$occupied_listbox[0] = $false;
			$vacant_listbox[0]   = $true;

		} else {
			print("color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref,:bad flow color \n");
		}

		$color_listbox->{flow_listbox_occupancy_aref} = \@occupied_listbox;
		$color_listbox->{flow_listbox_vacancy_aref}   = \@vacant_listbox;

		my @ans = @{ $color_listbox->get_flow_listbox_occupancy_aref };
#		print(
#			"color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref,color_listbox->flow_listbox_occupancy_aref=...@ans...\n"
#		);
		@ans = @{ $color_listbox->get_flow_listbox_vacancy_aref };
#		print(
#			"color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref,color_listbox->flow_listbox_vacancy_aref=...@ans...\n"
#		);

	} else {
		print("color_listbox,_update2prior_flow_listbox_occupancyNvacancy_aref, missing flow color, NADA\n");
	}

	return ();

}

=head2 sub _update_prior_available_flow_listbox_color
Return to the previously available listbox color
Mark previously  available vacant color listbox
Give preference to the previously available listbox
=cut

sub _update_prior_available_flow_listbox_color {

	my (
		$color_listbox, $new_current_prior_available_flow_listbox_color,
		$new_prior_prior_available_flow_listbox_color
	) = @_;

	#	print( "color_listbox,_update_prior_available_flow_listbox_color,new_current_prior_available_flow_listbox_color=$new_current_prior_available_flow_listbox_color, new_prior_prior_available_flow_listbox_color=$new_prior_prior_available_flow_listbox_color\n" );

	my $color;

	if ( $new_prior_prior_available_flow_listbox_color eq 'grey' ) {

		$color = 'grey';
		$color_listbox->{_is_flow_listbox_grey_w} = $false;
		_update2prior_flow_listbox_occupancyNvacancy_aref( $color_listbox, $color );
		_update2prior_flow_listbox_vacancy_color( $color_listbox, $color );

		#		print("1. color_listbox,_update_prior_available_flow_listbox_color, color:$color \n");

	} elsif ( $new_prior_prior_available_flow_listbox_color eq 'pink' ) {

		$color = 'pink';
#				$color_listbox->{_is_flow_listbox_pink_w} = $false;
		$color_listbox->{prior_available_flow_listbox_color} = $color;

		#		print("2. color_listbox,_update_prior_available_flow_listbox_color, color:$color\n");

	} elsif ( $new_prior_prior_available_flow_listbox_color eq 'green' ) {

		#		print("3. color_listbox,_update_prior_available_flow_listbox_color, color: green\n");

		$color = 'green';
#				$color_listbox->{_is_flow_listbox_green_w} = $false;
		$color_listbox->{prior_available_flow_listbox_color} = $color;

	} elsif ( $new_prior_prior_available_flow_listbox_color eq 'blue' ) {

		#		print("4. color_listbox,_update_prior_available_flow_listbox_color, color:blue\n");
#				$color_listbox->{_is_flow_listbox_blue_w} = $false;
		$color = 'blue';
		$color_listbox->{prior_available_flow_listbox_color} = $color;

	} else {
		print("color_listbox,_update_prior_available_flow_listbox_color, missing color \n");
	}

	return ();
}

=head2 sub initialize_my_dialogs
Create widgets that show messages
Show warnings or errors in a message box
Message box is defined in main where it is
also made invisible (withdraw)
Here we turn on the message box (deiconify, raise)
The message does not release the program
until OK or CANCEL is clicked and wait variable changes from yes 
to no.
Widgets belong to the MainWindow that is created
first in L_SUVx.x.pl
=cut

sub initialize_my_dialogs {

	my ( $self, $ok_button, $label, $cancel_button, $top_level ) = @_;

	if (   length $ok_button
		&& length $label
		&& $cancel_button
		&& $top_level ) {

		$ok_button->configure(
			-command => [ \&_set_shared_wait1 ],
		);

		$cancel_button->configure(
			-command => [ \&_set_shared_wait2 ],
		);

	} else {
		print("color_listbox, initialize_my_dialogs, missing widgets \n");
	}
	return ();
}

=head2 sub initialize_messages
Create widgets that show messages
Show warnings or errors in a message box
Message box is defined in main where it is
also made invisible (withdraw)
Here we turn on the message box (deiconify, raise)
The message does not release the program
until OK is clicked and wait variable changes from no
to yes.
Widgets belong to the MainWindow that is created
first in L_SUVx.x.pl
=cut

sub initialize_messages {

	my ($self) = @_;

	my $wait = 'no';

	$color_listbox_href->{_message_ok_button}->configure(
		-command => sub {
			print("color_listbox,initialize_messages1. wait = $wait\n");
			&_set_message_box_ok_click();
			$wait = &_get_message_box_ok_click();
			print("color_listbox, initialize_messages, 3. wait = $wait\n");
			print("color_listbox,i nitialize_messages, 4. wait = $wait\n");
			$color_listbox_href->{_message_box_w}->grabRelease;
			$color_listbox_href->{_message_box_w}->withdraw;
		},
	);

	# stop code until user EITHER clicks ok () or cancel and
	# variable changes
	# Otherwise, upper class program races ahead
	# initializes fine, but is first implemented next time
	( $color_listbox_href->{_message_box_w} )->waitVariable( \$wait );

	return ();
}

=head2 sub is_flow_listbox_color_available
Check wether a listbox of a certain color
is already occupied
=cut

sub is_flow_listbox_color_available {
	my ($self) = @_;

	#	print("color_listbox, is_flow_listbox_color_available, color_listbox->{_is_flow_listbox_color_available}=$color_listbox->{_is_flow_listbox_color_available}\n"
	#	);

	if ( length $color_listbox->{_is_flow_listbox_color_available} ) {

		my $response = $color_listbox->{_is_flow_listbox_color_available};
		return ($response);

	} else {

		#		print(
		#			"color_listbox, is_flow_listbox_color_available, color_listbox->{_is_flow_listbox_color_available}=$color_listbox->{_is_flow_listbox_color_available}\n"
		#		);
		print("color_listbox, is_flow_listbox_color_available, unexpected result\n");
		return ();
	}
}

sub is_vacant_listbox {

	my ( $self, $color ) = @_;

	#	print("1 color_listbox, is_vacant_listbox, currently, color to test for occupation=  $color \n");

	my @vacant_listbox = @{ $self->get_flow_listbox_vacancy_aref() };

	if ( scalar(@vacant_listbox) ) {
		if (   $vacant_listbox[0] == $false
			&& $color eq 'grey' ) {

			#		    print("1 color_listbox, is_vacant_listbox, grey is already occupied \n");
			return ($false);

		} elsif ( $vacant_listbox[1] == $false
			&& $color eq 'pink' ) {

			#            print("1 color_listbox, is_vacant_listbox, pink  is already occupied \n");
			return ($false);

		} elsif ( $vacant_listbox[2] == $false
			&& $color eq 'green' ) {

			#            print("1 color_listbox, is_vacant_listbox, green is already occupied \n");
			return ($false);

		} elsif ( $vacant_listbox[3] == $false
			&& $color eq 'blue' ) {

			#            print("1 color_listbox, is_vacant_listbox, blue  is already occupied \n");
			return ($false);

		} else {

			#			print("color_listbox, _is_vacant_listbox, $color listbox seems vacant\n");
			return ($true);
		}

	} else {
		print("color_listbox, is_vacant_listbox, difficult to say\n");
		return ();
	}
}

=head2 sub messages
Show warnings or errors in a message box
Message box is defined in main where it is
also made invisible (withdraw)
Here we turn on the message box (deiconify, raise)
The message does not release the program
until OK is clicked and wait variable changes from no 
to yes.
=cut

sub messages {

	my ( $self, $run_name, $number ) = @_;

	my $message       = $message_director->color_listbox($number);

	my $message_box   = $color_listbox_href->{_message_box_w};
	my $message_label = $color_listbox_href->{_message_label_w};

	$message_box->title($run_name);

	$message_label->configure(
		-textvariable => \$message,
	);

	$message_box->deiconify();
	$message_box->raise();

	return ();
}

=head2 sub my_dialogs
Show warnings or errors in a message box
Message box is defined in main where it is
also made invisible (withdraw)
Here we turn on the message box (deiconify, raise)
The message does not release the program
until OK or CANCEL is clicked and wait variable changes from yes 
to no.
=cut

sub my_dialogs {

	my ( $self, $run_name, $number ) = @_;

	my $message          = $message_director->color_listbox($number);

	my $my_dialog_box   = $color_listbox_href->{_my_dialog_box_w};
	my $ok_button       = $color_listbox_href->{_my_dialog_ok_button};
	my $my_dialog_label = $color_listbox_href->{_my_dialog_label_w};

	#	print("color_listbox,my_dialogs, my_dialog_box=$my_dialog_box\n");

	$my_dialog_box->title($run_name);

	$my_dialog_label->configure(
		-textvariable => \$message,
	);

	my $click = &_get_my_dialog_box_click();

	#	print("1. color_listbox, my_dialogs, shared wait start = $click\n");

	$my_dialog_box->deiconify();
	$my_dialog_box->raise();
	$my_dialog_box->grab();

	#    $my_dialog_box->grabGlobal();
	$click = &_get_my_dialog_box_click();

	#	print("1. color_listbox, my_dialogs, shared wait start = $click\n");
	#	print("1A. color_listbox, my_dialogs, shared wait start = $color_listbox->{_my_dialog_box_click}\n");

	$ok_button->waitVariable( \$color_listbox->{_my_dialog_box_click} );

	my $ans_cancel = _get_my_dialog_cancel_click();
	my $ans_ok     = _get_my_dialog_ok_click();

	#	print("cancel_wait = $ans_cancel\n");
	#	print("ok_wait = $ans_ok\n");
	# print("3. run, made it past\n");

	return ();
}

=head2 sub set_hash_ref
	
	Imports external hash into a local
	hash via gui_history module
	hash
	Note that color_listbox_href is not altered
	A private hash (color_listbox) is available for truly private variables
 	
=cut

sub set_hash_ref {
	my ( $self, $hash_ref ) = @_;

	$gui_history->set_defaults($hash_ref);
	$color_listbox_href = $gui_history->get_defaults();

	return ();
}

__PACKAGE__->meta->make_immutable;
1;
