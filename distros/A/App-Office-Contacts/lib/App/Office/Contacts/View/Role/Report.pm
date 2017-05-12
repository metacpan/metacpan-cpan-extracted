package App::Office::Contacts::View::Role::Report;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo::Role;

use Text::Xslate 'mark_raw';

our $VERSION = '2.04';

# -----------------------------------------------

sub build_report_html
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'View::Role::Report.build_report_html()');

	my($report);

	if ($self -> db -> library -> count_reports == 1)
	{
		$report = 'Records';
	}
	else
	{
		$report = mark_raw($self -> build_menu('report_id', , $self -> get_menu_data('reports') ) );
	}

	my($param) =
	{
		communication_types => mark_raw($self -> build_menu('report_communication_type_id', $self -> get_menu_data('communication_types') ) ),
		genders             => mark_raw($self -> build_menu('report_gender_id', $self -> get_menu_data('genders') ) ),
		report_entities     => mark_raw($self -> build_menu('report_entity_id', $self -> get_menu_data('report_entities') ) ),
		reports             => $report,
		roles               => mark_raw($self -> build_menu('report_role_id', $self -> get_menu_data('roles') ) ),
		sid                 => $self -> db -> session -> id,
		visibilities        => mark_raw($self -> build_menu('report_visibility_id', $self -> get_menu_data('visibilities') ) ),
	};

	# Make browser happy by turning the HTML into 1 long line.
	# Also, the embedded single quotes need to be escaped, because in
	# Initialize.build_head_init(), the output of this sub is inserted
	# into this Javascript:
	# content: '$report_html'.

	my($html) = $self -> db -> templater -> render
				(
					'report.tx',
					$param
				);
	$html =~ s/\n//g;
	$html =~ s/'/\\'/g;

	return $html;

} # End of build_report_html.

# -----------------------------------------------

sub format_record_report
{
	my($self, $result) = @_;

	$self -> db -> logger -> log(debug => 'View::Role::Report.format_record_report(...)');

	my($html) = <<EOS;
<table class="display" id="result_table" cellpadding="0" cellspacing="0" border="0" width="100%">
<thead>
<tr>
	<th>Count</th>
	<th>Name</th>
	<th>Entity type</th>
	<th>Contact via</th>
	<th>Role</th>
	<th>Visibility</th>
</tr>
</thead>
<tbody>
EOS

	my($count) = 0;

	my($class);

	for my $row (@$result)
	{
		$class = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';
		$html  .= <<EOS;
<tr class="$class">
	<td>$count</td>
	<td>$$row{data}{name}</td>
	<td>$$row{type}</td>
	<td>$$row{data}{communication_type_name}</td>
	<td>$$row{data}{role_name}</td>
	<td>$$row{data}{visibility_name}</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
<tfoot>
<tr>
	<th>Count</th>
	<th>Name</th>
	<th>Entity type</th>
	<th>Contact via</th>
	<th>Role</th>
	<th>Visibility</th>
</tr>
</tfoot>
</table>
EOS

	return $html;

} # End of format_record_report.

# -----------------------------------------------

sub generate_record_report
{
	my($self, $result) = @_;

	$self -> db -> logger -> log(debug => 'View::Role::Report.generate_record_report(...)');

	my($report) = {};

	for my $field_name ($result -> valids)
	{
		$$report{$field_name} = $result -> get_value($field_name) || '';
	}

	my(%comm_map)               = $self -> db -> library -> get_id2name_map('communication_types');
	my(%report_entity)          = $self -> db -> library -> get_name2id_map('report_entities');
	my($organization_entity_id) = $report_entity{Organizations};
	my($people_entity_id)       = $report_entity{People};
	my(%role_map)               = $self -> db -> library -> get_id2name_map('roles');
	my(%visibility_map)         = $self -> db -> library -> get_id2name_map('visibilities');

	my($communication_type_id);
	my($gender_id, $gender);
	my($item, @item);
	my($role_id, $role);
	my($visibility_id);

	# Filter out unwanted records.
	# 1. Does the user just want organizations, or just people, or both?

	if ($$report{report_entity_id} != $people_entity_id)
	{
		my($organization) = $self -> db -> organization -> get_organizations_for_report('-');

		for $item (@$organization)
		{
			$communication_type_id          = $$item{communication_type_id};
			$$item{communication_type_name} = $comm_map{$communication_type_id};
			$role_id                        = $$item{role_id};
			$$item{role_name}               = $role_map{$role_id};
			$visibility_id                  = $$item{visibility_id};
			$$item{visibility_name}         = $visibility_map{$visibility_id};

			# 2. Does the user just want entities with a specific visibility?

			if ( (! $$report{ignore_visibility}) && ($$report{visibility_id} != $visibility_id) )
			{
				next;
			}

			# 3. Does the user just want entities with a specific communication_type?

			if ( (! $$report{ignore_communication_type}) && ($$report{communication_type_id} != $communication_type_id) )
			{
				next;
			}

			# 4. Does the user just want entities with a specific gender?
			#		Does not apply to organizations...
			# 5. Does the user just want entities or people with a specific role?

			if ( (! $$report{ignore_role}) && ($$report{role_id} != $role_id) )
			{
				next;
			}

			push @item,
			{
				data => {%$item},
				type => 'Organization',
			};
		}
	}

	# 2. Does the user just want organizations, or just people, or both?

	if ($$report{report_entity_id} != $organization_entity_id)
	{
		my($person) = $self -> db -> person -> get_people_for_report;

		for $item (@$person)
		{
			$communication_type_id          = $$item{communication_type_id};
			$$item{communication_type_name} = $comm_map{$communication_type_id};
			$gender_id                      = $$item{gender_id};
			$role_id                        = $$item{role_id};
			$$item{role_name}               = $role_map{$role_id};
			$visibility_id                  = $$item{visibility_id};
			$$item{visibility_name}         = $visibility_map{$visibility_id};

			# 2. Does the user just want entities with a specific visibility?

			if ( (! $$report{ignore_visibility}) && ($$report{visibility_id} != $visibility_id) )
			{
				next;
			}

			# 3. Does the user just want entities with a specific communication_type?

			if ( (! $$report{ignore_communication_type}) && ($$report{communication_type_id} != $communication_type_id) )
			{
				next;
			}

			# 4. Does the user just want entities with a specific gender?

			if ( (! $$report{ignore_gender}) && ($$report{gender_id} != $gender_id) )
			{
				next;
			}

			# 5. Does the user just want entities with a specific role?

			if ( (! $$report{ignore_role}) && ($$report{role_id} != $role_id) )
			{
				next;
			}

			push @item,
			{
				data => {%$item},
				type => 'Person',
			};
		}
	}

	return $self -> format_record_report([@item]);

} # End of generate_record_report.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Role::Report - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

This module is a L<Moo::Role>-based role consumed by L<App::Office::Contacts::View::Report>, and has these
attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 build_report_html()

Returns the HTML used to populate the 'Report' tab.

=head2 format_record_report($result)

Returns a HTML table in response to the user running a report.

Called by generate_record_report($result).

=head2 generate_record_report($result)

Generates the records which match the report request from the user.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
