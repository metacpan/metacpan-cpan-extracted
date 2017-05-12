package App::LJ;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use JSON::XS ();
use JSON::Color ();

my $_coder;
sub _coder {
    $_coder ||= JSON::XS->new->pretty(1);
}

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
    unless (exists $opt->{color}) {
        $opt->{color} = 1;
    }
    bless $opt, $class;
}

sub _pretty_print {
    my ($self, $json) = @_;

    ($self->{printer} ||= do {
        !$self->{color} ? sub { chomp(my $l = $_coder->encode(shift)); $l} : sub { JSON::Color::encode_json(shift, {pretty => 1}) }
    })->($json);
}

sub run {
    my $self = shift;
    print $self->_process_line($_) . "\n" while <STDIN>;
}

sub _process_line {
    my ($self, $line) = @_;
    chomp $line;

    if ($line =~ /\s*\[?\{.*\}\]?\s*/) {
        my $pre = $`;
        my $maybe_json = $&;
        my $post = $';

        my $json;
        eval {
            $json = _coder->decode($maybe_json);
        };
        if (!$@) {
            my $r = '';
            $r .= "$pre\n" if $pre ne '';
            $r .= $self->_pretty_print($json);
            $r .= "\n$post" if $post ne '';
            return $r;
        }
    }
    return $line;
}

sub _print_usage {
    my $pretty = JSON::Color::encode_json({key => "value", array => [1,2,3]}, {pretty => 1});
    $pretty =~ s/^/    /msg;

    print <<'...', $pretty , "\n";
Usage:
    % echo '2015-01-31 [21:06:22] json: {"key": "value", "array": [1,2,3]}' | lj [--no-color]'
    2015-01-31 [21:06:22] json:
...
    exit;
}


1;
__END__

=encoding utf-8

=head1 NAME

App::LJ - detect json and prettify it from log

=head1 SYNOPSIS

    use App::LJ;

=head1 DESCRIPTION

App::LJ is backend module of L<lj>.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

