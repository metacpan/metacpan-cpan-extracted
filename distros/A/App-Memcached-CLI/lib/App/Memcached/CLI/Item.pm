package App::Memcached::CLI::Item;

use strict;
use warnings;
use 5.008_001;

use POSIX 'strftime';

use App::Memcached::CLI::Util ':all';

use version; our $VERSION = 'v0.9.5';

my @FIELDS = qw(key value length expire flags cas);
my %DISP_METHOD_OF = (
    value  => 'disp_value',
    length => 'disp_length',
    expire => 'disp_expire',
);

my $DISPLAY_DATA_LENGTH = 320;

sub new {
    my $class = shift;
    my %data  = @_;
    bless \%data, $class;
}

sub find {
    my $class = shift;
    my $keys  = shift;
    my $ds    = shift;
    my %opt   = @_;

    my $command = $opt{command} || 'get';
    my $list    = $ds->$command($keys);
    my @items;
    for my $data (@$list) {
        push(@items, bless($data, $class));
    }

    return \@items;
}

sub save {
    my $self = shift;
    my $ds   = shift;
    my %opt  = @_;

    for my $key (qw/flags expire value/) {
        if ($opt{$key}) { $self->{$key} = $opt{$key}; }
    }
    my %option = (
        flags  => $self->{flags},
        expire => $self->{expire},
    );

    my $command = $opt{command} || 'set';
    if ($command eq 'cas') {
        return $ds->$command(@$self{qw/key value cas/}, %option);
    } else {
        return $ds->$command(@$self{qw/key value/}, %option);
    }
}

sub remove {
    my $self = shift;
    my $ds   = shift;
    my $ret  = $ds->delete($self->{key});
    return $ret;
}

sub output {
    my $self = shift;
    my $space = q{ } x 4;
    for my $key (@FIELDS) {
        my $value = $self->{$key};
        if (my $_method = $DISP_METHOD_OF{$key}) {
            $value = $self->$_method;
        }
        next unless defined $value;
        printf "%s%6s:%s%s\n", $space, $key, $space, $value;
    }
}

sub output_line {
    my $self = shift;
    $self->{disp_max_value_length} = 100;

    my @kv;
    for my $key (@FIELDS) {
        my $value = $self->{$key};
        if (my $_method = $DISP_METHOD_OF{$key}) {
            $value = $self->$_method;
        }
        next unless defined $value;
        push @kv, join(q{:}, ucfirst $key, $value);
    }
    printf "%s\n", join("\t", @kv);
}

sub disp_length {
    my $self = shift;
    $self->{disp_length} ||= sub {
        return unless (defined $self->{length});
        my $length = $self->{length};
        if ($length >= 1024) {
            return sprintf '%.1fKB', $length / 1024.0;
        }
        return "${length}B";
    }->();
    return $self->{disp_length};
}

sub disp_expire {
    my $self = shift;
    $self->{disp_expire} ||= sub {
        return unless (defined $self->{expire});
        return strftime('%F %T', localtime($self->{expire}));
    }->();
    return $self->{disp_expire};
}

sub disp_value {
    my $self = shift;
    my $text = $self->value_text;
    return unless (defined $text);

    my $max_length = $self->{disp_max_value_length} || $DISPLAY_DATA_LENGTH;
    return $text if (length $text <= $max_length);

    my $length = length $text;
    my $result = substr($text, 0, $max_length - 1);
    $result .= '...(skipped)';
    return $result;
}

sub value_text {
    my $self = shift;
    $self->{value_text} ||= sub {
        return unless (defined $self->{value});
        if ($self->{value} !~ m/^[\x21-\x7e\s]/) {
            return '(Not ASCII)';
        }
        return $self->{value};
    }->();
    return $self->{value_text};
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::CLI::Item - Object module of Memcached data item

=head1 SYNOPSIS

    use App::Memcached::CLI::Item;
    my $item = App::Memcached::CLI::Item->get($key, $self->{ds});
    print $item->output;

=head1 DESCRIPTION

This package acts as object of Memcached data item.

=head1 LICENSE

Copyright (C) IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=cut

