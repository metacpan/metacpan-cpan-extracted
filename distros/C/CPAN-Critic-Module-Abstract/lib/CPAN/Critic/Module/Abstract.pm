package CPAN::Critic::Module::Abstract;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.091'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use Package::Stash;
use Perinci::Sub::DepChecker qw(check_deps);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       critique_cpan_module_abstract
                       declare_policy
               );

our %PROFILES;
our %SPEC;

sub declare_policy {
    my %args = @_;
    my $name = $args{name} or die "Please specify name";
    $SPEC{"policy_$name"} and die "Policy $name already declared";
    #$args{summary} or die "Please specify summary";

    my $meta = {
        v => 1.1,
        summary => $args{summary},
    };
    $meta->{deps} = $args{deps} if $args{deps};
    $meta->{args} = {
        abstract => {req=>1, schema=>'str*'},
        stash    => {schema=>'hash*'},
    };
    if ($args{args}) {
        for (keys %{ $args{args} }) {
            $meta->{args}{$_} = $args{args}{$_};
        }
    }
    $meta->{"_cpancritic.severity"} = $args{severity} // 3;
    $meta->{"_cpancritic.themes"}   = $args{themes} // [];

    no strict 'refs';
    *{__PACKAGE__."::policy_$name"} = $args{code};
    $SPEC{"policy_$name"} = $meta;
}

declare_policy
    name => 'prohibit_empty',
    severity => 5,
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab =~ /\S/) {
            [200];
        } else {
            [409];
        }
    };

declare_policy
    name => 'prohibit_too_short',
    severity => 4,
    args => {
        min_len => {schema=>['int*', default=>3]},
    },
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        my $l  = $args{min_len} // 3;
        if (!length($ab)) {
            [412];
        } elsif (length($ab) >= $l) {
            [200];
        } else {
            [409];
        }
    };

declare_policy
    name => 'prohibit_too_long',
    severity => 3,
    args => {
        max_len => {schema=>['int*', default=>72]},
    },
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        my $l  = $args{max_len} // 72;
        if (length($ab) <= $l) {
            [200];
        } else {
            [409];
        }
    };

declare_policy
    name => 'prohibit_multiline',
    severity => 3,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab !~ /\n/) {
            [200];
        } else {
            [409];
        }
    };

declare_policy
    name => 'prohibit_template',
    severity => 5,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab =~ /^(Perl extension for blah blah blah)/i) {
            [409, "Template from h2xs '$1'"];
        } elsif ($ab =~ /^(The great new )\w+(::\w+)*/i) {
            [409, "Template from module-starter '$1'"];
        } elsif ($ab =~ /^\b(blah blah)\b/i) {
            [409, "Looks like a template"];
        } else {
            [200];
        }
    };

declare_policy
    name => 'prohibit_starts_with_lowercase_letter',
    severity => 2,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if (!length($ab)) {
            [412];
        } elsif ($ab =~ /^[[:lower:]]/) {
            [409];
        } else {
            [200];
        }
    };

declare_policy
    name => 'prohibit_ends_with_full_stop',
    severity => 2,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab =~ /\.\z/) {
            [409];
        } else {
            [200];
        }
    };

declare_policy
    name => 'prohibit_redundancy',
    severity => 3,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab =~ /^( (?: (?:a|the) \s+)?
                        (?: perl\s?[56]? \s+)?
                        (?:extension|module|library|interface|xs \s binding)
                        (?: \s+ (?:to|for))?
                    )/xi) {
            [409, "Saying '$1' is redundant, omit it"];
        } else {
            [200];
        }
    };

declare_policy
    name => 'require_english',
    severity => 2,
    args => {},
    deps => {pm=>'Lingua::Identify'},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        my %langs = Lingua::Identify::langof($ab);
        return [412, "Empty result from langof"] unless keys(%langs);
        my @langs = sort { $langs{$b}<=>$langs{$a} } keys %langs;
        my $confidence = Lingua::Identify::confidence(%langs);
        log_trace(
            "Lingua::Identify result: langof=%s, langs=%s, confidence=%s",
            \%langs, \@langs, $confidence);
        if ($langs[0] ne 'en') {
            [409, "Language not detected as English, ".
                 sprintf("%d%% %s (confidence %.2f)",
                         $langs{$langs[0]}*100, $langs[0], $confidence)];
        } else {
            [200];
        }
    };

declare_policy
    name => 'prohibit_shouting',
    severity => 2,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab =~ /!{3,}/) {
            [409, "Too many exclamation points"];
        } else {
            my $spaces = 0; $spaces++ while $ab =~ s/\s+//;
            $ab =~ s/\W+//g;
            $ab =~ s/\d+//g;
            if ($ab =~ /^[[:upper:]]+$/ && $spaces >= 2) {
                return [409, "All-caps"];
            } else {
                return [200];
            }
        }
    };

declare_policy
    name => 'prohibit_just_module_name',
    severity => 2,
    args => {},
    code => sub {
        my %args = @_;
        my $ab = $args{abstract};
        if ($ab =~ /^\w+(::\w+)+$/) {
            [409, "Should not just be a module name"];
        } else {
            [200];
        }
    };

# policy: don't repeat module name
# policy: should be verb + ...

$PROFILES{all} = {
    policies => [],
};
for (Package::Stash->new(__PACKAGE__)->list_all_symbols("CODE")) {
    next unless /^policy_(.+)/;
    push @{$PROFILES{all}{policies}}, $1;
}
$PROFILES{default} = $PROFILES{all};
# XXX default: 4/5 if length > 100?

$SPEC{critique_cpan_module_abstract} = {
    v => 1.1,
    summary => 'Critic CPAN module abstract',
    args => {
        abstract => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        profile => {
            schema => ['str*' => {default=>'default'}],
        },
    },
};
sub critique_cpan_module_abstract {
    my %args = @_;
    my $abstract = $args{abstract} // "";
    my $profile  = $args{profile} // "default";

    # some cleanup for abstract
    for ($abstract) {
        s/\A\s+//; s/\s+\z//;
    }

    my $pr = $PROFILES{$profile} or return [400, "No such profile '$profile'"];

    my @res;
    log_trace("Running critic profile %s on abstract %s ...",
                 $profile, $abstract);
    my $pass;
    my $stash = {};
    for my $pol0 (@{ $pr->{policies} }) {
        log_trace("Running policy %s ...", $pol0);
        my $pol = ref($pol0) eq 'HASH' ? %$pol0 : {name=>$pol0};
        my $spec = $SPEC{"policy_$pol->{name}"} or
            return [400, "No such policy $pol->{name}"];
        if ($spec->{deps}) {
            my $err = check_deps($spec->{deps});
            return [500, "Can't run policy $pol->{name}: ".
                        "dependency failed: $err"] if $err;
        }
        no strict 'refs';
        my $code = \&{__PACKAGE__ . "::policy_$pol->{name}"};
        my $res = $code->(abstract=>$abstract, stash=>$stash); # XXX args
        log_trace("Result from policy %s: %s", $pol->{name}, $res);
        if ($res->[0] == 409) {
            my $severity = $spec->{"_cpancritic.severity"};
            $pass = 0 if $severity >= 5;
            push @res, {
                severity=>$severity,
                message=>$res->[1] // "Violates $pol->{name}",
            };
        }
    }
    $pass //= 1;

    #[200, "OK", {pass=>$pass, detail=>\@res}];
    [200, "OK", \@res];
}

1;
# ABSTRACT: Critic CPAN module abstract

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Critic::Module::Abstract - Critic CPAN module abstract

=head1 VERSION

This document describes version 0.091 of CPAN::Critic::Module::Abstract (from Perl distribution CPAN-Critic-Module-Abstract), released on 2019-07-03.

=head1 SYNOPSIS

 % critic-cpan-module-abstract 'Perl extension for blah blah blah'

 # customize profile (add/remove policies, modify severities, ...)
 # TODO

=head1 DESCRIPTION

B<STATUS:> This module is deprecated in favor of L<Module::Abstract::Cwalitee>.

This is a proof-of-concept module to critic CPAN module abstract.

Dist::Zilla plugin coming shortly.

=head1 FUNCTIONS


=head2 critique_cpan_module_abstract

Usage:

 critique_cpan_module_abstract(%args) -> [status, msg, payload, meta]

Critic CPAN module abstract.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<profile> => I<str> (default: "default")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_empty

Usage:

 policy_prohibit_empty(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_ends_with_full_stop

Usage:

 policy_prohibit_ends_with_full_stop(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_just_module_name

Usage:

 policy_prohibit_just_module_name(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_multiline

Usage:

 policy_prohibit_multiline(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_redundancy

Usage:

 policy_prohibit_redundancy(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_shouting

Usage:

 policy_prohibit_shouting(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_starts_with_lowercase_letter

Usage:

 policy_prohibit_starts_with_lowercase_letter(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_template

Usage:

 policy_prohibit_template(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_too_long

Usage:

 policy_prohibit_too_long(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<max_len> => I<int> (default: 72)

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_prohibit_too_short

Usage:

 policy_prohibit_too_short(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<min_len> => I<int> (default: 3)

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 policy_require_english

Usage:

 policy_require_english(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abstract>* => I<str>

=item * B<stash> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(.*)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Critic-Module-Abstract>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Critic-Module-Abstract>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Critic-Module-Abstract>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
