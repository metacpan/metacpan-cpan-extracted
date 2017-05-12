use 5.008;
use strict;
use warnings;

package Data::Conveyor::Mutex;
BEGIN {
  $Data::Conveyor::Mutex::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Sys::Hostname ();    # no import so we don't clash with our hostname()
use Error ':try';

# XXX the whole thing must be recoded with database locks.
# Note: one way or the other, this is probably not portable
# across databases.
use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_scalar_accessors(
    qw(
      application mutex_config_id max_parallel group_exlock program_name
      pid hostname dbinst
      )
);

# FIXME
use constant ADMINADDR => 'service-admin@domain.univie.ac.at';
use constant DEFAULTS  => (
    hostname     => Sys::Hostname::hostname(),
    pid          => $$,
    program_name => $0,
);

sub mutex_getconf {
    my $self = shift;
    $self->dbinst($self->storage->dbname);
    $self->log(
        sprintf '%s[%08d]@%s (%s) init "%s"' =>
          map($self->$_, qw/
              program_name pid hostname dbinst application/)
    );

    # get config id and parallelity
    my ($cnf_id, $parallel) = $self->storage->get_mutex_config($self);
    $self->mutex_config_id($cnf_id);
    $self->max_parallel($parallel);

    # require this to be configured.
    $self->error(
        sprintf '%s: mutex configuration: no valid entry found for "%s"' =>
          __PACKAGE__,
        $self->application
      )
      unless $self->mutex_config_id
          && defined $self->max_parallel;

    # now check if we are in a group
    my $tmp = $self->storage->get_mutex_data($self);

    # test validity of mutex configuration
    if ($self->group_exlock(scalar(@$tmp) > 1)) {
        for my $cnf (@$tmp) {
            $self->error(
                sprintf "%s: mutex misconfigured for '%s':\nApplication is"
                  . " in a GROUP (%d), but MTXCNF_MAXPARALLEL=%d. Aborting." =>
                  __PACKAGE__,
                $cnf->[1], $self->mutex_config_id, $cnf->[2]
            ) if $cnf->[2] > 1;
        }
    }

    # reset the transaction
    $self->storage->dbh->rollback;
    $self->log(
        sprintf '%s[%08d]@%s (%s) mutex_getconf CNFID=%d MXP=%d GROUP=%s'
          . ' "%s"' =>
          map($self->$_, qw/
              program_name pid hostname dbinst mutex_config_id max_parallel/),
        ($self->group_exlock ? 'yes' : 'no '),
        $self->application,
    );
    $self;
}

sub get_mutex {
    my $self = shift;

    # XXX: replace this with assert_defined
    $self->error(sprintf "%s: mutex not initialized. Aborting." => __PACKAGE__)
      unless $self->isa(__PACKAGE__)
          && $self->application
          && $self->storage
          && $self->mutex_config_id
          && defined $self->max_parallel;
    ## make sure previous transaction is over
    $self->storage->dbh->rollback
      || $self->error(
        sprintf "%s: critical rollback failed. Aborting." => __PACKAGE__);

    # try all slots < parallelity
    # try locks
    my $LOCKFAIL;
    my $HAVELOCK;
    for (my $slot = 0 ; $slot < $self->max_parallel ; $slot++) {
        $LOCKFAIL = 0;
        $HAVELOCK = undef;
        local $Error::Hierarchy::Internal::DBI::SkipWarning = 1;
        my $slot_info;
        try {
            $slot_info = $self->storage->get_mutex_slot($self, $slot);
        }
        catch Error with {
            $LOCKFAIL++;

            # XXX: log the exception here
        };
        $self->log(
            sprintf
              '%s[%08d]@%s (%s) get_mutex CNFID=%d SLOT=%d: lock=%s "%s"' =>
              map($self->$_,
                qw/program_name pid hostname dbinst mutex_config_id/),
            $slot,
            ($LOCKFAIL ? 'no ' : 'yes'),
            $self->application
        );
        ## lock failed...
        next if $LOCKFAIL;
        $self->error(
            sprintf "%s: mutex table problem. No mutex"
              . " row could be found for MTXCNF_ID %d, slot %d" => __PACKAGE__,
            $self->mutex_config_id, $slot
        ) unless $slot_info;
        $HAVELOCK = 1;
        last;
    }
    return $HAVELOCK;
}

sub release_mutex {
    my $self = shift;
    $self->log(
        sprintf '%s[%08d]@%s (%s) release_mutex "%s"' =>
          map($self->$_, qw/
              program_name pid hostname dbinst application/)
    );
    $self->storage->dbh->rollback;
    $self->storage->dbh->disconnect;
}
sub DESTROY { }

sub error {
    my ($self, $error) = @_;
    my $fatal = {
        to   => ADMINADDR,
        subj => sprintf('[%s] MUTEX', $self->hostname),
        body => sprintf('[%s] %s', $self->hostname, $error),
    };
    mail($fatal);
    die "FATAL ERROR: $fatal->{body}\n";
}

# XXX: use Log::Dispatch to log the mutex messages to the mutex log as well
sub log {
    my $self    = shift;
    my $message = localtime() . " " . shift(@_);
    1 while chomp $message;
    $self->SUPER::log->debug($message);
    open my $log_fh, '>>', '/tmp/mutex.log';
    print $log_fh "$message\n";
    close $log_fh;
}

sub mail {
    shift if $_[0] eq __PACKAGE__;
    my $init = shift;
    my %P;
    if ($init && ref $init eq 'HASH') {
        local $_;
        $P{$_} = $init->{$_} for qw/to subj body/;
        $P{to} ||= ADMINADDR;
    } else {
        $P{to}   = ADMINADDR;
        $P{subj} = "Mutex Crash";
        $P{body} = $init ? $init : 'Bitte manuell pruefen.';
    }
    my $exc;
    ($exc = $0) =~ s|.*/||;
    $P{body} .= "\n$exc, " . localtime() . "\n";
    ## no critic (ProhibitTwoArgOpen)
    open my $mail_fh, qq/| mail -s '$P{subj}' $P{to}/;
    print $mail_fh $P{body};
    close $mail_fh;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Mutex - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 error

FIXME

=head2 get_mutex

FIXME

=head2 mail

FIXME

=head2 mutex_getconf

FIXME

=head2 release_mutex

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

