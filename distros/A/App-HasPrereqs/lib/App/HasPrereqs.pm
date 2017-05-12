package App::HasPrereqs;

our $DATE = '2016-01-18'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG qw($log);

use Config::IniFiles;
use Module::Path::More qw(module_path);
use Sort::Versions;

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(has_prereqs);

$SPEC{has_prereqs} = {
    v => 1.1,
    summary =>
        'Check whether your Perl installation has prerequisites in dist.ini',
    args => {
        library => {
            schema => ['array*' => {of => 'str*'}],
            summary => 'Add directory to @INC',
            cmdline_aliases => {I => {}},
        },
    },
};
sub has_prereqs {

    my %args = @_;

    my $libs = $args{library} // [];
    local @INC = @INC;
    unshift @INC, $_ for @$libs;

    (-f "dist.ini")
        or return [412, "No dist.ini found, ".
                       "is your dist managed by Dist::Zilla?"];

    my $cfg = Config::IniFiles->new(-file => "dist.ini", -fallback => "ALL");
    $cfg or return [
        500, "Can't open dist.ini: ".join(", ", @Config::IniFiles::errors)];

    my @errs;
    for my $section (grep {
        m!^prereqs (?: \s*/\s* .+)?$!ix} $cfg->Sections) {
      MOD:
        for my $mod ($cfg->Parameters($section)) {
            my $v = $cfg->val($section, $mod);
            $log->infof("Checking prerequisite: %s=%s ...", $mod, $v);
            if ($v eq '0') {
                if ($mod eq 'perl') {
                    # do nothing
                } elsif (!module_path(module => $mod)) {
                    push @errs, {
                        module  => $mod,
                        needed_version => $v,
                        message => "Missing"};
                }
            } else {
                my $iv;
                if ($mod eq 'perl') {
                    $iv = $^V; $iv =~ s/^v//;
                    unless (Sort::Versions::versioncmp($iv, $v) >= 0) {
                        push @errs, {
                            module  => $mod,
                            has_version => $iv,
                            needed_version => $v,
                            message => "Version too old ($iv, needs $v)"};
                    }
                    next MOD;
                }
                my $modp = $mod; $modp =~ s!::!/!g; $modp .= ".pm";
                unless ($INC{$modp} || eval { require $modp; 1 }) {
                    push @errs, {
                        module  => $mod,
                        needed_version => $v,
                        message => "Missing"};
                    next MOD;
                }
                no strict 'refs'; no warnings;
                my $iv = ${"$mod\::VERSION"};
                unless ($iv && Sort::Versions::versioncmp($iv, $v) >= 0) {
                    push @errs, {
                        module  => $mod,
                        has_version => $iv,
                        needed_version => $v,
                        message => "Version too old ($iv, needs $v)"};
                }
            }
        }
    }

    [200, @errs ? "Some prerequisites unmet" : "OK", \@errs,
     {"cmdline.exit_code"=>@errs ? 200:0}];
}

1;
# ABSTRACT: Check whether your Perl installation has prerequisites in dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HasPrereqs - Check whether your Perl installation has prerequisites in dist.ini

=head1 VERSION

This document describes version 0.09 of App::HasPrereqs (from Perl distribution App-HasPrereqs), released on 2016-01-18.

=head1 SYNOPSIS

 # Use via has-prereqs CLI script

=head1 FUNCTIONS


=head2 has_prereqs(%args) -> [status, msg, result, meta]

Check whether your Perl installation has prerequisites in dist.ini.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<library> => I<array[str]>

Add directory to @INC.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-HasPrereqs>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-App-HasPrereqs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-HasPrereqs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
