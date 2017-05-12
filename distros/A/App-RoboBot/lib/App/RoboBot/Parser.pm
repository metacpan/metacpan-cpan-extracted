package App::RoboBot::Parser;
$App::RoboBot::Parser::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::ClassAttribute;
use MooseX::SetOnce;

use App::RoboBot::TypeFactory;

use Scalar::Util qw( looks_like_number );

has 'bot' => (
    is       => 'ro',
    isa      => 'App::RoboBot',
    required => 1,
);

has 'err' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_err',
    clearer   => 'clear_err',
);

has 'text' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_text',
    clearer   => 'clear_text',
);

has '_pos' => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub { [0] },
);

has '_line' => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub { [1] },
);

has '_col' => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub { [1] },
);

has '_chr' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

class_has 'tf' => (
    is     => 'rw',
    isa    => 'App::RoboBot::TypeFactory',
);

class_has 'macros' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

class_has 'log' => (
    is        => 'rw',
    predicate => 'has_logger',
);

sub BUILD {
    my ($self) = @_;

    $self->log($self->bot->logger('core.parser')) unless $self->has_logger;

    $self->log->debug('Initialized parser type factory.');

    $self->tf(App::RoboBot::TypeFactory->new( bot => $self->bot ));
}

sub parse {
    my ($self, $text) = @_;

    $self->log->debug(sprintf('Received parse request (%d bytes).', length($text)));

    return unless defined $text && !ref($text);
    return unless $text =~ m{^\s*\(.+\)\s*$}s;

    # Refresh the lookup table of all known macro names for symbol resolution.
    $self->log->debug('Refreshing lookup cross-network table of macros.');

    $self->macros({});
    foreach my $nid (keys %{$self->bot->macros}) {
        foreach my $macro (keys %{$self->bot->macros->{$nid}}) {
            $self->macros->{lc($macro)} = 1;
        }
    }

    $self->log->debug('Resetting parser cursor and state.');

    $self->clear_err;
    $self->text($text);
    $self->_pos([0]);
    $self->_line([1]);
    $self->_col([1]);
    $self->_chr([]);

    my $expr = [];

    while (my $l = $self->_read_list) {
        push(@{$expr}, $l);
    }

    # Return nothing if there were no valid expressions.
    return unless @{$expr} > 0;

    # Unwind any single-element arrayrefs until we have reached down to the
    # first list of valid forms (if there were any).
    while (ref($expr) eq 'ARRAY' && @{$expr} == 1) {
        $expr = $expr->[0];
    }

    # If we're still an arrayref and we got nuthin' inside, then there was no
    # valid form detected and we just return.
    return if ref($expr) eq 'ARRAY' && @{$expr} == 0;

    # If we're left with something that is not an arrayref, then it was a
    # single valid form and we should return it.
    return $expr unless ref($expr) eq 'ARRAY';

    # Otherwise, we're still an arrayref, but with multiple elements, which we
    # will wrap up in a list form and return.
    return $self->tf->build('List', $expr);
}

sub error {
    my ($self) = @_;

    return unless $self->has_err;
    return sprintf('%s at %d (line %d, col %d)',
        $self->err, $self->_pos->[-1], $self->_line->[-1], $self->_col->[-1]
    );
}

sub _read_list {
    my ($self, $terminator) = @_;

    $terminator //= ')';

    $self->log->debug(sprintf('Beginning list read with terminator %s.', $terminator));

    my $l = [];

    while (defined (my $c = $self->_read_char)) {
        if ($c eq $terminator) {
            if ($terminator eq ')') {
                if (@{$l} > 0 && ref($l->[0]) && $l->[0]->type eq 'Function') {
                    return $self->tf->build('Expression', $l);
                } elsif (@{$l} > 0 && ref($l->[0]) && $l->[0]->type eq 'Macro') {
                    return $self->tf->build('Expression', $l);
                } else {
                    return $self->tf->build('List', $l);
                }
            } else {
                return $l;
            }
        } elsif ($c =~ m{[\s,]}) {
            next;
        } elsif ($c eq '(') {
            push(@{$l}, $self->_read_list);
        } elsif ($c eq '{') {
            push(@{$l}, $self->_read_map);
        } elsif ($c eq '|') {
            push(@{$l}, $self->_read_set);
        } elsif ($c eq '[') {
            push(@{$l}, $self->_read_vec);
        } elsif ($c =~ m{\S}) {
            $self->_step_back;
            push(@{$l}, $self->_read_element($terminator));
        }
    }

    return $l if @{$l} > 0;

    $self->log->debug('List read did not locate child elements.');
    return;
}

sub _read_map {
    my ($self) = @_;

    my $list = $self->_read_list('}');

    $self->log->debug(sprintf('Read a Map with %d elements.', scalar(@{$list})));

    return $self->tf->build('Map', $list);
}

sub _read_set {
    my ($self) = @_;

    my $list = $self->_read_list('|');

    $self->log->debug(sprintf('Read a Set with %d elements.', scalar(@{$list})));

    return $self->tf->build('Set', $list);
}

sub _read_vec {
    my ($self) = @_;

    my $list = $self->_read_list(']');

    $self->log->debug(sprintf('Read a Vector with %d elements.', scalar(@{$list})));

    return $self->tf->build('Vector', $list);
}

sub _read_element {
    my ($self, $terminator) = @_;

    $terminator ||= ')';

    $self->log->debug(sprintf('Reading non-list element, using terminator %s.', $terminator));

    my $el = '';

    my $in_str  = 0;
    my $chr_esc = 0;

    my %escs = (
        'n'  => "\n",
        'r'  => "",
        't'  => "\t",
        ' '  => " ",
        "'"  => "'",
    );

    while (defined (my $c = $self->_read_char)) {
        if ($c eq '"') {
            if ($in_str && !$chr_esc) {
                $in_str = 0;
            } elsif ($chr_esc) {
                $el .= '"';
                $chr_esc = 0;
            } else {
                $in_str = 1;
            }
        } elsif ($c eq $terminator && !$in_str) {
            $self->_step_back;
            last;
        } elsif (exists $escs{$c} && $chr_esc) {
            $el .= $escs{$c};
            $chr_esc = 0;
# TODO: If adding support for , shorthand operator (opposite of '), it needs to
#       to be checked here (along with ensuring we're at the first character in
#       this element), prior to the generic "whitespace" check (since commans
#       in between list elements are treated as whitespace).
        } elsif ($c =~ m{[\s,]}) {
            if ($in_str) {
                $el .= $c;
            } else {
                last;
            }
        } elsif ($c eq '\\') {
            if ($chr_esc) {
                $el .= $c;
                $chr_esc = 0;
            } else {
                $chr_esc = 1;
            }
        } elsif ($c eq "'" && length($el) == 0) {
            my $peek = $self->_peek_char;

            if ($peek =~ m/[\(\|\{\[]/) {
                my $form;

                my $opener = $self->_read_char;

                if ($opener eq '(') {
                    $form = $self->_read_list;
                } elsif ($opener eq '{') {
                    $form = $self->_read_map;
                } elsif ($opener eq '[') {
                    $form = $self->_read_vec;
                } elsif ($opener eq '|') {
                    $form = $self->_read_set;
                }

                $form->quoted(1);
                return $form;
            } else {
                $el = $self->_read_element;
                $el->quoted(1);
                return $el;
            }
        } else {
            $el .= $c;
        }
    }

    if ($in_str) {
        return;
    }

    if (defined $el && length($el) > 0) {
        if (substr($el, 0, 1) eq ':') {
            $self->log->debug(sprintf('Treating non-list element "%s" as Symbol.', $el));
            return $self->tf->build('Symbol', $el);
        } elsif (looks_like_number($el)) {
            $self->log->debug(sprintf('Treating non-list element "%s" as Number.', $el));
            return $self->tf->build('Number', $el);
        } elsif (exists $self->bot->commands->{lc($el)}) {
            $self->log->debug(sprintf('Treating non-list element "%s" as Function.', $el));
            return $self->tf->build('Function', $el);
        } elsif (exists $self->macros->{lc($el)}) {
            $self->log->debug(sprintf('Treating non-list element "%s" as Macro.', $el));
            return $self->tf->build('Macro', $el);
        } else {
            $self->log->debug(sprintf('Treating non-list element "%s" as String.', $el));
            return $self->tf->build('String', $el);
        }
    } else {
        $self->log->debug('Expected an element, but there turned out to be nothing to read.');
        return undef;
    }
}

sub _read_char {
    my ($self) = @_;

    return unless length($self->text) >= $self->_pos->[-1];
    my $c = substr($self->text, $self->_pos->[-1], 1);
    return unless defined $c;

    push(@{$self->_pos}, $self->_pos->[-1] + 1);

    if (scalar(@{$self->_chr}) > 0 && $self->_chr->[-1] eq "\n") {
        push(@{$self->_line}, $self->_line->[-1] + 1);
        push(@{$self->_col}, 1);
    } else {
        push(@{$self->_line}, $self->_line->[-1]);
        push(@{$self->_col},  $self->_col->[-1] + 1);
    }

    push(@{$self->_chr}, $c);

    return $c;
}

sub _peek_char {
    my ($self) = @_;

    my $c = $self->_read_char;
    $self->_step_back;
    return unless defined $c;

    return $c;
}

sub _step_back {
    my ($self) = @_;

    pop(@{$self->_pos});
    pop(@{$self->_line});
    pop(@{$self->_col});
    pop(@{$self->_chr});
}

1;
