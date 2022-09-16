package App::MonM::Util; # $Id: Util.pm 134 2022-09-09 10:33:00Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Util - Internal utilities

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use App::MonM::Util qw/
            explain expire_calc
        /;

    print explain( $object );

=head1 DESCRIPTION

Internal utilities

=head1 FUNCTIONS

=over 4

=item B<explain>

    print explain( $object );

Returns Data::Dumper dump

=item B<blue>, B<cyan>, B<green>, B<red>, B<yellow>, B<magenta>, B<gray>

    print cyan("Format %s", "text");

Returns colored string

=item B<nope>, B<skip>, B<wow>, B<yep>

    my $status = nope("Format %s", "text");

Prints status message and returns status.

For nope returns - 0; for skip, wow, yep - 1

=item B<getCheckitByName>

    my $checkits = getCheckitByName($app->config("checkit"), "foo", "bar");

Returns list of normalized the "checkit" config sections by name

=item B<getExpireOffset>

    print getExpireOffset("+1d"); # 86400
    print getExpireOffset("-1d"); # -86400

Returns offset of expires time (in secs).

Original this function is the part of CGI::Util::expire_calc!

This internal routine creates an expires time exactly some number of hours from the current time.
It incorporates modifications from  Mark Fisher.

format for time can be in any of the forms:

    now   -- expire immediately
    +180s -- in 180 seconds
    +2m   -- in 2 minutes
    +12h  -- in 12 hours
    +1d   -- in 1 day
    +3M   -- in 3 months
    +2y   -- in 2 years
    -3m   -- 3 minutes ago(!)

If you don't supply one of these forms, we assume you are specifying the date yourself

=item B<getTimeOffset>

    my $off = getTimeOffset("1h2m24s"); # 4344
    my $off = getTimeOffset("1h 2m 24s"); # 4344

Returns offset of time (in secs)

=item B<getBit>

    print getBit(123, 3) ? "SET" : "UNSET"; # UNSET

Getting specified Bit

=item B<header_field_normalize>

    print header_field_normalize("content-type"); # Content-Type

Returns normalized header field

=item B<merge>

    my $a = {a => 1, c => 3, d => { i => 2 }, r => {}};
    my $b = {b => 2, a => 100, d => { l => 4 }};
    my $c = merge($a, $b);
    # $c is {a => 100, b => 2, c => 3, d => { i => 2, l => 4 }, r => {}}

Recursively merge two or more hashes, simply

This code was taken from L<Hash::Merge::Simple> (Thanks, Robert Krimen)

=item B<node2anode>

    my $anode = node2anode({});

Returns array of nodes

=item B<parsewords>

    my @b = parsewords("foo,bar baz"); # qw/foo bar baz/

Parses string and split it by words. See L<Text::ParseWords/quotewords>

=item B<run_cmd>

    my $hash = run_cmd($command, $timeout, $stdin);

Wrapped L<IPC::Cmd/run_forked> function

This function returns hash:

    {
        'cmd'     => 'perl -w',
        'code'    => 0, # Exit code (errorlevel)
        'message' => 'OK', # OK/ERROR
        'pgid'    => 176294, # Pid of child process
        'status'  => 1, # 1/0
        'stderr'  => '', # STDERR
        'stdout'  => '', # STDOUT
    }

=item B<set2attr>

    my $hash = set2attr({set => ["AttrName Value"]}); # {"AttrName" => "Value"}

Converts attributes from the "set" format to regular hash

=item B<setBit>

    printf("%08b", setBit(123, 3)); # 01111111

Setting specified Bit. Returns new value.

=item B<slurp>

    my $content = slurp($file);

Read all data at once from the file (utf8)

    my $content = slurp($file, 1);

Read all data at once from the file (binary)

=item B<spurt>, B<spew>

    my $error = spurt($file, qw/foo bar baz/);

Write all data at once to the file

=back

=head1 HISTORY

See C<Changes> file

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION @EXPORT @EXPORT_OK /;
$VERSION = '1.02';

use Data::Dumper; #$Data::Dumper::Deparse = 1;
use Term::ANSIColor qw/ colored /;
use Text::ParseWords qw/quotewords/;
use Clone qw/clone/;
use IO::File;
use IPC::Cmd qw/run_forked/;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util qw/ trim /;
use App::MonM::Const qw/IS_TTY/;

use constant {
        BIT_SET     => 1,
        BIT_UNSET   => 0,
    };

use base qw/Exporter/;
@EXPORT = qw/
        blue green red yellow cyan magenta gray
        yep nope skip wow
    /;
@EXPORT_OK = qw/
        explain
        parsewords
        getCheckitByName getExpireOffset getTimeOffset
        node2anode set2attr
        getBit setBit
        merge
        header_field_normalize
        slurp spurt spew
        run_cmd
    /;

sub explain {
    my $dumper = Data::Dumper->new( [shift] );
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    return $dumper->Dump;
}
sub parsewords {
    my $s = shift;
    my @words = grep { defined && length } quotewords(qr/\s+|[\,\;]+/, 0, $s);
    return @words;
}
sub getExpireOffset {
    my $time = trim(shift // 0);
    my %mult = (
            's' => 1,
            'm' => 60,
            'h' => 60*60,
            'd' => 60*60*24,
            'M' => 60*60*24*30,
            'y' => 60*60*24*365
        );
    if (!$time || (lc($time) eq 'now')) {
        return 0;
    } elsif ($time =~ /^\d+$/) {
        return $time; # secs
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
        return ($mult{$2} || 1) * $1;
    }
    return $time;
}
sub getTimeOffset {
    my $s = trim(shift // 0);
    return $s if $s =~ /^\d+$/;
    my $r = 0;
    my $c = 0;
    while ($s =~ s/([+-]?(?:\d+|\d*\.\d*)[smhdMy])//) {
        my $i = getExpireOffset("$1");
        $c++ if $i < 0;
        #print ">> $1 ($i)\n";
        $r += $i < 0 ? $i*-1 : $i;
    }
    return $c ? $r*-1 : $r;
}

sub getCheckitByName {
    my $sects = shift; # $app->config("checkit");
    my @names = @_; # names

    my $i = 0;
    my @j = ();
    if (ref($sects) eq 'ARRAY') { # Array
        foreach my $r (@$sects) {
            if ((ref($r) eq 'HASH') && exists $r->{enable}) { # Anonymous
                $r->{name} = sprintf("virtual%d", ++$i);
                next unless (!@names || grep {$r->{name} eq lc($_)} @names);
                push @j, $r;
            } elsif (ref($r) eq 'HASH') { # Named
                foreach my $k (keys %$r) {
                    my $v = $r->{$k};
                    next unless ref($v) eq 'HASH';
                    $v->{name} = lc($k);
                    next unless (!@names || grep {$v->{name} eq lc($_)} @names);
                    push @j, $v;
                }
            }
        }
    } elsif ((ref($sects) eq 'HASH') && !exists $sects->{enable}) { # Hash {name => {...}}
        foreach my $k (keys %$sects) {
            my $v = $sects->{$k};
            next unless ref($v) eq 'HASH';
            $v->{name} = lc($k);
            next unless (!@names || grep {$v->{name} eq lc($_)} @names);
            push @j, $v;
        }
    } elsif (ref($sects) eq 'HASH') { # Hash {...}
        $sects->{name} = sprintf("virtual%d", ++$i);
        push @j, $sects if (!@names || grep {$sects->{name} eq lc($_)} @names);
    }
    return grep {$_->{enable}} @j;
}
sub node2anode {
    my $n = shift;
    return [] unless $n && ref($n) =~ /ARRAY|HASH/;
    return [$n] if ref($n) eq 'HASH';
    return $n;
}
sub set2attr {
    my $in = shift;
    my $attr = is_array($in) ? $in : array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    return {%attrs};
}
sub setBit {
    my $v = fv2zero(shift);
    my $n = fv2zero(shift);
    return $v | (2**$n);
}
sub getBit {
    my $v = fv2zero(shift);
    my $n = fv2zero(shift);
    return ($v & (1 << $n)) ? BIT_SET : BIT_UNSET;
}
sub merge {
    my ($left, @right) = @_;
    return clone($left) unless @right; # Nothing to do
    return merge($left, merge(@right)) if @right > 1; # More than 2
    my ($r) = @right; # Get worked right
    my $l = clone($left);
    my %m = %$l;
    for my $key (keys %$r) {
        my ($hr, $hl) = map { ref $_->{$key} eq 'HASH' } $r, $l;
        if ($hr and $hl){
            $m{$key} = merge($l->{$key}, $r->{$key});
        } else {
            $m{$key} = $r->{$key};
        }
    }
    return {%m};
}
sub header_field_normalize {
    my $s = shift // "";
    $s =~ s/\b(\w)/\u$1/g;
    return $s;
}
sub slurp {
    my $file = shift;
    my $isbin = shift || 0;
    return "" unless $file;
    my $fh = IO::File->new($file, "r");
    return unless defined $fh; # "Can't load file $file: $!"
    $isbin ? $fh->binmode : $fh->binmode(':raw:utf8');

    my $ret;
    my $content = "";
    my $buf;
    while ($ret = read($fh, $buf, 131072)) {
        $content .= $buf;
    }
    undef $fh;
    return unless defined $ret;
    return $content;
}
sub spurt {
    my $file = shift;
    my @arr = @_;
    my $fh = IO::File->new($file, "w");
    return "Can't write file $file: $!" unless defined $fh;
    $fh->binmode(':raw:utf8');
    $fh->print(join("\n", @arr));
    undef $fh;
    return "";
}
sub spew {goto &spurt}
sub run_cmd {
    my $cmd = shift;
    my $timeout = shift || 0;
    my $exe_in = shift;

    my %args = ();
    $args{timeout} = $timeout if $timeout;
    $args{child_stdin} = $exe_in if $exe_in;

    my $r = {};
    $r = run_forked( $cmd, \%args) if $cmd;


    my %ret = (
        cmd     => $r->{cmd} // $cmd,
        pgid    => $r->{child_pgid} || 0,
        code    => $r->{exit_code} || 0,
        stderr  => $r->{stderr} // '',
        stdout  => $r->{stdout} // '',
        status  => $r->{exit_code} ? 0 : 1,
        message => $r->{exit_code} ? 'ERROR' : 'OK',
    );
    chomp($ret{stderr});
    chomp($ret{stdout});

    # Time outed
    if ($r->{killed_by_signal}) {
        $ret{status} = 0;
        $ret{message} = 'ERROR';
        $ret{code} = -1;
        $ret{stderr} = sprintf("Timeouted: killed by signal [%s]", $r->{killed_by_signal});
    }

    # Exitval
    if ($ret{code} && !length($ret{stderr})) {
        $ret{stderr} = sprintf("Exitval=%d", $ret{code});
    }

    return {%ret};
}

####################
# Colored functions
####################
sub yep {
    print(green(sprintf(shift, @_)), "\n");
    return 1;
}
sub nope {
    print(red(sprintf(shift, @_)), "\n");
    return 0;
}
sub skip {
    print(gray(sprintf(shift, @_)), "\n");
    return 1;
}
sub wow {
    print(yellow(sprintf(shift, @_)), "\n");
    return 1;
}

# Colored helper functions
sub green {  IS_TTY ? colored(['bright_green'],  sprintf(shift, @_)) : sprintf(shift, @_) }
sub red {    IS_TTY ? colored(['bright_red'],    sprintf(shift, @_)) : sprintf(shift, @_) }
sub yellow { IS_TTY ? colored(['bright_yellow'], sprintf(shift, @_)) : sprintf(shift, @_) }
sub cyan {   IS_TTY ? colored(['bright_cyan'],   sprintf(shift, @_)) : sprintf(shift, @_) }
sub blue {   IS_TTY ? colored(['bright_blue'],   sprintf(shift, @_)) : sprintf(shift, @_) }
sub magenta {IS_TTY ? colored(['bright_magenta'],sprintf(shift, @_)) : sprintf(shift, @_) }
sub gray {   IS_TTY ? colored(['white'],         sprintf(shift, @_)) : sprintf(shift, @_) }

1;

package # hide me from PAUSE
    App::MonM::Util::Scheduler;
use strict;

use Carp; # carp - warn; croak - die;
use CTK::TFVals qw/ is_void /;
use CTK::ConfGenUtil qw/ array is_array is_hash /;

our $VERSION = '1.00';

use constant {
        DAYS_OF_WEEK    => [qw/sunday monday tuesday wednesday thursday friday saturday/],
        DAYS_OF_WEEK_S  => [qw/sun mon tue wed thu fri sat/],
        DAYS_ALIASES    => {
                "sunday"    => "sun",
                "monday"    => "mon",
                "tuesday"   => "tue",
                "wednesday" => "wed",
                "thursday"  => "thu",
                "friday"    => "fri",
                "saturday"  => "sat",
            },
        AT_DEFAULT      => 'Sun-Sat',
        SFT_DEFAULT     => '[00:00-23:59]',
        OFFSET_START    => 0,          # 00:00
        OFFSET_FINISH   => 60*60*24-1, # 23:59
    };

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {
            calendar => {}, # { channel_name => [ { weekday_index => [start, finish] } ] }
            added    => {}, # { channel_name => at }
        }, $class;

    return $self;
}

sub getAtString {
    my $self = shift;
    my $chname = shift;
    croak("The channel name missing") unless $chname;
    my $added = $self->{added};
    return exists $added->{$chname} ? $added->{$chname} : '';
}
sub add {
    my $self = shift;
    my $chname = shift;
    my $at = lc(shift || AT_DEFAULT);
    croak("The channel name missing") unless $chname;
    $at =~ s/\s+//g; # remove spaces

    # Maybe already exists? - return
    my $added = $self->{added};
    return $self if $added->{$chname} && $added->{$chname} eq $at;
    $added->{$chname} = $at;

    # Split by days & times
    my @wdt_blocks = ();
    while ($at =~ /([a-z\-]{3,18}(\[([0-9\-:,;]+|none|no|off)\])?)/ig) {
        push @wdt_blocks, _parse_wdt($1);
    }
    $self->{calendar}{$chname} = [@wdt_blocks];

    return $self;
}
sub check {
    my $self = shift;
    my $chname = shift || "default";
    my $test = shift || time();

    # Exists
    return 1 unless exists $self->{calendar}{$chname}; # No calendar - no limits
    my $calendar = array($self->{calendar}, $chname);
    return 0 if is_void($calendar); # No allow intervals in the calendar - denied

    # Get test values
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($test);
    my $t = $hour*60*60 + $min*60 + $sec;

    # Check
    my $allow = 0; # denied by default
    foreach my $int (@$calendar) {
        next unless is_hash($int);
        my $sec = $int->{$wday};
        next unless $sec && is_array($sec);
        my ($s, $f) = (($sec->[0] || 0), ($sec->[1] || 0));
        next unless $s+$f;
        if (($t >= $s and $t <= $f) || ($t >= $f and $t <= $s)) {
            $allow++;
            next;
        }
    }
    return $allow;
}

sub _parse_wdt { # parse week day blocks
    my $wdtin = shift;
    $wdtin =~ /([a-z\-]{3,18})(\[([0-9\-:,;]+|none|no|off)\])?/;
    my $wd = $1;
    my $t = $2 || SFT_DEFAULT;
       $t = '[off]' if $t =~ /\[\-+\]/;

    # Resolve week days (wd)
    my %dw_aliases = %{DAYS_ALIASES()};
    my %dw_map; my $i = 0;
    for (@{DAYS_OF_WEEK_S()}) {
        $dw_map{$_} = $i++;
    }

    #print App::MonM::Util::explain(\%dw_map);
    my @wdts;
    my @pt = _parse_t($t);
    if ($wd =~ /^[a-z]{3,9}$/) {
        $wd = $dw_aliases{$wd} if $dw_aliases{$wd};
        return () unless exists $dw_map{$wd};
        for (@pt) {
            push @wdts, {$dw_map{$wd} => $_};
        }
    } elsif ($wd =~ /([a-z]{3,9})[\-]+([a-z]{3,9})/) {
        my ($sd, $fd) = ($1, $2);
        $sd = $dw_aliases{$sd} if $dw_aliases{$sd};
        $fd = $dw_aliases{$fd} if $dw_aliases{$fd};
        return () unless exists $dw_map{$sd} and exists $dw_map{$fd};
        #print ">>$dw_map{$sd} -- $dw_map{$fd}\n";
        my $mx = 7; # Max days per wd-interval
        my $start_flag = 0;
        foreach my $wdi (0..6,0..6) { # 2 weeks!!
            # Start def
            $start_flag = 1 if !$start_flag && ($dw_map{$sd} == $wdi);
            next unless $start_flag;
            # only 7 days!
            next if $mx-- <= 0;
            # Proc
            #print ">>cnt=$mx; wdi=$wdi\n";
            for (@pt) {
                push @wdts, {$wdi => $_};
            }
            # Finish def
            last if $dw_map{$fd} == $wdi;
        }
    }
    return (@wdts);
}
sub _parse_t { # parse time sections
    my $tin = shift;
    my @ret = ();
    while ($tin =~ /([0-9\-:]+|none|no|off)/g) {
        my ($s,$f) = (_parse_p($1));
        push @ret, [$s, $f] if $s || $f;
    }
    return @ret;
}
sub _parse_p { # parse time intervals (periods)
    my $period = shift;
    return (0,0) unless defined $period;
    my $start = OFFSET_START;   # 00:00
    my $finish = OFFSET_FINISH; # 23:59
    if ($period =~ /^\-+$/) { # -
        return (0,0);
    } elsif ($period =~ /none|no|off/i) {
        return (0,0);
    } elsif ($period =~ /(\d{1,2})\s*\:\s*(\d{1,2})\s*\-+\s*(\d{1,2})\s*\:\s*(\d{1,2})/) { # 00:00-23:59
        my ($sh,$sm,$fh,$fm) = ($1,$2,$3,$4);
        $start = $sh*60*60 + $sm*60;
        $finish = $fh*60*60 + $fm*60;
    } elsif ($period =~ /(\d{1,2})\s*\-+\s*(\d{1,2})\s*\:\s*(\d{1,2})/) { # 00-23:59
        my ($sh,$fh,$fm) = ($1,$2,$3);
        $start = $sh*60*60;
        $finish = $fh*60*60 + $fm*60;
    } elsif ($period =~ /(\d{1,2})\s*\-+\s*(\d{1,2})/) { # 00-23
        my ($sh,$fh) = ($1,$2);
        $start = $sh*60*60;
        $finish = $fh*60*60;
    } else { # Errors
        return (0,0);
    }

    $start = OFFSET_START if $start < OFFSET_START or $start > OFFSET_FINISH;
    $finish = OFFSET_FINISH if $finish < OFFSET_START or $finish > OFFSET_FINISH;
    return ($start, $finish);
}

1;

__END__
