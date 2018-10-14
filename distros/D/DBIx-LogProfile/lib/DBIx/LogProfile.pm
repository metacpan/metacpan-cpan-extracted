package DBIx::LogProfile;
use strict;
use warnings;
use parent 'DBI::Profile';
use Log::Any;
use Sub::Util 1.40;

our $VERSION = 0.02;

sub new {

  my $pkg = shift;

  my $self = $pkg->SUPER::new(
    Log => 'Any',
    OrderByDesc => 'longest_duration',
    Limit => undef,
    Level => 'trace',
    @_,
  );

  # sanity check the method name. if something like debugf is
  # specified, strange things may happen, but not dangerous.
  die unless $self->{Level} =~ /^[a-z]+$/;

  if ($self->{Log} eq 'Any') {

  } elsif ($self->{Log} eq 'Log4perl') {
    eval "require Log::Log4perl";
    eval "require Log::Log4perl::MDC";

  } else {
    die "Bad Log parameter `$self->{Log}`. Must be Any or Log4perl."

  }

  DBI->trace_msg("$self: @{[ %$self ]}\n", 0)
    if $self->{Trace} && $self->{Trace} >= 2;

  return $self;
}

sub flush_to_logger {
  my $self = shift;
  my $class = ref $self;
  my $data = $self->{Data};
  my $method = $self->{Level};

  my @fields = qw/
    count
    total_duration
    first_duration
    shortest_duration
    longest_duration
    time_of_first_sample
    time_of_last_sample
  /;

  my @nodes = map {
    my ($statistics, @keys) = @$_;

    my %h;
    @h{ @fields } = @$statistics;

    my @mapped_path = map {
      s/^&DBI::ProfileSubs::/&/;
      $_
    } map {
      'CODE' eq ref($_)
        ? '&' . Sub::Util::subname($_)
        : $_
    } @{ $self->{Path} };

    $h{path} = join ':', @mapped_path;

    for my $ix ( 0 .. @keys - 1 ) {
      $h{ $mapped_path[ $ix ] } = $keys[ $ix ];
    }

    \%h;

  } $self->as_node_path_list();

  my @sorted;
  
  if ($self->{OrderByDesc} !~ /^[^a-z]/) {
    @sorted = sort {
      $b->{ $self->{OrderByDesc} } 
      <=>
      $a->{ $self->{OrderByDesc} } 
    } @nodes;

  } else {
    @sorted = sort {
      $b->{ $self->{OrderByDesc} } 
      cmp
      $a->{ $self->{OrderByDesc} } 
    
    } @nodes;
    
  }

  my $counter = 0;

  eval {

    for my $h (@sorted) {

      if ($self->{Log} eq 'Log4perl') {
        my $ctx = Log::Log4perl::MDC->get_context();

        local @{ $ctx }{ keys %$h } = values %$h;

        Log::Log4perl->get_logger()->$method(__PACKAGE__);

      } elsif ($self->{Log} eq 'Any') {
        Log::Any->get_logger()->$method(__PACKAGE__, $h);

      }

      if (defined $self->{Limit}) {
        last if ++$counter >= $self->{Limit};
      }
    }

  };

  if ($@) {

    Log::Any->get_logger()->errorf(
      "%s caught exception: %s",
      __PACKAGE__,
      $@
    );

  }

  $self->empty();

}

sub on_destroy {
  my ($self) = @_;
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  $self->flush_to_logger();
}

sub DESTROY {
  on_destroy(@_);
}

END {

  DBI->visit_handles(sub {
    my ($dbh, $info) = @_;
    return unless UNIVERSAL::isa($dbh->{Profile}, __PACKAGE__);
    $dbh->{Profile}->flush_to_logger();
  });

};

1;

__END__

=head1 NAME

DBIx::LogProfile - Log DBI::Profile data into Log::Any or Log4perl

=head1 SYNOPSIS

  % DBI_PROFILE='2/DBIx::LogProfile/Log:Any:Level:trace' ex.pl
  % cat ex.log
  ...
    "!Statement"           : "DELETE FROM Vertex WHERE vertex = ?"
    "count"                : 10626,
    "total_duration"       : 0.0804088115692139
    "first_duration"       : 0.000133037567138672,
    "shortest_duration"    : 0,
    "longest_duration"     : 0.000622987747192383,
    "time_of_first_sample" : 1539396350.63128,
    "time_of_last_sample"  : 1539396364.50785,
    "path"                 : "!Statement",
  ...
  # Values as per DBI::Profile::as_node_path_list().
  # Additionally `path` indicating the `Path`, and 
  # one pair for each element of the path.
  #
  # Formatting of the values in your logfile will vary
  # based on your configuration of the logger you use.

=head1 DESCRIPTION

This module allows you to smuggle DBI::Profile data (like SQL
statements that have been executed, alongside frequency and
time statistics) into an existing application's log without
making changes to the application itself, using the environment
variable C<DBI_PROFILE>. This can be useful when you have a 
centralised structured logging facility and need information 
about DBI activity in it.

=head1 CONSTRUCTOR

=over

=item new( %options )

In addition to the options for parent C<DBI::Profile> the following
options are supported:

  Log   => 'Any' for Log::Any or 'Log4perl' for Log::Log4perl

  Level => One of 'trace', 'debug', 'info', 'warn', ...

  Limit => Maximum number of lines to log subject to OrderByDesc

  OrderByDesc => One of 
    count
    total_duration
    first_duration
    shortest_duration
    longest_duration
    time_of_first_sample
    time_of_last_sample
    key1
    key2
    ...

For instance, if your C<Path> is C<!Statement>, C<OrderByDesc> is
C<count> and C<Limit> is set to C<1>, like in

  DBI_PROFILE='2/DBIx::LogProfile/OrderByDesc:count:Limit:1'

then this module will log only the most frequently processed
statement and collected profile data in structured fields using 
the C<trace> log level using C<Log::Any> (the defaults).

The values will be passed as structured data to the logger, as hash
for C<Log::Any>, and as MDC data for C<Log::Log4perl>. The log message
for either is a string containing the substring C<DBIx::LogProfile>.

This module will log an error using C<Log::Any> if it fails to report
profile data to the logger. This module logs but does not rethrow
exceptions caught in that process.

Note that C<DBI::Profile> supports a normaliser function that can replace
variable parts of queries using some heuristics, which is very useful
to group queries that are not prepared with bind parameters. You can
enable it like so:

  DBI_PROFILE='&norm_std_n3/DBIx::LogProfile/...'

Instead of reporting individual statements like 

  SELECT 1
  SELECT 2
  ...

the statements would then be grouped like

  SELECT <N>

=back

=head1 METHODS

=over

=item flush_to_logger()

You can call this method on a C<DBIx::LogProfile> object to manually
force flushing the accumulated profile data to the logger. There is 
normally no need to do that, this module will automatically flush the
profile data through the C<DBIx::LogProfile> destructor (unless that
is called during global destruction) and during the module's C<END>
code block.

The primary use case is to enable this module's mechanism through the 
C<DBI_PROFILE> environment variable interpreted by C<DBI> without the 
need to change any other code. The logic described above seems to be
the best way to support that (alternative suggestions welcome).

However, when set through the environment variable, DBI keeps the 
profiler object around essentially until the application exits which
may be unhelpful for long-lived Perl processes. In that case it may
be useful to regularily do something like this in the application:

  DBI->visit_handles(sub {
    my ($dbh, $info) = @_;
    return unless UNIVERSAL::isa(
      $dbh->{Profile},
      'DBIx::LogProfile'
    );
    $dbh->{Profile}->flush_to_logger();
  });

This should have no effect if C<DBIx::LogProfile> is not actually 
used at runtime, and would flush all relevant profile data if it is.

=back

=head1 BUG REPORTS

=over

=item * L<https://github.com/hoehrmann/DBIx-LogProfile/issues>

=item * L<mailto:bug-DBIx-LogProfile@rt.cpan.org>

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-LogProfile>

=back

=head1 SEE ALSO

  * DBI::LogProfile

=head1 ACKNOWLEDGEMENTS

Thanks to the people on #perl on Freenode for the suggestion to 
call flush_to_logger during C<END>.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2018 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
