package App::PerlGlue;

use strict;
use warnings;
use feature qw(say);
use JSON::PP qw(encode_json decode_json);
use Text::ParseWords qw(parse_line);

our $VERSION = '0.04';

sub run {
    my ($class, @argv) = @_;
    my $cmd = shift @argv // 'help';

    return _help() if $cmd eq 'help' || $cmd eq '--help' || $cmd eq '-h';

    if ($cmd eq 'version' || $cmd eq '--version' || $cmd eq '-v') {
        say "perlglue $VERSION";
        return 0;
    }

    return _cmd_command_help($cmd)            if @argv && ($argv[0] eq '--help' || $argv[0] eq '-h');

    return _cmd_upper()                      if $cmd eq 'upper';
    return _cmd_lower()                      if $cmd eq 'lower';
    return _cmd_lines(@argv)                 if $cmd eq 'lines';
    return _cmd_lines(@argv)                 if $cmd eq 'where';
    return _cmd_replace(@argv)               if $cmd eq 'replace';
    return _cmd_pick(@argv)                  if $cmd eq 'pick';
    return _cmd_convert(@argv)               if $cmd eq 'convert' || $cmd eq 'csv' || $cmd eq 'from-csv';
    return _cmd_jsonl(@argv)                 if $cmd eq 'jsonl';
    return _cmd_template(@argv)              if $cmd eq 'template';
    return _cmd_rename(@argv)                if $cmd eq 'rename';

    warn "Unknown command: $cmd\n\n";
    _help();
    return 2;
}

sub _cmd_upper { while (my $line = <STDIN>) { print uc $line } return 0 }
sub _cmd_lower { while (my $line = <STDIN>) { print lc $line } return 0 }

sub _open_in {
    my ($file) = @_;
    return *STDIN unless defined $file && length $file;
    open my $fh, '<', $file or die "Cannot open $file: $!";
    return $fh;
}

sub _cmd_lines {
    my (@argv) = @_;
    my ($file, $expr);
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--where') { $expr = shift @argv; }
        elsif (!defined $file) { $file = $arg; }
        elsif (!defined $expr) { $expr = $arg; }
    }
    my $fh = _open_in($file);
    while (my $line = <$fh>) {
        local $_ = $line;
        if (defined $expr) {
            my $ok = eval $expr;
            next unless $ok;
        }
        print $line;
    }
    return 0;
}

sub _cmd_replace {
    my (@argv) = @_;
    my $expr = shift @argv // die "replace requires perl substitution expression\n";
    my $fh = _open_in(shift @argv);
    while (my $line = <$fh>) {
        local $_ = $line;
        eval $expr;
        print $_;
    }
    return 0;
}

sub _parse_csv_rows {
    my ($fh) = @_;
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '';
        push @rows, [ parse_line(',', 1, $line) ];
    }
    return @rows;
}

sub _cmd_pick {
    my (@argv) = @_;
    my $file = shift @argv // die "pick requires file\n";
    my $flag = shift @argv // '';
    die "pick expects --csv name,email\n" unless $flag eq '--csv';
    my @wanted = split /,/, (shift(@argv) // '');

    my $fh = _open_in($file);
    my @rows = _parse_csv_rows($fh);
    my $header = shift @rows // [];
    my %idx; @idx{@$header} = (0 .. $#$header);

    say join ',', @wanted;
    for my $r (@rows) {
        my @out = map { defined $idx{$_} ? $r->[ $idx{$_} ] : '' } @wanted;
        say join ',', @out;
    }
    return 0;
}

sub _cmd_convert {
    my (@argv) = @_;
    my $file = shift @argv // die "convert requires file\n";
    my $to;
    while (@argv) {
        my $a = shift @argv;
        $to = shift @argv if $a eq '--to';
    }
    die "convert only supports --to jsonl\n" unless defined $to && $to eq 'jsonl';

    my $fh = _open_in($file);
    my @rows = _parse_csv_rows($fh);
    my $header = shift @rows // [];
    for my $r (@rows) {
        my %obj;
        @obj{@$header} = @$r;
        say encode_json(\%obj);
    }
    return 0;
}

sub _cmd_jsonl {
    my (@argv) = @_;
    my ($file, $expr, $where);
    while (@argv) {
        my $a = shift @argv;
        if ($a eq '--where') { $where = shift @argv; }
        elsif (!defined $file && $a !~ /^\$_\-/) { $file = $a; }
        elsif (!defined $expr) { $expr = $a; }
    }
    $expr = $where if defined $where;
    my $fh = _open_in($file);
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '';
        local $_ = decode_json($line);
        if (defined $expr) {
            my $ok = eval $expr;
            next unless $ok;
        }
        say encode_json($_);
    }
    return 0;
}

sub _cmd_template {
    my (@argv) = @_;
    my $file = shift @argv // die "template requires file\n";
    my $tpl = shift @argv // die "template requires template string\n";

    my $fh = _open_in($file);
    my @rows = _parse_csv_rows($fh);
    my $header = shift @rows // [];
    for my $r (@rows) {
        my %obj;
        @obj{@$header} = @$r;
        (my $out = $tpl) =~ s/\{\{\s*(\w+)\s*\}\}/defined $obj{$1} ? $obj{$1} : ''/ge;
        say $out;
    }
    return 0;
}

sub _cmd_rename {
    my (@argv) = @_;
    my $expr = shift @argv // die "rename requires substitution expression\n";
    for my $old (@argv) {
        (my $new = $old);
        local $_ = $new;
        eval $expr;
        $new = $_;
        next if $new eq $old;
        die "Target exists: $new\n" if -e $new;
        rename $old, $new or die "rename $old -> $new failed: $!";
        say "$old -> $new";
    }
    return 0;
}

sub _cmd_command_help {
    my ($cmd) = @_;
    my %usage = (
        upper    => 'perlglue upper < input.txt',
        lower    => 'perlglue lower < input.txt',
        lines    => 'perlglue lines [file] [--where EXPR]',
        where    => 'perlglue where [file] [--where EXPR]',
        replace  => q{perlglue replace 's/foo/bar/g' [file]},
        pick     => 'perlglue pick users.csv --csv name,email',
        convert  => 'perlglue convert users.csv --to jsonl',
        csv      => 'perlglue csv users.csv --to jsonl',
        'from-csv' => 'perlglue from-csv users.csv --to jsonl',
        jsonl    => q{perlglue jsonl logs.jsonl '\$_->{status} >= 500'},
        template => q{perlglue template users.csv 'Hello, {{name}}'},
        rename   => q{perlglue rename 's/\s+/_/g' files...},
        version  => 'perlglue version',
        help     => 'perlglue help',
    );

    if (exists $usage{$cmd}) {
        say $usage{$cmd};
        return 0;
    }

    warn "Unknown command: $cmd\n";
    return 2;
}

sub _help {
    print <<'HELP';
perlglue - glue messy text into useful shapes

Usage:
  perlglue help
  perlglue --help
  perlglue version
  perlglue <command> --help
  perlglue upper < input.txt
  perlglue lower < input.txt
  perlglue lines [file] [--where EXPR]
  perlglue replace 's/foo/bar/g' [file]
  perlglue pick users.csv --csv name,email
  perlglue convert users.csv --to jsonl
  perlglue jsonl logs.jsonl '$_->{status} >= 500'
  perlglue template users.csv 'Hello, {{name}}'
  perlglue rename 's/\s+/_/g' files...
HELP
    return 0;
}

1;

__END__

=head1 NAME

App::PerlGlue - glue messy text into useful shapes

=head1 SYNOPSIS

  # text
  echo 'Perl is glue' | perlglue upper
  echo 'LOUD' | perlglue lower
  perlglue lines app.log --where '$_ =~ /ERROR/'
  perlglue replace 's/(?<=user=)\w+/REDACTED/g' app.log

  # csv/jsonl
  perlglue pick users.csv --csv name,email
  perlglue convert users.csv --to jsonl
  perlglue jsonl logs.jsonl '$_->{status} >= 500'
  perlglue template users.csv 'Hello, {{name}}'

  # filesystem
  perlglue rename 's/\s+/_/g' *.txt

=head1 DESCRIPTION

C<App::PerlGlue> provides the C<perlglue> command-line program for practical
text munging when simple one-liners become hard to maintain.

It focuses on connecting line-based text, CSV-ish input, and JSON Lines with a
single command surface and Perl expressions.

=head1 COMMANDS

=head2 help

Show built-in usage text.

=head2 version

Print the installed C<perlglue> version.

=head2 upper

Read STDIN and write uppercase text.

=head2 lower

Read STDIN and write lowercase text.

=head2 lines [file] [--where EXPR]

Read from a file (or STDIN if omitted) and print each line.
When C<--where EXPR> is provided, only lines where the Perl expression is true
are printed. The current line is available in C<$_>.

=head2 where [file] [EXPR]

Alias of C<lines>. Accepts the filter expression either as positional C<EXPR>
or via C<--where>.

=head2 replace 's/.../.../flags' [file]

Apply a Perl substitution expression to each input line and print the result.
Input is read from C<file> or STDIN.

=head2 pick FILE --csv fields

Extract selected CSV columns by header name. C<fields> is a comma-separated
header list (for example C<name,email>).

=head2 convert FILE --to jsonl

Convert CSV rows into JSON Lines objects keyed by the CSV header row.
Currently only C<--to jsonl> is supported.

=head2 csv / from-csv

Aliases for C<convert>.

=head2 jsonl [file] [EXPR]

Read JSON Lines, decode each line into C<$_>, and print each object as JSON.
If an expression is provided (or via C<--where EXPR>), only matching objects
are printed.

=head2 template FILE TEMPLATE

Apply simple C<{{field}}> placeholder substitution for each CSV row.
Fields are looked up from the CSV header.

=head2 rename 's/.../.../flags' files...

Safely rename files using a Perl substitution expression. The command fails if
a target path already exists.

=head1 NOTES

=over 4

=item *

CSV parsing currently uses C<Text::ParseWords::parse_line> with comma
separation and quote handling suitable for typical CLI data.

=item *

Filter and replacement expressions are evaluated as Perl code; use trusted
input only.

=back

=head1 AUTHOR

Shingo Kawamura E<lt>pannakoota@gmail.comE<gt>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
