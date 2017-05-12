package Brat::Handler;


use utf8;
use strict;
use warnings;
use open qw(:utf8 :std);

use Brat::Handler::File;

our $VERSION='0.1';

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
    
    my $ann = Brat::Handler::File->new($file);
    return($ann);
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
