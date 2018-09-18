package App::vl;
use strict;
use warnings;
use Getopt::Long qw/GetOptionsFromArray/;
use IO::Pager;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my @argv = @_;

    bless {
        _opt                => $class->_parse_opt(@argv),
        _labels             => [],
        _column_length_list => [],
    }, $class;
}

sub opt {
    my ($self, $key) = @_;

    return $self->{_opt}{$key};
}

sub labels {
    my ($self, $value) = @_;

    if ($value) {
        $self->{_labels} = $value;
        return $self;
    }
    else {
        return $self->{_labels};
    }
}

sub column_length_list {
    my ($self, $value) = @_;

    if ($value) {
        $self->{_column_length_list} = $value;
        return $self;
    }
    else {
        return $self->{_column_length_list};
    }
}

sub run {
    my $self = shift;

    my $header = <STDIN>;
    chomp $header;

    $self->_parse_header($header);

    my $line_count = 0;

    my $io = $self->opt('no_pager') ? *STDOUT : new IO::Pager;
    my $grep = $self->opt('grep');

    while (my $line = <STDIN>) {
        $line_count++;
        chomp $line;
        next if $grep && $line !~ m!\Q$grep\E!i;
        $io->print($self->opt('line_char') x 10 . " $line_count " . $self->opt('line_char') x 20 . "\n");
        next if $line eq '';
        my $elements = $self->opt('ps')
                     ? $self->_parse_ps_line($line)
                     : $self->_parse_line($line);
        $self->_show_elements($io, $elements);
    }
}

sub _parse_header {
    my ($self, $header) = @_;

    my $one_space_table = $self->_is_one_space_table($header);
    if (!$one_space_table) {
        $header =~ s/([^\s])\s([^\s])/$1\\$2/g;
    }

    my (@labels, @column_length_list);

    while ($header =~ s/(\s*([^\s]+)\s*)//) {
        my ($full_label, $label) = ($1, $2);
        $label =~ s/\\/ /g unless $one_space_table;
        push @labels, $label;
        push @column_length_list, length $full_label;
    }

    $self->labels($self->_sort_label(\@labels));
    $self->column_length_list(\@column_length_list);
}

sub _is_one_space_table {
    my ($self, $header) = @_;

    my @spaces;
    while ($header =~ s/(\s+)//) {
        push @spaces, $1;
    }

    my $one_space = 0;
    for my $space (@spaces) {
        $one_space++ if length $space == 1;
    }

    return 1 if $#spaces >= 3 && $#spaces / 2 <= $one_space; # roughly
}

sub _sort_label {
    my ($self, $labels) = @_;

    my $max = 0;
    for my $label (@{$labels}) {
        my $len = length($label);
        $max = $len if $max < $len;
    }

    for my $label (@{$labels}) {
        $label = ' ' x ($max - length $label) . "$label" . $self->opt('separator');
    }

    return $labels;
}

sub _parse_ps_line {
    my ($self, $line) = @_;

    $line =~ s/^\s+//g;
    my @elements = split /\s+/, $line, $#{$self->labels} + 1;

    return \@elements;
}

sub _parse_line {
    my ($self, $line) = @_;

    my $column_length_list = $self->column_length_list;
    my $limit = $#{$self->labels};

    my @elements;

    my $offset = 0;

    for my $i (0..$limit) {
        my $element = $i != $limit ? substr $line, $offset, $column_length_list->[$i] : substr $line, $offset;
        push @elements, $element;
        $offset += $column_length_list->[$i];
    }

    return \@elements;
}

sub _show_elements {
    my ($self, $io, $elements) = @_;

    my $label_filter_regexp = $self->_label_filter_regexp();
    my $labels = $self->labels;

    my $col = 0;

    for my $element (@{$elements}) {
        if (!$label_filter_regexp || $labels->[$col] =~ $label_filter_regexp) {
            $element =~ s/^\s+//g;
            $element =~ s/\s+$//g;
            $io->print("$labels->[$col]$element\n");
        }
        $col++;
    }
}

sub _label_filter_regexp {
    my ($self) = @_;

    return if !$self->opt('label');

    my $regexp = join '|', map { quotemeta $_ } split /\,/, $self->opt('label');

    $regexp = sprintf('(?:%s)', $regexp);

    return qr/$regexp/i;
}

sub _parse_opt {
    my ($class, @argv) = @_;

    my $opt = {};

    GetOptionsFromArray(
        \@argv,
        'no-pager' => \$opt->{no_pager},
        'grep=s'   => \$opt->{grep},
        'label=s'  => \$opt->{label},
        'ps'       => \$opt->{ps},
        'separator=s' => \$opt->{separator},
        'line-char=s' => \$opt->{line_char},
        'h|help'   => sub {
            $class->_show_usage(1);
        },
        'v|version' => sub {
            print "$0 $VERSION\n";
            exit 1;
        },
    ) or $class->_show_usage(2);

    $opt->{separator} ||= ': ';
    $opt->{line_char} ||= '*';

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

App::vl - Makes CUI table vertical


=head1 SYNOPSIS

    use App::vl;

    my $vl = App::vl->new(@ARGV)->run;

See command L<vl>.


=head1 DESCRIPTION

App::vl makes typical CUI table vertical.

For example,

    $ kubectl get pods
    NAME                         READY     STATUS    RESTARTS   AGE
    hello-web-4017757401-ntgdb   1/1       Running   0          9s
    hello-web-4017757401-pc4j9   1/1       Running   0          9s

Be vertical by L<vl>

    $ kubectl get pods | vl
    ********** 1 ********************
        NAME: hello-web-4017757401-ntgdb
       READY: 1/1
      STATUS: Running
    RESTARTS: 0
         AGE: 9s
    ********** 2 ********************
        NAME: hello-web-4017757401-pc4j9
       READY: 1/1
      STATUS: Running
    RESTARTS: 0
         AGE: 9s


=head2 CAVEAT

Labels must NOT contain L<\> (backslash).


=head1 METHODS

=head2 new

Constractor

=head2 run

main routine

=head2 opt

getter for options

=head2 labels

getter/setter for the label list

=head2 column_length_list

getter/setter for the length list of columns


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/App-vl"><img src="https://secure.travis-ci.org/bayashi/App-vl.png"/></a> <a href="https://coveralls.io/r/bayashi/App-vl"><img src="https://coveralls.io/repos/bayashi/App-vl/badge.png?branch=master"/></a>

=end html

App::vl is hosted on github: L<http://github.com/bayashi/App-vl>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<vl>

L<App::YG>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
