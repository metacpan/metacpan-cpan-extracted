package App::optex::glob;

our $VERSION = '0.01';

use v5.14;
use warnings;
use utf8;
use Data::Dumper;

use List::Util qw(first);
use Hash::Util qw(lock_keys);
use Text::Glob qw(glob_to_regex);
use File::Basename qw(basename);

my %opt = (
    regex   => undef,
    path    => undef,
    include => [],
    exclude => [],
    debug   => undef,
);
lock_keys %opt;

use List::Util qw(pairmap);

sub hash_to_spec {
    pairmap {
	$a = "$a|${\(uc(substr($a, 0, 1)))}";
	if    (not defined $b) { "$a"   }
	elsif ($b =~ /^\d+$/)  { "$a=i" }
	else                   { "$a=s" }
    } %{+shift};
}

sub finalize {
    my($mod, $argv) = @_;
    my $i = (first { $argv->[$_] eq '--' } keys @$argv) // return;
    splice @$argv, $i, 1; # remove '--'
    local @ARGV = splice @$argv, 0, $i or return;

    use Getopt::Long qw(GetOptionsFromArray);
    Getopt::Long::Configure qw(bundling);
    GetOptions \%opt, hash_to_spec \%opt or die "Option parse error.\n";

    push @{$opt{include}}, splice @ARGV;
    return if @{$opt{include}} + @{$opt{exclude}} == 0;

    my(@include_re, @exclude_re);
    for ( [ \@include_re, $opt{include} ] ,
	  [ \@exclude_re, $opt{exclude} ] ) {
	my($a, $b) = @$_;
	@$a = do {
	    if ($opt{regex}) {
		map qr/$_/, @$b;
	    } else {
		map glob_to_regex($_), @$b;
	    }
	};
    }

    my $test = sub {
	local $_ = shift;
	-e or return 1;
	$_ = basename($_) if not $opt{path};
	for my $re (@exclude_re) { /$re/ and return 0 }
	for my $re (@include_re) { /$re/ and return 1 }
	return @include_re > 0 ? 0 : 1;
    };

    @$argv = grep $test->($_), @$argv;
}

1;

=encoding utf-8

=head1 NAME

glob - optex filter to glob filenames

=head1 SYNOPSIS

optex -Mglob [ option ] pattern -- command

=head1 DESCRIPTION

This module is used to select filenames given as arguments by pattern.

For example, the following will pass only files matching C<*.c> from
C<*/*> as arguments to C<ls>.

    optex -Mglob '*.c' -- ls -l */*

Only existing file names will be selected.  Any arguments that do not
correspond to files will be passed through as is.  In this example,
the command name and options remain as they are because no
corresponding file exists.  Be aware that the existence of a
corresponding file could lead to confusing results.

There are several unique options that are valid only for this module.

=over 7

=item B<--exclude> I<pattern>

Option C<--exclude> will mean the opposite.

    optex -Mglob --exclude '*.c' -- ls */*

If the C<--exclude> option is used with positive patterns, the exclude
pattern takes precedence.  The following command selects files
matching C<*.c>, but excludes those begin with a capital letter.

    optex -Mglob --exclude '[A-Z]*' '*.c' -- ls */*

This opiton can be used multiple times.

=item B<--regex>

If the C<--regex> option is given, patterns are evaluated as a regular
expression instead of a glob pattern.

    optex -Mglob --regex '\.c$' -- ls */*

=item B<--path>

With the C<--path> option it matches against the entire path, not just
the filename.

    optex -Mglob --path '^*_test/' -- ls */*

=back

=head1 CONSIDERATION

You should also consider using the extended globbing (extglob) feature
of L<bash(1)> or similar. For example, you can use C<!(*.EN).md>,
which would specify files matching *.md minus those matching
C<*.EN.md>.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
