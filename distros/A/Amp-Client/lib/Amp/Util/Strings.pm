package Amp::Util::Strings;
use Moo;
use URI::Escape;
use JSON;

sub so_trim {
    my $self = shift;
    my $string = shift;
    if (defined $string) {
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
    }
    return $string;
}

sub trim {
    my $self = shift;
    my $string = shift;
    if (defined $string) {
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
    }
    return $string;
}

sub removeAllWhitespace {
    my $self = shift;
    my $string = shift;
    if (defined $string) {
        $string =~ s/\s+//g;
    }
    return $string;
}

# Remove all newlines from a string
sub chomp {
    my $self = shift;
    my $string = shift;
    if (defined $string) {
        $string =~ s/\R//g;
    }
    return $string;
}

sub uriEncode {
    my $self = shift;
    my $string = shift;
    my $opts = shift;
    if (defined $string) {
        if ($opts->{chomp}) {
            #            $string = $self->chomp($string);
            $string =~ s/\R//g;
        }
        if ($opts->{trim}) {
            $string = $self->trim($string);
        }
        $string = uri_escape($string);
    }
    return $string;
}

sub uriDecode {
    my $self = shift;
    my $string = shift;
    if (defined $string) {
        $string = uri_unescape($string);
    }
    return $string;
}

sub clean {
    my $self = shift;
    my $string = shift;
    $string =~ s/\R//g;
    $string = $self->trim($string);
    return $string;
}

sub json_encode {
    my $self = shift;
    my $string = shift;
    my $opts = shift;
    my $json = JSON->new->allow_nonref->allow_blessed->utf8;
    if ($opts->{pretty}) {
        $json->pretty(1);
    }
    if ($opts->{indent}) {
        $json->indent(1);
    }
    if ($opts->{canonical}) {
        $json->canonical(1);
    }
    if (defined $string) {
        $string = $json->encode($string);
    }
    return $string;
}

sub json_decode {
    my $self = shift;
    my $string = shift;
    my $json = JSON->new->allow_nonref->allow_blessed->utf8;
    my $data;
    if (defined $string) {
        $data = $json->decode($string);
    }
    return $data;
}

sub quote {
    my $self = shift;
    my ($s) = @_;
    $s = '' if !defined $s;
    $s =~ s/\\\\/\\/g;
    $s =~ s/\'/\\'/g;
    $s =~ s/\"/\\"/g;
    $s =~ s/\x08/\\b/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/\x1A/\\Z/g;

    return "'$s'";
}

1;
