package App::tabify;

our $DATE = '2015-01-31'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010;
use strict;
use warnings;

use Getopt::Long::Complete qw(GetOptionsWithCompletion);
use POSIX qw(ceil);

my %Opts = (
    tab_width      => 8,
    in_place       => 0,
    #backup_ext     => undef,
);

sub parse_cmdline {
    my $res = GetOptionsWithCompletion(
        sub {},
        'tab-width|w=i' => \$Opts{tab_width},
        #'in-place|i'  => sub { # XXX in-place|i:s doesn't work?
        #    $Opts{in_place} = 1;
        #    #$Opts{backup_ext} = $_[1] if defined $_[1];
        #},
        'version|v'     => sub {
            no warnings 'once';
            say "tabify version $main::VERSION";
            exit 0;
        },
        'help|h'        => sub {
            print <<USAGE;
Usage:
  (un)tabify [OPTIONS] <FILE...>
  (un)tabify --help|-h
  (un)tabify --version|-v
Options:
  --tab-width=i, -w  Set tab width (default: 8).
For more details, see the manpage/documentation.
USAGE
            exit 0;
        },
    );
    exit 99 if !$res;
}

sub run {
    my $which = shift; # either 'tabify' or 'untabify'

    my $oldargv = '';
    my $argvout;

    my $tw = $Opts{tab_width};

  LINE:
    while (<>) {
        #if ($ARGV ne $oldargv) {
        #    if (defined($Opts{backup_ext}) && $Opts{backup_ext} ne '') {
        #        rename $ARGV, "$ARGV$Opts{backup_ext}";
        #        open $argvout, ">", $ARGV;
        #        select $argvout;
        #        $oldargv = $ARGV;
        #    }
        #}
        if ($which eq 'untabify') {
            1 while s|^(.*?)\t|$1 .
                (" " x (ceil((length($1)+1)/$tw)*$tw - length($1)))|em;
        } else {
            s|^([ ]{2,})|
                ("\t" x int(length($1)/$tw)) .
                     (" " x (length($1) - int(length($1)/$tw)*$tw))|em;
        }
    } continue {
        print;
    }
    #select STDOUT;
}

1;
# ABSTRACT: Convert spaces to tabs (tabify), or tabs to spaces (untabify)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::tabify - Convert spaces to tabs (tabify), or tabs to spaces (untabify)

=head1 VERSION

This document describes version 0.01 of App::tabify (from Perl distribution App-tabify), released on 2015-01-31.

=head1 SYNOPSIS

See the command-line scripts L<tabify> and L<untabify>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-tabify>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-tabify>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-tabify>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
