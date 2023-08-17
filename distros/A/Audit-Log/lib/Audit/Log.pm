package Audit::Log 0.005;

use strict;
use warnings;

use 5.006;
use v5.12.0;    # Before 5.006, v5.10.0 would not be understood.

use File::Which();
use UUID::Tiny();
use List::Util qw{uniq};

# ABSTRACT: auditd log parser with minimal dependencies, using no perl features past 5.12

sub new {
    my ( $class, $path, @returning ) = @_;
    $path = '/var/log/audit/audit.log' unless $path;
    my $fullpath = File::Which::which('ausearch');

    if ( $path eq 'ausearch' ) {
        die "Cannot find ausearch" unless -f $fullpath;
    }
    else {
        die "Cannot access $path" unless -f $path;
    }
    return
      bless( { path => $path, ausearch => $fullpath, returning => \@returning },
        $class );
}

sub search {
    my ( $self, %options ) = @_;

    my $ret      = [];
    my $in_block = 1;
    my $line     = -1;
    my ( $cwd, $exe, $comm, $res ) = ( '', '', '', '' );
    my $fh;
    if ( $self->{path} eq 'ausearch' ) {
        my @args = qw{--input-logs --raw};
        push( @args, ( '-k',  $self->{key} ) );
        push( @args, ( '-sv', $options{res} ? 'yes' : 'no' ) )
          if defined $options{success};
        push( @args, ( '-comm', $options{comm} ) ) if defined $options{comm};
        open( $fh, '|', qq|$self->{fullpath} @args| )
          or die "Could not run $self->{fullpath}!";
    }
    else {
        open( $fh, '<', $self->{path} ) or die "Could not open $self->{path}!";
    }
  LINE: while (<$fh>) {
        next if index( $_, 'SYSCALL' ) < 0 && !$in_block;

        # I am trying to cheat here to snag the timestamp.
        my $msg_start = index( $_, 'msg=audit(' ) + 10;
        my $msg_end   = index( $_, ':' );
        my $timestamp = substr( $_, $msg_start, $msg_end - $msg_start );
        next if $options{older} && $timestamp > $options{older};
        next if $options{newer} && $timestamp < $options{newer};

        # Snag CWDs
        if ( index( $_, 'type=CWD' ) == 0 ) {
            my $cwd_start = index( $_, 'cwd="' ) + 5;
            my $cwd_end   = index( $_, "\n" ) - 1;
            $cwd = substr( $_, $cwd_start, $cwd_end - $cwd_start );
            $line++;
            next;
        }

        # Replace GROUP SEPARATOR usage with simple spaces
        s/[\x1D]/ /g;

        my %parsed = map {
            my @out = split( /=/, $_ );
            shift @out, join( '=', @out )
        } grep { $_ } map {
            my $subj = $_;
            $subj =~ s/"//g;
            chomp $subj;
            $subj
        } split( / /, $_ );

        $line++;
        $parsed{line}      = $line;
        $parsed{timestamp} = $timestamp;
        $parsed{cwd}       = $cwd;
        $parsed{exe}  //= $exe;
        $parsed{comm} //= $comm;
        $parsed{res}  //= $res;

        if ( exists $options{key} && $parsed{type} eq 'SYSCALL' ) {
            $in_block = $parsed{key} =~ $options{key};
            $exe      = $parsed{exe};
            $comm     = $parsed{comm};
            $res      = lc( $parsed{success} ) eq 'yes';
            $cwd      = '';
            next unless $in_block;
        }

        # Check constraints BEFORE filtering returned values, this is a WHERE clause
      CONSTRAINT: foreach my $constraint ( keys(%options) ) {
            next CONSTRAINT if !exists $parsed{$constraint};
            next LINE       if $parsed{$constraint} !~ $options{$constraint};
        }

        # Filter fields for RETURNING clause
        if ( @{ $self->{returning} } ) {
            foreach my $field ( keys(%parsed) ) {
                delete $parsed{$field}
                  unless grep { $field eq $_ } @{ $self->{returning} };
            }
        }
        push( @$ret, \%parsed );
    }
    close($fh);
    return $ret;
}

sub file_changes(&@) {
    my ( $block, @dirs ) = @_;
    my %rules;

    # Instruct auditctl to add UUID based rules
    foreach my $dir (@dirs) {
        $rules{$dir} = UUID::Tiny::create_uuid_as_string( UUID::Tiny::UUID_V1,
            UUID::Tiny::UUID_NS_DNS );

        #TODO handle errors, etc
        system( qw[auditctl -w], $dir, qw[-p rw -k], $rules{$dir} );
    }

    $block->();

    # Unload the rule, flush the log
    foreach my $dir (@dirs) {

        #TODO errors, flush
        system( qw[auditctl -W], $dir );
    }

    # Grab events
    my $parser = Audit::Log->new( 'ausearch', qw{name cwd} );

    # TODO support arrayref
    my $entries = $parser->search( 'key' => [ values(%rules) ] );
    return uniq
      map { $_->{name} =~ m/^\// ? $_->{name} : "$_->{cwd}/$_->{name}" }
      @$entries;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audit::Log - auditd log parser with minimal dependencies, using no perl features past 5.12

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    my $parser = Audit::Log->new();
    my $rows = $parser->search(
        type     => qr/path/i,
        nametype => qr/delete|create|normal/i,
        name     => qr/somefile.txt/i,
    );

=head1 WHY

I had to do reporting for non-incremental backups.
I needed something faster than GNU find, and which took less memory as well.
I didn't want to stat 1M+ files.
Just reads a log and keeps the bare minimum useful information.

You can use auditd for a number of other interesting purposes, which this should support as well.

=head1 CONSTRUCTOR

=head2 new(STRING path, ARRAY returning) = Audit::Log

Opens the provided audit log path when searching, or

    /var/log/audit/audit.log

if none is provided.

Also can filter returned keys by the provided array to not allocate unnecesarily in low mem situations.

=head3 using with ausearch

It's common to have the audit log be quite verbose, and log-rotated.
To get around that you can dump pieces of the audit log as appropriate with ausearch.
Here's an example of dumping keyed events for the last day, which you could then load into new().

    ausearch --raw --key backupwatch -ts `date --date yesterday '+%x'` > yesterdays-audit.log

If you pass 'ausearch' as the audit log path to new(), we will pipe-open to this in subsequent search() calls.

=head3 configuring retention

The audit log is quite likely to have very limited retention.
This is configured in the max_log_file and num_logs parameter of /etc/auditd/audit.conf
You will only have max_log_file * num_logs MB of events stored, so plan according to how much you need to watch.

Your specific use case should be observed, and tuned accordingly.
For example, the average audit log line is ~200 bytes, so you can get maybe 40k entries per log at max_log_file=8.
Each file action is (worst case) 5 lines in the log, resulting in maybe 8k file modifications per 8MB logfile.

As such, stashing results or watching very tightly around blocks of functionality is highly recommended.
Especially in situations such as public servers which are likely to get a large amount of SSH bounces recorded in the log by default.

The block-scoped methods in this module are built to serve precisely this use case.

=head1 METHODS

=head2 search(key => constraint) = ARRAY[HashRef{}]

Searches the log for lines where the value corresponding to the provided key matches the constraint, which is expected to be a quoted regex.
If no constraints are provided, all matching rows will be returned.

Example:

    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create|normal/i );

The above effectively will get you a list of all file modifications/creations/deletions in watched directories.

Adds in a 'line' parameter to rows returned in case you want to know which line in the log it's on.
Also adds a 'timestamp' parameter, since this is a parsed parameter.

=head3 Speeding it up: by event

Auditd logs are also structured in blocks separated between SYSCALL lines, which are normally filtered by 'key', which corresponds to rule name.
We can speed up processing by ignoring events of the incorrect key.

Example:

    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create|normal/i, key => qr/backup_watch/i );

The above will ignore events from all rules save those from the "backup_watch" rule.

=head3 Speeding it up: by timeframe

Auditd log rules also print a timestamp, which means we need a numeric comparison.
Pass in 'older' and 'newer', and we can filter out things appropriately.

Example:

    # Get all records that are from the last 24 hours
    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create|normal/i, newer => ( time - 86400 ) );

=head3 Speeding it up: by command or its outcome

The 'res' parameter in audit logs allows you to filter on whether or not the command had a good (or bad) exit code.
If this option is not passed, you will get all results regardless of their exit code.
Useful for building things like ban-on-fail watchdogs.

    # Failed outbound SSH attempts.
    # You can also pass 'exe' to specifically filter to the path of the executable
    # or neglect to do so if somebody's trying to hide from santa's naughty list.
    my $rows = $parser->search( res => 0, comm => 'ssh', exe => '/usr/bin/ssh' );
    my $maybe_fake = $parser->search( res => 0, comm => 'ssh' );
    my @naughty = List::Util::all { $_->{exe} ne '/usr/bin/ssh' } @$maybe_fake;

=head3 Getting full paths with CWDs

PATH records don't actually store the full path to what is acted upon unless the process acting upon it used an absolute path.
Thankfully, SYSCALL records are are always followed by a CWD record.  As such we add the 'cwd' field to all subsequent records.
As such, you can build full paths like so:

    my $parser = Audit::Log->new(undef, 'name', 'cwd');
    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create|normal/i );
    my @full_paths = map { "$_->{cwd}/$_->{name}" } @$rows;

=head3 Filtering by command

SYSCALL records store the command which executed the call.  This is exposed as part of the parse for each child record, such as PATH or DAEMON_* records.
Example of getting all the commands run which triggered audit events:

    my $parser = Audit::Log->new(undef, 'exe')
    my $rows = $parser->search();

=head1 FUNCTIONS

All these are block-scoped watchers provided for convenience and testing purposes.

=head2 file_changes(CODE block, LIST dirs) = ARRAY

Returns the list of files that changed in the proceeding block.

    my @changes = file_changes { ... } qw{/tmp /mydir};
    is(scalar(@changes), 0, "No spooky action at a distance");

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Audit-Log-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
