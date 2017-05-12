package Complete::Fish;

our $DATE = '2016-10-21'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       format_completion
               );

require Complete::Bash;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion module for fish shell',
};

$SPEC{format_completion} = {
    v => 1.1,
    summary => 'Format completion for output (for shell)',
    description => <<'_',

fish accepts completion reply in the form of one entry per line to STDOUT.
Description can be added to each entry, prefixed by tab character.

_
    args_as => 'array',
    args => {
        completion => {
            summary => 'Completion answer structure',
            description => <<'_',

Either an array or hash, as described in `Complete`.

_
            schema=>['any*' => of => ['hash*', 'array*']],
            req=>1,
            pos=>0,
        },
    },
    result => {
        summary => 'Formatted string (or array, if `as` key is set to `array`)',
        schema => ['any*' => of => ['str*', 'array*']],
    },
    result_naked => 1,
};
sub format_completion {
    my $comp = shift;

    my $as;
    my $entries;

    # we currently use Complete::Bash's rule because i haven't done a read up on
    # how exactly fish escaping rules are.
    if (ref($comp) eq 'HASH') {
        $as = $comp->{as} // 'string';
        $entries = Complete::Bash::format_completion({%$comp, as=>'array'});
    } else {
        $as = 'string';
        $entries = Complete::Bash::format_completion({
            words=>$comp, as=>'array',
        });
    }

    # insert description
    {
        my $compary = ref($comp) eq 'HASH' ? $comp->{words} : $comp;
        for (my $i=0; $i<@$compary; $i++) {

            my $desc = (ref($compary->[$i]) eq 'HASH' ?
                            $compary->[$i]{description} : '' ) // '';
            $desc =~ s/\R/ /g;
            $entries->[$i] .= "\t$desc";
        }
    }

    # turn back to string if that's what the user wants
    if ($as eq 'string') {
        $entries = join("", map{"$_\n"} @$entries);
    }
    $entries;
}

1;
# ABSTRACT: Completion module for fish shell

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Fish - Completion module for fish shell

=head1 VERSION

This document describes version 0.05 of Complete::Fish (from Perl distribution Complete-Fish), released on 2016-10-21.

=head1 DESCRIPTION

fish allows completion of option arguments to come from an external command,
e.g.:

 % complete -c deluser -l user -d Username -a "(cat /etc/passwd|cut -d : -f 1)"

The command is supposed to return completion entries one in a separate line.
Description for each entry can be added, prefixed with a tab character. The
provided function C<format_completion()> accept a completion answer structure
and format it for fish. Example:

 format_completion(["a", "b", {word=>"c", description=>"Another letter"}])

will result in:

 a
 b
 c       Another letter

=head1 FUNCTIONS


=head2 format_completion($completion) -> str|array

Format completion for output (for shell).

fish accepts completion reply in the form of one entry per line to STDOUT.
Description can be added to each entry, prefixed by tab character.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$completion>* => I<hash|array>

Completion answer structure.

Either an array or hash, as described in C<Complete>.

=back

Return value: Formatted string (or array, if `as` key is set to `array`) (str|array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Fish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Fish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Fish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

L<Complete::Bash>

Fish manual.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
