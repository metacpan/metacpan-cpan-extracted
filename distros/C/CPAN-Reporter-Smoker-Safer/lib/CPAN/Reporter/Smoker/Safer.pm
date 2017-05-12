package CPAN::Reporter::Smoker::Safer;

use strict;
use warnings;
use base qw(CPAN::Reporter::Smoker);
use CPAN;
use LWP::Simple();
use URI();
use File::Temp();
use Date::Calc();
use CPAN::DistnameInfo();
use CPAN::Reporter::History();

use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw/ start /;

our $VERSION = '0.04';

our $MIN_REPORTS  = 0;
our $MIN_DAYS_OLD = 14;
our @RE_EXCLUSIONS = (
  qr#/perl-5\.#,
  qr#/mod_perl-\d#,
);
our $EXCLUDE_TESTED = 1;

my %SEEN = map { $_->{dist} => 1 } CPAN::Reporter::History::have_tested();

sub start {              # Overload of CPAN::Reporter::Smoker::start()
  my $self = __PACKAGE__;
  my $args = { @_ };

  my $saferOpts = delete( $args->{safer} ) || {};
  $MIN_REPORTS   =   $saferOpts->{min_reports}  if exists $saferOpts->{min_reports};
  $MIN_DAYS_OLD  =   $saferOpts->{min_days_old} if exists $saferOpts->{min_days_old};
  @RE_EXCLUSIONS = @{$saferOpts->{exclusions}}  if exists $saferOpts->{exclusions};
  $EXCLUDE_TESTED=   $saferOpts->{exclude_tested} if exists $saferOpts->{exclude_tested};

  $args->{list} = $self->__installed_dists( @$saferOpts{qw/mask filter/} );

  return $args if $saferOpts->{preview};  # Mostly for debugging & testing.

  printf "Smoker::Safer: Found %d suitable distributions.\n", scalar @{ $args->{list} };
  return CPAN::Reporter::Smoker::start( %$args );
}

sub __filter {
  my $self = shift;
  my $dist = shift;
  my $d = $dist->pretty_id;
  foreach my $re ( @RE_EXCLUSIONS ){
    next unless $d =~ m/$re/;
    printf "Smoker::Safer: '%s' matches exclusion regex.\n", $d;
    return 0;
  }

  if( $EXCLUDE_TESTED && exists $SEEN{ $dist->base_id } ){
    printf "Smoker::Safer: '%s' already tested.\n", $d;
    return 0;
  }

  if( $MIN_DAYS_OLD ){
    no warnings 'uninitialized';
    my @date = split /-/, $dist->upload_date;  # expecting yyyy-mm-dd
    if( scalar(@date) == 3 ){
      my $days_old = Date::Calc::Delta_Days( @date[0,1,2], Date::Calc::Today() );
      return 0 if $days_old < $MIN_DAYS_OLD;
    }else{
      printf "Smoker::Safer: WARNING -- '%s' has invalid upload_date '%s'\n", $d, $dist->upload_date;
      return 0;
    }
  }

  if( $MIN_REPORTS ){
    my $info = CPAN::DistnameInfo->new($dist->id);
    my $n = eval {
      # see source of CPAN::Distribution->reports() for reference.
      my $url = sprintf "http://www.cpantesters.org/show/%s.yaml", $info->dist;
      my $f = File::Temp->new( template => 'cpan_reports_XXXX', suffix => '.yaml', unlink => 1 );
      our $ua;
      import LWP::Simple qw($ua);
      $ua->timeout(10);
      $ua->agent("CPAN::Reporter::Smoker::Safer/$VERSION");
      LWP::Simple::getstore($url, "$f");
      my $unserialized = CPAN->_yaml_loadfile("$f")->[0];
      my @reports = grep { $_->{version} eq $info->version } @$unserialized;
      scalar(@reports);
    };

    if( !defined $n ){
      printf "Smoker::Safer: WARNING -- couldn't retrieve reports for '%s'\n", $d;
      return 0;
    }elsif( $n < $MIN_REPORTS ){
      printf "Smoker::Safer: WARNING -- '%s' has %s reports (min=%s)\n", $d, $n, $MIN_REPORTS;
      return 0;
    }
  }

  return 1;
}

sub __installed_dists {
  my $self   = shift;
  my $mask   = shift || '/./';
  my $filter = shift || \&__filter;

  my %dists;
  foreach my $mod ( CPAN::Shell->expand('Module',$mask) ){
    my $d = $mod->distribution or next;
    my $k = $d->pretty_id;
    next if exists $dists{$k};
    next if ! $mod->inst_file;
    $dists{$k} = $d;
  };
  my @dists;
  foreach my $dist ( sort keys %dists ){
    if( ! &$filter($self, $dists{$dist}) ){
      printf "Smoker::Safer: EXCLUDING '%s'.\n", $dist;
      next;
    }
    push @dists, $dist;
  }
  return \@dists;
}


1;# End of CPAN::Reporter::Smoker::Safer

__END__

=pod

=head1 NAME

CPAN::Reporter::Smoker::Safer - Turnkey smoking of installed distros

=head1 VERSION

Version 0.04


=head1 SYNOPSIS

  # Default usage
  perl -MCPAN::Reporter::Smoker::Safer -e start

  # Control the 'trust' params for the default filter
  perl -MCPAN::Reporter::Smoker::Safer -e 'start( safer=>{min_reports=>0, min_days_old=>2} )'

  # Smoke all installed modules from a specific namespace
  perl -MCPAN::Reporter::Smoker::Safer -e 'start( safer=>{min_reports=>0, min_days_old=>0, mask=>"/MyFoo::/"} )'

  # Custom filter (in this case, specific authorid)
  perl -MCPAN::Reporter::Smoker::Safer -e 'start( safer=>{filter=>sub{$_[1]->pretty_id =~ m#^DAVIDRW/#}} )'

  # Preview mode - display distros found
  perl -MCPAN::Reporter::Smoker::Safer -MData::Dumper -e 'print Dumper start(safer=>{preview=>1})'

=head1 DESCRIPTION

This is a subclass of L<CPAN::Reporter::Smoker> that will limit the set of tested distributions to ones that are "trusted".
This means that the distribution is already installed on the system, and that the new version it has been on CPAN for a certain amount of time, and has already received a certain number of test reporters.
The assumption is that is it is safe (as in "safer") to install distributions (and their dependencies) that meet that criteria.

This can be used to run partial smoke testing on a box that normally wouldn't be desired for full smoke testing
(i.e. isn't a dedicated/isolated environment).
Another potential use is to vet everything before upgrading.

=head1 GETTING STARTED

See the CPAN Testers Quick Start guide L<http://wiki.cpantesters.org/wiki/QuickStart>.  Once L<CPAN::Reporter> is installed and configured, you should be all set.

There are also some very good hints and notes in the L<CPAN::Reporter::Smoker> documentation.

=head2 WARNING -- smoke testing is risky

While in theory this is much safer than full CPAN smoke testing, ALL of the same risks (see L<CPAN::Reporter::Smoker>) still apply:

Smoke testing will download and run programs that other people have uploaded to
CPAN.  These programs could do *anything* to your system, including deleting
everything on it.  Do not run CPAN::Reporter::Smoker unless you are prepared to
take these risks.  


=head1 USAGE

=head2 start()

This is an overload of L<CPAN::Reporter::Smoker>::start, and supports the same arguments, with the exception of C<list> which is set internally.  In addition, supports the following argument:

=head3 safer

Hashref with the following possible keys:

=over 2

=item mask

Scalar; Defaults to C<'/./'>; Value is passed to C<CPAN::Shell::expand()> for filtering the module list (applies to I<module> names, not distro names).

=item filter

Code ref; Defaults to L<"__filter">. First argument is the CPAN::Reporter::Smoker::Safer class/object; Second argument is a L<CPAN::Distribution> object.  Return value should be C<1> (true) to accept, and C<0> (false) to reject the distribution.

	filter => sub {
	  my ($safer, $dist) = @_;
	  ...
          return 1; 
	},

=item min_reports

Defaults to 0 (since this involves extra http fetches). This is used by the default filter -- distros are 'trusted' if they have at least this many CPAN testers reports already.

=item min_days_old

Defaults to 14. This is used by the default filter -- distros are 'trusted' if they were uploaded to CPAN at least this many days ago.

=item exclusions

Defaults to C<[ qr#/perl-5\.#, qr#/mod_perl-\d# ]>.  This is used by the default filter to exclude
any distro whose name (e.g. A/AU/AUTHOR/Foo-Bar-1.23.tar.gz) matches one of these regexes.

Note that the F<disabled.yml> functionality might be more suitable.  See L<CPAN::Reporter::Smoker>, L<CPAN>, and L<CPAN::Distroprefs> for more details.

=item preview

Default false.  If true, instead of invoking C<CPAN::Reporter::Smoker::start()> will just return the args (as hashref) that would have been passsed to C<start()>.  This is usefull for debugging/testing without kicking off the actual smoke tester.

=item exclude_tested

Default true. This is used by the default filter -- if true, distros are skipped if they were previously tested.  L<CPAN::Reporter::Smoker> does this anyways, so doing up front is more efficient. (Use in test suite is the only reason this is provided as a config option.)

=back

=head1 INTERNAL METHODS

=head2 __filter

Used as the default L<"filter"> code ref.

=over 2

=item *

Excludes any distro who's name (e.g. A/AU/AUTHOR/Foo-Bar-1.23.tar.gz) matches a list of L<"exclusions">.

=item *

If L<"exclude_tested"> is true, excludes any distro that was already tested, as determined by L<CPAN::Reporter::History>. 

=item *

Exclude any distro that was uploaded to CPAN less than L<"min_days_old"> days ago.

=item *

Exclude any distro that has less than L<"min_reports"> CPAN Testers reports.

=back


=head2 __installed_dists

Returns an array ref of dist names (e.g. 'ANDK/CPAN-1.9301.tar.gz' ).

	CPAN::Reporter::Smoker::Safer->__installed_dists( $mask, $filter );

C<mask> is optional, and is same value as L<"mask">. C<filter> is optional, and is same value as L<"filter">.


=head1 AUTHOR

David Westbrook (CPAN: davidrw), C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpan-reporter-smoker-safer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Reporter-Smoker-Safer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Reporter::Smoker::Safer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Reporter-Smoker-Safer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Reporter-Smoker-Safer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPAN-Reporter-Smoker-Safer>

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Reporter-Smoker-Safer>

=back

=head1 SEE ALSO

=over 4

=item *

L<http://cpantesters.org> - CPAN Testers site

=item *

L<http://groups.google.com/group/perl.cpan.testers.discuss/browse_thread/thread/4ae7f4960beda1d4> - The 1/2009 thread with initial discussion for this module.

=item *

L<CPAN>

=item *

L<CPAN::Reporter>

=item *

L<CPAN::Reporter::Smoker>

=back

=head1 ACKNOWLEDGEMENTS

The cpan-testers-discuss mailling list for supporting and enhancing the concept.

=head1 COPYRIGHT & LICENSE

Copyright 2009 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
