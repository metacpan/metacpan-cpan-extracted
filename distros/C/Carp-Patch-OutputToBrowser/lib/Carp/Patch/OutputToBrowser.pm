## no critic: TestingAndDebugging::RequireUseStrict
package Carp::Patch::OutputToBrowser;

use 5.010001;
#use strict 'vars';
no warnings;

use Browser::Open qw(open_browser);
use Data::Dump::HTML::Collapsible qw(dump);
use File::Temp qw(tempfile);
use HTML::Entities qw(encode_entities);
use Module::Patch;
use base qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-12'; # DATE
our $DIST = 'Carp-Patch-OutputToBrowser'; # DIST
our $VERSION = '0.001'; # VERSION

our %config;

my $p_ret_backtrace = sub {
    my ( $i, @error ) = @_;
    my $mess;
    my $err = join '', @error;
    $i++;

    my $tid_msg = '';
    if ( defined &threads::tid ) {
        my $tid = threads->tid;
        $tid_msg = " thread $tid" if $tid;
    }

    my %i = Carp::caller_info($i);
    $mess = "<h3>".encode_entities("$i. $err at $i{file} line $i{line}$tid_msg");
    if( $. ) {
      # Use ${^LAST_FH} if available.
      if (LAST_FH) {
        if (${+LAST_FH}) {
            $mess .= sprintf ", <%s> %s %d",
                              *${+LAST_FH}{NAME},
                              ($/ eq "\n" ? "line" : "chunk"), $.
        }
      }
      else {
        local $@ = '';
        local $SIG{__DIE__};
        eval {
            CORE::die;
        };
        if($@ =~ /^Died at .*(, <.*?> (?:line|chunk) \d+).$/ ) {
            $mess .= $1;
        }
      }
    }
    $mess .= "\.</h3>\n";

    while ( my %i = Carp::caller_info( ++$i ) ) {
        $mess .= "\t$i{sub_name} called at $i{file} line $i{line}$tid_msg<br />\n";
    }

    my ($temp_fh, $temp_filename) = tempfile("stacktrace-XXXXXXXX", SUFFIX=>".html", TMPDIR=>1) or die;
    print $temp_fh $mess;
    close $temp_fh;
    open_browser($temp_filename);

    return "Backtrace is output to $temp_filename and opened in browser\n";
};

sub patch_data {
    return {
        v => 3,
        config => {
        },
        patches => [
            {
                action      => 'replace',
                sub_name    => 'ret_backtrace',
                code        => $p_ret_backtrace,
            },
        ],
   };
}

1;
# ABSTRACT: Output stacktrace to browser as HTML instead of returning it

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::Patch::OutputToBrowser - Output stacktrace to browser as HTML instead of returning it

=head1 VERSION

This document describes version 0.001 of Carp::Patch::OutputToBrowser (from Perl distribution Carp-Patch-OutputToBrowser), released on 2024-03-12.

=head1 SYNOPSIS

Using with L<Devel::Confess> (since it uses Carp):

 % PERL5OPT="-MCarp::Patch::OutputToBrowser -MDevel::Confess::Patch::UseDataDumpHTMLCollapsible -d:Confess=dump" yourscript.pl

=head1 DESCRIPTION

=for Pod::Coverage ^()$

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Patch-OutputToBrowser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Carp-Patch-OutputToBrowser>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Patch-OutputToBrowser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
