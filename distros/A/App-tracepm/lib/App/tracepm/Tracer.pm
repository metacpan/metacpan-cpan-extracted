package App::tracepm::Tracer;

our $DATE = '2020-04-08'; # DATE
our $VERSION = '0.230'; # VERSION

# saving CORE::GLOBAL::require doesn't work
my $orig_require;

sub import {
    my $self = shift;

    # already installed
    return if $orig_require;

    # doesn't mention any file, e.g. in 00-compile.t
    my $file = shift
        or return;

    my $opts = {
        workaround_log4perl => 1,
    };
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    }


    open my($fh), ($ENV{TRACEPM_TRACER_APPEND} ? ">>":">"),
        $file or die "Can't open $file: $!";

    #$orig_require = \&CORE::GLOBAL::require;
    *CORE::GLOBAL::require = sub {
        my ($arg) = @_;
        my $caller = caller;
        if ($INC{$arg}) {
            if ($opts->{workaround_log4perl}) {
                # Log4perl <= 1.43 still does 'eval "require $foo" or ...'
                # instead of 'eval "require $foo; 1" or ...' so running will
                # fail. this workaround makes require() return 1.
                return 1 if $caller =~ /^Log::Log4perl/;
            }
            return 0;
        }
        unless ($arg =~ /\A\d/) { # skip 'require 5.xxx'
            print $fh $arg, "\t", $caller, "\n";
        }

        #$orig_require->($arg);
        CORE::require($arg);
    };
}

1;
# ABSTRACT: Trace module require to file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::tracepm::Tracer - Trace module require to file

=head1 VERSION

This document describes version 0.230 of App::tracepm::Tracer (from Perl distribution App-tracepm), released on 2020-04-08.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-tracepm>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-tracepm>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-tracepm>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
