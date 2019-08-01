package App::ParseCPANChanges;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.070'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{parse_cpan_changes} = {
    v => 1.1,
    summary => 'Parse CPAN Changes file',
    args => {
	file => {
	    schema => 'filename*',
	    summary => 'If not specified, will look for file called '.
		'Changes/ChangeLog in current directory',
	    pos => 0,
	},
        class => {
            schema => 'perl::modname*',
            default => 'CPAN::Changes',
        },
    },
};
sub parse_cpan_changes {
    require Data::Structure::Util;

    my %args = @_;

    my $class = $args{class} // 'CPAN::Changes';
    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $file = $args{file};
    if (!$file) {
	for (qw/Changes ChangeLog/) {
	    do { $file = $_; last } if -f $_;
	}
    }
    return [400, "Please specify file ".
                "(or run in directory where Changes file exists)"]
        unless $file;

    my $ch = $class->load($file);
    [200, "OK", Data::Structure::Util::unbless($ch)];
}

1;
# ABSTRACT: Parse CPAN Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ParseCPANChanges - Parse CPAN Changes file

=head1 VERSION

This document describes version 0.070 of App::ParseCPANChanges (from Perl distribution App-ParseCPANChanges), released on 2019-07-03.

=head1 DESCRIPTION

This distribution provides a simple command-line wrapper for
L<CPAN::Changes>. See L<parse-cpan-changes> for more details.

=head1 FUNCTIONS


=head2 parse_cpan_changes

Usage:

 parse_cpan_changes(%args) -> [status, msg, payload, meta]

Parse CPAN Changes file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class> => I<perl::modname> (default: "CPAN::Changes")

=item * B<file> => I<filename>

If not specified, will look for file called Changes/ChangeLog in current directory.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ParseCPANChanges>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ParseCPANChanges>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ParseCPANChanges>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Changes>

L<CPAN::Changes::Spec>

An alternative way to manage your Changes using INI master format:
L<Module::Metadata::Changes>.

Dist::Zilla plugin to check your Changes before build:
L<Dist::Zilla::Plugin::CheckChangesHasContent>,
L<Dist::Zilla::Plugin::CheckChangeLog>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
