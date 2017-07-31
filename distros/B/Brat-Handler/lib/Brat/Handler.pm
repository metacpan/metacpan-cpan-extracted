package Brat::Handler;


use utf8;
use strict;
use warnings;
use open qw(:utf8 :std);

use Brat::Handler::File;

our $VERSION='0.11';

sub new {

    my ($class) = @_;

    my $bratHandler = {
	'inputDir' => undef,
#	'outputFile' => undef,
	'inputFiles' => [],
	'bratAnnotations' => [],
    };
    bless($bratHandler, $class);

    return($bratHandler);
}

# sub _inputDir {
#     my $self = shift;

#     if (@_) {
# 	$self->{'inputDir'} = shift;
#     }
#     return($self->{'inputDir'});
# }

sub _scanDir {
    my $self = shift;
    my $inputDir = shift;
    my $file;
    if (defined ($inputDir)) {
	opendir DIR, $inputDir or die "no such dir $inputDir\n";
	while($file = readdir DIR) {
	    if (($file ne ".") && ($file ne "..") && ($file =~ /\.ann$/)) {
		$self->_inputFiles($inputDir . "/$file");
	    }
	}
	closedir DIR;
    }
}


#  sub _outputFile {
#     my $self = shift;

#     if (@_) {
# 	$self->{'outputFile'} = shift;
#     }
#     return($self->{'outputFile'});
# }


sub _inputFiles {
    my $self = shift;

    if (@_) {
	my $fileList = shift;
	if (ref($fileList) eq 'ARRAY') {
	push @{$self->{'inputFiles'}}, @$fileList;
	} else {
	push @{$self->{'inputFiles'}}, $fileList;
	}
    }
    return($self->{'inputFiles'});
}

sub _bratAnnotations {
    my $self = shift;

    if (@_) {
	my $bratAnn = shift;
	push @{$self->{'bratAnnotations'}}, $bratAnn;
    }
    return($self->{'bratAnnotations'});
}

sub _bratAnnotationSize {
    my $self = shift;

    return(scalar(@{$self->_bratAnnotations}));
}

sub _getBratAnnotationsFromId {
    my $self = shift;
   
    if (@_) {
	my $id = shift;
	return $self->{'bratAnnotations'}->[$id];
    }
    return(undef);
}

sub loadDir {
    my ($self, $inputDir) = @_;
    my $file;

    $self->_scanDir($inputDir);
    foreach $file (@{$self->_inputFiles}) {
	$self->_bratAnnotations($self->loadFile($file));
    }
}

sub loadList {
    my ($self, $list) = @_;
    my $file;
    my @files;
    open LIST, $list or die "no such file $list\n";
    @files = <LIST>;
    map {chomp;} @files;
    close LIST;
    $self->_inputFiles(\@files);
    foreach $file (@{$self->_inputFiles}) {
	$self->_bratAnnotations($self->loadFile($file));
    }
}

sub loadFile {
    my ($self, $file) = @_;
    
    if (($file =~ /\.ann$/) || ($file =~ /\.txt$/)) {
	my $ann = Brat::Handler::File->new($file);
	return($ann);
    }
    return(undef);
}

sub concat {
    my ($self) = @_;
    my $i;
    my $offset = 0;
    my $termIdOffset = 0;
    my $relationIdOffset = 0;
    my $attributeIdOffset = 0;
    my $currentBratAnnotations;
    my $concatAnn = Brat::Handler::File->new();
    my %Term2newTerm;
    for($i=0; $i < $self->_bratAnnotationSize; $i++) {
	%Term2newTerm = ();
	$currentBratAnnotations = $self->_getBratAnnotationsFromId($i);
	# warn "Read file: " . $currentBratAnnotations->_textFilename . "\n";
	$self->_copyTermsWithOffsetShift($currentBratAnnotations, $concatAnn, $termIdOffset, $offset, \%Term2newTerm);
	$self->_copyAttributesWithOffsetShift($currentBratAnnotations, $concatAnn, $attributeIdOffset, $offset, \%Term2newTerm);
	$self->_copyRelationsWithOffsetShift($currentBratAnnotations, $concatAnn, $relationIdOffset, $offset, \%Term2newTerm);
	$offset += $currentBratAnnotations->_textSize;
	$termIdOffset += $currentBratAnnotations->_maxTermId;
	$attributeIdOffset += $currentBratAnnotations->_maxAttributeId;
	$relationIdOffset += $currentBratAnnotations->_maxRelationId;
	$concatAnn->_textFilename(@{$currentBratAnnotations->_textFilename});
	$concatAnn->_annotationFilename(@{$currentBratAnnotations->_annotationFilename});
    }
    $concatAnn->_textSize($offset);
    

    return($concatAnn);
}

sub _copyTermsWithOffsetShift {
    my ($self, $ann, $concatAnn, $termIdOffset, $offset, $Term2newTerm) = @_;
    my $elt;
    my $id;
    my $newNumId;
    my @starts;
    my @ends;
    my @newStarts;
    my @newEnds;
    my $s;
    my $e;
    my $i = 0;

    foreach $id (keys %{$ann->_terms}) {
	@newStarts = ();
	@newEnds = ();
	$elt = $ann->_getTermFromId($id);
	$newNumId = $elt->{'numId'} + $termIdOffset;
	$Term2newTerm->{$elt->{'id'}} = "T$newNumId";
	foreach $s (@{$elt->{'start'}}) {
	    push @newStarts, ($s+$offset);
	}
	foreach $e (@{$elt->{'end'}}) {
	    push @newEnds, ($e+$offset);
	}

	$concatAnn->_addTerm("T$newNumId", {
		'id' => "T$newNumId",
		'numId' => $newNumId,
		'type' => $elt->{'type'},
		'start' => [@newStarts],
		'end' => [@newEnds],
		'str' => $elt->{'str'},
		'attrlst' => [], # TODO
			});
	$i++;
    }
    return($i);
}

sub _copyAttributesWithOffsetShift {
    my ($self, $ann, $concatAnn, $attributeIdOffset, $offset, $Term2newTerm) = @_;
    my $attr;
    my $id;
    my $newNumId;
    my $newTermId;

    foreach $id (keys %{$ann->_attributes}) {
	$attr = $ann->_getAttributeFromId($id);
	$newNumId = $attr->{'numId'} + $attributeIdOffset;
	$concatAnn->_addAttribute("A$newNumId", {
	    'id' => "A$newNumId",
	    'numId' => $newNumId,
	    'type' => $attr->{'type'},
	    'termId' => $Term2newTerm->{$attr->{'termId'}},
	    'value' => $attr->{'value'},
			     });
	    # warn "termId: $start\n";
	push @{$concatAnn->_getTermFromId($Term2newTerm->{$attr->{'termId'}})->{'attrlst'}}, "A$newNumId";
    }
}

sub _copyRelationsWithOffsetShift {
    my ($self, $ann, $concatAnn, $relationIdOffset, $offset, $Term2newTerm) = @_;
    my $relation;
    my $id;
    my $newNumId;
    my $newTermId1;
    my $newTermId2;

    foreach $id (keys %{$ann->_relations}) {
	$relation = $ann->_getRelationFromId($id);
	$newNumId = $relation->{'numId'} + $relationIdOffset;
	$concatAnn->_addRelation("R$newNumId", {
	    'id' => "R$newNumId",
	    'numId' => $newNumId,
	    'type' => $relation->{'type'},
	    'arg1' => $Term2newTerm->{$relation->{'arg1'}},
	    'arg2' => $Term2newTerm->{$relation->{'arg2'}},
			    });
    }    
    
}

sub printTermList {
    my ($self, $filename, $addmode) = @_;
    my $id;

    my $fh;
    if ($filename eq "-") {
	$fh = \*STDOUT;
    } else {
	
	if (defined $addmode) {
	    open $fh, ">>:utf8", $filename or die "no such file " . $filename . "\n";
	} else {
	    open $fh, ">:utf8", $filename or die "no such file " . $filename . "\n";
	}
    }
    print $fh $self->getTermList;

    if ($filename ne "-") {
	close $fh;
    }
}

sub getTermList {
    my ($self) = @_;
    my $termlistStr = "";
    my $bratFile;
    my %termList;
    my $term;

    foreach $bratFile (@{$self->_bratAnnotations}) {
	foreach $term (@{$bratFile->getTerms}) {
	    if (!exists $termList{$term->{'str'}}) {
		$termList{lc($term->{'str'})} = {'str' => $term->{'str'}, 'lmstr' => undef, 'type' => {$term->{'type'} => 1}};
	    } else {
		$termList{lc($term->{'str'})}->{'type'}->{$term->{'type'}}++;
	    }
	}
    }
    foreach $term (keys %termList) {
	$termlistStr .= $termList{$term}->{'str'} . " :  : " . join(';', keys%{$termList{$term}->{'type'}}) . " :\n";
    # foreach $id (keys %{$self->_terms}) {
    # 	$termlistStr .= $self->_getTermFromId($id)->{'str'} . " : : " . $self->_getTermFromId($id)->{'type'} . " :\n";
    }
    return($termlistStr);
}

sub getRelationList {
    my ($self) = @_;
    my $relation;
    my $relationListStr = "";
    my %relationList;
    my $bratFile;
    my $key;

    foreach $bratFile (@{$self->_bratAnnotations}) {
	foreach $relation (@{$bratFile->getRelations}) {
	    $key = lc($relation->{'str1'} . '_' . $relation->{'str2'} . '_' . $relation->{'type'});
	    if (!exists $relationList{$key}) {
		$relationList{$key} = [$relation->{'str1'}, $relation->{'str2'}, $relation->{'type'}];
	    }
	}
    }
    
    foreach $key (keys %relationList) {
	$relationListStr .= join(' : ', @{$relationList{$key}}) . "\n";
    }
    return($relationListStr);
}

sub printRelationList {
    my ($self, $filename, $addmode) = @_;
    my $id;

    my $fh;
    if ($filename eq "-") {
	$fh = \*STDOUT;
    } else {
	
	if (defined $addmode) {
	    open $fh, ">>:utf8", $filename or die "no such file " . $filename . "\n";
	} else {
	    open $fh, ">:utf8", $filename or die "no such file " . $filename . "\n";
	}
    }
    print $fh $self->getRelationList;

    if ($filename ne "-") {
	close $fh;
    }
}

sub getStats {
    my ($self) = @_;

    my $stats = "";
    my $nbFiles;
    my $bratFile;
    my $nbTerms = 0;
    my $nbRels = 0;
    my $sumTextSize = 0;
    my $minTextSize = 0;
    my $maxTextSize = 0;
    my $minTerms = 0;
    my $maxTerms = 0;
    my $minRels = 0;
    my $maxRels = 0;

    # my %Terms;
    # my %Relations;
    my %termTypes;
    my %relationTypes;
    my %tmp;
    my $k;

    $nbFiles = scalar(@{$self->_bratAnnotations});
    if ($nbFiles > 0) {
	$minTextSize = $self->_bratAnnotations->[0]->_textSize;
	$minTerms = scalar(keys(%{$self->_bratAnnotations->[0]->_terms}));
	$minRels = scalar(keys(%{$self->_bratAnnotations->[0]->_relations}));
    }
    
    foreach $bratFile (@{$self->_bratAnnotations}) {
	$sumTextSize += $bratFile->_textSize;
	if ($minTextSize > $bratFile->_textSize) {
	    $minTextSize = $bratFile->_textSize
	}
	if ($maxTextSize < $bratFile->_textSize) {
	    $maxTextSize = $bratFile->_textSize
	}
	$nbTerms += scalar(keys(%{$bratFile->_terms}));
	if ($minTerms > scalar(keys(%{$bratFile->_terms}))) {
	    $minTerms = scalar(keys(%{$bratFile->_terms}));
	}
	if ($maxTerms < scalar(keys(%{$bratFile->_terms}))) {
	    $maxTerms = scalar(keys(%{$bratFile->_terms}));
	}
	$nbRels += scalar(keys(%{$bratFile->_relations}));
	if ($minRels > scalar(keys(%{$bratFile->_relations}))) {
	    $minRels = scalar(keys(%{$bratFile->_relations}));
	}
	if ($maxRels < scalar(keys(%{$bratFile->_relations}))) {
	    $maxRels = scalar(keys(%{$bratFile->_relations}));
	}
	%tmp = $bratFile->getTermTypes;
	foreach $k (keys %tmp) {
	    $termTypes{$k}+=$tmp{$k};
	}
	%tmp = $bratFile->getRelationTypes;
	foreach $k (keys %tmp) {
	    $relationTypes{$k}+=$tmp{$k};
	}
	# map {$relationTypes{$_}++;} $bratFile->getRelationTypes;
    }
    
    $stats .= "Number of documents: $nbFiles\n";
    $stats .= "Text Size sum: $sumTextSize\n";
    $stats .= "Number of Terms: $nbTerms\n";
    $stats .= "Number of Relations: $nbRels\n";
    $stats .= "\n";
    $stats .= "Minimal Text Size: $minTextSize\n";
    $stats .= "Maximal Text Size: $maxTextSize\n";
    $stats .= "Average of Text Size: " . ($sumTextSize/$nbFiles) . "\n";
    $stats .= "\n";
    $stats .= "Minimal number of Terms: $minTerms\n";
    $stats .= "Maximal number of Terms: $maxTerms\n";
    $stats .= "Average number of Terms: " . ($nbTerms/$nbFiles) . "\n";
    $stats .= "\n";
    $stats .= "Minimal number of Relations: $minRels\n";
    $stats .= "Maximal number of Relations: $maxRels\n";
    $stats .= "Average number of Relations: " . ($nbRels/$nbFiles) . "\n";
    $stats .= "\n";
    $stats .= "Term types:" . "\n";
    foreach $k (sort keys %termTypes) {
	$stats .= "\t$k: " . $termTypes{$k} . "\n";
    }
    $stats .= "\n";
    $stats .= "Relation types:" . "\n";
    foreach $k (sort keys %relationTypes) {
	$stats .= "\t$k: " . $relationTypes{$k} . "\n";
    }
    
    # $stats .= "" . "\n";
    # $stats .= "" . "\n";
    # $stats .= "" . "\n";
    # $stats .= "" . "\n";
    # $stats .= "" . "\n";


    return($stats);
}

sub printStats {
    my ($self, $filename, $addmode) = @_;

    my $id;
    my %terms;
    my %termTypes;
    my %relations;
    my %relationTypes;

    my $fh;
    if ($filename eq "-") {
	$fh = \*STDOUT;
    } else {
	if (defined $addmode) {
	    open $fh, ">>:utf8", $filename or die "no such file " . $filename . "\n";
	} else {
	    open $fh, ">:utf8", $filename or die "no such file " . $filename . "\n";
	}
    }

    print $fh $self->getStats;

    if ($filename ne "-") {
	close $fh;
    }
}


1;

__END__

=head1 NAME

Brat::Handler - Perl extension for managing Brat files.

=head1 SYNOPSIS

use Brat::Handler;

$bratHandler = Brat::Handler->new();

$bratHandler->concat();

=head1 DESCRIPTION

The module manages Brat files (<http://brat.nlplab.org/> - Brat aims
at annotating text files with entities and relation).

The list of loaded files is indicated in the attribute
C<inputFiles>. Annotations are stored in the attribute
C<bratannotations>.

=head1 METHODS

=head2 new()

    Brat::Handler::new();

This method creates a handler to manage several files and their
annotations and returns the createed object.

=head2 loadDir()

    $bratHandler->loadDir($inputDir);

The methods loads annotation files from the directory C<inputDir>.

=head2 loadList()

    $bratHandler->loadList($list);

The methods loads annotation files from the C<$list>.

=head2 loadFile()

    $bratHandler->loadFile($file);

The methods loads annotation file specified in C<$file>.

=head2 concat()

    $bratHandler->concat();

The methods concatenates annotation files indicated in the field C<inputFiles>.

=head2 getTermList()

    $bratHandler->getTermList();

The method returns a string containing the list of entities of the
loaded files, in the C<Alvis::TermTagger> format.

=head2 getStats()

    $bratHandler->getStats();

The method returns a string containing the statistics for all the
loaded file.


=head2 printTermList()

    $bratHandler->printTermList($filename, $mode);

The method prints a entity list in the C<Alvis::TermTagger> format, in
the file C<$filename>. If the file is C<->, statistics are printed on
the standard output.



=head2 getRelationList()

    $bratHandler->getRelationList();

The method returns a string containing the relations between two
entities with the type of the relation. Separator is C< : >.

=head2 printRelationList()

    $bratHandler->printRelationList($filename, $mode);

The method prints relations between two entities with the type of the
relation in the file C<$filename>. Separator is C< : >. If the file is
C<->, statistics are printed on the standard output.


=head2 printStats()

    $bratHandler->printStats($filename, $mode);

The method prints the statistics of all the loaded files in the file
C<$filename>. If the file is C<->, statistics are printed on the
standard output.



=head1 SEE ALSO

http://brat.nlplab.org/

=head1 AUTHORS

Thierry Hamon <hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2015 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
