package Business::EDI::Spec;

use base qw/Business::EDI/;     # inherits AUTOLOAD for $self->{_permitted} keys

use strict;
use warnings;
use Carp;

our $VERSION = 0.02;

use UNIVERSAL::require;
use Data::Dumper;
use File::Find::Rule;
use File::Spec;
our $debug = 0;

our $spec_dir;       # for the whole class
our $syntax_dir;     # for the whole class
our $spec_map = {
    message   => {code => 'DMD', cache => {}, keys => [qw/code mandatory repeats    /]},
segment_group => {code => 'DMD', cache => {}, keys => [qw/code mandatory repeats    /]},
    segment   => {code => 'DSD', cache => {}, keys => [qw/pos code mandatory repeats/]},
    composite => {code => 'DCD', cache => {}, keys => [qw/pos code class def        /]},
#   codelist  => {code => 'DCL', cache => {}, keys => []},
    element   => {code => 'DED', cache => {}, },
};

my %fields = (
    edi_flavor      => 'edifact',   # someday could be x12 or something...
    spec_files      => undef,
    version_default => 'd08a',
    version         => undef,
    syntax_files    => undef,
    syntax_default => '40100',
    syntax          => undef,
    interactive     => 0,
);

# Constructors

sub new {
    my $class = shift;
    my %args;
    if (scalar(@_) == 1) {
        $args{version} = shift;
    } else {
        scalar(@_) % 2 and croak "Odd number of arguments to new() incorrect.  Use (name1 => value1) style.";
        %args = @_;
    }
    my $stuff = {_permitted => {(map {$_ => 1} keys %fields)}, %fields};
    foreach (keys %args) {
        $_ eq 'version' and next;  # special case, probably can remove
        $_ eq 'syntax'  and next;  # special case, probably can remove
        exists ($stuff->{_permitted}->{$_}) or croak "Unrecognized argument to new: $_ => $args{$_}";
    }
    my $self = bless($stuff, $class);
    my $version = lc($args{version} || $self->version || $fields{version} || $self->version_default || $fields{version_default});
    my $syntax  = lc($args{syntax } || $self->syntax  || $fields{syntax } || $self->syntax_default  || $fields{ syntax_default});
    $version eq 'default' and $version = $self->version_default || $fields{version_default};
    $syntax  eq 'default' and $syntax  = $self->syntax_default  || $fields{ syntax_default};
    $debug and warn "### Setting syntax/version $syntax/$version";
    $self->set_syntax_version($syntax) or croak "Unrecognized spec syntax '$syntax'";
    $self->set_spec_version( $version) or croak "Unrecognized spec version '$version'";
    $debug and $debug > 1 and print Dumper($self);
    return $self;
}

# We have to deal with two parallel kinds of CSV definitions: the spec version and the EDIFACT syntax
# So we have pairs of methods.

sub get_spec_dir {
    my $self = shift;
    $self->{spec_dir} and return $self->{spec_dir};
    $spec_dir         and return $spec_dir;
    my $target = 'Business/EDI/data/edifact/untdid';    # path relative to @INC.  Don't worry about filesystem oddities (see split below)
    my @dirs   = grep {-d} @INC;    # skip non-existant dirs, as in Debian default @INC (-d implies -e)
    foreach (split /\//, $target) {
        @dirs = File::Find::Rule->maxdepth(1)->name($_)->directory()->in(@dirs);
    }
    # we use serial Find's so we don't have to care about OS/filesystem variations.  And we only do it once, typcially.
    $debug and print STDERR "# get_spec_dir() found ", scalar(@dirs), " $target dirs:\n# ", join("\n# ", @dirs), "\n";
    unless (@dirs) {
        warn "Could not locate specifications directory ($target) in \@INC";
        return;
    }
    return $spec_dir = $dirs[0];
}
sub get_syntax_dir {
    my $self = shift;
    $self->{syntax_dir} and return $self->{syntax_dir};
    $syntax_dir         and return $syntax_dir;
    my $target = 'Business/EDI/data/edifact/iso9735';    # path relative to @INC.  Don't worry about filesystem oddities (see split below)
    my @dirs   = @INC;
    foreach (split /\//, $target) {
        @dirs = File::Find::Rule->maxdepth(1)->name($_)->directory()->in(@dirs);
    }
    # we use serial Find's so we don't have to care about OS/filesystem variations.  And we only do it once, typcially.
    $debug and print STDERR "# get_syntax_dir() found ", scalar(@dirs), " $target dirs:\n# ", join("\n# ", @dirs), "\n";
    unless (@dirs) {
        warn "Could not locate specifications directory ($target) in \@INC";
        return;
    }
    return $syntax_dir = $dirs[0];
}

sub set_spec_version {
    my $self = shift;
    my $code = shift or return $self->carp_error("set_spec_version: required version spec code argument not provided");
    my @files = $self->find_spec_files($code);
    unless (@files) {
        $self->error("set_spec_version: Unrecognized spec code '$code' (no csv files)");
        return;
    }
    $self->{spec_files} = \@files;
    return $self->{version} = $code;
}
sub set_syntax_version {
    my $self = shift;
    my $code = shift or return $self->carp_error("set_syntax_version: required syntax code argument not provided");
    my @files = $self->find_syntax_files($code);
    unless (@files) {
        $self->error("set_syntax_version: Unrecognized syntax code '$code' (no csv files)");
        return;
    }
    $self->{syntax_files} = \@files;
    return $self->{syntax} = $code;
}

sub find_spec_files {
    my $self = shift;
    my $code = @_ ? shift : ($self->version || $self->version_default);
    $code or return $self->carp_error("No EDI spec revision argument to find_spec_files().  Nothing to look for!");
    my $dir = $self->get_spec_dir or return $self->carp_error("EDI Specifications directory missing");
    $debug and warn "get_spec_dir returned '$dir'.  Looking for $dir/*.$code.csv";
    return File::Find::Rule->maxdepth(1)->name("*.$code.csv")->file()->in($dir);
}
sub find_syntax_files {
    my $self = shift;
    my $code = @_ ? shift : ($self->syntax || $self->syntax_default);
    $code or return $self->carp_error("No EDI spec revision argument to find_syntax_files().  Nothing to look for!");
    my $dir = $self->get_syntax_dir or return $self->carp_error("EDI Syntax directory missing");
    $debug and warn "get_syntax_dir returned '$dir'.  Looking for $dir/*.$code.csv";
    return File::Find::Rule->maxdepth(1)->name("*.$code.csv")->file()->in($dir);
}

sub get_spec_handle {
    my $self    = shift;
    my $type    = shift || '';
    my $version = @_ ? shift : $self->version;
    $version or return $self->carp_error("spec version is not set (nor passed as a parameter)");
    my $trio;
    unless ($type and $trio = $spec_map->{$type}) {
        return $self->carp_error("Type '$type' is not mapped to a spec file.  Options are: " . join(' ', keys %$spec_map));
    }
    my @files = $self->find_spec_files;
    my $name  = $self->csv_filename($trio->{code}, $version);
    $debug and print STDERR "get_spec_handle() checking " . scalar(@files) . " files for: $name\n";
    my @hits = grep {(File::Spec->splitpath($_))[2] eq $name} @files;
    scalar(@hits) or return $self->carp_error("Spec file for $type ($name) not found");
    my $file = $hits[0];
    $debug and warn "get_spec_handle opening $file";
    open (my $fh, "<$file") or carp "get_spec_handle failed to open $file";
    return $fh;
}
sub get_syntax_handle {
    my $self    = shift;
    my $type    = shift || '';
    my $syntax  = @_ ? shift : $self->syntax;
    $syntax or return $self->carp_error("spec syntax is not set (nor passed as a parameter)");
    my $trio;
    unless ($type and $trio = $spec_map->{$type}) {
        return $self->carp_error("Type '$type' is not mapped to a syntax file.  Options are: " . join(' ', keys %$spec_map));
    }
    my @files = $self->find_syntax_files;
    my $name  = $self->csv_filename('S', $trio->{code}, $syntax);
    $debug and print STDERR "get_syntax_handle() checking " . scalar(@files) . " files for: $name\n";
    my @hits = grep {(File::Spec->splitpath($_))[2] eq $name} @files;
    scalar(@hits) or return $self->carp_error("Syntax file for $type ($name) not found");
    my $file = $hits[0];
    $debug and warn "get_syntax_handle opening $file";
    open (my $fh, "<$file") or carp "get_syntax_handle failed to open $file";
    return $fh;
}

sub csv_filename {
    my $self = shift;
    return (scalar(@_) > 2 ? shift : $self->interactive ? 'I' : 'E')
        . (shift || '') . '.' . (shift || '') . ".csv";
}

# alias for get_spec
sub spec_page {
    my $self = shift;
    return $self->get_spec(@_);
}

# gets a page of the already declared spec, like say the one defining message(s)
sub get_spec {
    my $self = shift;
    my $type = shift   or return $self->carp_error("get_spec: required argument for spec 'type' missing.  Options are: " . join(', ', keys %$spec_map));
    $spec_map->{$type} or return $self->carp_error("Type '$type' is not mapped to a spec file.  Options are: " . join(' ', keys %$spec_map));
    my $subpart = @_ ? shift : '';
    my $version = $self->version or return $self->carp_error("spec version is not set");
    my $syntax  = $self->syntax  or return $self->carp_error("spec syntax is not set");
    if ($spec_map->{$type}->{cache}->{$version}) {
        $debug and print STDERR "cache hit for spec_map->{$type}->{cache}->{$version}\n";
    } elsif ($type eq 'segment_group') {
        my $message_spec = $self->get_spec('message', $subpart);  # segment groups are defined in the message file
        foreach (keys %$message_spec) {
            /^(\S+)\/(SG\d+)$/ or next; #  like ORDRSP/SG27
            $spec_map->{$type}->{cache}->{$version}->{$1}->{$2} = $message_spec->{$_};
        }
        my $message_syntax = $self->get_syntax('message');  # segment groups are defined in the message file
        foreach (keys %$message_syntax) {
            /^(\S+)\/(SG\d+)$/ or next; #  like ORDRSP/SG27
            $spec_map->{$type}->{cache}->{$version}->{$1}->{$2} = $message_syntax->{$_};  # combine syntax/spec defs
        }
    } else {
        my $fh = $self->get_spec_handle($type) or return;
        $spec_map->{$type}->{cache}->{$version} = $self->parse_plexer($type, $fh);
        my $extras = $self->get_syntax($type);
        foreach (keys %$extras) {
            $spec_map->{$type}->{cache}->{$version}->{$_} = $extras->{$_};                # combine syntax/spec defs
        }
    }
    return $spec_map->{$type}->{cache}->{$version};
}

sub get_syntax {    # no (separate from spec) cache
    my $self = shift;
    my $type = shift   or return $self->carp_error("get_syntax: required argument for syntax 'type' missing.  Options are: " . join(', ', keys %$spec_map));
    $spec_map->{$type} or return $self->carp_error("Type '$type' is not mapped to a spec file.  Options are: " . join(' ', keys %$spec_map));
    $type = 'message' if ($type eq 'segment_group');    # sort out the messages vs. segments yourself
    my $fh = $self->get_syntax_handle($type) or return;
    return $self->parse_plexer($type, $fh);
}

# returns pseudohash
sub parse_plexer {
    my $self = shift;
    my $type = shift or croak("parse_plexer: required argument for spec 'type' missing.  Options are: " . join(', ', keys %$spec_map));
    my $fh   = shift or croak("parse_plexer: required argument for 'filehandle' missing");
    my @slurp = <$fh>;
    chomp @slurp;
    $debug and print STDERR "parsing CSV for $type: $. lines\n";
    if ($type eq 'element') {
        # 1000;an..35;B;Document name
        return { 
            map {
                s/\s*$//;   # kill trailing spaces
                my @four = split ';', $_;
                $four[0] => {
                    code  => $four[0],
                    def   => $four[1],
                    class => $four[2],
                    label => $four[3]
                }
            } @slurp
       };
    } elsif ($type eq 'composite' or $type eq 'message' or $type eq 'segment' or $type eq 'segment_group') {
        return {
            map {
                my ($code, $label, @rest) = split ';', $_;
                my @codeparts = split ':', $code;
                my $xpath = $code = $codeparts[0];
                if ($codeparts[-1] and $codeparts[-1] ne $code and $codeparts[-1] ne 'UN') {
                    $xpath .= "/" . $codeparts[-1];
                }
                $debug and $debug > 1 and print STDERR "parsing CSV for $type/$xpath ($label)\n";
                $xpath => {
                    xpath   => $xpath,      # ORDERS/SG02 -- xpath is same as code except for segment_groups
                    code    => $code,       # SG02
                #   version => $codeparts[1] . $codeparts[2],
                    label   => $label,
                    parts   => $self->parse_array(\@rest, $spec_map->{$type}->{keys})
                }
            } @slurp
        };
    } else {
        croak "Cannot parse CSV for unknown type '$type'";
    }
}

# my $foobar = parse_array(\@elements, @keys)
sub parse_array {
    my $self = shift;
    @_ >= 2 or croak "\$self->parse_array needs two array_ref arguments";
    my @parts = @{(shift)}; # extra parens req'd
    my @keys  = @{(shift)}; # extra parens req'd

    @keys or croak "No keys passed to parse_array.  Cannot interpret spec line";
    (scalar(@parts) % scalar(@keys)) and croak sprintf "Cannot parse %s elements evenly into parts of %s for body: %s", scalar(@parts), scalar(@keys), join(';', @parts); 

    my @return;
    my $i = 0;
    while (@parts) {
        my %chunk = (index => $i++);
        foreach (@keys) {
            my $value = shift @parts;
            if ($_ eq 'mandatory') {
                next unless $value eq 'M';  # conditional is assumed
                $value = 1;                 # M => 1
            }
            $chunk{$_} = $value;
        }
        push @return, \%chunk;
    }
    return \@return;
}


# Cache Control

sub dump_cache {
    return Dumper($spec_map);
}
sub clear_cache {
    foreach (keys %$spec_map) {
        $spec_map->{$_}->{cache} = {};
    }
}


# Specialized sort functions

sub spec_version_sort {
    my $whatever = shift;
    my ($a, $b) = @_;
    my ($a_num, $b_num);
    if ($a =~ /^.((\d)\d).$/) {
        $a_num = $1;
        $a_num += 100 if $2 != 9;   # 2-digit year like 06 (or 12) has to sort as greater than 97
        if ($b =~ /^.((\d)\d).$/) {
            $b_num = $1;
            $b_num += 100 if $2 != 9;   # 2-digit year like 06 (or 12) has to sort as greater than 97
            return $a_num <=> $b_num || $a cmp $b;
        }
    }
    return $a cmp $b;
}

sub sg_sort {
    my $whatever = shift;
    my ($a, $b) = @_;
    my ($a_part, $a_num);
    if ($a =~ /^(.+)\/SG(\d+)$/) {
        $a_part = $1;
        $a_num  = $2;
        if ($b =~ /^(.+)\/SG(\d+)$/) {
            return $a_part cmp $1 || $a_num <=> $2;
        } elsif ($b =~ /SG(\d+)$/) {
            return $a_num <=> $1;
        }
    }
    if ($a =~ /SG(\d+)$/ and 
        $a_num = $1      and
        $b =~ /SG(\d+)$/     ) {
        return $a_num <=> $1;
    }
    return $a cmp $b;
}


# Meta-mapping
# This will need to be updated (or at least reviewed) with each new spec CSV file added
#
# Key pseudo-ranges should NOT overlap
# Many of these have ancillary counterparts as subunits of other SGs,
# but this mapping is for the TOP level SGs that apply to the whole message.  
#
# Note: data representation might be slimmed by specifying just:
#   first version where introduced, first value and a list of versions where SG is incremented
#      or
#   different kind of list of new SGs per version, increments needed calculated on the fly 

my $metamap = {
    ORDRSP => {
        # not in 1901..1902 !!
        line_detail => {
            '1911..d94b' => "SG25",
            'd95a..d05b' => "SG26",
            'd06a..'     => "SG27",
        },
        line_price => {
            '1911'       => "SG25/SG26",
            '1921..d94b' => "SG25/SG27",
            'd95a..d95b' => "SG26/SG29",
            'd96a..d05b' => "SG26/SG30",
            'd06a..'     => "SG27/SG31",
        },
        line_reference => {
            '1911'       => "SG25/SG27",
            '1921..d94b' => "SG25/SG28",
            'd95a..d95b' => "SG26/SG30",
            'd96a..d05b' => "SG26/SG31",
            'd06a..'     => "SG27/SG32",
        },
        party => {
            '1911..d94b' => "SG2",
            'd95a..'     => "SG3",
        },
        currency => {
            '1911..d94b' => "SG7",
            'd95a..'     => "SG8",
        },
        payment_terms => {
            '1911..d94b' => "SG8",
            'd95a..'     => "SG9",
        },
        transport => {
            '1911..d94b' => "SG9",
            'd95a..'     => "SG10",
        },
        delivery_terms => {
            '1911..d94b' => "SG11",
            'd95a..'     => "SG12",
        },
        delivery_schedule => {
            '1911..d94b' => "SG15",
            'd95a..'     => "SG16",
        },
        packaging => {
            '1911..d94b' => "SG12",
            'd95a..'     => "SG13",
        },
        mark_label => {
            '1911..d94b' => "SG13",
            'd95a..'     => "SG14",
        },
        handling => {
            '1911..d94b' => "SG14",
            'd95a..'     => "SG15",
        },
        APR => {
            '1911..d94b' => "SG17",
            'd95a..'     => "SG18",
        },
        allowance => {
            '1911..d94b' => "SG18",
            'd95a..'     => "SG19",
        },
        requirement => {
            '1911..d94b' => "SG24",
            'd95a..'     => "SG25",
        },
    },
};

# $self->metamap('ORDRSP', 'allowance');
# $self->metamap('ORDRSP', 'allowance', 'd11b');    # override $self's version w/ optional arg.

sub metamap {
    my $self    = shift or croak "Illegal direct call to object method metamap()";
    my $message = shift or return $self->carp_error("Missing message argument to method metamap(), e.g. 'ORDRSP'");
    my $target  = shift or return $self->carp_error("Missing target argument to method metamap(), e.g. 'line_detail'");
    unless ($metamap->{$message}) {
        $debug and $self->carp_error("Message '$message' is not mapped via metamap()");
        return;
    }
    my $v =  @_ ? shift : $self->version;
    $v or return $self->carp_error("Spec version not set (or passed as optional parameter)");
    my $ranges = $metamap->{$message}->{$target} or return; # else got nuthin
    my @keys = keys %$ranges or return;  # no ranges means no hits
    foreach (@keys) {   # note: unsorted, hence non-overlap requirement, else results undetermined (first hit in keys order)
        my ($low, $hi);
        # if (/^([^\.]*)\.\.([^\.]*)$/) {
        if (/^(.*)\.\.(.*)$/) {
            $low = $1 || '0900';    # tricky, default "lowest"  value as sorted by spec_version_sort
            $hi  = $2 || 'zzzz';    #         default "highest" value as sorted by spec_version_sort
            return $ranges->{$_} if ($v eq $low or $v eq $hi);  # match on a boundary is a hit
            my @trio = sort {$self->spec_version_sort($a,$b)} ($low, $hi, $v);
            $debug and print STDERR "metamap sorted (low,val,hi) ($low,$v,$hi): ", join(" ", @trio), ($v eq $trio[1] ? '  MATCH' : '' ), "\n";
            return $ranges->{$_} if $v eq $trio[1];             # else, if it sorts to the position between bounds, it's a hit
        } else {    # solitary value
            $v eq $_ and return $ranges->{$_};
        }
    }
    return $self->carp_error("$message/$target cannot place version $v in " . scalar(@keys) . " ranges: " . join(' ', @keys));
}

# $spec->metamap_keys('ORDRSP');
sub metamap_keys {
    my $self    = shift  or croak "Illegal direct call to object method metamap_keys()";
    my $message = shift  or return $self->carp_error("Missing message argument to method metamap_keys()");
    unless ($metamap->{$message}) {
        $debug and $self->carp_error("Message '$message' is not mapped via metamap_keys()");
        return;
    }
    return keys %{$metamap->{$message}};
}

1;
__END__

=head1 NAME

Business::EDI::Spec - Object class for CSV-based U.N. EDI specifications

=head1 SYNOPSIS

  use Business::EDI::Spec;
  
  my $spec = Business::EDI::Spec->new('segment');

=head1 DESCRIPTION

CSV files originally from edi4r are included as part of Business::EDI.  They are used to define the many different
messages, segements, data elements, composite data elements, and codelists that are part of a given version of the 
U.N. specification.  

The CSV spec files are composed differently for the different structures defined.
So we have to parse them differently.

 ==> Business/EDI/data/edifact/untdid/EDCD.d07a.csv  # Composite Elements
 CompositeCode;label;pos;code;mandatory;def;[pos;code;mandatory;def;...]
 C001;TRANSPORT MEANS;010;8179;C;an..8;020;1131;C;an..17;030;3055;C;an..3;040;8178;C;an..17;
 C002;DOCUMENT/MESSAGE NAME;010;1001;C;an..3;020;1131;C;an..17;030;3055;C;an..3;040;1000;C;an..35;
 C004;EVENT CATEGORY;010;9637;C;an..3;020;1131;C;an..17;030;3055;C;an..3;040;9636;C;an..70;

 C001 => {label => 'TRANSPORT MEANS;010;8179;C;an..8;020;1131;C;an..17;030;3055;C;an..3;040;8178;C;an..17;

 ==> Business/EDI/data/edifact/untdid/EDED.d07a.csv  # Data Elements
 code;def;class(?):label
 1000;an..35;B;Document name
 1001;an..3;C;Document name code
 1003;an..6;B;Message type code

 1000 => {label => 'an..35;B;Document name

 ==> Business/EDI/data/edifact/untdid/EDMD.d07a.csv  # Messages
 MessageCode:x:rel:org:z:SegmentGroup;label;SegCode;mandatory;repeats;[SegCode;mandatory;repeats;...]
 APERAK:D:07A:UN::;Application error and acknowledgement message;UNH;M;1;BGM;M;1;DTM;C;9;FTX;C;9;CNT;C;9;SG1;C;99;SG2;C;9;SG3;C;9;SG4;C;99999;UNT;M;1
 APERAK:D:07A:UN::SG1;SG01;DOC;M;1;DTM;C;99
 APERAK:D:07A:UN::SG2;SG02;RFF;M;1;DTM;C;9

 APERAK:D:07A:UN:: => {label => 'Application error and acknowledgement message',
    UNH;M;1;
    BGM;M;1;
    DTM;C;9;FTX;C;9;CNT;C;9;SG1;C;99;SG2;C;9;SG3;C;9;SG4;C;99999;UNT;M;1

 ==> Business/EDI/data/edifact/untdid/EDSD.d07a.csv  # Segments
 SegCode;label;pos;code;class;repeats[pos;code;class;repeats;...]
 ADR;ADDRESS;010;C817;C;1;020;C090;C;1;030;3164;C;1;040;3251;C;1;050;3207;C;1;060;C819;C;5;070;C517;C;5;
 AGR;AGREEMENT IDENTIFICATION;010;C543;C;1;020;9419;C;1;
 AJT;ADJUSTMENT DETAILS;010;4465;M;1;020;1082;C;1;

 ADR => {label => 'ADDRESS',
    010;C817;C;1;020;C090;C;1;030;3164;C;1;040;3251;C;1;050;3207;C;1;060;C819;C;5;070;C517;C;5;

 ==> Business/EDI/data/edifact/untdid/IDCD.d07a.csv   # Composites (interactive)
 E001 => {label => 'ADDRESS DETAILS;010;3477;M;an..3;020;3286;M;an..70;030;3286;C;an..70;040;3286;C;an..70;050;3286;C;an..70;060;3286;C;an..70;070;3286;C;an..70;

 ==> Business/EDI/data/edifact/untdid/IDMD.d07a.csv   # Messages (interactive)
 MsgCode:x:rel:org:z:SegmentGroup;label;SegCode;mandatory;class;repeats;;[mandatory;class;repeats;...]
 IHCEBI:D:07A:UN::;Interactive health insurance eligibility and benefits inquiry and;UIH;M;1;MSD;M;1;SG1;C;9;SG2;C;1;UIT;M;1
 IHCEBI:D:07A:UN::SG1;SG01;PRT;M;1;NAA;C;9;CON;C;9;FRM;C;9
 IHCEBI:D:07A:UN::SG2;SG02;DTI;M;1;ICI;C;1;FRM;C;9;SG3;C;999
 IHCEBI:D:07A:UN::SG3;SG03;BCD;M;1;HDS;C;9;DTI;C;1;PRT;C;9;FRM;C;9
 IHCLME:D:07A:UN::;Health care claim or encounter request and response - interactive;UIH;M;1;MSD;C;1;PRT;C;9;NAA;C;9;CON;C;9;BLI;C;1;ITC;C;1;FRM;C;99;SG1;C;3;SG2;C;99;UIT;M;1
 IHCLME:D:07A:UN::SG1;SG01;OTI;M;1;NAA;C;2
 IHCLME:D:07A:UN::SG2;SG02;PSI;M;1;DNT;C;35


 ==> Business/EDI/data/edifact/untdid/IDSD.d07a.csv   # Segments (interactive)
 SegCode;label;pos;code;mandatory;repeats(?)
 AAI;ACCOMMODATION ALLOCATION INFORMATION;010;E997;M;20;
 ADS;ADDRESS;010;E817;C;1;020;E001;C;1;030;3164;C;1;040;3251;C;1;050;3207;C;1;060;E819;C;1;070;E517;C;1;

 AAI => {label => 'ACCOMMODATION ALLOCATION INFORMATION',
    pos => '010',
    E997;M;20;

=head1 TO DO

Parsing for interactive specs.

=head1 SEE ALSO

edi4r - http://edi4r.rubyforge.org

Business::EDI

=head1 AUTHOR

Joe Atzberger

