#
# This file is part of Convert-TBX-RNG
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Convert::TBX::RNG;
use strict;
use warnings;
use TBX::XCS;
use feature 'state';
use File::Slurp;
use Path::Tiny;
use autodie;
use Carp;
use Data::Dumper;
use XML::Twig;
use File::ShareDir 'dist_dir';
use Exporter::Easy (
    OK => [qw(generate_rng core_structure_rng)],
);

our $VERSION = '0.04'; # VERSION

# ABSTRACT: Create an RNG to validate a TBX dialect


#when used as a script: take an XCS file name and print an RNG
print ${ generate_rng( xcs_file => $ARGV[0] ) } unless caller;


sub generate_rng {
    my (%args) = @_;
    if ( not( $args{xcs_file} || $args{xcs_string} || $args{xcs} ) ) {
        croak "requires either 'xcs_file', 'xcs_string' or 'xcs' parameters";
    }
    my $xcs = TBX::XCS->new();
    if ( $args{xcs_file} ) {
        $xcs->parse( file => $args{xcs_file} );
    }
    elsif($args{xcs_string}) {
        $xcs->parse( string => $args{xcs_string} );
    }else{
        $xcs = $args{xcs};
    }

    my $twig = XML::Twig->new(
        pretty_print    => 'indented',
        output_encoding => 'UTF-8',
        do_not_chain_handlers =>
          1,    #can be important when things get complicated
        keep_spaces => 0,
        no_prolog   => 1,
    );

    #parse the original RNG
    $twig->parsefile( _core_structure_rng_location() );

    #edit the RNG structure to match the XCS constraints
    _constrain_languages( $twig, $xcs->get_languages() );
    _constrain_ref_objects( $twig, $xcs->get_ref_objects() );
    _constrain_meta_cats( $twig, $xcs->get_data_cats() );

    my $rng = $twig->sprint;
    return \$rng;
}

# add the language choices to the langSet specification
sub _constrain_languages {
    my ( $twig, $languages ) = @_;

    #make an RNG choice for the xml:lang attribute of langSet
    my $choice    = XML::Twig::Elt->new('choice');
    for my $abbrv ( sort keys %$languages ) {
        XML::Twig::Elt->new( 'value', $abbrv )->paste($choice);
    }
    my $lang_elt = $twig->root->get_xpath(
      'define[@name="attlist.langSet"]/' .
      'attribute[@name="xml:lang"]', 0);
    $choice->paste($lang_elt);
    return;
}

# add ref object choices to back matter
sub _constrain_ref_objects {
    # my ( $rng, $ref_objects ) = @_;

    #unimplemented
    return;
}

# constrain meta-data cats by their data cats
sub _constrain_meta_cats {
    my ( $twig, $data_cats ) = @_;

    # impIDLangTypTgtDtyp includes: admin(Note), descrip(Note), ref, termNote, transac(Note)
    # must account for ID, xml:lang, type, target, and datatype
    for my $meta_cat (
        qw(admin adminNote
        descripNote ref transac transacNote)
      )
    {
        my $elt = $twig->get_xpath(
          "//*[\@xml:id='$meta_cat.element']", 0);
        _edit_meta_cat($elt, $data_cats->{$meta_cat});

        #we no longer use the attlists
        $twig->get_xpath( qq<define[\@name="attlist.$meta_cat"]>, 0)->delete;
    }

    _constrain_termCompList($twig, $data_cats->{'termCompList'});

    # similar to above meta data cats, but with two levels
    _constrain_termNote($twig, $data_cats->{'termNote'});
    # no longer use the attlists
    $twig->get_xpath( 'define[@name="attlist.termNote"]', 0)->delete;

    # similar to above meta data cats, but with three levels
    _constrain_descrip($twig, $data_cats->{'descrip'});
    $twig->get_xpath('define[@name="attlist.descrip"]', 0)->delete;

    # we leave no reference to this entity
    $twig->get_xpath( 'define[@name="impIDLangTypTgtDtyp"]', 0)->delete;

    # hi and xref are similar because all that needs constraining is
    # an optional type attribute
    for my $meta_type(qw(hi xref)){
        _constrain_optional_type($twig, $meta_type, $data_cats->{$meta_type});
    }

    return;
}

# handles elements of impIDLangTypTgtDtyp which do not have level specifications
# args: twig element of meta-data cat to be constrained,
# array ref containing data cat specs for a meta-data category
sub _edit_meta_cat {
    my ( $meta_cat_elt, $data_cat_list ) = @_;
    #disallow content if none specified
    unless ( $data_cat_list && @$data_cat_list ) {
        $meta_cat_elt->set_outer_xml('<empty/>');
        return;
    }

    #replace children with rng:choice, with contents based on data categories
    $meta_cat_elt->cut_children;
    my $choice = XML::Twig::Elt->new('choice');
    for my $data_cat ( @{$data_cat_list} ) {
        _get_rng_group_for_datacat($data_cat)->paste($choice);
    }
    $choice->paste($meta_cat_elt);

    #allow ID, xml:lang, target, and datatype
    XML::Twig::Elt->new( 'ref', { name => 'impIDLangTgtDtyp' } )
      ->paste($meta_cat_elt);

    return;
}

sub _constrain_termCompList {
    my ($twig, $data_cat_list) = @_;

    #disallow all content if none specified
    if(!$data_cat_list){
      $twig->get_xpath(
      '//*[@xml:id="termCompList.element"]', 0)->set_outer_xml('<empty/>');
      return;
    }
    my $termCompList_type_elt = $twig->get_xpath(
      '//*[@xml:id="termCompList.type"]', 0);

    #create choices for type attribute
    my $choice = XML::Twig::Elt->new('choice');
    for my $data_cat ( @{$data_cat_list} ) {
        XML::Twig::Elt->new('value',$data_cat->{'name'})->
          paste($choice);
    }
    $choice->paste($termCompList_type_elt);

    return;
}

#use for meta data category with an optional type (hi and xref)
sub _constrain_optional_type {
    my ($twig, $meta_type, $data_cat_list) = @_;

    my $type_elt = $twig->get_xpath(
        "//*[\@xml:id='$meta_type.type']", 0);

    #disallow type if none are specified in XCS
    if(!$data_cat_list){
      $type_elt->parent()->delete();
      return;
    }

    #create choices for type attribute
    my $choice = XML::Twig::Elt->new('choice');
    for my $data_cat ( @{$data_cat_list} ) {
        XML::Twig::Elt->new('value',$data_cat->{'name'})->
          paste($choice);
    }
    $choice->paste($type_elt);

    return;
}

# args are parsed twig and hash ref of data_categories
# constrain allowed values for termNotes at each level
sub _constrain_termNote {
  my ($twig, $data_cat_list) = @_;

    #elements present at the two levels
    my $termNote_elt = $twig->get_xpath(
            '//*[@xml:id="termNote.element"]', 0);
    my $termNote_termCompGrp_elt = $twig->get_xpath(
            '//*[@xml:id="termComp.termNote.element"]', 0);

    #disallow content if none specified
    unless ( $data_cat_list ) {
        $termNote_elt->set_outer_xml('<empty/>');
        $termNote_termCompGrp_elt->set_outer_xml('<empty/>');
        return;
    }

    #edit the data categories for the termComp level
    my @termComp_cats = grep
    {
        exists $_->{forTermComp} and
        $_->{forTermComp} eq 'yes'
    } @$data_cat_list;
    _edit_meta_cat($termNote_termCompGrp_elt, \@termComp_cats);

    #edit the data categories for the other levels
    _edit_meta_cat($termNote_elt, $data_cat_list);

    return;
}

# args are parsed twig and hash ref of data_categories
# constrain allowed values for descrips at each level
sub _constrain_descrip {
  my ($twig, $data_cat_list) = @_;

    # elements present at the three levels
    my $term_descrip_elt = $twig->get_xpath(
            '//*[@xml:id="term.descrip.element"]', 0);
    my $langSet_descrip_elt = $twig->get_xpath(
            '//*[@xml:id="langSet.descrip.element"]', 0);
    my $termEntry_descrip_elt = $twig->get_xpath(
            '//*[@xml:id="termEntry.descrip.element"]', 0);

    #disallow content if none specified
    unless ( $data_cat_list ) {
        $_->set_outer_xml('<empty/>')
            for (($term_descrip_elt, $langSet_descrip_elt, $termEntry_descrip_elt));
        return;
    }

    #find the data categories for each level
    my @term_cats = grep { _descrip_has_level('term',$_) } @$data_cat_list;
    my @langSet_cats = grep { _descrip_has_level('langSet',$_) } @$data_cat_list;
    my @termEntry_cats = grep { _descrip_has_level('termEntry',$_) } @$data_cat_list;

    #edit the allowed types at each level
    _edit_meta_cat($term_descrip_elt, \@term_cats);
    _edit_meta_cat($langSet_descrip_elt, \@langSet_cats);
    _edit_meta_cat($termEntry_descrip_elt, \@termEntry_cats);

    return;
}

#check if a descrip data category has a specified level
sub _descrip_has_level {
    my ($level, $data_cat) = @_;
    return grep {$_ eq $level} @{$data_cat->{levels}};
}

# arg: hash ref containing data category information
# returns an RNG group element containing contents of data category
sub _get_rng_group_for_datacat {
    my ($data_cat) = @_;
    my $group = XML::Twig::Elt->new('group');
    if ( $data_cat->{datatype} eq 'picklist' ) {
        _get_rng_picklist( $data_cat->{choices} )->paste($group);
    }
    else {
        XML::Twig::Elt->new( 'ref',
            { name => $data_cat->{datatype} } )->paste($group);
    }
    _get_rng_attribute( 'type', $data_cat->{name} )->paste($group);
    return $group;
}

# arg: attribute name, attribute value
# return RNG attribute element with value as contents
sub _get_rng_attribute {
    my ($name, $value) = @_;
    return XML::Twig::Elt->parse(
        '<attribute name="' . $name . '"><value>' . $value . '</value></attribute>' );
}

#create a <choice> element containing values from an array ref
sub _get_rng_picklist {
    my ($picklist) = @_;
    my $choice = XML::Twig::Elt->new('choice');
    for my $value (@$picklist) {
        XML::Twig::Elt->new( 'value', $value )->paste($choice);
    }
    return $choice;
}


sub core_structure_rng {
    my $rng = read_file( _core_structure_rng_location() );
    return \$rng;
}

sub _core_structure_rng_location {
    return path( dist_dir('Convert-TBX-RNG'), 'TBXcoreStructV02.rng' );
}

1;

__END__

=pod

=head1 NAME

Convert::TBX::RNG - Create an RNG to validate a TBX dialect

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This module creates RNG files for validating TBX dialects. Currently, the user
can generate RNG using XCS files, but in the future there may be functionality
for tweaking the core structure.

=head1 SYNOPSIS
    use Convert::TBX::RNG qw(generate_rng);
    my $rng = generate_rng(xcs_file => '/path/to/xcs');
    print $$rng;

=head1 METHODS

=head2 C<generate_rng>

Creates an RNG representation of this dialect and returns it in a string pointer.

Currently one argument is requried: C<xcs_file>, which specifies the location of
an XCS file which defines the desired dialect.

=head2 C<core_structure_rng>

Returns a pointer to a string containing the TBX core structure (version 2) RNG.
This RNG file has been edited to make processing by this module easier, but it
still properly validates the core structure of a TBX file.

=head1 GOTCHAS

RNG does not validate IDREF attributes, unlike DTD. Therefore, you will not
be able to check that target attributes refer to actual IDs within the file.

Most of the functionality of the produced RNG files matches the TBX Checker exactly;
however, some features remain unimplemented in the TBXChecker, and so behavior may not
always match.

=head1 FUTURE WORK

Currently, nothing is done to check the validity of ref objects; the RNG validates only
their core structure.

In the future we may provide functionality to tweak the TBX core structure.

=head1 SEE ALSO

Other features and documentation to help validate TBX documents can be found on
our L<gitHub|https://github.com/byutrg/TBX-Spec> page.

1;

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
