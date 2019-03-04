package App::NDTools::Slurp;

# input/output related subroutines for NDTools

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use open qw(:std :utf8);

use File::Basename qw(basename);
use JSON qw();
use Scalar::Util qw(readonly);

use App::NDTools::INC;
use App::NDTools::Util qw(is_number);
use Log::Log4Cli;

our @EXPORT_OK = qw(
    s_decode
    s_dump
    s_dump_file
    s_encode
    s_fmt_by_uri
    s_load
    s_load_uri
);

our %FORMATS = (
    JSON => {
        allow_nonref => 1,
        canonical => 1,
        pretty => 1,
        relaxed => 1,
        space_before => 0,
    },
);

use constant {
    TRUE  => JSON::true,
    FALSE => JSON::false,
};

sub _decode_yaml($) {
    require YAML::XS;

    my $data = YAML::XS::Load($_[0]);

    # YAML::XS decode boolean vals as PL_sv_yes and PL_sv_no, both - read only
    # at least until https://github.com/ingydotnet/yaml-libyaml-pm/issues/25
    # second thing here: get rid of dualvars: YAML::XS load numbers as
    # dualvars, but JSON::XS dumps them as strings =(

    my @stack = (\$data);
    my $ref;

    while ($ref = shift @stack) {
        if (ref ${$ref} eq 'ARRAY') {
            for (0 .. $#{${$ref}}) {
                if (ref ${$ref}->[$_]) {
                    push @stack, \${$ref}->[$_];
                } elsif (readonly ${$ref}->[$_]) {
                    splice @{${$ref}}, $_, 1, (${$ref}->[$_] ? TRUE : FALSE);
                } elsif (is_number ${$ref}->[$_]) {
                    ${$ref}->[$_] += 0;
                }
            }
        } elsif (ref ${$ref} eq 'HASH') {
            for (keys %{${$ref}}) {
                if (ref ${$ref}->{$_}) {
                    push @stack, \${$ref}->{$_};
                } elsif (readonly ${$ref}->{$_}) {
                    ${$ref}->{$_} = delete ${$ref}->{$_} ? TRUE : FALSE;
                } elsif (is_number ${$ref}->{$_}) {
                    ${$ref}->{$_} += 0;
                }
            }
        } elsif (is_number ${$ref}) {
            ${$ref} += 0;
        }
    }

    return $data;
}

sub _encode_yaml($) {
    require YAML::XS;
    my $modern_yaml_xs = eval { YAML::XS->VERSION(0.67) };

    # replace booleans for YAML::XS (accepts only boolean and JSON::PP::Boolean
    # since 0.67 and PL_sv_yes/no in earlier versions). No roundtrip for
    # versions < 0.67: 1 and 0 used for booleans (there is no way to set
    # PL_sv_yes/no into arrays/hashes without XS code)

    my ($false, $true) = (0, 1);

    local $YAML::XS::Boolean = "JSON::PP" if ($modern_yaml_xs);

    if ($modern_yaml_xs) {
        return YAML::XS::Dump($_[0]) if (ref TRUE eq 'JSON::PP::Boolean');

        require JSON::PP;
        ($false, $true) = (JSON::PP::false(), JSON::PP::true());
    }

    my @stack = (\$_[0]);
    my $ref;
    my $bool_type = ref TRUE;

    while ($ref = shift @stack) {
        if (ref ${$ref} eq 'ARRAY') {
            for (0 .. $#{${$ref}}) {
                if (ref ${$ref}->[$_]) {
                    push @stack, \${$ref}->[$_];
                } elsif (ref ${$ref}->[$_] eq $bool_type) {
                    ${$ref}->[$_] = ${$ref}->[$_] ? $true : $false;
                }
            }
        } elsif (ref ${$ref} eq 'HASH') {
            for (keys %{${$ref}}) {
                if (ref ${$ref}->{$_}) {
                    push @stack, \${$ref}->{$_};
                } elsif (ref ${$ref}->{$_} eq $bool_type) {
                    ${$ref}->{$_} = ${$ref}->{$_} ? $true : $false;
                }
            }
        } elsif (ref ${$ref} eq $bool_type) {
            ${$ref} = ${$ref} ? $true : $false;
        }
    }

    return YAML::XS::Dump($_[0]);
}

sub s_decode($$;$) {
    my ($data, $fmt, $opts) = @_;
    my $format = uc($fmt);

    if ($format eq 'JSON') {
        my $o = { %{$FORMATS{JSON}}, %{$opts || {}} };
        $data = eval {
            JSON->new(
                )->allow_nonref($o->{allow_nonref}
                )->relaxed($o->{relaxed}
            )->decode($data);
        };
    } elsif ($format eq 'YAML') {
        $data = eval { _decode_yaml($data) };
    } elsif ($format eq 'RAW') {
        ;
    } else {
        die_fatal "Unable to decode '$fmt' (not supported)";
    }

    die_fatal "Failed to decode '$fmt': " . $@, 4 if $@;

    return $data;
}

sub s_dump(@) {
    my ($uri, $fmt, $opts) = splice @_, 0, 3;

    $uri = \*STDOUT if ($uri eq '-');

    $fmt = s_fmt_by_uri($uri) unless (defined $fmt);
    my $data = join('', map { s_encode($_, $fmt, $opts) } @_);

    if (ref $uri eq 'GLOB') {
        print $uri $data;
    } else {
        s_dump_file($uri, $data);
    }
}

sub s_dump_file($$) {
    my ($file, $data) = @_;

    open(my $fh, '>', $file) or die_fatal "Failed to open '$file' ($!)", 2;
    print $fh $data;
    close($fh);
}

sub s_encode($$;$) {
    my ($data, $fmt, $opts) = @_;
    my $format = uc($fmt);

    if ($format eq 'JSON' or $format eq 'RAW' and ref $data) {
        my $o = { %{$FORMATS{JSON}}, %{$opts || {}} };
        $data = eval {
            JSON->new(
                )->allow_nonref($o->{allow_nonref}
                )->canonical($o->{canonical}
                )->pretty($o->{pretty}
                )->space_before($o->{space_before}
            )->encode($data);
        };
    } elsif ($format eq 'YAML') {
        $data = eval { _encode_yaml($data) };
    } elsif ($format eq 'RAW') {
        $data .= "\n";
    } else {
        die_fatal "Unable to encode to '$fmt' (not supported)";
    }

    die_fatal "Failed to encode structure to $fmt: " . $@, 4 if $@;

    return $data;
}

sub s_fmt_by_uri($) {
    my @names = split(/\./, basename(shift));
    if (@names and @names > 1) {
        my $ext = uc($names[-1]);
        return 'YAML' if ($ext eq 'YML' or $ext eq 'YAML');
    }

    return 'JSON'; # by default
}

sub s_load($$;@) {
    my ($uri, $fmt, %opts) = @_;

    $uri = \*STDIN if ($uri eq '-');
    my $data = s_load_uri($uri);
    $fmt = s_fmt_by_uri($uri) unless (defined $fmt);

    return s_decode($data, $fmt);
}

sub s_load_uri($) {
    my $uri = shift;
    my $data;

    if (ref $uri eq 'GLOB') {
        $data = do { local $/; <$uri> };
    } else {
        open(my $fh, '<', $uri) or
            die_fatal "Failed to open file '$uri' ($!)", 2;
        $data = do { local $/; <$fh> }; # load whole file
        close($fh);
    }

    return $data;
}

1;
