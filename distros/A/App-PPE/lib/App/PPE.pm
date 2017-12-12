package App::PPE;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use Parse::ErrorString::Perl;
use Term::ANSIColor qw//;

# https://perldoc.perl.org/perldiag.html#DESCRIPTION
our $TAG_MAP = {
     W => 'WARN',
     D => 'WARN',
     S => 'WARN',
     F => 'CRITICAL',
     P => 'CRITICAL',
     X => 'ERROR',
     A => 'ERROR',

     undef => 'UNKNOWN',
};

our $COLOR = {
    'warn' => {
        text       => 'black',
        background => 'yellow',
    },
    'critical' => {
        text       => 'black',
        background => 'red'
    },
    'error' => {
        text       => 'red',
        background => 'black'
    },
    'unknown' => {
        text       => 'white',
        background => 'red'
    }
};

our $FORMAT = sub {
    my ($tag, $type, $message, $file, $line) = @_;
    return "$file:$line: [$tag] ($type) $message";
};



sub new_with_options {
    my ($class, @argv) = @_;

    my ($opt) = $class->parse_options(@argv);
    $class->new($opt);
}

sub parse_options {
    my ($class, @argv) = @_;

    if (grep /^--?h(?:elp)?$/, @argv) {
        _print_usage();
    }

    my $opt = {};
    my @rest;
    for my $v (@argv) {
        if ($v eq '--no-color') {
            $opt->{color} = undef;
            next;
        }
        push @rest, $v;
    }
    ($opt, \@rest)
}

sub new {
    my $class = shift;

    my $opt = @_ == 1 ? $_[0] : {@_};
    unless (exists $opt->{parser}) {
        $opt->{parser} = Parse::ErrorString::Perl->new()
    }

    unless (exists $opt->{color}) {
        $opt->{color} = 1;
    }

    bless $opt, $class;
}

sub run {
    my $self = shift;
    print $self->prettify_perl_error($_) . "\n" while <STDIN>
}

sub prettify_perl_error {
    my ($self, $perl_error) = @_;

    my ($error_item) = $self->{parser}->parse_string($perl_error);
    return $perl_error unless $error_item;
    $self->prettify_error_item($error_item);
}

sub prettify_error_item {
    my ($self, $error_item) = @_;

    my $tag     = $self->_prettify_tag($error_item);
    my $type    = $self->_prettify_type($error_item);
    my $message = $self->_prettify_message($error_item);
    my $file    = $self->_prettify_file($error_item);

    $FORMAT->($tag, $type, $message, $file, $error_item->line);
}

sub _tag {
    my $error_item = shift;
    my $type = $error_item->type // 'undef';
    return $TAG_MAP->{$type};
}

sub _prettify_color {
    my ($self, $error_item) = @_;

    return {} unless $self->{color};

    my $tag = _tag($error_item);
    my $color = $COLOR->{lc($tag)};

    return $color;
}

sub _prettify_tag {
    my ($self, $error_item) = @_;

    my $tag  = _tag($error_item);
    my $color = $self->_prettify_color($error_item);
    $tag = Term::ANSIColor::color($color->{text}) . $tag . Term::ANSIColor::color("reset") if $color->{text};
    $tag = Term::ANSIColor::color("on_".$color->{background}) . $tag . Term::ANSIColor::color("reset") if $color->{background};

    return $tag;
}

sub _prettify_type {
    my ($self, $error_item) = @_;
    return $error_item->type // 'undef';
}

sub _prettify_message {
    my ($self, $error_item) = @_;

    my $message = $error_item->message;
    if (my $near = $error_item->near) {
        $near =~ s/:$//;
        $message .= ", near " . $near;
    }

    return $message;
}

sub _prettify_file {
    my ($self, $error_item) = @_;
    return $error_item->file;
}


sub _print_usage {
    print <<'EOS';
        $ echo 'syntax error at /home/kfly8/foo.pl line 52, near "$foo:"' | ppe
            foo.pl:52: [CRITICAL] syntax error: near $foo
EOS

    exit;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::PPE - Prettify Perl Error messages

=head1 SYNOPSIS

    use App::PPE;

=head1 DESCRIPTION

App::PPE is is backend module of L<ppe>.

=head1 LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kenta, Kobayashi E<lt>kentafly88@gmail.comE<gt>

=cut

