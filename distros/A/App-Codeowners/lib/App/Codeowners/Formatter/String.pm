package App::Codeowners::Formatter::String;
# ABSTRACT: Format codeowners output using printf-like strings


use warnings;
use strict;

our $VERSION = '0.45'; # VERSION

use parent 'App::Codeowners::Formatter';

use App::Codeowners::Util qw(stringf zip);
use Color::ANSI::Util 0.03 qw(ansifg);
use Encode qw(encode);

sub stream {
    my $self    = shift;
    my $result  = shift;

    $result = {zip @{$self->columns}, @$result};

    my %info = (
        F => $self->_create_filterer->($result->{File},    undef),
        O => $self->_create_filterer->($result->{Owner},   $self->_owner_colorgen),
        P => $self->_create_filterer->($result->{Project}, undef),
        T => $self->_create_filterer->($result->{Pattern}, undef),
    );

    my $text = stringf($self->format, %info);
    print { $self->handle } encode('UTF-8', $text), "\n";
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

sub _ansi_reset { "\033[0m" }

sub _colored {
    my $text = shift;
    my $rgb  = shift or return $text;

    return $text if $ENV{NO_COLOR} || (defined $ENV{COLOR_DEPTH} && !$ENV{COLOR_DEPTH});

    $rgb =~ s/^(.)(.)(.)$/$1$1$2$2$3$3/;
    if ($rgb !~ m/^[0-9a-fA-F]{6}$/) {
        warn "Color value must be in 'ffffff' or 'fff' form.\n";
        return $text;
    }

    my ($begin, $end) = (ansifg($rgb), _ansi_reset);
    return "${begin}${text}${end}";
}

sub _create_filterer {
    my $self = shift;

    my %filter = (
        quote   => sub { local $_ = $_[0]; s/"/\"/s; "\"$_\"" },
    );

    return sub {
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
}

sub _owner_colorgen {
    my $self = shift;

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
    $self->{owner_color} ||= sub {
        my $owner = shift or return;
        $owner_colors{$owner} ||= do {
            $num = ($num + 1) % scalar @contrasting_colors;
            $contrasting_colors[$num];
        };
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Formatter::String - Format codeowners output using printf-like strings

=head1 VERSION

version 0.45

=head1 DESCRIPTION

This is a L<App::Codeowners::Formatter> that formats output using a printf-like string.

See L<git-codeowners/"Format string">.

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
