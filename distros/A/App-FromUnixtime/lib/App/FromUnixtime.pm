package App::FromUnixtime;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use IO::Interactive::Tiny;
use POSIX qw/strftime/;
use Config::CmdRC qw/.from_unixtimerc/;
use Exporter 'import';
our @EXPORT = qw/from_unixtime/;

our $VERSION = '0.17';

our $MAYBE_UNIXTIME = join '|', (
    'created_(?:at|on)',
    'updated_(?:at|on)',
    'released_(?:at|on)',
    'closed_(?:at|on)',
    'published_(?:at|on)',
    'expired_(?:at|on)',
    'date',
    'unixtime',
    '_time',
);

our $DEFAULT_DATE_FORMAT = '%a, %d %b %Y %H:%M:%S %z';

sub run {
    my $self = shift;
    my @argv = @_;

    my $config = +{};
    _get_options($config, \@argv);

    _main($config);
}

sub _main {
    my $config = shift;

    if ( ! IO::Interactive::Tiny::is_interactive(*STDIN) ) {
        while ( my $line = <STDIN> ) {
            chomp $line;
            if ( my $match = _may_replace($line, $config) ) {
                if ( ! _may_not_replace($line, $config) ) {
                    _replace_unixtime($match => \$line, $config);
                }
            }
            print "$line\n";
        }
    }
    else {
        for my $unixtime (@{$config->{unixtime}}) {
            _replace_unixtime($unixtime => \$unixtime, $config);
            print "$unixtime\n";
        }
    }
}

sub _may_replace {
    my ($line, $config) = @_;

    if ($line =~ m!(?:$MAYBE_UNIXTIME).*[^\d](\d+)!
                || ($config->{_re} && $line =~ m!(?:$config->{_re}).*[^\d](\d+)!)
                || $line =~ m!^[\s\t\r\n]*(\d+)[\s\t\r\n]*$!
    ) {
        return $1;
    }
}

sub _may_not_replace {
    my ($line, $config) = @_;

    return unless $config->{'no-re'};

    for my $no_re (@{$config->{'no-re'}}) {
        return 1 if $line =~ m!$no_re!;
    }
}

sub _replace_unixtime {
    my ($maybe_unixtime, $line_ref, $config) = @_;

    if ($maybe_unixtime > 2**31-1) {
        return;
    }

    if ($config->{'min-time'} && $maybe_unixtime < $config->{'min-time'}) {
        return;
    }

    my $date = strftime($config->{format}, localtime($maybe_unixtime));
    my $replaced_unixtime = sprintf(
        "%s%s%s%s",
        $config->{'replace'} ? '' : $maybe_unixtime,
        $config->{'start-bracket'},
        $date,
        $config->{'end-bracket'},
    );

    $$line_ref =~ s/$maybe_unixtime/$replaced_unixtime/;
}

sub from_unixtime {
    my ($lines, @argv) = @_;

    my $config = +{};
    _get_options($config, \@argv);

    my @replaced_lines;
    for my $line ( split /\n/, $lines ) {
        if ( my $match = _may_replace($line, $config) ) {
            _replace_unixtime($match => \$line, $config);
        }
        push @replaced_lines, $line;
    }
    return join("\n", @replaced_lines);
}

sub _get_options {
    my ($config, $argv) = @_;

    GetOptionsFromArray(
        $argv,
        'f|format=s'      => \$config->{format},
        'start-bracket=s' => \$config->{'start-bracket'},
        'end-bracket=s'   => \$config->{'end-bracket'},
        're=s@'           => \$config->{re},
        'no-re=s@'        => \$config->{'no-re'},
        'min-time=i'      => \$config->{'min-time'},
        'replace'         => \$config->{'replace'},
        'h|help' => sub {
            _show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or _show_usage(2);

    _validate_options($config, $argv);
}

sub _validate_options {
    my ($config, $argv) = @_;

    $config->{format} ||= RC->{format} || $DEFAULT_DATE_FORMAT;
    $config->{'start-bracket'} ||= RC->{'start-bracket'} || '(';
    $config->{'end-bracket'}   ||= RC->{'end-bracket'}   || ')';
    if (ref RC->{re} eq 'ARRAY') {
        push @{$config->{re}}, @{RC->{re}};
    }
    elsif (RC->{re}) {
        push @{$config->{re}}, RC->{re};
    }
    if ($config->{re}) {
        $config->{_re} = join '|', map { quotemeta $_;  } @{$config->{re}};
    }
    push @{$config->{unixtime}}, @{$argv};
}

sub _show_usage {
    my $exitval = shift;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
}

1;

__END__

=head1 NAME

App::FromUnixtime - to convert from unixtime to date suitably


=head1 SYNOPSIS

    use App::FromUnixtime;

    App::FromUnixtime->run(@ARGV);


=head1 DESCRIPTION

C<App::FromUnixtime> provides the L<from_unixtime> command and the B<from_unixtime> function.


=head1 METHOD

=head2 run

run to convert process


=head1 EXPORT FUNCTION

=head2 from_unixtime($line, @options)

C<App::FromUnixtime> exports B<from_unixtime> function for converting the string that may be included unixtime.

    use App::FromUnixtime;

    print from_unixtime('created_at 1419702037'); # created_at 1419702037(Sun, 28 Dec 2014 02:40:37 +0900)

    print from_unixtime('created_at 1419702037', '--format' => '%Y-%m-%d'); # created_at 1419702037(2014-12-28)

See L<from_unixtime> command for more options.


=head1 REPOSITORY

App::FromUnixtime is hosted on github: L<http://github.com/bayashi/App-FromUnixtime>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<from_unixtime>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
