use utf8;
use strict;
use warnings;

package DBIx::DR::PerlishTemplate;
use Mouse;
use Carp;
use Scalar::Util;
use DBIx::DR::ByteStream;

has     line_tag        => (is => 'rw', isa => 'Str',   default => '%');
has     open_tag        => (is => 'rw', isa => 'Str',   default => '<%');
has     close_tag       => (is => 'rw', isa => 'Str',   default => '%>');
has     quote_mark      => (is => 'rw', isa => 'Str',   default => '=');
has     immediate_mark  => (is => 'rw', isa => 'Str',   default => '==');

has     sql             => (is => 'ro', isa => 'Str',   default => '');
has     variables       => (is => 'ro', isa => 'ArrayRef');

has     template        => (is => 'rw', isa => 'Str',   default => '');
has     template_file   => (is => 'rw', isa => 'Str',   default => '');

has     stashes         => (is => 'ro', isa => 'ArrayRef');
has     pretokens       => (is => 'ro', isa => 'ArrayRef');
has     prepretokens    => (is => 'ro', isa => 'ArrayRef');
has     parsed_template => (is => 'ro', isa => 'Str',   default => '');
has     namespace       => (is => 'rw', isa => 'Str',
                        default => 'DBIx::DR::PerlishTemplate::Sandbox');


has sql_utf8     => (is => 'ro', isa => 'Bool', default => 1);
sub _render {
    my ($_PTPL) = @_;
    my $_PTSUB;

    unless ($_PTPL->parsed_template) {
        $_PTSUB = $_PTPL->{parsed_template} = $_PTPL->_parse;
    } else {
        $_PTSUB = $_PTPL->parsed_template;
    }

    $_PTPL->{parsed_template} = $_PTSUB;

    my $esub = eval $_PTSUB;
    if (my $e = $@) {
        my $do_croak;
        my $template;
        if ($_PTPL->template_file) {
            $template = $_PTPL->template_file;
        } else {
            $do_croak = 1;
            $template = 'inline template';
        };
        $e =~ s{ at .*?line (\d+)(\.\s*|,\s+.*?)?$}
            [" at $template line " . ( $1 - $_PTPL->pre_lines )]gsme;

        if ($1) {
            $e =~ s/\s*$/\n/g;
            die $e unless $do_croak;
            croak $e;
        }

        croak "$e at $template";
    }

    $_PTPL->{sql} = '';
    $_PTPL->{variables} = [];

    $esub->( @{ $_PTPL->stashes } );
    1;
}

sub render {
    my ($self, $tpl, @args) = @_;
    $self->{parsed_template} = '';
    $self->template($tpl);
    $self->template_file('');
    $self->{stashes} = \@args;
    $self->clean_namespace;
    return $self->_render;
}

sub render_file {
    my ($self, $file, @args)  = @_;
    croak "File '@{[ $file // 'undef' ]}' not found or readable"
        unless -r $file;
    open my $fh, '<:raw', $file;
    my $data;

    { local $/; $data = <$fh> }

    utf8::decode $data if $self->sql_utf8;

    $self->{parsed_template} = '';
    $self->template_file($file);
    $self->template($data);
    $self->{stashes} = \@args;
    $self->clean_namespace;
    return $self->_render;
}

sub clean_prepends {
    my ($self) = @_;
    $self->{pretokens} = [];
    $self;
}

sub clean_preprepends {
    my ($self) = @_;
    $self->{prepretokens} = [];
    $self;
}


sub immediate {
    my ($self, $str) = @_;
    if (Scalar::Util::blessed $str) {
        if ('DBIx::DR::ByteStream' eq Scalar::Util::blessed $str) {
            $self->{sql} .= $str->content;
        } elsif ($str->can('content')) {
            $self->{sql} .= $str->content;
        } else {
            croak "Can't extract content from " . Scalar::Util::blessed $str;
        }
    } else {
        $self->{sql} .= $str;
    }
    return DBIx::DR::ByteStream->new('');
}

sub add_bind_value {
    my ($self, @values) = @_;
    push @{ $self->variables } => @values;
}


sub quote {
    my ($self, $variable) = @_;

    if (Scalar::Util::blessed $variable) {
        return $self->immediate($variable)
            if 'DBIx::DR::ByteStream' eq Scalar::Util::blessed $variable;
    }

    $self->{sql} .= '?';
    $self->add_bind_value($variable);
    return DBIx::DR::ByteStream->new('');
}

sub _parse {
    my ($self) = @_;

    my $result = '';

    my $immediate_mark = $self->immediate_mark;
    my $quote_mark = $self->quote_mark;

    my $code_cb = sub {
        my ($t) = @_;
        return unless defined $t and length $t;

        if ($t =~ /^\Q$immediate_mark\E/) {
            $result .= join '',
                'immediate(',
                    substr($t, length($immediate_mark)),
                ');';
            return;
        }

        if ($t =~ /^\Q$quote_mark\E/) {
            $result .= join '',
                'quote(',
                    substr($t, length($quote_mark)),
                ');';
            return;
        }

        $result .= "$t;"; # always place ';' at end of code.
    };

    my $text_cb = sub {
        my ($content) = @_;
        return unless defined $content and length $content;
        $content =~ s/'/\\'/g;
        $result .= "immediate('" . $content . "');";
    };

    $self->_parse_ep($self->template, $text_cb, $code_cb);

    $result = join '',
        'package ', $self->namespace, ';',
        'BEGIN { ',
        '*quote = sub { $_PTPL->quote(@_) };',
        '*immediate = sub { $_PTPL->immediate(@_) };',
        '};',
        $self->preprepend,
        'sub {', $self->prepend, $result, "\n}";

    return $result;
}

sub _parse_ep {

    my ($self, $tpl, $text_cb, $code_cb) = @_;

    #---------------------------------------------------------
    # единственные три переменные из self
        my $line_tag = $self->line_tag;
        my $open_tag = $self->open_tag;
        my $close_tag = $self->close_tag;
    # по идее это можно было оформить в виде независимого кода
    #---------------------------------------------------------

    my @lines = split /\n/, $tpl;

    my $st = 'text';
    my $code_text;

    for (my $i = 0; $i < @lines; $i++) {
        local $_ = $lines[$i];

        CODE:
            if ($st eq 'code') {
                if (/^(.*?)\Q$close_tag\E(.*)/) {
                    $_ = $2;
                    $code_cb->($code_text . $1);
                    $code_text = undef;
                    $st = 'text';
                    goto ANYTEXT;
                } else {
                    $code_text .= $_;
                    $code_text .= "\n";
                    next;
                }
            }

        TEXT_BEGIN:
            if (/^(\s*)\Q$line_tag\E(.*)/) {
                $text_cb->($1);
                if ($i < $#lines) {
                    $code_cb->("$2\n");
                } else {
                    $code_cb->($2);
                }
                next;
            }

        ANYTEXT:
            if (/^(.*?)\Q$open_tag\E(.*)/) {
                $_ = $2;
                $text_cb->($1);
                $code_text = '';
                $st = 'code';
                goto CODE;
            } else {
                $text_cb->($_);
                $text_cb->("\n") if $i < $#lines;
                next;
            }
    }
    $text_cb->("<%" . $code_text) if defined $code_text and length $code_text;
}


sub preprepend {
    my ($self, @tokens) = @_;
    $self->{prepretokens} ||= [];
    push @{ $self->prepretokens } => map "$_;\n", @tokens if @tokens;
    return join '' => @{ $self->prepretokens } if defined wantarray;
}

sub prepend {
    my ($self, @tokens) = @_;
    $self->{pretokens} ||= [];
    push @{ $self->pretokens } => map "$_;", @tokens if @tokens;
    return join '' => @{ $self->pretokens } if defined wantarray;
}


sub pre_lines {
    my ($self) = @_;
    my $lines = 0;
    $lines += @{[ /\n/g ]} for ($self->preprepend, $self->prepend);
    return $lines;
}

sub clean_prepend {
    my ($self) = shift;
    $self->{pretokens} = [];
}

sub clean_namespace {
    my ($self) = @_;
    my $sb = $self->namespace;

    no strict 'refs';
    undef *{$sb . '::' . $_} for keys %{ $sb . '::' };
}

1;

=head1 NAME

DBIx::DR::PerlishTemplate - template engine for L<DBIx::DR>.

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut





