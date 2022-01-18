package Audit::Log 0.001;

use strict;
use warnings;

use 5.006;
use v5.12.0;    # Before 5.006, v5.10.0 would not be understood.

# ABSTRACT: auditd log parser with no external dependencies, using no perl features past 5.12

sub new {
    my ( $class, $path, @returning ) = @_;
    $path = '/var/log/audit/audit.log' unless $path;
    die "Cannot access $path" unless -f $path;
    return bless( { path => $path, returning => \@returning }, $class );
}

sub search {
    my ( $self, %options ) = @_;

    my $ret      = [];
    my $in_block = 1;
    my $line     = -1;
    open( my $fh, '<', $self->{path} );
  LINE: while (<$fh>) {
        next if index( $_, 'SYSCALL' ) < 0 && !$in_block;

        # I am trying to cheat here to snag the timestamp.
        my $msg_start = index( $_, 'msg=audit(' ) + 10;
        my $msg_end   = index( $_, ':' );
        my $timestamp = substr( $_, $msg_start, $msg_end - $msg_start ) . "\n";
        next if $options{older} && $timestamp > $options{older};
        next if $options{newer} && $timestamp < $options{newer};

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
        $parsed{line} = $line;
        chomp $timestamp;
        $parsed{timestamp} = $timestamp;

        if ( exists $options{key} && $parsed{type} eq 'SYSCALL' ) {
            $in_block = $parsed{key} =~ $options{key};
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audit::Log - auditd log parser with no external dependencies, using no perl features past 5.12

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $parser = Audit::Log->new();
    my $rows = $parser->search(
        type     => qr/path/i,
        nametype => qr/delete|create/i,
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

=head1 METHODS

=head2 search(key => constraint) = ARRAY[HashRef{}]

Searches the log for lines where the value corresponding to the provided key matches the constraint, which is expected to be a quoted regex.
If no constraints are provided, all matching rows will be returned.

Example:

    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create/i );

The above effectively will get you a list of all file modifications/creations/deletions in watched directories.

Adds in a 'line' parameter to rows returned in case you want to know which line in the log it's on.
Also adds a 'timestamp' parameter, since this is a parsed parameter.

=head3 Speeding it up: by event

Auditd logs are also structured in blocks separated between SYSCALL lines, which are normally filtered by 'key', which corresponds to rule name.
We can speed up processing by ignoring events of the incorrect key.

Example:

    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create/i, key => qr/backup_watch/i );

The above will ignore events from all rules save those from the "backup_watch" rule.

=head3 Speeding it up: by timeframe

Auditd log rules also print a timestamp, which means we need a numeric comparison.
Pass in 'older' and 'newer', and we can filter out things appropriately.

Example:

    # Get all records that are from the last 24 hours
    my $rows = $parser->search( type => qr/path/i, nametype=qr/delete|create/i, newer => ( time - 86400 ) );

Handling rotated logs is left as an exercise for the reader.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Audit-Log-perl/issues>

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

Copyright (c) 2020 Troglodyne LLC


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
