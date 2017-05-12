package AI::Classifier::Text;
{
  $AI::Classifier::Text::VERSION = '0.03';
}

use strict;
use warnings;
use 5.010;
use Moose;
use MooseX::Storage;

use AI::Classifier::Text::Analyzer;
use Module::Load (); # don't overwrite our sub load() with Module::Load::load()

with Storage(format => 'Storable', io => 'File');

has classifier => (is => 'ro', required => 1 );
has analyzer => ( is => 'ro', default => sub{ AI::Classifier::Text::Analyzer->new() } );
# for store/load only, don't touch unless you really know what you're doing
has classifier_class => (is => 'bare');

before store => sub {
    my $self = shift;
    $self->{classifier_class} = $self->classifier->meta->name;
};

around load => sub {
    my ($orig, $class) = (shift, shift);
    my $self = $class->$orig(@_);
    Module::Load::load($self->{classifier_class});
    return $self;
};

sub classify {
    my( $self, $text, $features ) = @_;
    return $self->classifier->classify( $self->analyzer->analyze( $text, $features ) );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

AI::Classifier::Text - A convenient class for text classification

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $cl = AI::Classifier::Text->new(classifier => AI::NaiveBayes->new(...));
    my $res = $cl->classify("do cats eat bats?");
    $res    = $cl->classify("do cats eat bats?", { new_user => 1 });
    $cl->store('some-file');
    # later
    my $cl = AI::Classifier::Text->load('some-file');
    my $res = $cl->classify("do cats eat bats?");

=head1 DESCRIPTION

AI::Classifier::Text combines a lexical analyzer (by default being
L<AI::Classifier::Text::Analyzer>) and a classifier (like AI::NaiveBayes) to
perform text classification.

This is partially based on AI::TextCategorizer.

=head1 ATTRIBUTES

=over 4

=item C<classifier>

An object that'll perform classification of supplied feature vectors. Has to
define a C<classify()> method, which accepts a hash refence. The return value of
C<AI::Classifier::Text->classify()> will be the return value of C<classifier>'s
C<classify()> method.

This attribute has to be supplied to the C<new()> method during object creation.

=item C<analyzer>

The class performing lexical analysis of the text in order to produce a feature
vector. This defaults to C<AI::Classifier::Text::Analyzer>.

=back

=head1 METHODS

=over 4

=item C<< new(classifier => $foo) >>

Creates a new C<AI::Classifier::Text> object. The classifier argument is mandatory.

=item C<classify($document, $features)>

Categorize the given document. A lexical analyzer will be used to extract
features from C<$document>, and in addition to that the features from
C<$features> hash reference will be added. The return value comes directly from
the C<classifier> object's C<classify> method.

=back

=head1 SEE ALSO

AI::NaiveBayes (3), AI::Categorizer(3)

=head1 AUTHOR

Zbigniew Lukasiak <zlukasiak@opera.com>, Tadeusz Sośnierz <tsosnierz@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Opera Software ASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A convenient class for text classification

