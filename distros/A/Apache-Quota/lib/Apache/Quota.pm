package Apache::Quota;

use strict;

use Apache;
use Apache::Constants qw( OK DECLINED FORBIDDEN HTTP_OK );
use Fcntl qw(O_CREAT O_RDWR O_RDONLY);
use File::Path ();
use File::Temp ();

use vars qw ( $VERSION $DEBUG );

$VERSION = 0.04;

use constant KB => 1024;
use constant MB => 1024 ** 2;
use constant GB => 1024 ** 3;

use constant SECOND => 1;
use constant MINUTE => 60;
use constant HOUR   => 60 * 60;
use constant DAY    => 24 * 60 * 60;

sub handler
{
    my $r = shift;

    return DECLINED if $r->header_only;

    local $DEBUG = $r->dir_config('QuotaDebug') ? 1 : 0;
    $r->notes( 'Apache::Quota::DEBUG' => 1 ) if $DEBUG;

    my $main = $r->is_main ? $r : $r->main;

    unless ( $main->notes('Apache::Quota::initialized') )
    {
        my $file = $r->dir_config('QuotaFile');

        die "Cannot use Apache::Quota unless QuotaFile is specified"
            unless defined $file;

        $main->notes( 'Apache::Quota::file' => $file );

        my $locker;
        {
            my $class;

            if ( $r->dir_config('QuotaLocker') )
            {
                $class = $r->dir_config('QuotaLocker');
                $class = "Apache::Quota::$class"
                    unless $class =~ /^Apache::Quota::/;

                eval "require $class";
                die $@ if $@;
            }
            else
            {
                for my $c ( qw( Apache::Quota::BerkeleyDB Apache::Quota::DB_File::Lock ) )
                {
                    eval "require $_";
                    $class = $c unless $@;
                }

                die "Cannot load Apache::Quota::BerkeleyDB or Apache::Quota::DB_File::Lock"
                    unless $class;
            }

            _log( $r, "locker is $class" ) if $DEBUG;

            $locker = $class;
            $main->notes( 'Apache::Quota::locker' => $locker );
        }


        _log( $r, "will record usage in $file for request for " . $r->uri )
            if $DEBUG;

        my $type = lc $r->dir_config('QuotaType') || 'global';

        _log( $r, "limit type is $type" )
            if $DEBUG;

        my $key  = $r->dir_config('QuotaLocationKey') || 'Apache-Quota global key';

        _log( $r, "key is $key" )
            if $DEBUG;

        die "Your location key cannot contain a colon" if $key =~ /:/;

        my $full_key = ( $type eq 'client-ip'
                         ? join ':', 'client-ip', $r->connection->remote_ip, $key
                         : $type eq 'sub'
                         ? join ':', 'sub', _key_from_sub($r), $key
                         : $key
                       );

        _log( $r, "full key is $full_key" )
            if $DEBUG;

        $main->notes( 'Apache::Quota::full_key' => $full_key );

        my $limit = _get_limit($r);

        _log( $r, "limit is $limit bytes" )
            if $DEBUG;

        my $period = _get_period($r);

        _log( $r, "period is $period seconds" )
            if $DEBUG;

        my $db = $locker->_open_db( file => $file, mode => 'read' );

        my $expired = time - $period;
        $main->notes( 'Apache::Quota::expired' => $expired );

        if ( exists $db->{$full_key} )
        {
            _log( $r, "found key ($full_key) in DB file" )
                if $DEBUG;

            $main->notes( 'Apache::Quota::exceeds' =>
                          _check_against_limit( $r, $expired, $limit, $db->{$full_key} )
                        );
        }

        untie %$db;
    }

    $main->notes( 'Apache::Quota::initialized' => 1 );

    if ( $main->notes('Apache::Quota::exceeds') )
    {
        my $on_exceed = lc $r->dir_config('QuotaOnExceed') || 'deny';

        _log( $r, "on exceed is $on_exceed" )
            if $DEBUG;

        if ( $on_exceed eq 'notes' )
        {
            _log( $r, "setting \$r->notes() value for Apache::Quota::exceeded to 1" )
                if $DEBUG;

            $r->notes( 'Apache::Quota::exceeded' => 1 );
        }
        else
        {
            _log( $r, "returning FORBIDDEN" )
                if $DEBUG;

            return FORBIDDEN;
        }
    }
    else
    {
        _log( $r, "registering cleanup" )
            if $DEBUG;

        $r->register_cleanup( \&_record_usage );
    }

    return OK;
}

sub _key_from_sub
{
    my $r = shift;

    my $sub = $r->dir_config('QuotaSub');

    die "Cannot set QuotaType to sub if QuotaSub is not set"
        unless $sub;

    _log( $r, "sub is $sub" )
        if $DEBUG;

    my $key;
    {
        no strict 'refs';
        $key = &{$sub}($r);
    }

    return $key;
}

my %limit_letter_to_number = ( k => KB, m => MB, g => GB );
sub _get_limit
{
    my $r = shift;

    my $limit = $r->dir_config('QuotaLimit');

    die "Cannot use Apache::Quota unless QuotaLimit is specified"
        unless defined $limit;

    _log( $r, "limit set to $limit in config file" )
        if $DEBUG;

    my ( $num, $letter ) = $limit =~ /(\d+)([kmg])/i;
    $letter ||= 'k';

    die "Invalid limit in QuotaLimit: $limit"
        unless exists $limit_letter_to_number{lc $letter};

    return $num * $limit_letter_to_number{ lc $letter };
}

sub _get_period
{
    my $r = shift;

    my $period = $r->dir_config('QuotaPeriod');

    die "Cannot use Apache::Quota unless QuotaPeriod is specified"
        unless defined $period;

    _log( $r, "period set to $period in config file" )
        if $DEBUG;

    return _parse_period($period);
}

my %period_letter_to_number = ( s => SECOND, m => MINUTE, h => HOUR, d => DAY );
sub _parse_period
{
    my $period = shift;

    my ( $num, $letter ) = $period =~ /(\d+)([smhd])/i;
    $letter ||= 's';

    die "Invalid period: $period"
        unless exists $period_letter_to_number{ lc $letter };

    return $num * $period_letter_to_number{ lc $letter };
}

sub _check_against_limit
{
    my ( $r, $expired, $limit, $current ) = @_;

    my $total = 0;
    foreach my $record ( split /;/, $current )
    {
        my ( $time, $bytes ) = split /:/, $record;

        _log( $r, "key has record: $time - $bytes" )
            if $DEBUG;

        # These will be removed during cleanup, but for now we'll
        # avoid writing to the file to try to speed things up a bit.
        next unless $time > $expired;

        $total += $bytes;
    }

    _log( $r, "key has total bytes of $total" )
        if $DEBUG;

    if ( $total > $limit )
    {
        _log( $r, "total bytes ($total) exceeds limit ($limit)" )
            if $DEBUG;

        return 1;
    }

    return 0;
}

sub _record_usage
{
    my $r = shift;

    return 0 unless $r->status == HTTP_OK;

    return 0 unless $r->bytes_sent;

    _log( $r, "status was HTTP_OK, recording traffic" )
        if $DEBUG;

    my $db =
        $r->notes('Apache::Quota::locker')->_open_db
            ( file => $r->notes('Apache::Quota::file'), mode => 'write' );

    my $key = $r->notes('Apache::Quota::full_key');
    my $expired = $r->notes('Apache::Quota::expired');

    my @records;
    if ( exists $db->{$key} )
    {
        foreach my $record ( split /;/, $db->{$key} )
        {
            my ( $time, $bytes ) = split /:/, $record;

            next unless $time > $expired;

            push @records, "$time:$bytes";
        }
    }

    push @records, join ':', time, $r->bytes_sent;

    _log( $r, "adding record of " . $r->bytes_sent . " bytes sent" )
        if $r->notes('Apache::Quota::DEBUG');

    $db->{$key} = join ';', @records;

    untie %$db;

    return 1;
}

sub usage
{
    my %p = @_;

    my $locker = $p{locker};
    $locker = "Apache::Quota::$locker"
        unless $locker =~ /^Apache::Quota::/;

    eval "require $locker";
    die $@ if $@;

    my $db = $locker->_open_db( file => $p{file}, mode => 'read' );

    my $expired = 0;
    if ( defined $p{period} )
    {
        $expired = time - _parse_period( $p{period} );
    }

    my %vals;
    foreach my $key ( keys %$db )
    {
        my $total = 0;
        if ( defined $db->{$key} )
        {
            foreach my $record ( split /;/, $db->{$key} )
            {
                my ( $time, $bytes ) = split /:/, $record;

                next unless $time > $expired;

                $total += $bytes;
            }
        }

        next unless $total;

        my %extra;
        if ( $key =~ /^client-ip:([\d\.]+)/ )
        {
            $extra{ip} = $1;
        }
        elsif ( $key =~ /^sub:(.+):[^:]+$/ )
        {
            $extra{sub} = $1;
        }

        $vals{$key} = { %extra, bytes => $total };
    }

    untie %$db;

    return %vals;
}

sub set_key
{
    my %p = @_;

    die "Cannot call set_key without a key parameter"
        unless defined $p{key};

    my $locker = $p{locker};
    $locker = "Apache::Quota::$locker"
        unless $locker =~ /^Apache::Quota::/;

    eval "require $locker";
    die $@ if $@;

    my $db = $locker->_open_db( file => $p{file}, mode => 'write' );

    return 0 unless exists $db->{ $p{key} };

    if ( defined $p{value} )
    {
        die "Cannot set quota to a non-numeric value"
            unless $p{value} =~ /^\d+$/;

        $db->{ $p{key} } = time . ":$p{value}";
    }
    else
    {
        delete $db->{ $p{key} };
    }

    untie %$db;

    return 1;
}

sub reset_key { set_key( @_, value => undef ) }

sub _log
{
    my $r = shift;
    my $msg = '[Apache::Quota debug] ' . shift;
    $msg .= "\n";

    warn($msg);
}

1;

__END__

=head1 NAME

Apache::Quota - Flexible transfer limiting/throttling under mod_perl

=head1 SYNOPSIS

  PerlSetVar  QuotaFile  /tmp/Apache-Quota.db
  PerlSetVar  QuotaLocker       BerkeleyDB

  <Location /foo>
    PerlSetVar  QuotaLocationKey  foo
    PerlSetVar  QuotaType         client-ip
    PerlSetVar  QuotaPeriod       1d
    PerlSetVar  QuotaLimit        3M
    PerlSetVar  QuotaOnExceed     notes

    PerlFixupHandler  Apache::Quota
  </Location>

  <Location /bar>
    PerlSetVar  QuotaLocationKey  bar
    PerlSetVar  QuotaType         sub
    PerlSetVar  QuotaSub          "MyApp::get_user_id"
    PerlSetVar  QuotaPeriod       60s
    PerlSetVar  QuotaLimit        500k
    PerlSetVar  QuotaOnExceed     deny

    PerlFixupHandler  Apache::Quota
  </Location>

=head1 DESCRIPTION

This module provides flexible transfer quotas for all or part of a
site.  Additionally, quotas may be enforced for the site as a whole,
on a per-client IP basis, or based on some other criterion you define.

=head1 USAGE

Most of this module's functionality is used by setting variables via
the mod_perl C<PerlSetVar> directive.  The module should be installed
as a C<PerlFixupHandler> in a Location or similar Apache configuration
block.

=head2 PerlSetVar Parameters

The following directives are available:

=over 4

=item * QuotaFile (required)

The DB file where quota usage will be recorded.  A single file can be
shared across multiple locations.

=item * QuotaLimit (required)

This sets the quota limit.  This can be a plain number, which will be
interpreted as bytes, or a number followed by a letter.  The valid
letters are "k/K" (kilobytes), "m/M" (megabytes), or "g/G"
(gigabytes).  This module defines a kilobyte as 1024 bytes, a megabyte
as 1024 ** 2 bytes, and a gigabyte as 1024 ** 3 bytes.

=item * QuotaPeriod (required)

This sets the time period for which a quota is enforced.  This can be
a number, which will be interpreted as seconds, or a number followed
by a letter.  The valid letters are "s/S" (seconds), "m/M" (minutes),
"h/H" (hours), or "d/D" (days).

=item * QuotaType

This can be one of "global", "client-ip", or "sub".  If it is set to
"global", then the bandwidth limit is shared across B<all> clients
accessing the particular location.

If it is set to "client-ip", then quota usage is tracked on a per
client IP address basis.  Of course, given the presence of proxies,
this may not actually correspond to a single client.

If it is set to "sub", then the module will call a user-specified
subroutine to generate the unique identifier for the client.  One way
to use this would be to have it call a subroutine that gets a unique
id from a cookie or uses C<< $r->user() >>.

This parameter defaults to "global".

=item * QuotaSub

This is the subroutine that should be called if QuotaType is set to
"sub".  This should simply be a string like "MyApp::quota_key".  This
parameter is required if you set QuotaType to "sub".

=item * QuotaLocationKey

If this is specified, then this key is used to uniquely indentify the
current location.  This allows you to use one quota file for multiple
locations, and track quota usage for each location separately.  This
key can be anything, but it B<must not contain a colon (:)>.

If not given, this default to "Apache-Quota global key" for I<all>
locations.

=item * QuotaOnExceed

This parameter defines what the module does when it detects that a
client has exceed the quota.  The two valid options are "deny" or
"notes".  If this is set to "deny", then the module simply returns the
C<FORBIDDEN> constant for the request.  If it is set to "notes", then
it sets C<< $r->notes('Apache::Quota::exceeded') >> to a true value.
This can be checked from your application code.

This defaults to "deny".

=item * QuotaLocker

The locking class to use.  This should be one of "BerkeleyDB" or
"DB_File::Lock".  Using BerkeleyDB is preferred, as it better
supported and uses a much more robust locking implementation.  If no
locker is specified, the module will try to load BerkeleyDB and
DB_File::Lock, in that order.  If it cannot load either, it will die.

=item * QuotaDebug

Setting this to a true value turns on debugging messages which are
sent to the Apache log via C<warn()>.

=back

=head2 Functions for External Use

This module also offers some functions for directly looking at and
manipulating quotas.  None of these functions are exportable.

=head3 Common Parameters

All of these functions accept the following parameters:

=over 4

=item * file (required)

This is the db file you want to access.

=item * locker (required)

The locker class to use, "BerkeleyDB" or "DB_File::Lock".

=back

=head3 Functions

=over 4

=item * usage

This function returns the current usage values in the form of a hash.

It takes an additional optional parameter, "period".  If given, this
will be used to determine which entries to ignore.  This can be any
value which is valid for the "QuotaPeriod" parameter.

The has returned is keyed on the "full key" used by Apache::Quota
internally.  This should be treated as an opaque value, and is
returned only so that you can pass it back to the C<set_key()> or
C<reset_key()> functions later.

The hash values are hash references.  Each reference always contains
the key "bytes", which is the total number of bytes used by the
user/client identified by the "full key".

The other keys in the hash reference varies depending on whether the
C<QuotaType> parameter was set to "global", "client", or "sub".  If it
was set to "global", then there are no other keys.  If the type was
set to "client-ip", then the other key is "ip", and contains the
client's IP address.  If the type was set to "sub", then the other key
is "sub", and contains the value returned by the subroutine you
provided.

=item * set_key

This function requires two additional parameters, "key" and "value".
The key should be a "full key", as returned by the C<usage()>
function.  The value should be a number, which will be the new number
of bytes for the key.  All historical values will be wiped out, and
the number value will be set, along with the current time.

If the key is not in the db file, then this method returns a false
value.

=item * reset_key

This function requires a "key" parameter.  This completely resets
usage information for the given key.

If the key is not in the db file, then this method returns a false
value.

=back

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache%3A%3AQuota
or via email at bug-apache-quota@rt.cpan.org.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2003 David Rolsky.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

The Apache modules mod_bandwidth and mod_throttle.

=cut
