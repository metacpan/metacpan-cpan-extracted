package Claude::Agent::Hook::Matcher;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Hook::Matcher',
        'matcher:predicate',
        'hooks:ArrayRef:default([])',
        'timeout:Num:predicate',
    );
}

sub matches {
    my ($self, $tool_name) = @_;

    return 0 unless defined $tool_name;
    return 1 unless defined $self->matcher;

    my $pattern = $self->matcher;

    if ($pattern eq quotemeta($pattern)) {
        return $tool_name eq $pattern;
    }

    my $use_alarm = $^O ne 'MSWin32' && $^O ne 'cygwin';
    my $result = 0;
    my $ok = eval {
        die "Pattern too long\n" if length($pattern) > 1000;
        if ($pattern =~ /\([^)]*[+*][^)]*\)[+*]/ || $pattern =~ /\([^)]*\|[^)]*\)[+*]/) {
            die "Potentially dangerous nested quantifier pattern\n";
        }
        local $SIG{ALRM} = sub { die "Regex timeout\n" } if $use_alarm;
        alarm(1) if $use_alarm;
        require Time::HiRes;
        my $start_time = Time::HiRes::time();
        my $compiled = qr/$pattern/;
        $result = $tool_name =~ $compiled ? 1 : 0;
        if (!$use_alarm && (Time::HiRes::time() - $start_time) > 1) {
            die "Regex timeout\n";
        }
        1;
    };
    alarm(0) if $use_alarm;
    return $ok ? $result : 0;
}

1;

__END__

=head1 NAME

Claude::Agent::Hook::Matcher - Which tools a set of hook callbacks applies to

=head1 SYNOPSIS

    use Claude::Agent::Hook::Matcher;

    my $matcher = Claude::Agent::Hook::Matcher->new(
        matcher => 'Bash',
        hooks   => [sub { ... }, sub { ... }],
        timeout => 30,
    );

    my $any = Claude::Agent::Hook::Matcher->new(
        hooks => [sub { ... }],
    );

=head1 DESCRIPTION

A matcher groups callbacks with the pattern the CLI uses to decide which
tool uses they fire for. The pattern is sent to the CLI with the
C<initialize> request and the CLI does the matching; C<matches> mirrors
that matching for code that wants to test a matcher locally.

=head1 ATTRIBUTES

=head2 matcher

A tool name, or a regular expression matched against it, such as
C<Write|Edit> or C<mcp__.*>. Unset matches every tool. For events that are
not about tools the matcher is ignored.

=head2 hooks

ArrayRef of callbacks. Each is registered with the CLI separately and the
CLI runs them in order.

=head2 timeout

Seconds the CLI allows each callback. Unset leaves the CLI's default.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 matches

    if ($matcher->matches('Bash')) { ... }

True when the pattern matches the tool name. A plain string is an exact
match; anything with regex metacharacters is a regular expression, run
with a one second alarm and refused outright when it nests quantifiers.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
