package App::GitGrepPerlStatement::StatementFinder;
use 5.008001;
use strict;
use warnings;
use PPI;
use List::MoreUtils qw(any);
use Term::ANSIColor qw(colored);

sub new {
    my ($class, $word) = @_;
    bless {
        word => $word,
        docs => [],
    }, $class;
}

sub word {
    my ($self) = @_;
    $self->{word};
}

sub search {
    my ($self, $file) = @_;

    my $doc = PPI::Document->new($file);
    return unless $doc;
    push @{$self->{docs}}, $doc;

    my $statements = $doc->find('PPI::Statement');

    grep {
        my $tokens = [ $_->children ];

        any {
            $_ eq $self->word;
        } @$tokens;
    } @$statements;
}

sub flush {
    my ($self) = @_;
    $self->{docs} = [];
}

sub highlight_style {
    ['red'];
}

sub highlight {
    my ($self, $statement) = @_;

    join '', map {
        if ($_ eq $self->word) {
            colored($self->highlight_style, $_);
        } else {
            $_;
        }
    } $statement->children;
}

1;
