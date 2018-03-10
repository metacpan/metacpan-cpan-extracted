package App::Glacier::Command::Jobs;
use strict;
use warnings;
use App::Glacier::Core;
use parent qw(App::Glacier::Command);
use Carp;
use Data::Dumper;
use App::Glacier::Timestamp;

=head1 NAME

glacier jobs - list Glacier jobs

=head1 SYNOPSIS

B<glacier jobs>
[B<-cl>]
[B<--cached>]    
[B<--long>]    
[B<--time-style=>B<default>|B<full-iso>|B<long-iso>|B<iso>|B<locale>|B<+I<FORMAT>>]
[I<VAULT>...]
    
=head1 DESCRIPTION

Verifies and lists pending and completed glacier jobs.  By default, all jobs
are listed.  If one or more I<VAULT> arguments are given, only jobs for the
listed vaults are displayed.    

Verification consists in querying the Glacier for the status of the current
job and updating cached data accordingly.  Failed and expired jobst are
removed.
    
=head1 OPTIONS

=over 4

=item B<-c>, B<--cached>

Displays cached results without querying Glacier.

=item B<-l>, B<--long>

List jobs in long format.  Long format includes Glaciar job identifier.

=item B<--time-style=>I<STYLE>

List timestamps in style STYLE.  The STYLE should be one of the
following:

=over 8

=item B<+I<FORMAT>>

List timestamps using I<FORMAT>, which is interpreted as the I<format>
argument to B<strftime>(3) function.
    
=item B<default>

Default format.  For timestamps not older than 6 month: month, day, hour
and minute, e.g.: "May 23 15:00".  For older timestamps: month, day, and
year, e.g.: "May 23  2017".
    
=item B<full-iso>

List timestamps in full using ISO 8601 date, time, and time zone format with
nanosecond precision, e.g., "2017-05-23 15:53:10.633308971 +0000".  This style
is equivalent to "B<+%Y-%m-%d %H:%M:%S.%N %z>".

=item B<long-iso>

List ISO 8601 date and time in minutes, e.g., "2017-05-23 15:53".  Equivalent
to "B<+%Y-%m-%d %H:%M>".    
    
=item B<iso>

B<GNU ls>-compatible "iso": ISO 8601 dates for non-recent timestamps (e.g.,
"2017-05-23"), and ISO 8601 month, day, hour, and minute for recent
timestamps (e.g., "03-30 23:45").  Timestamp is considered "recent", if it
is not older than 6 months ago.    

=item B<locale>

List timestamps in a locale-dependent form.  This is equivalent to B<+%c>.

=back

=back

=head1 SEE ALSO

B<glacier>(1),    
B<strftime>(3).
    
=cut    

sub new {
    my ($class, $argref, %opts) = @_;
    $class->SUPER::new(
	$argref,
        optmap => {
	    'time-style=s' => sub { $_[0]->set_time_style_option($_[2]) },
	    'long|l+' => 'long',
	    'cached|c' => 'cached',
	},
	%opts);
}

sub run {
     my $self = shift;
#     my $res = $self->glacier_eval('list_jobs');
     $self->list($self->command_line);
}

sub list {
    my ($self, @vault_names) = @_;

    my $db = $self->jobdb();
    $db->foreach(sub {
	my ($key, $descr) = @_;
	my $vault = $descr->{VaultARN};
	$vault =~ s{.*:vaults/}{};

	return if (@vault_names && ! grep { $_ eq $vault } @vault_names);

	unless ($self->{_options}{cached}) {
	    if ($descr->{StatusCode} eq 'Failed') {
		$self->debug(1, "deleting failed $key $vault " .
			     ($descr->{JobDescription} || $descr->{Action}) .
			     $descr->{JobId});
		$db->delete($key) unless $self->dry_run;
		return;
	    }
	    
	    my $res = $self->glacier_eval('describe_job',
					  $vault,
					  $descr->{JobId});
	    if ($self->lasterr) {
		if ($self->lasterr('code') == 404) {
		    $self->debug(1, "deleting expired $key $vault " .
			     ($descr->{JobDescription} || $descr->{Action}) .
			     $descr->{JobId});
		    $db->delete($key) unless $self->dry_run;
		    return;
		} else {
		    $self->error("can't describe job $descr->{JobId}: ",
				 $self->last_error_message);
		}
	    } elsif (ref($res) ne 'HASH') {
		croak "describe_job returned wrong datatype (".ref($res).") for \"$descr->{JobId}\"";
	    } else {
		$res = timestamp_deserialize($res);
		$self->debug(2, $res->{StatusCode});
		$db->store($key, $res) unless $self->dry_run;
		$descr = $res;
	    }		
	}
	
	my $started = $self->format_date_time($descr, 'CreationDate');
	    
	print "$started - ";
	if ($descr->{Completed} && $descr->{StatusCode} eq 'Succeeded') {
	    print $self->format_date_time($descr, 'CompletionDate');
	} else {
	    my $len = length($started);
	    printf("%$len.${len}s", $descr->{StatusCode});
	}
	printf(" %-10.10s ", $vault);	
	print $descr->{JobDescription} || $descr->{Action};
	if ($self->{_options}{long}) {
	    print ' ', $descr->{JobId};
	}
	print "\n";
		 });
}

1;
