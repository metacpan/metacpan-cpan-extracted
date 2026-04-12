package Chandra::Log;

use strict;
use warnings;

# Load XS functions from Chandra bootstrap
use Chandra ();

our $VERSION = '0.22';

1;

__END__

=head1 NAME

Chandra::Log - Structured logging framework for Chandra applications

=head1 SYNOPSIS

    use Chandra::Log;

    my $log = Chandra::Log->new(
        level  => 'debug',
        output => 'stderr',
    );

    $log->debug('Variable dump', { x => 42 });
    $log->info('Application started');
    $log->warn('Deprecated method called');
    $log->error('Connection failed', { host => 'db.local' });
    $log->fatal('Unrecoverable error');

    # Level filtering
    $log->set_level('warn');    # Only warn, error, fatal shown

    # Contextual logger
    my $req_log = $log->with(request_id => 'abc-123');
    $req_log->info('Processing');

    # JSON formatter
    $log->formatter('json');

    # File output with rotation
    my $log = Chandra::Log->new(
        level  => 'info',
        output => { file => '/var/log/app.log' },
        rotate => { max_size => '10M', keep => 5 },
    );

    # Multiple outputs
    my $log = Chandra::Log->new(
        output => [
            'stderr',
            { file => 'app.log', level => 'info' },
            { callback => sub { my ($entry) = @_; ... } },
        ],
    );

=head1 DESCRIPTION

Chandra::Log provides structured, multi-output logging with level filtering,
formatters, contextual loggers, file rotation, and DevTools console integration.

=head1 METHODS

=head2 new(%args)

Create a new logger. Options: C<level>, C<output>, C<formatter>, C<rotate>.

=head2 debug($msg, \%data), info, warn, error, fatal

Log at the given level with optional structured data.

=head2 level($new_level)

Get or set the current log level.

=head2 set_level($level)

Set the log level (alias for C<level($level)>).

=head2 formatter($fmt)

Set formatter: C<'text'>, C<'json'>, C<'minimal'>, or a code ref.

=head2 with(%context)

Return a child logger with additional context fields.

=cut
