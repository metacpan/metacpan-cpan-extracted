package CatalystX::VCS::Lookup;

=head1 NAME

CatalystX::VCS::Lookup - Extract VCS revision of application code

=cut

use 5.010;
use File::Which 'which';
use Moose::Role;

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

If your application is started from the working copy of version control system,
this module allows to get automatically current revision identificator in the
application config.

Setup application:

  package MyApp;

  use Catalyst::Runtime;
  use Moose;

  extends 'Catalyst';
  with    'CatalystX::VCS::Lookup';

  1;

Get revision from controller:

  sub index : Path Args(0) {
      my ( $self,$c ) = @_;

      $c->res->body( "Current version:" . $c->config->{ revision } );
  }

=head1 CONFIGURATION

You can customize config key for storing revision identificator.
Default key is 'revision'.

  __PACKAGE__->config(
      'VCS::Lookup' => { Revision => 'version' }
  );

=cut

before setup_finalize => sub {
	my ( $app ) = @_;

	# get config key
	my $key = exists $app->config->{ 'VCS::Lookup' }{ Revision } ?
		$app->config->{ 'VCS::Lookup' }{ Revision } : 'revision';

	# revision is already set
	return if exists $app->config->{ $key };

	# assume that the root directory of the installation
	# is a VCS working copy
	my $home = $app->config->{ home };

	# try to detect used VCS type
	if ( -d $app->path_to('.git') ) {
		if ( which 'git' ) {
			my $info = qx( cd $home && git show --pretty=format:%H ) or
				$app->log->warn("VCS::Lookup is unable to fetch Git info");

			( $app->config->{ $key } ) = $info =~ m{ ^(\w+) }x or
				$app->log->warn("VCS::Lookup is unable to determine Git revision")
				if $info;
		} else {
			$app->log->warn("VCS::Lookup can't found git executable")
		}
	}
	elsif ( -d $app->path_to('.hg') ) {
		if ( which 'hg' ) {
			my $info = qx( hg --cwd $home id --id ) or
				$app->log->warn("VCS::Lookup is unable to fetch Mercurial info");

			( $app->config->{ $key } ) = $info =~ m{ ^(\w+) }x or
				$app->log->warn("VCS::Lookup is unable to determine Mercurial revision")
				if $info;
		} else {
			$app->log->warn("VCS::Lookup can't found hg executable")
		}
	}
	elsif ( -d $app->path_to('.svn') ) {
		if ( which 'svn' ) {
			my $info = qx( svnversion $home ) or
				$app->log->warn("VCS::Lookup is unable to fetch SVN info");

			( $app->config->{ $key } ) = $info =~ m{ ^(\d+) }x or
				$app->log->warn("VCS::Lookup is unable to determine SVN revision")
				if $info;
		} else {
			$app->log->warn("VCS::Lookup can't found svn executable")
		}
	}
	else {
		$app->log->warn("VCS::Lookup is unable to determine VCS type")
	}
};


=head1 AUTHOR

Oleg A. Mamontov, C<< <lonerr at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-vcs-lookup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-VCS-Lookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::VCS::Lookup

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-VCS-Lookup>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-VCS-Lookup>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-VCS-Lookup>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-VCS-Lookup/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Oleg A. Mamontov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
