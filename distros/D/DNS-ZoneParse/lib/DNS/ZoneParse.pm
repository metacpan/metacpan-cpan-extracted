# DNS::ZoneParse
# Parse and Manipulate DNS Zonefiles
package DNS::ZoneParse;

use 5.006;
use Storable 'dclone';
use POSIX 'strftime';
use File::Basename;
use vars qw($VERSION);
use strict;
use Carp;

# It makes everyone's life easier if you double-escape the backslash, and only
# the backslash, here.
my @ESCAPABLE_CHARACTERS = qw/ ; " \\\\ /;

my $rr_class             = qr/(?:IN|HS|CH)/i;
my $rr_ttl               = qr/(?:\d+[wdhms]?)+/i;

$VERSION = '1.10';
my (
    %dns_id,  %dns_soa, %dns_ns,  %dns_a,     %dns_cname, %dns_mx, %dns_txt,
    %dns_ptr, %dns_a4,  %dns_srv, %dns_hinfo, %dns_rp,    %dns_loc,
    %dns_generate,
    %dns_last_name, %dns_last_origin, %dns_last_class, %dns_last_ttl,
    %dns_found_origins, %unparseable_line_callback, %last_parse_error_count,
);

my %possibly_quoted = map { $_ => undef } qw/ os cpu text mbox /;

sub new {
    my $class = shift;
    my $file = shift;
    my $origin = shift;
    my $unparseable_callback = shift;
    my $self = bless [], $class;

    if ( ref $unparseable_callback eq 'CODE' ) {
        $unparseable_line_callback{$self} = $unparseable_callback;
    }

    $self->_initialize();
    $self->_load_file( $file, $origin ) if $file;
    return $self;
}

sub on_unparseable_line {
    my $self = shift;
    my $arg = shift;
    if ( !defined $arg ) {
        return $unparseable_line_callback{$self};
    } elsif ( ref $arg eq 'CODE' ) {
        my $old = $unparseable_line_callback{$self};
        $unparseable_line_callback{$self} = $arg;
        return $old;
    } else {
        return undef;
    }
}

sub last_parse_error_count {
    my $self = shift;
    return $last_parse_error_count{$self};
}

sub DESTROY {
    my $self = shift;
    delete $dns_soa{$self};
    delete $dns_ns{$self};
    delete $dns_a{$self};
    delete $dns_cname{$self};
    delete $dns_mx{$self};
    delete $dns_txt{$self};
    delete $dns_ptr{$self};
    delete $dns_a4{$self};
    delete $dns_srv{$self};
    delete $dns_hinfo{$self};
    delete $dns_rp{$self};
    delete $dns_loc{$self};
    delete $dns_id{$self};
    delete $dns_generate{$self};
    delete $dns_last_name{$self};
    delete $dns_last_origin{$self};
    delete $dns_last_ttl{$self};
    delete $dns_last_class{$self};
    delete $dns_found_origins{$self};
    delete $unparseable_line_callback{$self};
    delete $last_parse_error_count{$self};
}

sub AUTOLOAD {
    my $self = shift;
    ( my $method = $DNS::ZoneParse::AUTOLOAD ) =~ s/.*:://;

    my $rv =
       $method eq 'soa'      ? $dns_soa{$self}
     : $method eq 'ns'       ? $dns_ns{$self}
     : $method eq 'a'        ? $dns_a{$self}
     : $method eq 'cname'    ? $dns_cname{$self}
     : $method eq 'mx'       ? $dns_mx{$self}
     : $method eq 'txt'      ? $dns_txt{$self}
     : $method eq 'ptr'      ? $dns_ptr{$self}
     : $method eq 'aaaa'     ? $dns_a4{$self}
     : $method eq 'srv'      ? $dns_srv{$self}
     : $method eq 'hinfo'    ? $dns_hinfo{$self}
     : $method eq 'rp'       ? $dns_rp{$self}
     : $method eq 'loc'      ? $dns_loc{$self}
     : $method eq 'generate' ? $dns_generate{$self}
     : $method eq 'zonefile' ? $dns_id{$self}->{ZoneFile}
     : $method eq 'origin'   ? $dns_id{$self}->{Origin}
     :                         undef;

    croak "Invalid method called: $method" unless defined $rv;
    return $rv;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Public OO Methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub dump {
    # returns a HOH for use with XML modules, etc
    my $self = shift;
    return dclone( {
            SOA   => $dns_soa{$self},
            AAAA  => $dns_a4{$self},
            A     => $dns_a{$self},
            NS    => $dns_ns{$self},
            CNAME => $dns_cname{$self},
            MX    => $dns_mx{$self},
            PTR   => $dns_ptr{$self},
            TXT   => $dns_txt{$self},
            SRV   => $dns_srv{$self},
            HINFO => $dns_hinfo{$self},
            RP    => $dns_rp{$self},
            LOC   => $dns_loc{$self},
    } );
}

sub new_serial {
    my $self      = shift;
    my $incriment = shift || 0;
    my $soa       = $dns_soa{$self};
    if ( $incriment > 0 ) {
        $soa->{serial} += $incriment;
    } else {
        my $newserial = strftime( "%Y%m%d%H", localtime( time ) );
        $soa->{serial} =
         ( $newserial > $soa->{serial} )
         ? $newserial
         : $soa->{serial} + 1;
    }
    return $soa->{serial};
}

sub output {
    my $self     = shift;
    my $zone_ttl = $dns_soa{$self}{ttl} ? "\$TTL $dns_soa{$self}{ttl}" : '';
    my $output   = '';
    $output .= <<ZONEHEADER1;
;
;  Database file $dns_id{$self}->{ZoneFile} for $dns_id{$self}->{Origin} zone.
;	Zone version: $dns_soa{$self}->{serial}
;
ZONEHEADER1

    if ( $dns_soa{$self}->{'ORIGIN'} ne $dns_soa{$self}->{'origin'} ) {
        $output .= "\n\$ORIGIN $dns_soa{$self}->{'ORIGIN'}\n\n";
    }

    $output .= <<ZONEHEADER2;

$zone_ttl
$dns_soa{$self}->{origin}		$dns_soa{$self}->{ttl}	IN  SOA  $dns_soa{$self}->{primary} $dns_soa{$self}->{email} (
				$dns_soa{$self}->{serial}	; serial number
				$dns_soa{$self}->{refresh}	; refresh
				$dns_soa{$self}->{retry}	; retry
				$dns_soa{$self}->{expire}	; expire
				$dns_soa{$self}->{minimumTTL}	; minimum TTL
				)
;
; Zone NS Records
;

ZONEHEADER2

    my @origins_to_process = grep {
        if ( $_ eq $dns_soa{$self}->{'ORIGIN'} ) {
            0;
        } else {
            1;
        }
    } keys %{ $dns_found_origins{$self} };
    unshift @origins_to_process, $dns_soa{$self}->{'ORIGIN'};

    foreach my $process_this_origin ( @origins_to_process ) {
        if ( $process_this_origin ne $dns_soa{$self}->{'ORIGIN'} ) {
            $output .= "\n\;\n\; $process_this_origin records\n\;\n\n";
            $output .= "\$ORIGIN $process_this_origin\n\n";
        }

    foreach my $o ( @{ $dns_ns{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	NS	$o->{host}\n";
    }

    foreach my $o ( @{ $dns_mx{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	MX	$o->{priority} $o->{host}\n";
    }

    foreach my $o ( @{ $dns_a{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	A	$o->{host}\n";
    }
    foreach my $o ( @{ $dns_cname{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	CNAME	$o->{host}\n";
    }
    foreach my $o ( @{ $dns_a4{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	AAAA	$o->{host}\n";
    }
    foreach my $o ( @{ $dns_txt{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= qq[$o->{name}	$o->{ttl} $o->{class} TXT	"$o->{text}"\n];
    }
    foreach my $o ( @{ $dns_ptr{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	PTR		$o->{host}\n";
    }
    foreach my $o ( @{ $dns_srv{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	SRV	$o->{priority}	$o->{weight}	$o->{port}	$o->{host}\n";
    }
    foreach my $o ( @{ $dns_hinfo{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	HINFO	$o->{cpu}   $o->{os}\n";
    }
    foreach my $o ( @{ $dns_rp{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	RP	$o->{mbox}  $o->{text}\n";
    }
    foreach my $o ( @{ $dns_loc{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "$o->{name}	$o->{ttl}	$o->{class}	LOC	$o->{d1}	$o->{m1}	$o->{s1}	$o->{NorS}	";
        $output .= "$o->{d2}	$o->{m2}	$o->{s2}	$o->{EorW}	";
        $output .= "$o->{alt}	$o->{siz}	$o->{hp}	$o->{vp}\n";
    }
    foreach my $o ( @{ $dns_generate{$self} } ) {
        next unless defined $o;
        next unless $o->{'ORIGIN'} eq $process_this_origin;
        $self->_escape_chars( $o );
        $output .= "\$GENERATE $o->{range}  $o->{lhs}  $o->{ttl}  $o->{class}  $o->{type}  $o->{rhs}\n";
    }

    }

    return $output;
}

sub fqname {
    my ( $self, $record_ref ) = @_;

    # Is this an SOA record?
    if ( $record_ref->{'origin'} ) {
        if ( ( $record_ref->{'origin'} eq '@' ) || ( $record_ref->{'origin'} =~ /\.$/ ) ) {
            return $record_ref->{'ORIGIN'};
        } else {
            if ( $record_ref->{'ORIGIN'} =~ /^\./ ) {
                return $record_ref->{'origin'} . $record_ref->{'ORIGIN'};
            }
            return $record_ref->{'origin'} . '.' . $record_ref->{'ORIGIN'};
        }
    } else {
        if ( $record_ref->{'name'} eq '@' ) {
            return $record_ref->{'ORIGIN'};
        } else {
            if ( $record_ref->{'ORIGIN'} =~ /^\./ ) {
                return $record_ref->{'name'} . $record_ref->{'ORIGIN'};
            }
            return $record_ref->{'name'} . '.' . $record_ref->{'ORIGIN'};
        }
    }
}

sub ttl_to_int {
    my ( $self, $t ) = @_;

    # Passed in nothing? Huh?
    if ( !$t ) {
        return 0;
    }

    # If it's all digits already, just pass it right back.
    if ( $t =~ /^\d+$/ ) {
        return $t;
    }

    # If it doesn't look like a valid TTL string, error. We know, because of
    # the above test, that it's not just a number, if we got this far.
    if ( $t !~ /^(?:\d+[WDHMS])+$/i ) {
        die "Unknown TTL string format!\n";
    }
    $t = uc( $t );

    my $r;
    my %ttl;
    while ( $t =~ /(\d+)([WDHMS])/g ) {
        # Did we already see this modifier?
        if ( defined $ttl{ $2 } ) { die "Invalid TTL!\n"; }
        $ttl{ $2 } = $1;
    }

    foreach my $m ( qw/ W D H M S / ) {
        if ( !exists $ttl{ $m } ) { $ttl{ $m } = 0; }
    }
 
    $r = $ttl{'W'} * 7;
    $r = ( $r + $ttl{'D'} ) * 24;
    $r = ( $r + $ttl{'H'} ) * 60;
    $r = ( $r + $ttl{'M'} ) * 60;
    $r = ( $r + $ttl{'S'} );

    die unless $r == $ttl{'S'} + 60 * ( $ttl{'M'} + 60 * ( $ttl{'H'} + 24 * ( $ttl{'D'} + 7 * $ttl{'W'} ) ) );
    return $r;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Private Methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _initialize {
    my $self = shift;
    $dns_id{$self}        = {};
    $dns_soa{$self}       = {};
    $dns_ns{$self}        = [];
    $dns_a{$self}         = [];
    $dns_cname{$self}     = [];
    $dns_mx{$self}        = [];
    $dns_txt{$self}       = [];
    $dns_ptr{$self}       = [];
    $dns_a4{$self}        = [];
    $dns_srv{$self}       = [];
    $dns_hinfo{$self}     = [];
    $dns_rp{$self}        = [];
    $dns_loc{$self}       = [];
    $dns_generate{$self}  = [];
    $dns_last_name{$self} = undef;
    $dns_last_origin{$self} = undef;
    $dns_last_ttl{$self} = undef;
    $dns_last_class{$self} = 'IN'; # Class defaults to IN.
    $dns_found_origins{$self} = {};
    $last_parse_error_count{$self} = 0;
    return 1;
}

sub _load_file {
    my ( $self, $zonefile, $origin ) = @_;
    my $zone_contents;
    if ( ref( $zonefile ) eq 'SCALAR' ) {
        $zone_contents = $$zonefile;
    } else {
        my $inZONE;
        if ( open( $inZONE, '<', $zonefile ) ) {
            local $/;
            $zone_contents = <$inZONE>;
            close( $inZONE );
        } else {
            croak qq[DNS::ZoneParse Could not open input file: "$zonefile":$!];
        }
    }
    if ( $self->_parse( $zonefile, $zone_contents, $origin ) ) { return 1; }
}

sub _parse {
    # Support IsAlnum for unicode names.
    use utf8;
    my ( $self, $zonefile, $contents, $origin ) = @_;
    $self->_initialize();

    # Here's how we auto-detect the zonefile and origin. Note, the zonefile is
    # only used to print out a comment in the file, so its okay if we're
    # inaccurate. First, prefer what the user configures. Next, try to read a
    # comment we would have written if we wrote the file out in the past.
    # Finally, pick up any SOA or $ORIGIN statements present in the file.
    if ( ref( $zonefile ) eq 'SCALAR' ) { $zonefile = ''; }

    if ( !$origin || !$zonefile ) {
        # I don't know why the ( dns)? capture is there, perhaps at one point
        # this module wrote a different header comment? I'll leave it as to
        # preserve whatever backwards compatability this affords us...
        $contents =~ /^\s*;\s*Database file (\S+)( dns)? for (\S+) zone/im;
        if ( !$origin && $3 ) { $origin = $3; }
        if ( !$zonefile && $1 ) { $zonefile = $1; }
    }

    if ( $zonefile ) {
        $zonefile = basename( $zonefile );
    } else {
        $zonefile = 'unknown';
    }

    if ( $origin ) {
        # A trite way of insuring there is a trailing dot on the origin. It's
        # really important you supply a trailing . in an origin when you mean
        # it.
        $origin =~ s/([^.])$/$1./;
    } else {
        $origin = '';
    }

    $dns_id{$self} = {
        ZoneFile => $zonefile,
        Origin   => $origin,
    };

    my $records = $self->_clean_records( $contents );

    # Everything valid in the name, except the '.' character.
    my $valid_name_start_char = q/(?:[\p{IsAlnum}\@_\-*:+=!#$%^&`~,\[\]{}|?'\/]|/
     . join( '|', map { "\\\\$_" } @ESCAPABLE_CHARACTERS ) . ')';

    # The above, but adds the literal '.' character.
    my $valid_name_char        = qr/(?:$valid_name_start_char|[\.\\])/o;
    my $valid_txt_char         = qr/\S+/o;
    my $valid_quoted_txt_char  = qr/.+/o;
    # Like the above, but adds whitespace (space and tabs) too.
    my $valid_quoted_name_char = qr/(?:$valid_name_start_char|[. ;\t()\\])/o;
    my $valid_name             = qr/$valid_name_start_char$valid_name_char*/o;
    my $valid_ip6              = qr/[\@a-zA-Z_\-\.0-9\*:]+/;
    my $rr_type                = qr/\b(?:NS|A|CNAME)\b/i;
    #my $ttl_cls                = qr/(?:($rr_ttl)\s)?(?:($rr_class)\s)?/o;
    my $ttl_cls                = qr/(?:\b((?:$rr_ttl)|(?:$rr_class))\s)?(?:\b((?:$rr_class)|(?:$rr_ttl))\s)?/o;
    my $generate_range         = qr{\d+\-\d+(?:/\d+)?};
    my $last_good_line;

    foreach ( @$records ) {
        #TRACE( "parsing line <$_>" );

        # It's faster to skip blank lines here than to remove them inside
        # _clean_records.
        next if /^\s*$/;

        # The below is inside of an eval block to catch possible errors
        # found inside _massage and propagate them up properly.
        eval {
        local $SIG{__DIE__} = 'DEFAULT';

        if (
            /^($valid_name)? \s+         # host
              $ttl_cls                   # ttl & class
              ($rr_type) \s              # record type
              ($valid_name)              # record data
             /ixo
         )
        {
            my ( $name, $ttl, $class, $type, $host ) = ( $1, $2, $3, $4, $5 );
            my $dns_thing =
               uc $type eq 'NS' ? $dns_ns{$self}
             : uc $type eq 'A'  ? $dns_a{$self}
             :                    $dns_cname{$self};
            push @$dns_thing,
             $self->_massage( {
                    name  => $name,
                    class => $class,
                    host  => $host,
                    ttl   => $ttl,
             } );
        } elsif (
            /^($valid_name)? \s+
                $ttl_cls
                AAAA \s
                ($valid_ip6)
                /ixo
         )
        {
            my ( $name, $ttl, $class, $host ) = ( $1, $2, $3, $4 );
            push @{ $dns_a4{$self} },
             $self->_massage( {
                    name  => $name,
                    class => $class,
                    host  => $host,
                    ttl   => $ttl,
             } );
        } elsif (
            /^($valid_name)? \s+
                 $ttl_cls
                 MX \s+
                 (\d+) \s+
                 ($valid_name_char+)
               /ixo
         )
        {
            # host ttl class mx pri dest
            my ( $name, $ttl, $class, $pri, $host ) = ( $1, $2, $3, $4, $5 );
            push @{ $dns_mx{$self} },
             $self->_massage( {
                    name     => $name,
                    priority => $pri,
                    host     => $host,
                    ttl      => $ttl,
                    class    => $class,
             } );
        } elsif (
            /^($valid_name)? \s+
                 $ttl_cls
                 SRV \s+
                 (\d+) \s+
                 (\d+) \s+
                 (\d+) \s+
                 ($valid_name)
               /ixo
         )
        {
            # host ttl class mx priority weight port dest
            my ( $name, $ttl, $class, $pri, $weight, $port, $host ) = ( $1, $2, $3, $4, $5, $6, $7 );
            push @{ $dns_srv{$self} },
             $self->_massage( {
                    name     => $name,
                    priority => $pri,
                    weight   => $weight,
                    port     => $port,
                    host     => $host,
                    ttl      => $ttl,
                    class    => $class,
             } );
        } elsif (
            /^($valid_name) \s+
                 $ttl_cls
                 SOA \s+
                 ($valid_name) \s+
                 ($valid_name) \s+
                 ($rr_ttl) \s+
                 ($rr_ttl) \s+
                 ($rr_ttl) \s+
                 ($rr_ttl) \s+
                 ($rr_ttl)
               /ixo
         )
        {
            # SOA record
            $dns_soa{$self} = $self->_massage( {
                    origin     => $1,
                    ttl        => $2,
                    class      => $3,
                    primary    => $4,
                    email      => $5,
                    serial     => $6,
                    refresh    => $7,
                    retry      => $8,
                    expire     => $9,
                    minimumTTL => $10,
            } );

            if ( !$origin ) {
                $origin = $1;
                $dns_id{$self} = {
                    ZoneFile => $zonefile,
                    Origin   => $origin,
                };
            }

        } elsif (
            /^($valid_name)? \s+
                $ttl_cls
                PTR \s+
                ($valid_name)
               /ixo
         )
        {
            # PTR
            push @{ $dns_ptr{$self} },
             $self->_massage( {
                    name  => $1,
                    class => $3,
                    ttl   => $2,
                    host  => $4,
             } );
        } elsif (
            /($valid_name)? \s+
                $ttl_cls
                TXT \s+
                ("$valid_quoted_txt_char*(?<!\\)"|$valid_txt_char+)
            /ixo
        ) {
            push @{ $dns_txt{$self} },
             $self->_massage( {
                    name  => $1,
                    ttl   => $2,
                    class => $3,
                    text  => $4,
             } );
        } elsif (
            /^\s*\$TTL \s+
                ($rr_ttl)
            /ixo
        ) {
            if ( !defined $dns_soa{$self} ) {
                $dns_soa{$self}->{ttl} = $1;
            }
            $dns_last_ttl{$self} = $1;
        } elsif (
            /^($valid_name)? \s+
                 $ttl_cls
                 HINFO \s+
                 ("$valid_quoted_txt_char*(?<!\\)"|$valid_txt_char+) \s+
                 ("$valid_quoted_txt_char*(?<!\\)"|$valid_txt_char+)
               /ixo
         )
        {
            push @{ $dns_hinfo{$self} },
             $self->_massage( {
                    name  => $1,
                    ttl   => $2,
                    class => $3,
                    cpu   => $4,
                    os    => $5,
             } );
        } elsif (
            /^($valid_name)? \s+
                 $ttl_cls
                 RP \s+
                 ($valid_name_char+) \s+
                 ($valid_name_char+)
               /ixo
         )
        {
            push @{ $dns_rp{$self} },
             $self->_massage( {
                    name  => $1,
                    ttl   => $2,
                    class => $3,
                    mbox  => $4,
                    text  => $5,
             } );
        } elsif (
            /^($valid_name)? \s+
                 $ttl_cls
                 LOC \s+
                 (-?[\d\.]+) \s*
                 ([\d\.]*) \s*
                 ([\d\.]*) \s+
                 ([NS]) \s+
                 (-?[\d\.]+) \s*
                 ([\d\.]*) \s*
                 ([\d\.]*) \s+
                 ([EW]) \s*
                 (-?[\d\.]*m?) \s*
                 ([\d\.]*m?) \s*
                 ([\d\.]*m?) \s*
                 ([\d\.]*m?)
               /ixo
         )
        {
            push @{ $dns_loc{$self} },
             $self->_massage( {
                    name  => $1,
                    ttl   => $2,
                    class => $3,
                    d1    => $4,
                    m1    => $5,
                    s1    => $6,
                    NorS  => $7,
                    d2    => $8,
                    m2    => $9,
                    s2    => $10,
                    EorW  => $11,
                    alt   => $12,
                    siz   => $13,
                    hp    => $14,
                    vp    => $15,
             } );

        } elsif ( /^\s*\$ORIGIN\s+($valid_name_char+)/io ) {
            my $new_origin = $1;
            # We could track each origins origin, all the way down, but what
            # would that get us? Madness, surely.
            if ( $new_origin !~ /\.$/ ) {
                if ( $dns_last_origin{$self} =~ /^\./ ) {
                    $new_origin .= $dns_last_origin{$self};
                } else {
                    $new_origin .= '.' . $dns_last_origin{$self};
                }
            }
            $dns_last_origin{$self} = $new_origin;
            $dns_found_origins{$self}->{ $new_origin } = 1;

        } elsif ( /^ \s* \$GENERATE \s+
                   ($generate_range) \s+     # range
                   ($valid_name) \s+         # lhs
                   (?:($rr_ttl) \s+)?        # ttl
                   (?:($rr_class) \s+)?      # class
                   ([a-z]+) \s+              # type
                   ($valid_name)             # rhs
                 /ixo
         )
        {
            push @{ $dns_generate{$self} },
             $self->_massage( {
                    range  => $1,
                    lhs    => $2,
                    ttl    => $3,
                    class  => $4,
                    type   => $5,
                    rhs    => $6,
            } );

        } else {
            die "Unknown record type\n";
        }

        }; # End of eval block.
        if ( $@ ) {
            chomp $@;
            $last_parse_error_count{$self}++;
            if ( $unparseable_line_callback{$self} ) {
                $unparseable_line_callback{$self}->( $self, $_, $@, $last_good_line );
            } else {
                carp "Unparseable line ($@)\n  $_\n";
            }
        } else {
            $last_good_line = $_;
        }
    }
    return 1;
}

sub _clean_records {
    my $self = shift;
    my $zone = shift;
    my $x = 0;
    my $in_comment = 0;
    my $in_quote = 0;
    my $in_concat = 0;
    my $last_char = '';
    my $next_is_escaped = 0;
    my @lines;

    $zone =~ s/\r\n/\n/sg;
    $zone =~ s{[ \t]+}{ }g;     # Collapse whitespace, turn TABs to spaces.

    # Trim comments, handle parentheses and some escape sequences.
    while (1) {
        my $c = substr( $zone, $x, 1 );

        # If we're not in a comment then process parentheses, braces, comment
        # tags, and quotes. If not, just look for the newline.
        if ( !$in_comment ) {
            if ( !$next_is_escaped ) {
                if ( $c eq '"' ) {
                    $in_quote = !$in_quote;
                } elsif ( $c eq '\\' ) {
                    $next_is_escaped = 1;
                } elsif ( !$in_quote ) {
                    if ( $c eq ';' ) {
                        $in_comment = 1;
                        substr( $zone, $x, 1 ) = '';
                        $x--;
                    } elsif ( $c eq '(' ) {
                        substr( $zone, $x, 1 ) = ' ';
                        $in_concat++;
                    } elsif ( ( $in_concat ) && ( $c eq ')' ) ) {
                        substr( $zone, $x, 1 ) = ' ';
                        $in_concat--;
                    }
                }
            } else {
                $next_is_escaped = 0;
            }
        } elsif ( $c ne "\n" ) {
            substr( $zone, $x, 1 ) = '';
            $x--;
        }
        if ( $c eq "\n" ) {
            $in_comment = 0;
            if ( $in_concat ) {
                substr( $zone, $x, 1 ) = '';
                $x--;
            }
        }
        $x++;
        if ( $x >= length( $zone ) ) { last; }
        $last_char = $c;
    }

    return [ split( /\n/, $zone ) ];
}

sub _massage {
    my ( $self, $record ) = @_;

    foreach my $r ( keys %$record ) {
        if ( !defined $record->{$r} ) {
            $record->{$r} = '';
            next;
        }
        if ( exists $possibly_quoted{$r} ) {
            ( $record->{$r} =~ s/^"// ) && ( $record->{$r} =~ s/"$// );
        }

        # We return email addresses just as they are in the file... for better
        # or worse (mostly for backwards compatability reasons).
        if ( $r ne 'email' && $r ne 'mbox' ) {
            while ( $record->{$r} =~ m/\\/g ) {
                my $pos = pos( $record->{$r} );
                my $escape_char = substr( $record->{$r}, $pos, 1 );
                if ( $escape_char =~ /\d/ ) {
                    $escape_char = substr( $record->{$r}, $pos, 3 );
                    # Max oct value that converts to 255 in dec.
                    if ( ( $escape_char =~ /^\d{3}$/ ) && ( $escape_char <= 377 ) ) {
                        substr( $record->{$r}, $pos - 1, 4 ) = chr( oct( $escape_char ) );
                    } else {
                        die "Invalid escape sequence\n";
                    }
                } else {
                    # Not followed by a digit, so just remove the backslash.
                    # Like BIND does...
                    substr( $record->{$r}, $pos - 1, 2 ) = $escape_char;
                }
                pos( $record->{$r} ) = $pos;
            }
        }
    }

    if (
        ( ( $record->{'class'} =~ $rr_class ) && ( $record->{'ttl'} =~ $rr_class ) )
        ||
        ( ( $record->{'class'} =~ $rr_ttl   ) && ( $record->{'ttl'} =~ $rr_ttl   ) )
    ) {
        die "Invalid ttl/class values!\n";
    };

    if ( ( $record->{'class'} =~ $rr_ttl ) || ( $record->{'ttl'} =~ $rr_class ) ) {
        my $x = $record->{'class'};
        $record->{'class'} = $record->{'ttl'};
        $record->{'ttl'} = $x;
    }

    if ( $record->{'class'} ) {
        $record->{'class'} = uc $record->{'class'};
        $dns_last_class{$self} = $record->{'class'};
    } else {
        # This case should never happen, because we supply a default.
        #if ( !defined $dns_last_class{$self} ) {
        #    die "No class defined!\n";
        #}
        $record->{'class'} = $dns_last_class{$self};
    }

    # This is silly, but we don't know what type of record we are massaging at
    # this point. We can detect an SOA record because it's the only type that
    # supplies this value, which is what we need to do here to properly set
    # the owner.
    if ( exists $record->{'minimumTTL'} ) {
        $dns_last_name{$self} = $record->{'origin'};

        # In the case of an SOA record, we fall back to the minimumTTL value
        # when a TTL isn't otherwise specified. This is what BIND does.
        if ( $record->{'ttl'} ) {
            $record->{'ttl'} = $dns_last_ttl{$self} = uc( $record->{'ttl'} );
        } else {
            if ( $dns_last_ttl{$self} ) {
                $record->{'ttl'} = $dns_last_ttl{$self};
            } else {
                $record->{'ttl'} = $dns_last_ttl{$self} = uc( $record->{'minimumTTL'} );
            }
        }

        if ( $record->{'origin'} eq '@' ) {
            # We encountered a @ SOA line without an origin directive above
            # it, so we will try and guess the origin.
            if ( !$dns_last_origin{$self} ) {
                if ( !$dns_id{$self}->{'Origin'} ) {
                    die "Unknown origin\n";
                }
                $dns_last_origin{$self} = $dns_id{$self}->{'Origin'};
            }
            $record->{'ORIGIN'} = $dns_last_origin{$self};
        } else {
            my $new_origin = $record->{'origin'};

            # Similar to above, it's origins all the way down. Don't bother
            # tracking each separately, just collapse them all into the
            # current origin.
            if ( $new_origin =~ /\.$/ ) {
                # If no one has set an $ORIGIN before, we need to use the SOA
                # line to do it.
                if ( !$dns_last_origin{$self} ) {
                    $dns_last_origin{$self} = $new_origin;
                }
            }
            # Now we have a valid ORIGIN for this SOA, so assign it.
            $record->{'ORIGIN'} = $dns_last_origin{$self};
        }
        # Alright, make sure we know we found this origin.
        $dns_found_origins{$self}->{ $record->{'ORIGIN'} } = 1;

    # Not an SOA record.
    } else {

        # The silliness continues: only $GENERATE directives have a lhs, and
        # don't need a 'name'.
        if ( !exists $record->{'lhs'} ) {
            if ( $record->{'name'} ) {
                $dns_last_name{$self} = $record->{'name'};
            } else {
                #TRACE( "Record has no name, using last name" );
                if ( !$dns_last_name{$self} ) {
                    die "No current owner name\n";
                }
                $record->{'name'} = $dns_last_name{$self};
            }
        }

        if ( !$dns_last_origin{$self} ) {
            die "Unknown origin\n";
        } else {
            $record->{'ORIGIN'} = $dns_last_origin{$self};
        }

        # Nothing special about TTL parsing for non-SOA records.
        if ( $record->{'ttl'} ) {
            $record->{'ttl'} = $dns_last_ttl{$self} = uc( $record->{'ttl'} );
        } else {
            if ( !defined $dns_last_ttl{$self} ) {
                die "No ttl defined!\n";
            }
            $record->{'ttl'} = $dns_last_ttl{$self};
        }
    }

    #DUMP( "Record parsed", $record );
    return $record;
}

sub _escape_chars {
    my $self     = shift;
    my $clean_me = shift;
    local $" = '|';

    foreach my $k ( keys( %{$clean_me} ) ) {
        $clean_me->{$k} =~ s/(@ESCAPABLE_CHARACTERS)/\\$1/g;
    }
}

sub TRACE { 0 && print @_, $/ }
sub DUMP { 0 && require Data::Dumper && TRACE( shift, Data::Dumper::Dumper( @_ ) ) }

1;
__END__

=head1 NAME

DNS::ZoneParse - Parse and manipulate DNS Zone Files.

=head1 SYNOPSIS

    use DNS::ZoneParse;
    
    my $zonefile = DNS::ZoneParse->new("/path/to/dns/zonefile.db", $origin);
    
    # Get a reference to the MX records
    my $mx = $zonefile->mx;
    
    # Change the first mailserver on the list
    $mx->[0] = { host => 'mail.localhost.com',
                 priority => 10,
                 name => '@' };
    
    # update the serial number
    $zonefile->new_serial();
    
    # write the new zone file to disk 
    my $newzone;
    open($newzone, '>', '/path/to/dns/zonefile.db') or die "error";
    print $newzone $zonefile->output();
    close $newzone;

=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

Win32 users substitute "make" with "nmake" or equivalent. 
nmake is available at http://download.microsoft.com/download/vc15/Patch/1.52/W95/EN-US/Nmake15.exe

=head1 DESCRIPTION

This module will parse a Zone File and put all the Resource Records (RRs)
into an anonymous hash structure. Various record types are supported, see the
L<methods> section for details. It could be useful for maintaining DNS zones,
or for transferring DNS zones to other servers. If you want to generate an
XML-friendly version of your zone files, it is easy to use XML::Simple with
this module once you have parsed the zone file.

DNS::ZoneParse scans the DNS zone file - removes comments and seperates
the file into its constituent records. It then parses each record and
stores the records internally. See below for information on the accessor
methods.


=head2 METHODS

=over 4

=item new

This creates the DNS::ZoneParse object and loads the zone file.

Example:
    my $zonefile = DNS::ZoneParse->new("/path/to/zonefile.db");

You can also initialise the object with the contents of a file:
    my $zonefile = DNS::ZoneParse->new( \$zone_contents );

You can pass a second, optional parameter to the constructor to supply an
C<$origin> if none can be found in the zone file.

    my $zonefile = DNS::ZoneParse->new( \$zone_contents, $origin );

You can pass a third, optional parameter to the constructor to supply a
callback which will be called whenever an unparsable line is encountered in
the zone file. See C<on_unparseable_line> for details on this parameter and
how errors are handled when parsing zone files.

If you plan to pass a on_unparseable_line callback but do not wish to specify
an C<$origin>, pass 'undef' as the C<$origin> parameter.

=item a(), cname(), srv(), mx(), ns(), ptr(), txt(), hinfo(), rp(), loc()

These methods return references to the resource records. For example:

    my $mx = $zonefile->mx;

Returns the mx records in an array reference.

All records (except SOA) have the following properties: 'ttl', 'class',
'host', 'name', 'ORIGIN'.

MX records also have a 'priority' property.

SRV records also have 'priority', 'weight' and 'port' properties.

TXT records also have a 'text' property representing the record's 'txt-data'
descriptive text.

HINFO records also have 'cpu' and 'os' properties.

RP records also have 'mbox' and 'text' properties.

LOC records also have 'd1', 'm1', 's1', 'NorS', 'd2', 'm2', 's2', 'EorW',
'alt', 'siz', 'hp', and 'vp', as per RFC 1876.

If there are no records of a given type in the zone, the call will croak with
an error message about an invalid method. (This is not an ideal behavior, but
has been kept for backwards compatibility.)

The 'ORIGIN' property is the fully-qualified origin of the record. See
L<fqname> for details on constructing a fully qualified domain name. Note: for
SOA records, the 'ORIGIN' will match the 'origin' property when the SOA record
is specified as fully qualified.

=item soa()

Returns a hash reference with the following properties:
'serial', 'origin', 'primary', 'refresh', 'retry', 'ttl', 'minimumTTL',
'email', 'expire', 'class', 'ORIGIN'.

The 'ORIGIN' property is returned separate from 'origin' property, though the
data may be the same. 'ORIGIN' represents the implicit origin for the record
while 'origin' represents the origin specified on the SOA line in the file.

If the 'origin' value is relative (that is, does not end with a '.'), the
actual zone for which the SOA line applies must be computed by concatenating
the 'origin' and 'ORIGIN' values. See L<fqname> for details. If the 'origin'
value is absolute, no computation is necessary and 'origin' is the same as
'ORIGIN'.

=item generate()

Returns an array of hashes representing $GENERATE directives present in the
zone. Note, $GENERATE directives are BIND-specific additions. They are not
expanded by DNS::ZoneParse, but users are able to access and modify these
directives. The following properties are returned:

'range', 'lhs', 'ttl', 'class', 'type', 'rhs', 'ORIGIN'.

See the BIND documentation for details on the syntax and usage of the $GENERATE
directive.

=item dump

Returns a copy of the datastructute that stores all the resource records. This
might be useful if you want to quickly transform the data into another format,
such as XML.

=item fqname

Takes a single parameter, a hash reference containing a record.

Returns the fully qualified name of this record, with a trailing '.'. In most
cases this is as simple as concatenating the 'name' and 'ORIGIN' with a '.'
unless 'name' is '@', in which case the fqname is simply the 'ORIGIN'. For
SOA records, the same process is performed on the 'origin' instead of 'name'.

Please note, fqname will not expand the right hand side of a record (ie,
CNAME, SOA, MX, etc). The user must expand these values via the above method.

=item ttl_to_int

Takes a single parameter, a string representing a valid record TTL.

Returns an integer representing the number of seconds the TTL represents.
Note, this does not take into account any leap-years, leap-seconds, DST
changes, etc. It is simply the count of the number of seconds in the specified
period of time.

=item new_serial

C<new_serial()> incriments the Zone serial number. It will generate a
date-based serial number. Or you can pass a positive number to add to the
current serial number.

Examples:

    $zonefile->new_serial(); 
            # generates a new serial number based on date:
            # YYYYmmddHH format, incriments current serial
            # by 1 if the new serial is still smaller

    $zonefile->new_serial(50);  
            # adds 50 to the original serial number

=item output

C<output()> returns the new zone file output as a string. If you wish your
output formatted differently, you can pass the output of C<dump()> to your
favourite templating module.

=item last_parse_error_count

Returns a count of the number of unparsable lines from the last time a
zone file was parsed. If no zone file has been parsed yet, returns 0.

If you want to be sure that a zone file was parsed completely and without
error, the return value of this method should be checked after the constructor
is called (or after a call to _parse).

=item on_unparseable_line

C<on_unparseable_line()> is an accessor method for the callback used when an
unparseable line is encountered while parsing a zone file. If not set,
DNS::ZoneParse will C<croak> when an unparsable line is encountered, but will
continue to parse the file. Each time an unparsable line is encountered, an
internal counter is incrememnted. See C<last_parse_error_count> for details.

The callback is passed four parameters, a reference to the DNS::ZoneParse
object which is doing the parsing, the text of the line that is unable to be
parsed, the text of the reason the line could not be parsed, and the text of
the last successfully parsed line.

If you want to abort parsing when an unparsable line is found, call C<die>
from within your callback and catch that die with an eval block around the
DNS::ZoneParse constructor (or call to _parse).

The method takes a single optional parameter, a code reference to the function
that will be called when an unparsable line is reached. Returns a reference to
the last callback. If passed an undefined value, a reference to the current
callback is returned. If passed any other value, undef is returned.

=back

=head2 EXAMPLES

This script will print the A records in a zone file, add a new A record for the
name "new" and then return the zone file.

    use strict;
    use DNS::ZoneParse;
    
    my $zonefile = DNS::ZoneParse->new("/path/to/zonefile.db");
    
    print "Current A Records\n";
    my $a_records = $zonefile->a();
    
    foreach my $record (@$a_records) {
        print "$record->{name} resolves at $record->{host}\n";
    }
    
    push (@$a_records, { name => 'new', class => 'IN',
                         host => '127.0.0.1', ttl => '' });
    
    $zonefile->new_serial();
    my $newfile = $zonefile->output();




This script will convert a DNS Zone file to an XML file using XML::Simple.


    use strict;
    use DNS::ZoneParse;
    use XML::Simple;

    my $zonefile = DNS::ZoneParse->new("/path/to/zonefile.db");

    my $new_xml = XMLout($zonefile->dump,
                         noattr => 1,
                         suppressempty => 1,
                         rootname => $zonefile->origin);

=head1 CHANGES

See F<Changes>

=head1 API

The DNS::ZoneParse API may change in future versions. At present, the parsing
is not as strict as it should be and support for C<$ORIGIN> and C<$TTL> is
quite basic. It would also be nice to support the C<INCLUDE>
statement. Furthermore, parsing large zone files with thousands of records can
use lots of memory - some people have requested a callback interface.

=head1 BUGS

I can squash more bugs with your help. Please let me know if you spot something
that doesn't work as expected.

You can report bugs via the CPAN RT:
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DNS-ZoneParse>

If possible, please provide a diff against F<t/dns-zoneparse.t> and
F<t/test-zone.db> that demonstrates the bug(s).

=head1 SEE ALSO

Other modules with similar functionality:

Net::DNS::ZoneParser, Net::DNS::ZoneFile, DNS::ZoneFile

=head1 AUTHOR

Simon Flack

=head1 MAINTENANCE

Maintainers: Mike Schilli (m@perlmeister.com), John Eaglesham (perl@8192.net).

Bug queue: http://rt.cpan.org/Public/Dist/Display.html?Name=DNS-ZoneParse

=head1 LICENSE

DNS::ZoneParse is free software which you can redistribute and/or modify under
the same terms as Perl itself.

=cut
