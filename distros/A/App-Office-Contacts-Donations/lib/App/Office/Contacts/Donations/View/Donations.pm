package App::Office::Contacts::Donations::View::Donations;

use Scalar::Util 'looks_like_number';

use Moose;

extends 'App::Office::Contacts::View::Base';

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub build_donations_js
{
	my($self, $context) = @_;

	$self -> log(debug => 'Entered build_donations_js');

	my($js) = $self -> load_tmpl('update.donations.js');

	$js -> param(context     => $context);
	$js -> param(form_action => $self -> script_name);

	return $js -> output;

} # End of build_donations_js.

# -----------------------------------------------

sub display
{
	my($self, $id, $entity, $donation, $entity_type, $report) = @_;

	$self -> log(debug => 'Entered display');

	my($currency_code) = ${$self -> config}{'default_currency_code'};
	my($currency_id)   = $self -> db -> util -> get_currency_id_via_code($currency_code);

	my($template) = $self -> load_tmpl('update.donations.tmpl');
	my($total)    = 0;

	my($amount);
	my($motive_name, $motive_text);
	my($project_name, $project_text);

	$template -> param
	(
	 donations_loop =>
	 [
	  map
	  {
	  	$motive_name = $self -> db -> util -> get_donation_motive_name_via_id($$_{'donation_motive_id'});
	  	$motive_text = $$_{'motive_text'};

	  	if ($motive_name ne '-')
	  	{
	  		$motive_text = "$motive_name $motive_text";
	  	}

		$amount       = $$_{'amount_input'};
	  	$project_name = $self -> db -> util -> get_donation_project_name_via_id($$_{'donation_project_id'});
	  	$project_text = $$_{'project_text'};

		if (looks_like_number($amount) )
		{
	  		$total += $amount;
		}
		else
		{
			$amount .= ' <span class="error">(Not numeric)</span>';
		}

	  	if ($project_name ne '-')
	  	{
	  		$project_text = "$project_name $project_text";
	  	}

		{
			amount_input  => $amount,
			currency_code => $self -> db -> util -> get_currency_code_via_id($$_{'currency_id_1'}),
			donations_id  => $$_{'id'},
			motive_text   => $motive_text,
			project_text  => $project_text,
			timestamp     => $self -> format_timestamp($$_{'timestamp'}),
		}
	  } @$donation
	 ]
	);

	$template -> param(context           => $entity_type);
	$template -> param(currencies        => $self -> build_select('currencies', '_1', $currency_id) );
	$template -> param(currency_code     => $#$donation < 0 ? '' : $self -> db -> util -> get_currency_code_via_id($$donation[0]{'currency_id_1'}) );
	$template -> param(donation_motives  => $self -> build_select('donation_motives') );
	$template -> param(donation_projects => $self -> build_select('donation_projects') );
	$template -> param(result            => $report ? $report : "Donations for '$$entity{'name'}'");
	$template -> param(sid               => $self -> session -> id);
	$template -> param(target_id         => $id);
	$template -> param(total             => $total);

	return $template -> output;

} # End of display.

# -----------------------------------------------

sub report_add
{
	my($self, $user_id, $result, $entity_type, $id, $name) = @_;

	$self -> log(debug => 'Entered report_add');

	my($template) = $self -> load_tmpl('update.report.tmpl');

	if ($result -> success)
	{
		# Force the user_id into the donations's record, so it is available elsewhere.
		# Note: This is the user_id of the person logged on.

		my($donation)            = {};
		$$donation{'creator_id'} = $user_id;

		for my $field (qw/amount_input currency_id_1 donation_motive_id donation_project_id motive_text project_text/)
		{
			$$donation{$field} = $result -> get_value($field) || ''; # Stop undef getting in to Pg.
		}

		# For the moment, do no conversion between currencies.

		$$donation{'amount_local'}  = $$donation{'amount_input'};
		$$donation{'currency_id_2'} = $$donation{'currency_id_1'};

		# Convert id to table_name_id and table_id.

		$$donation{'table_id'} = $id;
		my(%table_name)    =
		(
		 organization => 'organizations',
		 person       => 'people',
		);
		my($table_name)             = $table_name{$entity_type};
		$$donation{'table_name_id'} = ${$self -> db -> util -> table_map}{$table_name}{'id'};

		$self -> log(debug => '-' x 50);
		$self -> log(debug => 'Adding donation ...');
		$self -> log(debug => "$_ => $$donation{$_}") for sort keys %$donation;
		$self -> log(debug => '-' x 50);

		$template -> param(message => $self -> db -> donations -> add($donation, $name) );
	}
	else
	{
		$self -> db -> util -> build_error_report($result, $template);

		$template -> param(message => "Failed to add donation for '$name'");
	}

	return $template -> output;

} # End of report_add.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
