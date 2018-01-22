package App::NDTools::Slurp;

# input/output related subroutines for NDTools

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use open qw(:std :utf8);

use File::Basename qw(basename);
use JSON qw();
use Scalar::Util qw(readonly);
use YAML::XS qw();

use App::NDTools::INC;
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
    },
);

# YAML::XS decode boolean values as PL_sv_yes and PL_sv_no, both - read only
# at leas until https://github.com/ingydotnet/yaml-libyaml-pm/issues/25
sub _fix_decoded_yaml_bools($) {
    my @stack = (\$_[0]);
    my $ref;

    while ($ref = shift @stack) {
        if (ref ${$ref} eq 'ARRAY') {
            for (reverse 0 .. $#{${$ref}}) {
                if (ref ${$ref}->[$_]) {
                    push @stack, \${$ref}->[$_];
                } elsif (readonly ${$ref}->[$_]) {
                    splice @{${$ref}}, $_, 1, (${$ref}->[$_] ? JSON::true : JSON::false);
                }
            }
        } elsif (ref ${$ref} eq 'HASH') {
            for (keys %{${$ref}}) {
                if (ref ${$ref}->{$_}) {
                    push @stack, \${$ref}->{$_};
                } elsif (readonly ${$ref}->{$_}) {
                    ${$ref}->{$_} = delete ${$ref}->{$_} ? JSON::true : JSON::false;
                }
            }
        }
    }
}

sub s_decode($$;$) {
    my ($data, $fmt, $opts) = @_;
    my $format = uc($fmt);

    if ($format eq 'JSON') {
        $data = eval { JSON::from_json($data, {%{$FORMATS{JSON}}, %{$opts || {}}}) };
    } elsif ($format eq 'YAML') {
        $data = eval { YAML::XS::Load($data) };
        die_fatal "Failed to decode '$fmt': " . $@, 4 if $@;
        _fix_decoded_yaml_bools($data);
    } elsif ($format eq 'RAW') {
        ;
    } else {
        die_fatal "Unable to decode '$fmt' (not supported)";
    }
    die_fatal "Failed to decode '$fmt': " . $@, 4 if $@;

    return $data;
}

sub s_dump(@) {
    my ($uri, $fmt, $opts) = (shift, shift, shift);
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
        $data = eval { JSON::to_json($data, {%{$FORMATS{JSON}}, %{$opts || {}}}) };
    } elsif ($format eq 'YAML') {
        $data = eval { YAML::XS::Dump($data) };
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
        my $ext = uc(pop @names);
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
        open(my $fh, '<', $uri) or die_fatal "Failed to open file '$uri' ($!)", 2;
        $data = do { local $/; <$fh> }; # load whole file
        close($fh);
    }

    return $data;
}

1;
