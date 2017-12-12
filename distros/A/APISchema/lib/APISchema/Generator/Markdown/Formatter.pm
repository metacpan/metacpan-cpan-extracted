package APISchema::Generator::Markdown::Formatter;
use 5.014;
use strict;
use warnings;

# core
use Exporter qw(import);
our @EXPORT = qw(type json pretty_json code restriction desc anchor method methods content_type http_status http_status_code);

# cpan
use HTTP::Status qw(status_message);
use URI::Escape qw(uri_escape_utf8);
use JSON::XS ();
my $JSON = JSON::XS->new->canonical(1);

use constant +{
    RESTRICTIONS => [qw(required max_items min_items max_length min_length maximum minimum pattern)],
    SHORT_DESCRIPTION_LENGTH => 100,
};

sub type ($); # type has recursive call

sub type ($) {
    my $def = shift;
    my $bar = '&#124;';

    if (ref $def) {
        for my $type (qw(oneOf anyOf allOf)) {
            if (my $union = $def->{$type}) {
                return join($bar, map { type($_) } @$union);
            }
        }
    }

    my $ref = ref $def ? $def->{'$ref'} : $def;
    if ($ref) {
        $ref = $ref =~ s!^#/resource/!!r;
        my $ref_text = "`$ref`";
        my $name = $ref =~ s!/.*$!!r;
        $ref_text = sprintf('[%s](#%s)', $ref_text, anchor(resource => $name)) if $name;
        return $ref_text;
    }

    my $type = $def->{type};
    if ($type) {
        return sprintf '`%s`', $type unless ref $type;
        return join $bar, map { code($_) } @{$type} if ref $type eq 'ARRAY';
    }

    return join $bar, map { code($_) } @{$def->{enum}} if $def->{enum};

    return 'undefined';
}

sub json ($) {
    my $x = shift;
    if (ref $x eq 'SCALAR') {
        if ($$x eq 1) {
            $x = 'true';
        } elsif ($$x eq 0) {
            $x = 'false';
        }
    } elsif (ref $x) {
        $x = $JSON->encode($x);
    } else {
        $x = $JSON->encode([$x]);
        $x =~ s/^\[(.*)\]$/$1/;
    }
    return $x;
}

my $PRETTY_JSON = JSON::XS->new->canonical(1)->indent(1)->pretty(1);
sub pretty_json ($) {
    my $x = shift;
    if (ref $x) {
        $x = $PRETTY_JSON->encode($x);
    } else {
        $x = $PRETTY_JSON->encode([$x]);
        $x =~ s/^\[\s*(.*)\s*\]\n$/$1/;
    }
    return $x;
}

sub _code ($) {
    my $text = shift;
    return '' unless defined $text;
    if ($text =~ /[`|]/) {
        $text =~ s/[|]/&#124;/g;
        return sprintf '<code>%s</code>', $text;
    }
    return sprintf '`%s`', $text;
}

sub code ($) {
    my $text = shift;
    return '' unless defined $text;
    return _code json $text;
}

sub anchor ($$) {
    my ($label, $obj) = @_;
    my $name = ref $obj ? $obj->title : $obj;
    return sprintf '%s-%s', $label, uri_escape_utf8($name);
}

sub restriction ($) {
    my $def = shift;
    return '' unless (ref $def) eq 'HASH';

    my @result = ();
    for my $r (sort @{+RESTRICTIONS}) {
        next unless defined $def->{$r};

        if (ref $def->{$r}) {
            push @result, _code sprintf "$r%s", json $def->{$r};
        } else {
            push @result, _code sprintf "$r(%s)", json $def->{$r};
        }
    }
    return join ' ', @result;
}

sub desc ($) {
    my $text = shift || '';
    $text = $text =~ s/[\r\n].*\z//sr;
    $text = substr($text, 0, SHORT_DESCRIPTION_LENGTH) . '...'
        if length($text) > SHORT_DESCRIPTION_LENGTH;
    return $text;
}

sub method ($) {
    my $method = shift;
    return $method->[0] if (ref $method || '') eq 'ARRAY';
    return $method;
}

sub methods ($) {
    my $method = shift;
    return join ', ', map { _code($_) } @$method
        if (ref $method || '') eq 'ARRAY';
    return _code($method);
}

sub content_type ($) {
    my $type = shift;
    return '-' unless length($type);
    return "`$type`";
}

sub http_status ($) {
    my $code = shift;
    return undef unless $code;
    return join(' ', $code, status_message($code));
}

sub http_status_code {
    return _code http_status shift;
}

1;
