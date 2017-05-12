package Complete::Regexp::Pattern;

our $DATE = '2016-12-31'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);
use List::MoreUtils qw(uniq);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_regexp_pattern_pattern
                       complete_regexp_pattern_module
               );

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines for Regexp::Pattern',
};

$SPEC{complete_regexp_pattern_module} = {
    v => 1.1,
    summary => 'Complete with Regexp::Pattern::* module, without the Regexp::Pattern:: prefix',
    description => <<'_',

This is just a thin wrapper for:

    Complete::Module::complete_module(ns_prefix=>'Regexp::Pattern', ...)

_
    args => {
        %arg_word,
        path_sep => {
            summary => 'Will be passed to Complete::Module::complete_module',
            schema => 'str*',
        },
    },
    result_naked => 1,
};
sub complete_regexp_pattern_module {
    require Complete::Module;

    my %args = @_;

    Complete::Module::complete_module(
        ns_prefix => 'Regexp::Pattern',
        word => $args{word},
        (path_sep => $args{path_sep}) x defined($args{path_sep}),
    );
}

$SPEC{complete_regexp_pattern_pattern} = {
    v => 1.1,
    summary => 'Complete Regep::Pattern name, e.g. YouTube::video_id',
    description => <<'_',

The name is qualified with its module name, without the `Regexp::Pattern::`
prefix.

_
    args => {
        %arg_word,
        path_sep => {
            schema => 'str*',
        },
    },
    result_naked => 1,
};
sub complete_regexp_pattern_pattern {
    require Complete::Path;

    my %args = @_;

    my $word = $args{word} // '';
    #$log->tracef('[comprp] Entering complete_regexp_pattern_pattern(), word=<%s>', $word);
    #$log->tracef('[comprp] args=%s', \%args);

    # convenience (and compromise): if word doesn't contain :: we use the
    # "safer" separator /, but if already contains '::' we use '::'. (Can also
    # use '.' if user uses that.) Using "::" in bash means user needs to use
    # quote (' or ") to make completion behave as expected since : is by default
    # a word break character in bash/readline.
    my $sep = $args{path_sep};
    unless (defined $sep) {
        $sep = $word =~ /::/ ? '::' :
            $word =~ /\./ ? '.' : '/';
    }

    $word =~ s!(::|/|\.)!::!g;

    #$log->tracef('[comprp] invoking complete_path, word=<%s>', $word);
    my $res = Complete::Path::complete_path(
        word => $word,
        starting_path => 'Regexp::Pattern',
        list_func => sub {
            my ($path, $intdir, $isint) = @_;
            (my $fspath = $path) =~ s!::!/!g;
            my @res;

            for my $inc (@INC) {
                next if ref($inc);

                # list .pm files and directories
                my $dir = $inc . (length($fspath) ? "/$fspath" : "");
                #say "D:try opendir $dir ...";
                if (opendir my($dh), $dir) {
                    for my $e (readdir $dh) {
                        next if $e eq '.' || $e eq '..';
                        next unless $e =~ /\A\w+(\.\w+)?\z/;
                        my $is_dir = (-d "$dir/$e");
                        if ($is_dir) {
                            push @res, "$e\::";
                        } elsif ($e =~ /(.+)\.pm\z/) {
                            push @res, "$1\::";
                        }
                    }
                }

                # list regexp patterns inside a .pm file
                (my $file = $dir) =~ s!/\z!!; $file .= ".pm";
                {
                    no strict 'refs';
                    last unless -f $file;
                    #say "D:$file is a .pm ...";
                    (my $mod = $path) =~ s/::\z//;
                    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
                    eval { require $mod_pm; 1 } or last;
                    my $re = \%{"$mod\::RE"};
                    for (keys %$re) {
                        push @res, $_;
                    }
                }

            }
            [sort(uniq(@res))];
        },
        path_sep => '::',
        is_dir_func => sub { }, # not needed, we already suffixed "dirs" with ::
    );

    for (@$res) { s/::/$sep/g }

    $res = { words=>$res, path_sep=>$sep };
    #$log->tracef('[comprp] Leaving complete_regexp_pattern_pattern(), result=<%s>', $res);
    $res;
}

1;
# ABSTRACT: Completion routines for Regexp::Pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Regexp::Pattern - Completion routines for Regexp::Pattern

=head1 VERSION

This document describes version 0.001 of Complete::Regexp::Pattern (from Perl distribution Complete-Regexp-Pattern), released on 2016-12-31.

=head1 SYNOPSIS

 use Complete::Regexp::Pattern qw(
     complete_regexp_pattern_module
     complete_regexp_pattern_pattern
 );
 my $res = complete_regep_pattern_module(word => 'L');
 # -> {word=>['License', 'License/'], path_sep=>'/'}

 my $res = complete_regep_pattern_pattern(word => 'Y');
 # -> {word=>['YouTube/video_id'], path_sep=>'/'}

=head1 FUNCTIONS


=head2 complete_regexp_pattern_module(%args) -> any

Complete with Regexp::Pattern::* module, without the Regexp::Pattern:: prefix.

This is just a thin wrapper for:

 Complete::Module::complete_module(ns_prefix=>'Regexp::Pattern', ...)

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path_sep> => I<str>

Will be passed to Complete::Module::complete_module.

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_regexp_pattern_pattern(%args) -> any

Complete Regep::Pattern name, e.g. YouTube::video_id.

The name is qualified with its module name, without the C<Regexp::Pattern::>
prefix.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path_sep> => I<str>

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Regexp-Pattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Regexp-Pattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Regexp-Pattern>

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
