package Data::Dumper::Table;

use strict;
use warnings;
use 5.018;
use utf8;

use Scalar::Util qw( reftype refaddr blessed );
use Text::Table;

use Exporter qw( import );
our @EXPORT = qw( Tabulate );

our $VERSION = '0.012';

our %seen;

sub Tabulate ($) {
    my ($thing) = @_;
    my $run = \do { my $o };
    $run = refaddr($run);
    $seen{ $run } = { };
    my $rv = _tblize($thing, $run);
    delete $seen{ $run };
    return $rv;
}

sub _tblize {
    my ($thing, $run) = @_;
    return 'undef()' unless defined $thing;
    my $r = reftype($thing) || '';
    my $addr = lc sprintf('%x', refaddr($thing) || 0);
    my $circular;
    if ($r and defined($seen{ $run }->{ $addr })) {
        $circular++;
    }
    my $alias
        = $r
        ? $r . '(' . ($seen{ $run }->{ $addr } //= scalar keys %{$seen{ $run }}) . ')'
        : '( scalar )'
        ;
    if (my $b = blessed($thing)) {
        $alias = $b . '=' . $alias unless $b eq 'Regexp';
    }
    if ($circular) {
        return '-> ' . $alias;
    }
    my $container = Text::Table->new(($alias)x($alias ne '( scalar )'));
    my $inner = $thing;
    my $snidge = '+';
    if ($r eq 'ARRAY') {
        my %header;
        my @v = grep {
            ref($_) eq 'HASH' ?
            do {
                for my $k (keys %$_) {
                    undef $header{ $k };
                }
                1;
            } : undef
        } @$thing;
        if (@v == @$thing) {
            $alias =~ s/ARRAY/ARRAY<HASH>/;
            $container = Text::Table->new($alias);
            my @cols = sort keys %header;
            my @head = map { \' | ', defined($_) ? q{'} . quotemeta($_) . q{'} : 'undef()' } @cols;
            shift @head;
            unshift @head, \' ';
            push @head, \' ';
            $inner = Text::Table->new(@head);
            for my $row (@$thing) {
                my @body;
                for my $k (@cols) {
                    push @body, (exists($row->{ $k }) ? _tblize($row->{ $k }, $run) : '-');
                }
                $inner->add(@body);
            }
        }
        else {
            $inner = Text::Table->new();
            my $n = 0;
            my $index = "$alias [" . $n++ . "]";
            for my $row (@$thing) {
                $inner->add($index, _tblize($row, $run));
                $index = (' ' x (2 + length($alias) - length($n))) . '[' . $n++ . ']';
            }
            return $inner;
        }
    }
    elsif ($r eq 'HASH') {
        my @keys = sort keys %$thing;
        $inner = Text::Table->new();
        for my $k (@keys) {
            $inner->add((defined($k) ? q{'} . quotemeta($k) . q{'} : 'undef()'), '=>', _tblize($thing->{ $k }, $run));
            $snidge = '-';
        }
    }
    elsif ($r eq 'CODE') {
        $inner = 'sub DUMMY { }'; # TODO for now
    }
    elsif (uc $r eq 'REGEXP') {
        return "/$thing/";
    }
    elsif ($r) {
        $inner = _tblize("\\do { " . $$thing . "}", $run); # TODO for now
    }
    else {
        $inner = "'" . quotemeta($inner) . "'";
    }
    if (ref $inner) {
        $container->add($inner->title . $inner->rule('-', $snidge) . $inner->body);
        return $container->title . $container->body;
    }
    $container->add($inner);
    return $container->title . $container->body;
}

1;

__END__

=head1 NAME

Data::Dumper::Table - A more tabular way to Dumper your Data

=head1 VERSION

Version 0.012

=head1 SYNOPSIS

    use Data::Dumper::Table;

    my $x = [qw(one two three)];

    say Tabulate [
        { foo => $x, bar => 2 },
        { foo => 3, bar => { apple => q(or'ange) } },
        $x,
        [
            { bar => q(baz), flibble => q(quux), flobble => undef() },
            { bar => q(baz2), flobble => qr/foo/ }
        ]
    ];

    ARRAY(1) [0] HASH(2)
                 -----------------------------
                 'bar' => '2'
                 'foo' => ARRAY(3) [0] 'one'
                                   [1] 'two'
                                   [2] 'three'
             [1] HASH(4)
                 ------------------------------
                 'bar' => HASH(5)
                          ---------------------
                          'apple' => 'or\'ange'
                 'foo' => '3'
             [2] -> ARRAY(3)
             [3] ARRAY<HASH>(6)
                  'bar'  | 'flibble' | 'flobble'
                 --------+-----------+-------------
                  'baz'  | 'quux'    | undef()
                  'baz2' | -         | /(?^u:foo)/

=head1 DESCRIPTION

The goal of Data::Dumper::Table is to provide a more-tabular alternative to Data::Dumper.

=head1 EXPORTED FUNCTIONS

=over

=item Tabulate DATA

Turn the provided DATA into a (hopefully) nicely-formatted table. More verbose and space-hungry than Data::Dumper, but possibly easier to read.

=back

=head1 CAVEATS

=head2 This is Alpha software

This module is explicitly alpha-quality software. If you successfully use it in production, you're a braver being than I am. See also the TODO list for things that are known not to be handled well.

=head1 TODO

=head2 Sortkeys

Replicate $Data::Dumper::Sortkeys

=head2 Deparse

Replicate $Data::Dumper::Deparse

=head2 Filehandles and other weird globs

Handle them, somehow

=head2 Tied data

Handle it, somehow. Be especially wary of stuff tied to databases, files, and other not-supposed-to-be-dumped things

=head2 Data::Dumper::Table::HTML

Should be a SMOP once this thing's in the air properly ;-)

=head1 LICENSE

Artistic 2.0

=cut

