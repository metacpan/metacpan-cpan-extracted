package Dancer::Logger::File::PerRequest;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.03';

use Carp;
use base 'Dancer::Logger::Abstract';
use Dancer::FileUtils qw(open_file);
use Dancer::Config 'setting';
use Dancer::Hook;
use Dancer::Factory::Hook;
use Dancer::SharedData;
use IO::File;
use Fcntl qw(:flock SEEK_END);
use Scalar::Util ();

Dancer::Factory::Hook->instance->install_hooks(
    qw/before_file_per_request_close after_file_per_request_close/
);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $logdir = logdir();
    return unless ($logdir);
    mkdir($logdir) unless -d $logdir;

    my $logfile_callback = setting('logfile_callback') || sub {
        ## timestamp + pid + request->id
        my @d = localtime();
        my $file = sprintf('%04d%02d%02d%02d%02d%02d', $d[5] + 1900, $d[4] + 1, $d[3], $d[2], $d[1], $d[0]);
        my $request_id = Dancer::SharedData->request ? Dancer::SharedData->request->id : '';
        return $file . '-' . $$ . '-' . $request_id . '.log';
    };
    $self->{logfile_callback} = $logfile_callback;

    # per request
    Scalar::Util::weaken $self;
    my $on_end = sub {
        return unless $self->{fh};

        Dancer::Factory::Hook->execute_hooks('before_file_per_request_close', $self->{fh}, $self->{logfile});
        close($self->{fh}); # close
        undef $self->{fh};
        Dancer::Factory::Hook->execute_hooks('after_file_per_request_close', $self->{logfile}, Dancer::SharedData->response);
        undef $self->{logfile};
    };
    Dancer::Hook->new('after' => $on_end);
    if (setting('serializer')) { # when serializer, on error, it's not call 'after' hook
        Dancer::Hook->new('after_error_render' => $on_end);
    }
}

sub _log {
    my ($self, $level, $message) = @_;

    my $fh = $self->{fh};
    unless ($fh) {
        my $logfile = $self->{logfile_callback}->();
        my $logdir = logdir() or return;
        $logfile = File::Spec->catfile($logdir, $logfile);

        unless($fh = open_file('>>', $logfile)) {
            carp "unable to create or append to $logfile";
            return;
        }

        # looks like older perls don't auto-convert to IO::File
        # and can't autoflush
        # see https://github.com/PerlDancer/Dancer/issues/954
        eval { $fh->autoflush };

        $self->{fh} = $fh;
        $self->{logfile} = $logfile;
    }

    return unless(ref $fh && $fh->opened);

    flock($fh, LOCK_EX)
        or carp "locking logfile $self->{logfile} failed";
    seek($fh, 0, SEEK_END)
        or carp "seeking to logfile $self->{logfile} end failed";
    $fh->print($self->format_message($level => $message))
        or carp "writing to logfile $self->{logfile} failed";
    flock($fh, LOCK_UN)
        or carp "unlocking logfile $self->{logfile} failed";
}

# Copied from Dancer::Logger::File
sub logdir {
    if ( my $altpath = setting('log_path') ) {
        return $altpath;
    }

    my $logroot = setting('appdir');

    if ( $logroot and ! -d $logroot and ! mkdir $logroot ) {
        carp "app directory '$logroot' doesn't exist, am unable to create it";
        return;
    }

    my $expected_path = $logroot                                  ?
                        Dancer::FileUtils::path($logroot, 'logs') :
                        Dancer::FileUtils::path('logs');

    return $expected_path if -d $expected_path && -x _ && -w _;

    unless (-w $logroot and -x _) {
        my $perm = (stat $logroot)[2] & 07777;
        chmod($perm | 0700, $logroot);
        unless (-w $logroot and -x _) {
            carp "app directory '$logroot' isn't writable/executable and can't chmod it";
            return;
        }
    }
    return $expected_path;
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer::Logger::File::PerRequest - per-request file-based logging engine for Dancer

=head1 SYNOPSIS

    ## in yml config
    logger: "File::PerRequest"

=head1 DESCRIPTION

Dancer::Logger::File::PerRequest is a per-request file-based logging engine for Dancer.

=head2 SETTINGS

=head3 logfile_callback

By default, it will be generating YYYYMMDDHHMMSS-$pid-$request_id.log under logs of application dir.

the stuff can be configured as

=over 4

=item * per pid

    set 'logfile_callback' => sub {
        return $$ . '.log';
    };

will genereate $pid.log

=item * per hour

    set 'logfile_callback' => sub {
        my @d = localtime();
        my $file = sprintf('%04d%02d%02d%02d', $d[5] + 1900, $d[4] + 1, $d[3], $d[2]);
        return $file . '.log';
    };

will do file as YYYYMMDDHH.log

=back

it's quite flexible that you can configure it as daily or daily + pid + server or whatever.

=head3 log_path

the log path, same as L<Dancer::Logger::File>, default to $appdir/logs

=head2 HOOKS

=head3 before_file_per_request_close

    hook 'before_file_per_request_close' => sub {
        my ($fh, $logfile) = @_;

        print $fh "# END on " . scalar(localtime()) . "\n";
    };

=head3 after_file_per_request_close

    hook 'after_file_per_request_close' => sub {
        my ($logfile, $response) = @_;

        # response as Dancer::Response
        if ($response->status >= 500) { ## server error
            # move file to error dir
        } else {
            # just rm it?
            unlink($logfile);
        }
    };

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
