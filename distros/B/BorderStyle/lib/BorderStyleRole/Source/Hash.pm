package BorderStyleRole::Source::Hash;

use strict;
use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'BorderStyleRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.2'; # VERSION

sub get_border_char {
    my ($self, %args) = @_;

    my $char = $args{char} or die "Please specify 'char'";
    my $repeat = $args{repeat} // 1;

    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    #use DD; dd \%args;

    my $_char;

    # @MULTI_CHARS
    {
        last unless @{"$self->{orig_class}::MULTI_CHARS"};
        my $i = -1;
      ENTRY:
        for my $entry (@{"$self->{orig_class}::MULTI_CHARS"}) {
            $i++;
            #use DD; print "entry: "; dd $entry;
            for my $criteria_key (keys %$entry) {
                next unless $criteria_key =~ /^for_/;
                #print "D:criteria_key=$criteria_key ";
                next ENTRY unless defined $args{$criteria_key};
                next ENTRY unless $entry->{$criteria_key} == $args{$criteria_key};
            }
            #print "D:entry[$i] matches criteria\n";
            # the entry matches the criteria
            die "Unknown (in \$MULTI_CHARS[$i]) border character requested: '$char'"
                unless defined ($_char = $entry->{chars}{$char});
            goto PROCESS;
        } # for $entry
    }

    # %CHARS
    {
        my $chars = \%{"$self->{orig_class}::CHARS"};
        die "Unknown (in \%CHARS) border character requested: '$char'"
            unless defined ($_char = $chars->{$char});
        goto PROCESS;
    }

  PROCESS:
    # process coderef border char
    if (ref $_char eq 'CODE') {
        return $_char->(%args);
    } else {
        #print "D:char=<$_char>\n";
        return $_char x $repeat;
    }
}

1;
# ABSTRACT: Get border characters from %CHARS (or @MULTI_CHARS) package variable

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyleRole::Source::Hash - Get border characters from %CHARS (or @MULTI_CHARS) package variable

=head1 VERSION

This document describes version 3.0.2 of BorderStyleRole::Source::Hash (from Perl distribution BorderStyle), released on 2022-02-14.

=head1 SYNOPSIS

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

=head1 SEE ALSO

Other C<BorderStyleRole::Source::*> roles.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
