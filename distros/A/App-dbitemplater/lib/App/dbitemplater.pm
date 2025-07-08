package App::dbitemplater;

use 5.006;
use strict;
use warnings;
use Template    ();
use File::Slurp qw(write_file);
use DBI         ();

=head1 NAME

App::dbitemplater - A utility for running a SQL query via DBI and using the output in a template.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use App::dbitemplater;
    use YAML::XS;
    use File::Slurp;

    $config=Load(read_file('/usr/local/etc/dbitemplater.yaml'));

    my $dbitemplater = App::dbitemplater->new($config);

    $dbitemplater->process;

=head1 METHODS

=head2 new

Initiates the object.

A hash reference is required. The contents should be the config.
See the docs for dbitemplater for the config.

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	my @possible_args = (
		'ds',  'user',   'pass',       'output',    'query', 'header',
		'row', 'footer', 'POST_CHOMP', 'PRE_CHOMP', 'TRIM',  'START_TAG',
		'END_TAG'
	);
	my $required_args = {
		'ds'     => 1,
		'header' => 1,
		'row'    => 1,
		'footer' => 1,
		'query'  => 1
	};

	my $self = {
		'ds'         => undef,
		'user'       => undef,
		'pass'       => undef,
		'output'     => undef,
		'header'     => undef,
		'row'        => undef,
		'footer'     => undef,
		'POST_CHOMP' => undef,
		'PRE_CHOMP'  => undef,
		'TRIM'       => undef,
		'START_TAG'  => undef,
		'END_TAG'    => undef,
		'config'     => \%args,
	};
	bless $self;

	# ensure that all required args are present and that any arts that are present have a
	# ref of ""
	foreach my $item (@possible_args) {
		if ( defined( $required_args->{$item} ) && !defined( $args{$item} ) ) {
			die( '$args{"' . $item . '"} is not defined and is required' );
		}
		if ( defined( $args{$item} ) && ref( $args{$item} ) ne '' ) {
			die( '$args{"' . $item . '"} is defined and ref is "' . ref( $args{$item} ) . '" and not ""' );
		}
		if ( defined( $args{$item} ) ) {
			$self->{$item} = $args{$item};
		}
		if ( $item eq 'header' || $item eq 'row' || $item eq 'footer' ) {
			# if a slash is found, assume it is a full path
			if ( $args{$item} =~ /[\\\/]/ ) {
				if ( !-f $args{$item} ) {
					die( '$args{"' . $item . '"}, "' . $args{$item} . '", is not a file or does not exist' );
				}
			} else {
				my $full_path = '/usr/local/etc/dbitemplater/templates/' . $item . '/' . $args{$item};
				if ( !-f $full_path ) {
					die(      '$args{"'
							. $item . '"}, "'
							. $args{$item} . '","'
							. $full_path
							. '", is not a file or does not exist' );
				}
				$self->{$item} = $full_path;
			} ## end else [ if ( $args{$item} =~ /[\\\/]/ ) ]
		} ## end if ( $item eq 'header' || $item eq 'row' ||...)
	} ## end foreach my $item (@possible_args)

	return $self;
} ## end sub new

=head2 process

Connects, run the query, and processes the templates.

=cut

sub process {
	my $self = $_[0];

	# initiate TT
	my $tt = Template->new(
		{
			'INCLUDE_PATH' => '/usr/local/etc/dbitemplater/templates',
			'EVAL_PERL'    => 1,
			'POST_CHOMP'   => $self->{'POST_CHOMP'},
			'PRE_CHOMP'    => $self->{'PRE_CHOMP'},
			'TRIM'         => $self->{'TRIM'},
			'START_TAG'    => $self->{'START_TAG'},
			'END_TAG'      => $self->{'END_TAG'},
			'ABSOLUTE'     => 1,
		}
	);

	# stores the results of the template
	my $results = '';

	# will be passed to the template for vars
	my $to_pass_to_template = { 'config' => $self->{config}, };
	# process the headertemplate
	my $output = '';
	eval {
		$tt->process( $self->{'header'}, $to_pass_to_template, \$output )
			|| die $tt->error(), "\n";
		$results = $results . $output;
	};
	if ($@) {
		warn( 'Error processing header template, "' . $self->{'header'} . '"... ' . $@ );
	}

	# connect to it
	my $dbh;
	eval { $dbh = DBI->connect( $self->{'ds'}, $self->{'user'}, $self->{'pass'} ) or die $DBI::errstr; };
	if ($@) {
		die( 'DBI connect failed... ' . $@ );
	}

	# prepare the statement
	my $sth;
	eval { $sth = $dbh->prepare( $self->{'query'} ) or die $DBI::errstr; };
	if ($@) {
		die( 'statement prepare failed... ' . $@ );
	}

	eval { $sth->execute or die $DBI::errstr; };
	if ($@) {
		die( 'statement execute failed... ' . $@ );
	}

	# fetch each row and process it
	while ( my $row_hash_ref = $sth->fetchrow_hashref ) {
		$to_pass_to_template->{'row'} = $row_hash_ref;
		# process the template for each row
		my $output = '';
		eval {
			$tt->process( $self->{'row'}, $to_pass_to_template, \$output )
				|| die $tt->error(), "\n";
			$results = $results . $output;
		};
		if ($@) {
			warn( 'Error processing header template, "' . $self->{'row'} . '"... ' . $@ );
		}
	} ## end while ( my $row_hash_ref = $sth->fetchrow_hashref)

	# remove the row variable from what is passed to the template
	delete( $to_pass_to_template->{'row'} );

	# process the footer template
	$output = '';
	eval {
		$tt->process( $self->{'footer'}, $to_pass_to_template, \$output )
			|| die $tt->error(), "\n";
		$results = $results . $output;
	};
	if ($@) {
		warn( 'Error processing footer template, "' . $self->{'header'} . '"... ' . $@ );
	}

	# handle the output
	if ( !defined( $self->{output} ) ) {
		print $results;
	} else {
		eval { write_file( $self->{'output'}, { atomic => 1 }, $results ); };
		if ($@) {
			die( 'Failed to write results out to "' . $self->{'output'} . '"... ' . $@ );
		}
	}

	return 1;
} ## end sub process

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-dbitemplater at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-dbitemplater>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::dbitemplater


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-dbitemplater>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-dbitemplater>

=item * Search CPAN

L<https://metacpan.org/release/App-dbitemplater>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;    # End of App::dbitemplater
