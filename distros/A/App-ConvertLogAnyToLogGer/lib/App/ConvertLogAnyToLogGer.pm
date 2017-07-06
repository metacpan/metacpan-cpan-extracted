package App::ConvertLogAnyToLogGer;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use PPI;

our %SPEC;

my %log_statements = (
    trace => "trace",
    debug => "debug",
    info => "info",
    warn => "warn",
    warning => "warn",
    error => "error",
    fatal => "fatal",
);

$SPEC{convert_log_any_to_log_ger} = {
    v => 1.1,
    summary => 'Convert code that uses Log::Any to use Log::ger',
    description => <<'_',

This is a tool to help converting code that uses <pm:Log::Any> to use
<pm:Log::ger>. It converts:

    use Log::Any;
    use Log::Any '$log';

    use Log::Any::IfLOG;
    use Log::Any::IfLOG '$log';

to:

    use Log::ger;

It converts:

    $log->warn("blah");
    $log->warn("blah", "more blah");

to:

    log_warn("blah");
    log_warn("blah", "more blah"); # XXX this actually does not work and needs to be converted to e.g. log_warn(join(" ", "blah", "more blah"));

It converts:

    $log->warnf("blah %s", $arg);

to:

    log_warn("blah %s", $arg);

It converts:

    $log->is_warn

to:

    log_is_warn()

_
    args => {
        input => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub convert_log_any_to_log_ger {
    my %args = @_;

    my $doc = PPI::Document->new(\$args{input});
    my $envres;
    my $res = $doc->find(
        sub {
            my ($top, $el) = @_;

            my $match;
            if ($el->isa('PPI::Statement::Include')) {
                # matching 'use Log::Any' or "use Log::Any '$log'"
                my $c0 = $el->child(0);
                if ($c0->content eq 'use') {
                    my $c1 = $c0->next_sibling;
                    if ($c1->content eq ' ') {
                        my $c2 = $c1->next_sibling;
                        if ($c2->content =~ /\A(Log::Any::IfLOG|Log::Any)\z/) {
                            if ($args{_detect}) {
                                $envres = [200, "OK", 1, {'cmdline.result'=>'', 'cmdline.exit_code' => 1}];
                                goto RETURN_ENVRES;
                            }
                            $c2->insert_before(PPI::Token::Word->new("Log::ger"));
                            my $remove_cs;
                            my $cs = $c2;
                            while (1) {
                                $cs = $cs->next_sibling;
                                $remove_cs->remove if $remove_cs;
                                last unless $cs;
                                last if $cs->isa("PPI::Token::Structure") && $cs->content eq ';';
                                $remove_cs = $cs;
                            }
                            $c2->remove;
                        }
                    }
                }
            }

            if ($el->isa('PPI::Statement')) {
                # matching '$log->trace(...);' or '$log->tracef(...);'
                my $c0 = $el->child(0);
                if ($c0->content eq '$log') {
                    my $c1 = $c0->snext_sibling;
                    if ($c1->content eq '->') {
                        my $c2 = $c1->snext_sibling;
                        my $c2c = $c2->content;
                        if (grep { $c2c eq $_ } keys %log_statements) {
                            my $func = "log_".$log_statements{$c2c};
                            # insert "log_trace"
                            $c0->insert_after(PPI::Token::Word->new($func));
                            $c0->remove(); # remove $log
                            $c1->remove; # remove '->'
                            $c2->remove; # remove 'trace'
                        } elsif (grep { $c2c eq "${_}f" } keys %log_statements) {
                            (my $key = $c2c) =~ s/f$//;
                            my $func = "log_".$log_statements{$key};
                            # insert "log_trace"
                            $c0->insert_after(PPI::Token::Word->new($func));
                            $c0->remove(); # remove $log
                            $c1->remove; # remove '->'
                            $c2->remove; # remove 'tracef'
                        } else {
                            warn "Unreplaced: \$log->$c2c in line ".
                                $el->line_number."\n";
                        }
                    }
                }
            }

            if ($el->isa('PPI::Statement::Compound')) {
                # matching 'if ($log->is_trace) { ... }'
                my $c0 = $el->child(0);
                if ($c0->content eq 'if') {
                    my $cond = $c0->snext_sibling;
                    if ($cond->isa('PPI::Structure::Condition')) {
                        my $expr = $cond->child(0);
                        if ($expr->isa('PPI::Statement::Expression')) {
                            my $c0 = $expr->child(0);
                            if ($c0->content eq '$log') {
                                my $c1 = $c0->snext_sibling;
                                if ($c1->content eq '->') {
                                    my $c2 = $c1->snext_sibling;
                                    my $c2c = $c2->content;
                                    if (grep { $c2c eq "is_$_" } keys %log_statements) {
                                        (my $key = $c2c) =~ s/^is_//;
                                        my $func = "log_is_".$log_statements{$key};
                                        # insert "log_is_trace"
                                        $c0->insert_after(PPI::Token::Word->new($func));
                                        $c0->remove(); # remove $log
                                        $c1->remove; # remove '->'
                                        $c2->remove; # remove 'is_trace'
                                    }
                                }
                            }
                        }
                    }
                }
            }

            0;
        }
    );
    die "BUG: find() dies: $@!" unless defined($res);

    if ($args{_detect}) {
        $envres = [200, "OK", 0, {'cmdline.result'=>'', 'cmdline.exit_code' => 0}];
        goto RETURN_ENVRES;
    }

    $envres = [200, "OK", $doc->serialize];

  RETURN_ENVRES:
    $envres;
}

$SPEC{detect_log_any_usage} = {
    v => 1.1,
    summary => 'Detect whether code uses Log::Any',
    description => <<'_',

The CLI will return exit code 1 when usage of Log::Any is detected. It will
return 0 otherwise.

_
    args => {
        input => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
    },
};
sub detect_log_any_usage {
    convert_log_any_to_log_ger(@_, _detect=>1);
}

1;
# ABSTRACT: Convert code that uses Log::Any to use Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ConvertLogAnyToLogGer - Convert code that uses Log::Any to use Log::ger

=head1 VERSION

This document describes version 0.002 of App::ConvertLogAnyToLogGer (from Perl distribution App-ConvertLogAnyToLogGer), released on 2017-07-03.

=head1 SYNOPSIS

See the included script L<convert-log-any-to-log-ger>.

=head1 FUNCTIONS


=head2 convert_log_any_to_log_ger

Usage:

 convert_log_any_to_log_ger(%args) -> [status, msg, result, meta]

Convert code that uses Log::Any to use Log::ger.

This is a tool to help converting code that uses L<Log::Any> to use
L<Log::ger>. It converts:

 use Log::Any;
 use Log::Any '$log';
 
 use Log::Any::IfLOG;
 use Log::Any::IfLOG '$log';

to:

 use Log::ger;

It converts:

 $log->warn("blah");
 $log->warn("blah", "more blah");

to:

 log_warn("blah");
 log_warn("blah", "more blah"); # XXX this actually does not work and needs to be converted to e.g. log_warn(join(" ", "blah", "more blah"));

It converts:

 $log->warnf("blah %s", $arg);

to:

 log_warn("blah %s", $arg);

It converts:

 $log->is_warn

to:

 log_is_warn()

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 detect_log_any_usage

Usage:

 detect_log_any_usage(%args) -> [status, msg, result, meta]

Detect whether code uses Log::Any.

The CLI will return exit code 1 when usage of Log::Any is detected. It will
return 0 otherwise.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ConvertLogAnyToLogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ConvertLogAnyToLogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ConvertLogAnyToLogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::ger>

L<Log::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
