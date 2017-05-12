package Devel::REPL::Plugin::Carp::REPL;

our $VERSION = '0.18';

use Devel::REPL::Plugin;
use namespace::autoclean;
use Devel::LexAlias;
use Devel::StackTrace::WithLexicals;
use Data::Dump::Streamer;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('LexEnv');
}

has stacktrace => (
    is      => 'ro',
    isa     => 'Devel::StackTrace::WithLexicals',
    handles => [qw/frame_count/],
    default => sub {
        my $stacktrace = Devel::StackTrace::WithLexicals->new(
            ignore_class => ['Carp::REPL', __PACKAGE__],
            unsafe_ref_capture => 1,
        );

        # skip all the Moose metaclass frames
        shift @{ $stacktrace->{raw} }
            until @{ $stacktrace->{raw} } == 0
               || $stacktrace->{raw}[0]{caller}[3] eq 'Carp::REPL::repl';

        # get out of Carp::
        shift @{ $stacktrace->{raw} }
            until @{ $stacktrace->{raw} } == 0
               || $stacktrace->{raw}[0]{caller}[0] !~ /^Carp(?:::|$)/;

        shift @{ $stacktrace->{raw} }
            until @{ $stacktrace->{raw} } == 0
               || $Carp::REPL::bottom_frame-- <= 0;

        return $stacktrace;
    },
);

has frame_index => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

sub frame {
    my $self = shift;
    my $i = @_ ? shift : $self->frame_index;

    return $self->stacktrace->frame($i);
}

around 'frame_index' => sub {
    my $orig = shift;
    my ($self, $index) = @_;

    return $orig->(@_) if !defined($index);

    if ($index < 0) {
        warn "You're already at the bottom frame.\n";
    }
    elsif ($index >= $self->frame_count) {
        warn "You're already at the top frame.\n";
    }
    else {
        $orig->(@_);
        my $frame = $self->frame;
        my ($file, $line) = ($frame->filename, $frame->line);
        $self->print("Now at $file:$line (frame $index).");
    }
};

# this is totally the wrong spot for this. oh well.
around 'read' => sub {
    my $orig = shift;
    my ($self, @rest) = @_;
    my $line = $self->$orig(@rest);

    return if !defined($line) || $line =~ /^\s*:q\s*/;

    if ($line =~ /^\s*:b?t\b/) {
        $self->print($self->stacktrace);
        return '';
    }

    if ($line =~ /^\s*:top\b/) {
        $self->frame_index($self->frame_count - 1);
        return '';
    }

    if ($line =~ /^\s*:b(?:ot(?:tom)?)?\b/) {
        $self->frame_index(0);
        return '';
    }

    if ($line =~ /^\s*:up?\b/) {
        $self->frame_index($self->frame_index + 1);
        return '';
    }

    if ($line =~ /^\s*:d(?:own)?\b/) {
        $self->frame_index($self->frame_index - 1);
        return '';
    }

    if ($line =~ /^\s*:l(?:ist)?\b/) {
        my $frame = $self->frame;
        my ($file, $num) = ($frame->filename, $frame->line);
        open my $handle, '<', $file or do {
            warn "Unable to open $file for reading: $!\n";
            return '';
        };
        my @code = <$handle>;
        chomp @code;

        my $min = $num - 6;
        my $max = $num + 4;
        $min = 0 if $min < 0;
        $max = $#code if $max > $#code;

        my @lines;
        $self->print("File $file:\n");
        for my $cur ($min .. $max) {
            next if !defined($code[$cur]);

            push @lines, sprintf "%s%*d: %s",
                            $cur + 1 == $num ? '*' : ' ',
                            length($max),
                            $cur + 1,
                            $code[$cur];
        }

        $self->print(join "\n", @lines);

        return '';
    }

    if ($line =~ /^\s*:e(?:nv)?\s*/) {
        $self->print(Dump($self->frame->lexicals)->Names('Env')->Out);
        return '';
    }

    return $line;
};

# Provide an alias for each lexical in the current stack frame
around 'mangle_line' => sub {
    my $orig = shift;
    my ($self, @rest) = @_;
    my $line = $self->$orig(@rest);

    my $frame = $self->frame;
    my $package = $frame->package;
    my $lexicals = $frame->lexicals;

    my $declarations = join "\n",
                       map {"my $_;"}
                       keys %$lexicals;

    my $aliases = << '    ALIASES';
    while (my ($k, $v) = each %{ $_REPL->frame->lexicals }) {
        Devel::LexAlias::lexalias 0, $k, $v;
    }
    my $_a; Devel::LexAlias::lexalias 0, '$_a', \$_REPL->frame->{args};
    ALIASES

    return << "    CODE";
    package $package;
    no warnings 'misc'; # declaration in same scope masks earlier instance
    no strict 'vars';   # so we get all the global variables in our package
    $declarations
    $aliases
    $line
    CODE
};

1;

__END__

=head1 NAME

Devel::REPL::Plugin::Carp::REPL - Devel::REPL plugin for Carp::REPL

=head1 SYNOPSIS

This sets up the environment captured by L<Carp::REPL>. This plugin
isn't intended for use by anything else. There are plans to move some features
from this into a generic L<Devel::REPL> plugin.

This plugin also adds a few extra commands like :up and :down to move up and
down the stack.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

Please report any bugs to a medium given by Carp::REPL.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Best Practical Solutions, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

