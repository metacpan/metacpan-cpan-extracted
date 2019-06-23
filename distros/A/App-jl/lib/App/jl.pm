package App::jl;
use strict;
use warnings;
use JSON qw//;
use Sub::Data::Recursive;
use Getopt::Long qw/GetOptionsFromArray/;

our $VERSION = '0.11';

my $MAX_DEPTH = 10;

my $MAYBE_UNIXTIME = join '|', (
    'create',
    'update',
    'expire',
    '.._(?:at|on)',
    '.ed$',
    'date',
    'time',
    'since',
    'when',
);

my $UNIXTIMESTAMP_KEY = '';

my $GMTIME;

my $INVOKER = 'Sub::Data::Recursive';

sub new {
    my $class = shift;
    my @argv  = @_;

    my $opt = $class->_parse_opt(@argv);

    my $self = bless {
        _opt  => $opt,
        _json => JSON->new->utf8->pretty(!$opt->{no_pretty})->canonical(1),
    }, $class;

    $self->_lazyload_modules;

    return $self;
}

sub opt {
    my ($self, $key) = @_;

    return $self->{_opt}{$key};
}

sub run {
    my ($self) = @_;

    while (my $orig_line = <STDIN>) {
        if ($orig_line !~ m!^\s*[\[\{]!) {
            print $orig_line;
            next;
        }
        print $self->process($orig_line);
    }
}

sub _lazyload_modules {
    my ($self) = @_;

    if ($self->opt('xxxx') || $self->opt('timestamp_key')) {
        require 'POSIX.pm'; ## no critic
        POSIX->import;
    }

    if ($self->opt('yaml')) {
        require 'YAML/Syck.pm'; ## no critic
        YAML::Syck->import;
        $YAML::Syck::SortKeys = 1;
    }
}

sub process {
    my ($self, $line) = @_;

    my $decoded = eval {
        $self->{_json}->decode($line);
    };
    if ($@) {
        return $line;
    }
    else {
        $self->_recursive_process($decoded);
        return $self->_output($decoded);

    }
}

sub _output {
    my ($self, $decoded) = @_;

    if ($self->opt('yaml')) {
        return YAML::Syck::Dump($decoded);
    }
    else {
        return $self->{_json}->encode($decoded);
    }
}

sub _recursive_process {
    my ($self, $decoded) = @_;

    $self->_recursive_pre_process($decoded);

    $self->{_depth} = $self->opt('depth');
    $self->_recursive_decode_json($decoded);

    $self->_recursive_post_process($decoded);
}

sub _recursive_pre_process {
    my ($self, $decoded) = @_;

    $INVOKER->invoke(\&_split_lf => $decoded) if $self->opt('x');
}

sub _recursive_post_process {
    my ($self, $decoded) = @_;

    if ($self->opt('x')) {
        $INVOKER->invoke(\&_split_lf => $decoded);
    }

    if ($self->opt('xx')) {
        $INVOKER->invoke(\&_split_comma => $decoded);
    }

    if ($self->opt('xxx')) {
        $INVOKER->invoke(\&_split_label => $decoded);
    }

    if ($self->opt('xxxx') || $self->opt('timestamp_key')) {
        $INVOKER->massive_invoke(\&_convert_timestamp => $decoded);
    }

    $INVOKER->invoke(\&_trim => $decoded);
}

sub _split_lf {
    my $line = $_[0];

    if ($line =~ m![\t\r\n]!) {
        chomp $line;
        my @elements = split /[\t\r\n]+/, $line;
        $_[0] = \@elements if scalar @elements > 1;
    }
}

sub _split_comma {
    my $line = $_[0];

    chomp $line;

    return $line if $line !~ m!, ! || $line =~ m!\\!;

    my @elements = split /,\s+/, $line;

    $_[0] = \@elements if scalar @elements > 1;
}

sub _split_label {
    my $line = $_[0];

    chomp $line;

    return $line if $line =~ m!\\!;

    $line =~ s!([])>])\s+([[(<])!$1$2!g;
    $line =~ s!((\[[^])>]+\]|\([^])>]+\)|<[^])>]+>))!$1\n!g; # '\n' already replaced by --x option
    my @elements = split /\n/, $line;

    $_[0] = \@elements if scalar @elements > 1;
}

my $LAST_VALUE = '';

sub _convert_timestamp {
    my $line    = $_[0];
    my $context = $_[1];

    return $line if !$context || $context ne 'HASH';

    if (
        ($UNIXTIMESTAMP_KEY && $LAST_VALUE eq $UNIXTIMESTAMP_KEY && $line =~ m!(\d+(\.\d+)?)!)
            || ($LAST_VALUE =~ m!(?:$MAYBE_UNIXTIME)!i && $line =~ m!(\d+(\.\d+)?)!)
    ) {
        if (my $date = _ts2date($1, $2)) {
            $_[0] = $date;
        }
    }

    $LAST_VALUE = $line;
}

sub _trim {
    my $line = $_[0];

    my $trim = 0;

    if ($line =~ m!^[\s\t\r\n]+!) {
        $line =~ s!^[\s\t\r\n]+!!;
        $trim = 1;
    }

    if ($line =~ m![\s\t\r\n]+$!) {
        $line =~ s![\s\t\r\n]+$!!;
        $trim = 1;
    }

    if ($trim) {
        $_[0] = $line;
    }
}

sub _ts2date {
    my $unix_timestamp = shift;
    my $msec           = shift || '';

    # 946684800 = 2000-01-01T00:00:00Z
    if ($unix_timestamp > 946684800) {
        if ($unix_timestamp > 2**31 -1) {
            ($msec) = ($unix_timestamp =~ m!(\d\d\d)$!);
            $msec = ".$msec";
            $unix_timestamp = int($unix_timestamp / 1000);
        }
        my @t = $GMTIME ? gmtime($unix_timestamp) : localtime($unix_timestamp);
        return POSIX::strftime('%Y-%m-%d %H:%M:%S', @t) . $msec;
    }
}

sub _recursive_decode_json {
    my ($self, $hash) = @_;

    Sub::Data::Recursive->invoke(sub {
        if ($self->{_depth} > 0) {
            my $orig = $_[0];
            return if $orig =~ m!^\[\d+\]$!;
            my $decoded = eval {
                $self->{_json}->decode($orig);
            };
            if (!$@) {
                $self->{_depth}--;
                $_[0] = $decoded;
                $self->_recursive_decode_json($_[0]); # recursive calling
            }
        }
    } => $hash);
}

sub _parse_opt {
    my ($class, @argv) = @_;

    my $opt = {};

    GetOptionsFromArray(
        \@argv,
        'depth=s'   => \$opt->{depth},
        'no-pretty' => \$opt->{no_pretty},
        'x'         => \$opt->{x},
        'xx'        => \$opt->{xx},
        'xxx'       => \$opt->{xxx},
        'xxxx'      => \$opt->{xxxx},
        'timestamp-key=s' => \$opt->{timestamp_key},
        'gmtime'    => \$opt->{gmtime},
        'yaml|yml'  => \$opt->{yaml},
        'h|help'    => sub {
            $class->_show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or $class->_show_usage(2);

    $opt->{depth} ||= $MAX_DEPTH;

    $opt->{xxx} ||= $opt->{xxxx};
    $opt->{xx}  ||= $opt->{xxx};
    $opt->{x}   ||= $opt->{xx};

    $UNIXTIMESTAMP_KEY = $opt->{timestamp_key};

    $GMTIME = $opt->{gmtime};

    return $opt;
}

sub _show_usage {
    my ($class, $exitval) = @_;

    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval => $exitval);
}

1;

__END__

=encoding UTF-8

=head1 NAME

App::jl - Show JSON Log Nicely


=head1 SYNOPSIS

See L<jl> for CLI to view logs.

    use App::jl;
    
    App::jl->new(@ARGV)->run;


=head1 DESCRIPTION

App::jl is recursive JSON in JSON decoder. It makes JSON log nice.


=head1 METHODS

=head2 new

constructor

=head2 opt

getter of optional values

=head2 run

The main routine

=head2 process

The parser of the line


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/App-jl"><img src="https://secure.travis-ci.org/bayashi/App-jl.png?_t=1561133163"/></a> <a href="https://coveralls.io/r/bayashi/App-jl"><img src="https://coveralls.io/repos/bayashi/App-jl/badge.png?_t=1561133163&branch=master"/></a>

=end html

App::jl is hosted on github: L<http://github.com/bayashi/App-jl>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<jl>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
