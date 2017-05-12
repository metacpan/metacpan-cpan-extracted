#!/usr/bin/perl

=head1 NAME

index.cgi - Example of audit search interface using Audit::DBI and Audit::DBI::TT2.


=head1 DESCRIPTION

Caveat: I tried to avoid having this example rely on fancy modules, in order
to allow it to run on most machines. The drawback of course is that it isn't
fancy (for example, it uses the CGI module).

=cut

use strict;
use warnings;

use lib '../lib';

use Audit::DBI::TT2;
use Audit::DBI;
use CGI qw();
use Class::Date;
use DBI;
use Template;


=head1 MAIN CODE

=cut

my $cgi = CGI->new();
print $cgi->header();

my $dbh = DBI->connect(
	'dbi:SQLite:dbname=test_database',
	'',
	'',
	{
		RaiseError => 1,
	}
);

my $template = Template->new(
	{
		INCLUDE_PATH => 'templates/',
		EVAL_PERL    => 1,
		PLUGINS      =>
		{
			audit => 'Audit::DBI::TT2',
		},
	}
) || die $Template::ERROR;

# Actions
my $action = $cgi->param('action') || '';
if ( $action eq 'results' )
{
	results();
}
else
{
	search();
}


=head1 FUNCTIONS


=head2 search()

Displays a search interface to query audit data.

=cut

sub search
{
	# Output the template.
	$template->process(
		'search.tt2',
		{},
	) || die $template->error();

	return;
}


=head2 results()

Displays search results.

=cut

sub results
{
	# Parse criteria passed by the user.
	my %param = ();
	foreach my $include ( qw( 0 1 ) )
	{
		# IP addresses.
		foreach my $value ( map { split( /\s*,\s*/, $_ ) } ( $cgi->param( 'ip_address' . $include ) ) )
		{
			push(
				@{ $param{'ip_ranges'} },
				{
					include => $include,
					begin   => $value,
					end     => $value,
				}
			);
		}

		# Date ranges.
		foreach my $value ( map { split( /\s*,\s*/, $_ ) } ( $cgi->param( 'date_range' . $include ) ) )
		{
			my @temp = split( '::', $value );
			my @begin = split( '/', $temp[0] );
			my @end = split( '/', $temp[1] );

			push(
				@{ $param{'date_ranges'} },
				{
					include => $include,
					begin   => Class::Date::date( "$begin[2]-$begin[0]-$begin[1] 00:00:00" )->epoch(),
					end     => Class::Date::date( "$end[2]-$end[0]-$end[1] 23:59:59" )->epoch(),
				}
			);
		}

		# Events.
		foreach my $value ( map { split( /\s*,\s*/, $_ ) } ( $cgi->param( 'event' . $include ) ) )
		{
			push(
				@{ $param{'events'} },
				{
					include => $include,
					event   => $value,
				}
			);
		}

		# Account logged-in.
		foreach my $value ( map { split( /\s*,\s*/, $_ ) } ( $cgi->param( 'account_logged_in' . $include ) ) )
		{
			push(
				@{ $param{'logged_in'} },
				{
					include    => $include,
					account_id => $value,
				}
			);
		}

		# Account affected.
		foreach my $value ( map { split( /\s*,\s*/, $_ ) } ( $cgi->param( 'account_affected' . $include ) ) )
		{
			push(
				@{ $param{'affected'} },
				{
					include    => $include,
					account_id => $value,
				}
			);
		}

		# Subjects.
		foreach my $value ( $cgi->param( 'subject_type' . $include ) )
		{
			my @temp = split( '::', $value );
			push(
				@{ $param{'subjects'} },
				{
					include    => $include,
					type       => $temp[0],
					ids        => [ split( /\s*,\s*/, ( $temp[1] || '' ) ) ],
				}
			);
		}

		# Values.
		foreach my $value ( $cgi->param( 'indexed_data' . $include ) )
		{
			my @temp = split( '::', $value );
			push(
				@{ $param{'values'} },
				{
					include    => $include,
					name       => $temp[0],
					values     => [ split( /\s*,\s*/, ( $temp[1] || '' ) ) ],
				}
			);
		}
	}

	# Get results.
	my $need_at_least_one_criteria;
	my $results;
	if ( scalar( keys %param ) == 0 )
	{
		$need_at_least_one_criteria = 1;
	}
	else
	{
		my $audit = Audit::DBI->new(
			database_handle => $dbh,
		);
		$results = $audit->review( %param );
	}

	my $querystring = $ENV{'QUERY_STRING'};
	$querystring .= '&' unless substr( $querystring, -1) eq '&';
	$querystring =~ s/action=results&//;
	$querystring =~ s/&$//;

	# Output the template.
	$template->process(
		'results.tt2',
		{
			need_at_least_one_criteria => $need_at_least_one_criteria,
			results                    => $results,
			found                      => scalar( @$results ),
			refine_url                 => "?$querystring",
		},
	) || die $template->error();

	return;
}


=head1 COPYRIGHT & LICENSE

Copyright 2010-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut
