package Alvis::NLPPlatform::UserNLPWrappers;

use strict;
use warnings;

use Alvis::NLPPlatform::NLPWrappers;

our @ISA = ("Alvis::NLPPlatform::NLPWrappers");

our $VERSION=$Alvis::NLPPlatform::VERSION;

=head1 NAME

Alvis::NLPPlatform::UserNLPWRapper - User interface for customizing
the NLP wrappers used for linguistically annotating of XML documents
in Alvis

=head1 SYNOPSIS

use Alvis::NLPPlatform::UserNLPWrapper;

Alvis::NLPPlatform::UserNLPWrappers->tokenize($h_config,$doc_hash);

=head1 DESCRIPTION

This module is a mere infterface for allowing the cutomisation of the
NLP Wrappers. Anyone who wants to integrated a new NLP tool have to
overwrite the default wrapper. The aim of this module is to make
easier the development a specific wrapper, its integration and its use
in the platform.


Before developing a new wraper, it is necessary to copy and modify
this file in a local directory and add this directory to the PERL5LIB
variable.

=head1 METHODS


=head2 tokenize()

    tokenize($h_config, $doc_hash);

This method carries out the tokenisation process of the input
document. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. See documentation in
C<Alvis::NLPPlatform::NLPWrappers>.  It is not recommended to
overwrite this method.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The method returns the number of tokens.

=cut


sub tokenize {
    my @arg = @_;

    my $class = shift @arg;

    return($class->SUPER::tokenize(@arg));

}

=head2 scan_ne()

    scan_ne($h_config, $doc_hash);

This method wraps the Named entity recognition and tagging
step. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.  It aims at annotating semantic
units with syntactic and semantic types. Each text sequence
corresponding to a named entity will be tagged with a unique tag
corresponding to its semantic value (for example a "gene" type for
gene names, "species" type for species names, etc.). All these text
sequences are also assumed to be equivalent to nouns: the tagger
dynamically produces linguistic units equivalent to words or noun
phrases.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut


sub scan_ne 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::scan_ne(@arg);

}

=head2 word_segmentation()

    word_segmentation($h_config, $doc_hash);

This method wraps the default word segmentation step.  C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.  

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub word_segmentation 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::word_segmentation(@arg);

}

=head2 sentence_segmentation()

    sentence_segmentation($h_config, $doc_hash);

This method wraps the default sentence segmentation step.
C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub sentence_segmentation 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::sentence_segmentation(@arg);

}

=head2 pos_tag()

    pos_tag($h_config, $doc_hash);

The method wraps the Part-of-Speech (POS) tagging.  C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.  For every input word, the wrapped Part-Of-Speech tagger
outputs its tag.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub pos_tag 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::pos_tag(@arg);

}

=head2 lemmatization()

    lemmatization($h_config, $doc_hash);

This methods wraps the lemmatizer. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. For
every input word, the wrapped lemmatizer outputs its lemma i.e. the
canonical form of the word..

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub lemmatization 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::lemmatization(@arg);

}


=head2 term_tag()

    term_tag($h_config, $doc_hash);

The method wraps the term tagging step of the ALVIS NLP
Platform. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. This step aims at recognizing terms
in the documents differing from named entities, like I<gene
expression>, I<spore coat cell>.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub term_tag
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::term_tag(@arg);

}

=head2 syntactic_parsing()

    syntactic_parsing($h_config, $doc_hash);

This method wraps the sentence parsing. It aims at exhibiting the
graph of the syntactic dependency relations between the words of the
sentence. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut


sub syntactic_parsing
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::syntactic_parsing(@arg);

}

=head2 semantic_feature_tagging()

    semantic_feature_tagging($h_config, $doc_hash)

The method wraps the semantic typing step, that is the attachment of a
semantic type to the words, terms and named-entities (referred to as
lexical items in the following) in documents according to the
conceptual hierarchies of the ontology of the domain.

C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub semantic_feature_tagging
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::semantic_feature_tagging(@arg);

}

=head2 semantic_relation_tagging()

    semantic_relation_tagging($h_config, $doc_hash)


This method wraps the semantic relation identification step. These
semantic relation annotations give another level of semantic
representation of the document that makes explicit the role that these
semantic units (usually named-entities and/or terms) play with respect
to each other, pertaining to the ontology of the domain.

C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub semantic_relation_tagging
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::semantic_relation_tagging(@arg);

}

=head2 anaphora_resolution()

    anaphora_resolution($h_config, $doc_hash)

The methods wraps the anaphora solver. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. It
aims at identifing and solving the anaphora present in a document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub anaphora_resolution
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::anaphora_resolution(@arg);

}

# =head1 ENVIRONMENT

=head1 SEE ALSO

Alvis web site: http://www.alvis.info

=head1 AUTHORS

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr> and Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2005 by Thierry Hamon and Julien Deriviere

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
