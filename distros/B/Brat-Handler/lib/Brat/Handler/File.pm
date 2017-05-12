package Brat::Handler::File;


use utf8;
use strict;
use warnings;
use open qw(:utf8 :std);

our $VERSION='0.1';

sub new {

    my ($class, $filename) = @_;
    my $annotationFilename;
    my $textFilename;
    my $textSize = 0;
    my @annFiles;
    my @textFiles;
    my @files;
    my $f;
    my $line;

    # print STDERR "\n==> $filename - " . ref($filename) . ";\n";
    if (defined $filename) {
	if (ref($filename) eq "") {
	    push @files, $filename;
	} elsif (ref($filename) eq "ARRAY") {
	    push @files, @$filename;
	}
    }
    foreach $f (@files) {
	# warn "$f\n";
	$annotationFilename = $f;
	$annotationFilename =~ s/\.txt$/.ann/;
	$textFilename = $f;
	$textFilename =~ s/\.ann$/.txt/;
	$textSize = 0;
	open FILE, $textFilename or die "no such file $textFilename\n";
	while($line = <FILE>) {
	    $textSize += length($line);
	}
	close FILE;
	# my @s = stat($textFilename);
	# $textSize += $s[7];
	push @annFiles, $annotationFilename;
	push @textFiles, $textFilename;
    }
    my $bratfile = {
	'annotationFilename' => [@annFiles],
	'textFilename' => [@textFiles],
	'terms' => {},
	'relations' => {},
	'attributes' => {},
	'maxTermId' => 0,
	'maxRelationId' => 0,
	'maxAttributeId' => 0,
	'textSize' => $textSize,
    };
    
    bless($bratfile, $class);

    if (defined $filename) {
	if (ref($filename) eq "") {
	    $bratfile->loadBratFile;
	} elsif (ref($filename) eq "ARRAY") {
	    warn "load of several brat files not implemented\n";
	}
    }
    return($bratfile);
}

sub _textFilename {
    my $self = shift;

    if (@_) {
	my $arg = shift;
	push @{$self->{'textFilename'}}, $arg;
    }
    return($self->{'textFilename'});
}

sub _textSize {
    my $self = shift;

    if (@_) {
	$self->{'textSize'} = shift;
    }
    return($self->{'textSize'});
}

sub _annotationFilename {
    my $self = shift;
    if (@_) {
	my $arg = shift;
	if ($arg =~ /^\d+$/) {
	    return($self->{'annotationFilename'}->[$arg]);
	} else {
	    push @{$self->{'annotationFilename'}}, $arg;
	}
    }
    return($self->{'annotationFilename'});
}

sub _terms {
    my $self = shift;

    if (@_) {
	my $list = shift;
	my $term;
	foreach $term (@$list) {
	    $self->_addTerm($term->{'id'}, $term);
	}
	# $self->{'terms'} = shift;

	# max Term Id
    }
    return($self->{'terms'});
}

sub _addTerm {
    my $self = shift;

    if (@_) {
	my $id = shift;
	$self->_terms->{$id} = shift;
	# max Term Id
	if ($self->_maxTermId < $self->_terms->{$id}->{'numId'}) {
	    $self->_maxTermId($self->_terms->{$id}->{'numId'});
	}
	return($self->_getTermFromId($id));
    }
    return(undef);
}

sub _maxTermId {
    my $self = shift;

    if (@_) {
	$self->{'maxTermId'} = shift;
    }
    return($self->{'maxTermId'});
}

sub _getTermFromId {
    my $self = shift;
    my $id = shift;

    if ((defined $id) && (exists $self->_terms->{$id})) {
	return($self->_terms->{$id});
    }
}

sub _relations {
    my $self = shift;

    if (@_) {
	my $list = shift;
	my $relation;
	foreach $relation (@$list) {
	    $self->_addRelation($relation->{'id'}, $relation);
	}
	# $self->{'relations'} = shift;
	# max Relation Id
    }
    return($self->{'relations'});
}

sub _addRelation {
    my $self = shift;

    if (@_) {
	my $id = shift;
	$self->_relations->{$id} = shift;
	# max Relation Id
	# warn $self->_maxRelationId . " < " . $self->_relations->{$id}->{'numId'} . "\n";
	if ($self->_maxRelationId < $self->_relations->{$id}->{'numId'}) {
	    $self->_maxRelationId($self->_relations->{$id}->{'numId'});
	}
	return($self->_getRelationFromId($id));
    }
    return(undef);
}

sub _maxRelationId {
    my $self = shift;

    if (@_) {
	$self->{'maxRelationId'} = shift;
    }
    return($self->{'maxRelationId'});
}

sub _getRelationFromId {
    my $self = shift;
    my $id = shift;

    if ((defined $id) && (exists $self->_relations->{$id})) {
	return($self->_relations->{$id});
    }
}

sub _attributes {
    my $self = shift;

    if (@_) {
	my $list = shift;
	my $attribute;
	foreach $attribute (@$list) {
	    $self->_addAttribute($attribute->{'id'}, $attribute);
	}
	# $self->{'attributes'} = shift;
	# max Attribute Id
    }
    return($self->{'attributes'});
}

sub _addAttribute {
    my $self = shift;

    if (@_) {
	my $id = shift;
	$self->_attributes->{$id} = shift;
	# max Attribute Id
	if ($self->_maxAttributeId < $self->_attributes->{$id}->{'numId'}) {
	    $self->_maxAttributeId($self->_attributes->{$id}->{'numId'});
	}
	return($self->_getAttributeFromId($id));
    }
    return(undef);
}

sub _maxAttributeId {
    my $self = shift;

    if (@_) {
	$self->{'maxAttributeId'} = shift;
    }
    return($self->{'maxAttributeId'});
}

sub _getAttributeFromId {
    my $self = shift;
    my $id = shift;

    if ((defined $id) && (exists $self->_attributes->{$id})) {
	return($self->_attributes->{$id});
    }
}

sub loadBratFile {
    my ($self) = @_;
    my $line;
    my $id;
    my $info;
    my $str;
    my $type;
    my $termId;
    my $value;
    my $arg1;
    my $arg2;
    my $o;
    my $s;
    my $e;
    my @starts;
    my @ends;
    my $numId;
#    warn "===> " . $self->_filename . "\n";
    open FILE, "<:utf8", $self->_annotationFilename(0) or die "no such file " . $self->_annotationFilename(0) . "\n";
    while($line = <FILE>) {
	chomp $line;
	@starts = ();
	@ends = ();

	($id, $info, $str) = split /\t/, $line;
	# warn "$id\n";
	if ($id =~ /^T(?<numid>\d+)/) {
	    $numId = $+{numid};
#	    ($type, $start, $end) = split / /, $info;
#	    warn "info: $info\n";
	    if ($info =~ /^(?<type>[^ ]+) (?<offsets>.*)/) {
		$type = $+{type};
		foreach $o (split /;/, $+{offsets}) {
		    ($s, $e) = split / /, $o;
#		    warn "\t$s : $e\n";
		    push @starts, $s;
		    push @ends, $e;
		}
	    # warn "->$id\n";
	    $self->_addTerm($id, {
		'id' => $id,
		'numId' => $numId,
		'type' => $type,
		'start' => [@starts],
		'end' => [@ends],
		'str' => $str,
		'attrlst' => [],
			    });
	    }
	}
	if ($id =~ /^A(?<numid>\d+)/) {
	    $numId = $+{numid};
	    ($type, $termId, $value) = split / /, $info;
	    $self->_addAttribute($id, {
		'id' => $id,
                'numId' => $numId,
		'type' => $type,
		'termId' => $termId,
		'value' => $value,
			       });
	    # warn "termId: $start\n";
	    push @{$self->_getTermFromId($termId)->{'attrlst'}}, $id;
	    
	}
	if ($id =~ /^R(?<numid>\d+)/) {
	    # warn "==> $id " . $+{numid} . "\n";
	    $numId = $+{numid};
	    ($type, $arg1, $arg2) = split / /, $info;
	    $arg1 =~ s/^Arg1://;
	    $arg2 =~ s/^Arg2://;
	    $self->_addRelation($id, {
		'id' => $id,
                'numId' => $numId,
		'type' => $type,
		'arg1' => $arg1,
		'arg2' => $arg2,
			      });
	}
    }
    close FILE;
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

sub getStats {
    my ($self) = @_;

    my $id;
    my %terms;
    my %termTypes;
    my %relations;
    my %relationTypes;
    my $stats;

    foreach $id (keys %{$self->_terms}) {
	$terms{$self->_getTermFromId($id)->{'str'}}++;
	$termTypes{$self->_getTermFromId($id)->{'type'}}++;
    }
    
    foreach $id (keys %{$self->_relations}) {
	$relations{$self->_getTermFromId($self->_getRelationFromId($id)->{'arg1'})->{'str'} . " : " . $self->_getTermFromId($self->_getRelationFromId($id)->{'arg2'})->{'str'}}++;
	$relationTypes{$self->_getRelationFromId($id)->{'type'}}++;
    }


    $stats = "number of annotated terms: " . scalar(keys %{$self->_terms}) . "\n";
    $stats .= "number of annotated relations: " . scalar(keys %{$self->_relations}) . "\n";

    $stats .= "number of terms: " . scalar(keys %terms) . "\n";
    $stats .= "number of term type: " . scalar(keys %termTypes) . "\n";

    $stats .= "number of relations: " . scalar(keys %relations) . "\n";
    $stats .= "number of relation type: " . scalar(keys %relationTypes) . "\n";
    return($stats);
    # print "number of relations: " . scalar(keys %{$data->{'relations'}}) . "\n";
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
    # foreach $id (keys %{$self->_terms}) {
    # 	print $fh $self->_getTermFromId($id)->{'str'} . " : : " . $self->_getTermFromId($id)->{$id}->{'type'} . " :\n";
    # }
    print $fh $self->getTermList;

    if ($filename ne "-") {
	close $fh;
    }

}

sub getTermList {
    my ($self) = @_;
    my $id;
    my $termlistStr = "";

    foreach $id (keys %{$self->_terms}) {
	$termlistStr .= $self->_getTermFromId($id)->{'str'} . " : : " . $self->_getTermFromId($id)->{'type'} . " :\n";
    }
    return($termlistStr);
}



sub printRelationList {
    my ($self, $filename, $addmode) = @_;
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

sub getRelationList {
    my ($self, $addmode) = @_;
    my $id;
    my $relationList = "";
    
    foreach $id (keys %{$self->_relations}) {
	$relationList .= $self->_getTermFromId($self->_getRelationFromId($id)->{'arg1'})->{'str'} . " : " . $self->_getTermFromId($self->_getRelationFromId($id)->{'arg2'})->{'str'} . " : " . $self->_getRelationFromId($id)->{'type'} . "\n";
    }
    return($relationList);
}

sub getAnnotationList {
    my ($self) = @_;
    my $id;
    my $attrId;
    my $elt;
    my $attr;
    my $annotations = "";
    my $i;

    foreach $id (sort {&_sortId($a,$b)} keys %{$self->_terms}) {
	$elt = $self->_getTermFromId($id);
	$annotations .= $elt->{'id'} . "\t";
	$annotations .= $elt->{'type'} . " ";
	for($i=0; $i < scalar(@{$elt->{'start'}}); $i++) {
	    $annotations .= $elt->{'start'}->[$i] . " " . $elt->{'end'}->[$i] . ";";
	}
	chop $annotations;
	
	$annotations .= "\t" . $elt->{'str'} . "\n";
	foreach $attrId (sort {&_sortId($a,$b)} @{$elt->{'attrlst'}}) {
	    $attr = $self->_getAttributeFromId($attrId);
	    $annotations .= $attr->{'id'} . "\t";
	    $annotations .= $attr->{'type'} . " " . $attr->{'termId'} . " " . $attr->{'value'} . "\n";
	}
    }
    foreach $id (sort {&_sortId($a,$b)} keys %{$self->_relations}) {
	$elt = $self->_getRelationFromId($id);
	$annotations .= $elt->{'id'} . "\t";
	$annotations .= $elt->{'type'} . " Arg1:" . $elt->{'arg1'} . " Arg2:" . $elt->{'arg2'} . "\n";
    }    
    return($annotations);
}

sub _sortId {
    my ($A, $B) = @_;

    my $idA = $a;
    $idA =~ s/^[TAR]//;
    my $idB = $b;
    $idB =~ s/^[TAR]//;
    return($idA <=> $idB);
}

sub print {
    my ($self, $filename, $addmode) = @_;
    my $fh;
    my $line;
    my $file;
    my $annotationFilename = $filename;
    $annotationFilename =~ s/\.txt$/.ann/;
    my $textFilename = $filename;
    $textFilename =~ s/\.ann$/.txt/;

    # print/copy text
    if ($filename eq "-") {
	$fh = \*STDOUT;
    } else {
	if (defined $addmode) {
	    open $fh, ">>:utf8", $textFilename or die "no such file $textFilename\n";
	} else {
	    open $fh, ">:utf8", $textFilename or die "no such file $textFilename\n";
	}
    }
    foreach $file (@{$self->_textFilename}) {
	open FILE, $file or die "no such file " . $file . "\n";
	while($line = <FILE>) {
	    print $fh $line;
	}
	close FILE;
    }
    if ($filename ne "-") {
	close $fh;
    }

    # print annotations
    if ($filename eq "-") {
	$fh = \*STDOUT;
    } else {
	if (defined $addmode) {
	    open $fh, ">>:utf8", $annotationFilename or die "no such file $annotationFilename\n";
	} else {
	    open $fh, ">:utf8", $annotationFilename or die "no such file $annotationFilename\n";
	}
    }
    print $fh $self->getAnnotationList;
    if ($filename ne "-") {
	close $fh;
    }
}

1;

__END__

=head1 NAME

Brat::Handler::File - Perl extension for handling a Brat file

=head1 SYNOPSIS

use Brat::Handler::File;

$bratFile = Brat::Handler::File->new($filename);

$bratFile->print("-");


=head1 DESCRIPTION

The module handles Brat annotations associated to a text file. It also
manages annotations concatenated from several files.

As for the annotations, the terms are stored in the attribute
C<terms>, relations in the attribute C<relations> and attributes in
the attribute C<attributes>.

The name of the file containing the annotation is stored in the
attribute C<annotationFilemane>, and the name of the text file is
recorded in the attribute C<textFilename>. Since those attributes are
arrays, it is possible to store annotations from several files.

Other attributes are used to describe the annotations: C<maxTermId>
contains the last term id, C<maxRelationId> contains the last relation
id, C<maxAttributeId> contains the last attribute id, and C<textSize>
records the number of characters of the text file.

=head1 METHODS

=head2 new()

    Brat::Handler::File::new($filename);

The method creates a C<Brat::Handler::File> object and returns the
object. 

The filename can have the C<txt> or the C<ann> extension. C<$filename>
can be a string or a list of string. If C<$filename> is specified and
if it is a string, Brat annotations are loaded.

=head2 loadBratFile()

    $bratFile->loadBratFile();

The method loads Brat annotation of the first file specified in the
attribute C<annotationFilename>.


=head2 printStats()

    $bratFile->printStats($filename, $mode);

The method prints statistics on the loaded annotations.

=head2 getStats()

    $bratFile->getStats();

The method returns a string containing the statistics on the loaded
annotations.


=head2 printTermList()

    $bratFile->printTermList($filename, $mode);

The method prints a entity list in the C<Alvis::TermTagger> format.


=head2 getTermList()

    $bratFile->getTermList();

The method returns a string containing the list of entities in the
C<Alvis::TermTagger> format.

=head2 printRelationList()

    $bratFile->printRelationList($filename, $mode);

The method prints relations between two entities with the type of the
relation. Separator is C< : >.



=head2 getRelationList()

    $bratFile->getRelationList();

The method returns a string containing the relations between two
entities with the type of the relation. Separator is C< : >.

=head2 getAnnotationList()

    $bratFile->getAnnotationList();

The methods returns the annotations in the Brat format.

=head2 print()

    $bratFile->print($filename, $mode);

The methods prints the annotations in the Brat format.

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
