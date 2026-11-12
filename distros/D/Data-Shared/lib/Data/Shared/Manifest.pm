package Data::Shared::Manifest;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw(refaddr blessed);
use Fcntl qw(:flock O_RDWR O_APPEND O_CREAT);
use Errno ();
use B ();

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared Data::Shared::Manifest Data::Shared::Storage
                   Data::Shared::Composite);

sub snapshot {
    my ($value, $active) = @_;
    return (_scalar_snapshot($value), 1) unless ref $value;
    # JSON::XS booleans are JSON::PP::Boolean objects without JSON::PP loaded.
    if (blessed($value) && $value->isa('JSON::PP::Boolean')) {
        require JSON::PP;
        return ($value ? JSON::PP::true() : JSON::PP::false(), 1);
    }
    return ($value, 0) unless ref $value eq 'ARRAY' || ref $value eq 'HASH';
    $active ||= {};
    my $addr = refaddr($value);
    Carp::croak('Data::Shared: cyclic mount configuration is not supported') if $active->{$addr};
    local $active->{$addr} = 1;
    my $serializable = 1;
    if (ref $value eq 'ARRAY') {
        my @copy;
        for my $item (@$value) {
            my ($copy, $ok) = snapshot($item, $active);
            push @copy, $copy;
            $serializable &&= $ok;
        }
        return (\@copy, $serializable);
    }
    my %copy;
    for my $key (keys %$value) {
        my ($copy, $ok) = snapshot($value->{$key}, $active);
        $copy{$key} = $copy;
        $serializable &&= $ok;
    }
    return (\%copy, $serializable);
}

my %HELD;       # "dev:ino" of a held manifest lock => { exclusive }, this process only

my $INFINITY = 9**9**9;

# Checked by value: under PERL_JSON_PP_USE_B JSON::PP quotes a stringified Inf.
# Any NV may be one; int() on an Inf sets IOK as well as NOK.
sub _refuse_nonfinite {
    my ($value, $flags) = @_;
    my $number = 0 + $value;
    return unless $number != $number || $number == $INFINITY || $number == -$INFINITY;
    # Before 5.40 the string 'inf' used numerically has a real Inf's flags: only a PV
    # spelled unlike perl's own marks it a string. No PV: refused.
    Carp::croak("Data::Shared: '$value' is not a serializable mount argument")
        unless ($flags & B::SVp_POK()) && "$value" ne "$number";
    return;
}

# The backend constructor and the manifest both get this value, so a recorded
# path is the one the file was created under.
sub _scalar_snapshot {
    my ($value) = @_;
    return $value unless defined $value;
    if (utf8::is_utf8($value)) {
        # Before the byte return: an upgraded stringified Inf is UTF-8 too.
        my $wide = B::svref_2object(\$value)->FLAGS;
        _refuse_nonfinite($value, $wide) if $wide & B::SVp_NOK();
        # Lone surrogates and codepoints above Unicode encode to JSON that JSON::PP cannot reparse.
        Carp::croak('Data::Shared: mount argument is not representable in a manifest')
            if $value =~ /[\x{D800}-\x{DFFF}]|[^\x{0}-\x{10FFFF}]/;
        # Record the bytes the filesystem and the leaf's SvPV see; JSON cannot tell them apart.
        # Stringify, not assign: a copy keeps numeric flags, and '123' would replay as 123.
        my $bytes = "$value";
        utf8::encode($bytes);
        return $bytes;
    }
    my $flags = B::svref_2object(\$value)->FLAGS;
    return $value unless $flags & (B::SVp_IOK() | B::SVp_NOK());
    _refuse_nonfinite($value, $flags) if $flags & B::SVp_NOK();
    # A pure number is spelled here: JSON::PP's choice varies by version and flag
    # history, and perl's NV_DIG spelling loses precision (1+2**-52 prints as 1).
    if (!($flags & B::SVp_POK())) {
        my $copy = $value;              # a copy: stringifying $value would
        my $short = "$copy";            # set POK and change what follows
        if (0 + $short != $value) {
            # %.0f for integral values; else the first width that round-trips
            # this perl's NV (17 double, 21 long double, 36 __float128).
            my @widths = $value == int($value) ? (0) : (17, 21, 36);
            for my $digits (@widths) {
                my $decimal = $digits ? sprintf('%.*g', $digits, $value)
                                      : sprintf('%.0f', $value);
                # Numify a copy: $decimal must keep string-only flags or JSON::PP may respell it.
                my $check = $decimal;
                return $decimal if $check + 0 == $value;
            }
        }
    }
    return $value;
}

sub with_lock {
    my ($root, $exclusive, $code) = @_;
    return $code->() unless defined $root->{dir};
    my $path = "$root->{dir}/.manifest.lock";
    my $fh;
    if ($root->{readonly}) {
        # A read-only root must never create the lock; a shipped copy may lack it.
        return $code->() unless -e $path;
        open $fh, '<', $path or Carp::croak("Data::Shared: cannot open manifest lock '$path': $!");
    } else {
        # fcntl-based flock emulation needs O_RDWR for LOCK_SH.
        unless (sysopen($fh, $path, O_RDWR | O_APPEND | O_CREAT, 0600)) {
            my $err = $!;
            unless (!$exclusive && -e $path && open $fh, '<', $path) {
                $! = $err;
                Carp::croak("Data::Shared: cannot open manifest lock '$path': $!");
            }
        }
    }
    # flock does not nest across descriptors: relocking in this process would self-deadlock,
    # so refuse unless both holders are shared. Keyed by dev:ino, since paths alias.
    my ($dev, $ino) = (stat $fh)[0, 1];
    my $key = defined $ino ? "$dev:$ino" : $path;
    if (my $held = $HELD{$key}) {
        Carp::croak("Data::Shared: this process already holds the manifest lock for"
            . " '$root->{dir}'; use the root you were given rather than opening it again")
            if $exclusive || $held->{exclusive};
    }
    my $op = $exclusive ? LOCK_EX : LOCK_SH;
    until (flock $fh, $op) {
        Carp::croak("Data::Shared: cannot lock manifest: $!") unless $!{EINTR};
    }
    local $HELD{$key} = { exclusive => $exclusive ? 1 : 0 };
    return $code->(); # lexical filehandle releases the lock on return or exception
}

sub read {
    my ($path) = @_;
    open my $fh, '<', $path or Carp::croak("Data::Shared: cannot read manifest '$path': $!");
    # $. too: localizing it restores the caller's last-read handle, which bare eof consults.
    my $json = do { local ($/, $.); <$fh> };
    close $fh or Carp::croak("Data::Shared: cannot close manifest '$path': $!");
    require JSON::PP;
    my $data = eval { JSON::PP->new->decode($json) };
    Carp::croak("Data::Shared: invalid manifest '$path': $@") if $@;
    Carp::croak("Data::Shared: invalid manifest '$path': expected an object") unless ref $data eq 'HASH';
    Carp::croak("Data::Shared: unsupported manifest version in '$path'")
        unless defined $data->{version} && !ref $data->{version} && $data->{version} eq '1';
    Carp::croak("Data::Shared: invalid manifest mounts in '$path'") unless ref $data->{mounts} eq 'ARRAY';
    $data->{revision} = 0 unless exists $data->{revision};
    Carp::croak("Data::Shared: invalid manifest revision in '$path'")
        unless defined $data->{revision} && !ref $data->{revision} && $data->{revision} =~ /\A[0-9]+\z/;
    Carp::croak("Data::Shared: invalid store identity in '$path'")
        if exists $data->{store}
        && !(defined $data->{store} && !ref $data->{store} && $data->{store} =~ /\A[0-9a-f]+\z/);
    # The checks above gave these a PV; older JSON::PP would then re-encode them as strings.
    $data->{version} = 1;
    $data->{revision} = 0 + $data->{revision};
    my %names;
    for my $mount (@{ $data->{mounts} }) {
        Carp::croak("Data::Shared: invalid mount record in '$path'") unless ref $mount eq 'HASH';
        Carp::croak("Data::Shared: invalid mount name in '$path'")
            unless defined $mount->{name} && !ref $mount->{name} && length $mount->{name};
        Carp::croak("Data::Shared: duplicate mount '$mount->{name}' in '$path'") if $names{$mount->{name}}++;
        $mount->{args} = [] unless exists $mount->{args};
        Carp::croak("Data::Shared: invalid mount arguments in '$path'") unless ref $mount->{args} eq 'ARRAY';
        Carp::croak("Data::Shared: missing mount spec in '$path'") unless defined $mount->{spec};
    }
    if (exists $data->{retained}) {
        Carp::croak("Data::Shared: invalid retained storage in '$path'")
            unless ref $data->{retained} eq 'ARRAY';
        for my $kept (@{ $data->{retained} }) {
            Carp::croak("Data::Shared: invalid retained storage in '$path'")
                unless defined $kept && !ref $kept && length $kept;
        }
    }
    # The validated manifest is trusted; untaint it before the backends' taint guards.
    _untaint($data);
    # Fingerprint the published bytes; JSON::PP may re-encode decoded numbers differently.
    return wantarray ? ($data, $json) : $data;
}

sub _untaint {
    my ($node) = @_;
    if (ref $node eq 'HASH')  { $_ = _untaint_scalar($_) for values %$node; return $node }
    if (ref $node eq 'ARRAY') { $_ = _untaint_scalar($_) for @$node;        return $node }
    return $node;
}

sub _untaint_scalar {
    my ($v) = @_;
    return _untaint($v) if ref $v;
    return $v unless defined $v;
    my ($clean) = "$v" =~ /\A(.*)\z/s;
    # Restore published bytes after JSON decoding, including bytes above 0x7f.
    utf8::downgrade($clean, 1);
    # JSON::PP gives numbers IOK/NOK and strings POK only, so "007" stays a string.
    my $flags = B::svref_2object(\$v)->FLAGS;
    return 0 + $clean if $flags & (B::SVp_IOK() | B::SVp_NOK());
    return $clean;
}

sub write {
    my ($path, $data) = @_;
    require JSON::PP;
    my $json = JSON::PP->new->canonical(1)->ascii(1)->encode($data);
    require File::Temp;
    require File::Basename;
    my ($fh, $tmp) = File::Temp::tempfile('.manifest-XXXXXXXX', DIR => File::Basename::dirname($path), UNLINK => 0);
    # The replacement keeps the existing manifest's mode.
    my $mode = (stat $path)[2];
    my $ok = eval {
        chmod $mode & 07777, $tmp or die "cannot set manifest mode: $!" if defined $mode;
        local ($,, $\);
        print {$fh} $json, "\n" or die "cannot write manifest: $!";
        close $fh or die "cannot close manifest: $!";
        rename $tmp, $path or die "cannot rename manifest to '$path': $!";
        1;
    };
    my $err = $@;
    if (!$ok) {
        close $fh if defined fileno($fh);
        unlink $tmp;
        Carp::croak("Data::Shared: $err");
    }
    return "$json\n";       # what read() will slurp back, for the fingerprint
}

1;

__END__

=head1 NAME

Data::Shared::Manifest - Internal manifest validation and publication

=head1 DESCRIPTION

Internal to L<Data::Shared>; not a public API. Copies configuration,
validates version-one manifests, and publishes revisions under a
directory lock. Revisions absent
from legacy manifests are read as zero. Atomic replacement protects readers
from partial JSON; it does not promise durability across a machine crash.

=cut
