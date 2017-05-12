package Acme::KnowledgeWisdom;

our $VERSION = '0.01';

use Moose;
use warnings FATAL => 'all';

has 'in_questions' => ( isa => 'Bool', is => 'ro', default => 1);
has 'has_already'  => ( isa => 'Bool', is => 'ro', default => 0);

sub get {
    my $kw = shift;
    
    return $kw->ask
        if $kw->in_questions;

    return 42;
}

sub ask {
    my $self = shift;
    
    return 42
        if $self->has_already;
    
    my $kw = Acme::KnowledgeWisdom->new;
    return $kw->get;
}

1;


__END__

=head1 NAME

Acme::KnowledgeWisdom - knowledge and wisdom interface through questioning

=head1 SYNOPSIS

    use Acme::KnowledgeWisdom;
    use Test::Exception;
    
    my $kw_questions = Acme::KnowledgeWisdom->new();
    dies_ok { $kw_questions->get };

=head1 DESCRIPTION

What if the knowledge is not in answers, but in questions?

=head1 ACCESSORS

=head2 in_questions

Boolean, default value is true.

=head2 has_already

Boolean, default value is false.

=head1 METHODS

=head2 get

Get the knowledge and wisdom.

=head2 ask

Ask a question.

=head1 AUTHOR

Jozef

=cut
