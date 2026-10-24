package App::FileSync::Ignore;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    my $patterns = $args{patterns} || [];
    my $case_insensitive = $args{case_insensitive} ? 1 : 0;

    my @compiled;
    for my $raw (@{$patterns}) {
        next unless defined $raw;
        # "# comment" is a comment; "#*#" is a pattern, as in .gitignore's
        # escaped-hash case, which we allow without the backslash.
        next if $raw =~ /\A\s*(?:#\s|#\z|\z)/;

        my $negated = $raw =~ s/\A!// ? 1 : 0;
        $raw =~ s/\A\s+//;
        $raw =~ s/\s+\z//;
        next unless length $raw;

        my $re = _glob_to_re($raw);
        push @compiled, {
            negated => $negated,
            re      => $case_insensitive ? qr/\A$re\z/i : qr/\A$re\z/,
        };
    }

    return bless { compiled => \@compiled }, $class;
}

# Later patterns win, so a trailing "!keep" can re-include something.
sub match {
    my ($self, $path) = @_;
    return 0 unless defined $path && length $path;

    # A path inside an ignored directory is ignored too, even if the caller only
    # asks about the file (the scanner prunes at the directory, but this keeps the
    # answer correct for every caller).
    my @candidates = ($path);
    my $prefix = $path;
    while ($prefix =~ s{/[^/]+\z}{}) {
        push @candidates, $prefix;
    }

    for my $candidate (@candidates) {
        my $ignored = 0;
        for my $pattern (@{ $self->{compiled} }) {
            $ignored = $pattern->{negated} ? 0 : 1 if $candidate =~ $pattern->{re};
        }
        return 1 if $ignored;
    }

    return 0;
}

sub _glob_to_re {
    my ($pattern) = @_;

    $pattern =~ s{\A/}{};
    my $has_slash = $pattern =~ m{/} ? 1 : 0;

    my $re = '';
    my @chars = split //, $pattern;
    for (my $i = 0; $i < @chars; $i++) {
        my $char = $chars[$i];
        if ($char eq '*') {
            if ($i + 1 < @chars && $chars[$i + 1] eq '*') {
                $i++;
                if ($i + 1 < @chars && $chars[$i + 1] eq '/') {
                    $i++;
                    $re .= '(?:.*/)?';
                } else {
                    $re .= '.*';
                }
            } else {
                $re .= '[^/]*';
            }
        } elsif ($char eq '?') {
            $re .= '[^/]';
        } else {
            $re .= quotemeta($char);
        }
    }

    # A pattern without a slash matches any path segment, like .gitignore.
    $re = "(?:.*/)?$re" unless $has_slash;

    return $re;
}

1;
