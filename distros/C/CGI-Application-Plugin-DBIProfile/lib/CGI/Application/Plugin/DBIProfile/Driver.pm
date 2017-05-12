package CGI::Application::Plugin::DBIProfile::Driver;
use strict;
use IO::Scalar;

=head1 TODO: POD

=cut

use vars qw($VERSION $DEBUG @ISA);
$DEBUG = 0;
$VERSION = "1.1";
@ISA = qw(DBI::ProfileDumper);
# TODO: requires DBI 1.49 for class method call interface.
# TODO: requires DBI 1.24 for DBI->{Profile} support, period.
use Carp qw(carp croak);
use DBI;
use DBI::ProfileDumper;

# Override flush_to_disk() to use IO::Scalar rather than a real file.
# Also, change it to return the current formatted dataset, rather
# than write anything out.
# NOTE: the name doesn't fit. Could change that.
sub flush_to_disk
{
    my $self = _get_dbiprofile_obj(shift);
    return unless defined $self;

    my $output = $self->get_current_stats();

    $self->empty();

    return $output;
}

# This does what flush_to_disk does, without emptying data afterwards.
sub get_current_stats
{
    my $self = _get_dbiprofile_obj(shift);
    return unless defined $self;

    my $data = $self->{Data};

    my $output;
    my $fh = new IO::Scalar \$output;

    $self->write_header($fh);
    $self->write_data($fh, $self->{Data}, 1);

    close($fh) or croak("Unable to close scalar filehandle: $!");

    return $output;
}

# Override on_destroy() to simply clear the data, and close the IO::Scalar.
sub on_destroy
{
    shift->empty();
}

# Override empty to it'll behave has a class method.
sub empty
{
    my $self = _get_dbiprofile_obj(shift);
    return unless defined $self;
    $self->SUPER::empty;
}

# utility method to get a usable DBI::Profile object.
sub _get_dbiprofile_obj
{
    my $self = shift;

    # if we're called by an instance var, just return it.
    return $self if ref $self and UNIVERSAL::isa($self, 'DBI::Profile');

    # XXX: I couldn't find an instance where I needed to look at more
    # than one database handle, even with multiple database handles 
    # talking to separate dbs using separate drivers.
    # I'm not sure how this works out under mod_perl2 using the
    # multi-threaded apache service (is there a separate perl memory/name
    # space for each thread, or one per process?)
    # We may need to loop over handles, fetch data && clear data && merge.

    # if we're called as a class method, we need to find at least one
    # db handle to work with, and snag its profile.
    my $dbh = (_get_all_dbh_handles())[0];
    unless (ref $dbh && UNIVERSAL::isa($dbh, 'DBI::db'))
    {
        carp "Unable to locate active dbh." if $DEBUG;
        return;
    }
    $self = $dbh->{Profile};
    if (! ref $self) {
        carp "Handle lacks Profile support";
        return;
    }

    return $self;
}

# utility methods to enumerate all database handles
sub _get_all_dbh_handles
{
    return grep { $_->{Type} eq 'db' } _get_all_dbi_handles();
}
sub _get_all_dbi_handles
{
    my @handles;
    my %drivers = DBI->installed_drivers();
    push(@handles, _get_all_dbi_child_handles($_) ) for values %drivers;
    return @handles;
}
sub _get_all_dbi_child_handles
{
    my $h = shift;
    my @h = ($h);
    push(@h, _get_all_dbi_child_handles($_))
        for (grep { defined } @{$h->{ChildHandles}});
    return @h;
}


1;
