package App::Codeowners;
# ABSTRACT: A tool for managing CODEOWNERS files

use v5.10.1;    # defined-or
use utf8;
use warnings;
use strict;

use App::Codeowners::Options;
use App::Codeowners::Util qw(find_codeowners_in_directory run_git git_ls_files git_toplevel stringf);
use Color::ANSI::Util qw(ansifg ansi_reset);
use Encode qw(encode);
use File::Codeowners;
use Path::Tiny;

our $VERSION = '0.41'; # VERSION


sub main {
    my $class = shift;
    my $self  = bless {}, $class;

    my $opts = App::Codeowners::Options->new(@_);

    my $color = $opts->{color};
    local $ENV{NO_COLOR} = 1 if defined $color && !$color;

    my $command = $opts->command;
    my $handler = $self->can("_command_$command")
        or die "Unknown command: $command\n";
    $self->$handler($opts);

    exit 0;
}

sub _command_show {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = File::Codeowners->parse_from_filepath($codeowners_path);

    my ($cdup) = run_git(qw{rev-parse --show-cdup});

    my @results;

    my $filepaths = git_ls_files('.', $opts->args) or die "Cannot list files\n";
    for my $filepath (@$filepaths) {
        my $match = $codeowners->match(path($filepath)->relative($cdup));
        push @results, [
            $filepath,
            $match->{owners},
            $opts->{project} ? $match->{project} : (),
        ];
    }

    _format(
        format  => $opts->{format} || ' * %-50F %O',
        out     => *STDOUT,
        headers => [qw(File Owner), $opts->{project} ? 'Project' : ()],
        rows    => \@results,
    );
}

sub _command_owners {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = File::Codeowners->parse_from_filepath($codeowners_path);

    my $results = $codeowners->owners($opts->{pattern});

    _format(
        format  => $opts->{format} || '%O',
        out     => *STDOUT,
        headers => [qw(Owner)],
        rows    => [map { [$_] } @$results],
    );
}

sub _command_patterns {
    my $self = shift;
    my $opts = shift;

    my $toplevel = git_toplevel('.') or die "Not a git repo\n";

    my $codeowners_path = find_codeowners_in_directory($toplevel)
        or die "No CODEOWNERS file in $toplevel\n";
    my $codeowners = File::Codeowners->parse_from_filepath($codeowners_path);

    my $results = $codeowners->patterns($opts->{owner});

    _format(
        format  => $opts->{format} || '%T',
        out     => *STDOUT,
        headers => [qw(Pattern)],
        rows    => [map { [$_] } @$results],
    );
}

sub _command_create { goto &_command_update }
sub _command_update {
    my $self = shift;
    my $opts = shift;

    my ($filepath) = $opts->args;

    my $path = path($filepath || '.');
    my $repopath;

    die "Does not exist: $path\n" if !$path->parent->exists;

    if ($path->is_dir) {
        $repopath = $path;
        $path = find_codeowners_in_directory($path) || $repopath->child('CODEOWNERS');
    }

    my $is_new = !$path->is_file;

    my $codeowners;
    if ($is_new) {
        $codeowners = File::Codeowners->new;
        my $template = <<'END';
 This file shows mappings between subdirs/files and the individuals and
 teams who own them. You can read this file yourself or use tools to query it,
 so you can quickly determine who to speak with or send pull requests to. ❤️

 Simply write a gitignore pattern followed by one or more names/emails/groups.
 Examples:
   /project_a/**  @team1
   *.js  @harry @javascript-cabal
END
        for my $line (split(/\n/, $template)) {
            $codeowners->append(comment => $line);
        }
    }
    else {
        $codeowners = File::Codeowners->parse_from_filepath($path);
    }

    if ($repopath) {
        # if there is a repo we can try to update the list of unowned files
        my $git_files = git_ls_files($repopath);
        if (@$git_files) {
            $codeowners->clear_unowned;
            $codeowners->add_unowned(grep { !$codeowners->match($_) } @$git_files);
        }
    }

    $codeowners->write_to_filepath($path);
    print STDERR "Wrote $path\n";
}

sub _format {
    my %args = @_;

    my $format  = $args{format}  || 'table';
    my $fh      = $args{out}     || *STDOUT;
    my $headers = $args{headers} || [];
    my $rows    = $args{rows}    || [];

    if ($format eq 'table') {
        eval { require Text::Table::Any } or die "Missing dependency: Text::Table::Any\n";

        my $table = Text::Table::Any::table(
            header_row  => 1,
            rows        => [$headers, map { [map { _stringify($_) } @$_] } @$rows],
            backend     => $ENV{PERL_TEXT_TABLE},
        );
        print { $fh } encode('UTF-8', $table);
    }
    elsif ($format =~ /^json(:pretty)?$/) {
        my $pretty = !!$1;
        eval { require JSON::MaybeXS } or die "Missing dependency: JSON::MaybeXS\n";

        my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1, pretty => $pretty);
        my $data = _combine_headers_rows($headers, $rows);
        print { $fh } $json->encode($data);
    }
    elsif ($format =~ /^([ct])sv$/) {
        my $sep = $1 eq 'c' ? ',' : "\t";
        eval { require Text::CSV } or die "Missing dependency: Text::CSV\n";

        my $csv = Text::CSV->new({binary => 1, eol => $/, sep => $sep});
        $csv->print($fh, $headers);
        $csv->print($fh, [map { encode('UTF-8', _stringify($_)) } @$_]) for @$rows;
    }
    elsif ($format =~ /^ya?ml$/) {
        eval { require YAML } or die "Missing dependency: YAML\n";

        my $data = _combine_headers_rows($headers, $rows);
        print { $fh } encode('UTF-8', YAML::Dump($data));
    }
    else {
        my $data = _combine_headers_rows($headers, $rows);

        # https://sashat.me/2017/01/11/list-of-20-simple-distinct-colors/
        my @contrasting_colors = qw(
            e6194b 3cb44b ffe119 4363d8 f58231
            911eb4 42d4f4 f032e6 bfef45 fabebe
            469990 e6beff 9a6324 fffac8 800000
            aaffc3 808000 ffd8b1 000075 a9a9a9
        );

        # assign a color to each owner, on demand
        my %owner_colors;
        my $num = -1;
        my $owner_color = sub {
            my $owner = shift or return;
            $owner_colors{$owner} ||= do {
                $num = ($num + 1) % scalar @contrasting_colors;
                $contrasting_colors[$num];
            };
        };

        my %filter = (
            quote   => sub { local $_ = $_[0]; s/"/\"/s; "\"$_\"" },
        );

        my $create_filterer = sub {
            my $value = shift || '';
            my $color = shift || '';
            my $gencolor = ref($color) eq 'CODE' ? $color : sub { $color };
            return sub {
                my $arg = shift;
                my ($filters, $color) = _expand_filter_args($arg);
                if (ref($value) eq 'ARRAY') {
                    $value = join(',', map { _colored($_, $color // $gencolor->($_)) } @$value);
                }
                else {
                    $value = _colored($value, $color // $gencolor->($value));
                }
                for my $key (@$filters) {
                    if (my $filter = $filter{$key}) {
                        $value = $filter->($value);
                    }
                    else {
                        warn "Unknown filter: $key\n"
                    }
                }
                $value || '';
            };
        };

        for my $row (@$data) {
            my %info = (
                F => $create_filterer->($row->{File},    undef),
                O => $create_filterer->($row->{Owner},   $owner_color),
                P => $create_filterer->($row->{Project}, undef),
                T => $create_filterer->($row->{Pattern}, undef),
            );

            my $text = stringf($format, %info);
            print { $fh } encode('UTF-8', $text), "\n";
        }
    }
}

sub _expand_filter_args {
    my $arg = shift || '';

    my @filters = split(/,/, $arg);
    my $color_override;

    for (my $i = 0; $i < @filters; ++$i) {
        my $filter = $filters[$i] or next;
        if ($filter =~ /^(?:nocolor|color:([0-9a-fA-F]{3,6}))$/) {
            $color_override = $1 || '';
            splice(@filters, $i, 1);
            redo;
        }
    }

    return (\@filters, $color_override);
}

sub _colored {
    my $text = shift;
    my $rgb  = shift or return $text;

    # ansifg honors NO_COLOR already, but ansi_reset does not.
    return $text if $ENV{NO_COLOR};

    $rgb =~ s/^(.)(.)(.)$/$1$1$2$2$3$3/;
    if ($rgb !~ m/^[0-9a-fA-F]{6}$/) {
        warn "Color value must be in 'ffffff' or 'fff' form.\n";
        return $text;
    }

    my ($begin, $end) = (ansifg($rgb), ansi_reset);
    return "${begin}${text}${end}";
}

sub _combine_headers_rows {
    my $headers = shift;
    my $rows    = shift;

    my @new_rows;

    for my $row (@$rows) {
        push @new_rows, (my $new_row = {});
        for (my $i = 0; $i < @$headers; ++$i) {
            $new_row->{$headers->[$i]} = $row->[$i];
        }
    }

    return \@new_rows;
}

sub _stringify {
    my $item = shift;
    return ref($item) eq 'ARRAY' ? join(',', @$item) : $item;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners - A tool for managing CODEOWNERS files

=head1 VERSION

version 0.41

=head1 METHODS

=head2 main

    App::Codeowners->main(@ARGV);

Run the script and exit; does not return.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
