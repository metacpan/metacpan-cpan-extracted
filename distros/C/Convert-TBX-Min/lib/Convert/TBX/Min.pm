#
# This file is part of Convert-TBX-Min
#
# This software is copyright (c) 2016 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Convert::TBX::Min;
use strict;
use warnings;
use TBX::Min 0.07;
use XML::Writer;
use XML::Twig;
use Exporter::Easy (
	OK => ['min2basic']
);

# report parsing errors from TBX::Min in the caller's namespace,
# not ours
our @CARP_NOT = __PACKAGE__;

# mappings between TBX-Min and TBX-Basic picklists
my %status_map = (
    preferred => 'preferredTerm-admn-sts',
    admitted => 'admittedTerm-admn-sts',
    notRecommended => 'deprecatedTerm-admn-sts',
    obsolete => 'supersededTerm-admn-sts'
);

# convert input file if called as a script
min2basic(@ARGV) unless caller;

our $VERSION = '0.07'; # VERSION

# ABSTRACT: Convert TBX-Min to TBX-Basic


sub min2basic {
	my ($input) = @_;
	my $min;
	if(ref $input eq 'TBX::Min'){
		$min = $input;
	}else{
	   $min = TBX::Min->new_from_xml($input);
	}
	my $martif = XML::Twig::Elt->new(martif => {type => 'TBX-Basic'});
    $martif->set_pretty_print('indented');
	if($min->source_lang){
		$martif->set_att('xml:lang' => $min->source_lang);
	}
    my $header = _make_header($min);
    $header->paste($martif);
    _make_text($min)->paste('after' => $header);

    my $twig = XML::Twig->new();
    $twig->set_doctype('martif', 'TBXBasiccoreStructV02.dtd');
    $twig->set_encoding('UTF-8');
    $twig->set_root($martif);
	return \$twig->sprint;
}

# create the martifHeader element from the TBX::Min input
sub _make_header {
    my ($min) = @_;
    my $header = XML::Twig::Elt->new('martifHeader');
    XML::Twig::Elt->new(p => {type => 'XCSURI'}, 'TBXBasicXCSV02.xcs')->
        wrap_in('encodingDesc')->paste($header);

    my $file_desc = XML::Twig::Elt->new('fileDesc');
    $file_desc->paste($header);
    XML::Twig::Elt->new(title => $min->id)->
        wrap_in('titleStmt')->paste($file_desc);

    my $source_desc = XML::Twig::Elt->new('sourceDesc')->
        paste(last_child => $file_desc);

    my @header_atts;
    for my $header_att (qw(creator description directionality license)){
        if(my $value = $min->$header_att){
            push @header_atts, "$header_att: $value";
        }
    }
    if(@header_atts){
        for my $att(@header_atts){
            XML::Twig::Elt->new(p => $att)->paste($source_desc);
        }
    }
    # need a default source description
    if(not $min->description){
        XML::Twig::Elt->new(p => $min->id . ' (generated from UTX)')->
            paste($source_desc);
    }

    return $header;
}

# create the body element from the TBX::Min input
sub _make_text {
    my ($min) = @_;
    my $body = XML::Twig::Elt->new('body');

    for my $concept (@{$min->entries}){
        my $entry = XML::Twig::Elt->new(
            'termEntry' => {id => $concept->id})->paste(
            last_child => $body);
        if(my $subject_field = $concept->subject_field){
            XML::Twig::Elt->new(descrip => {type => 'subjectField'},
                $subject_field)->paste($entry);
        }
        for my $lang_group (@{$concept->lang_groups}){
            my $lang_el = XML::Twig::Elt->new(
                langSet => {'xml:lang' => $lang_group->code})->
                paste(last_child => $entry);
            for my $term_group (@{$lang_group->term_groups}){
                my $term_el = XML::Twig::Elt->new('tig');
                $term_el->paste(last_child => $lang_el);
                XML::Twig::Elt->new(
                    term => $term_group->term)->paste($term_el);
                if(my $status = $term_group->status){
                    XML::Twig::Elt->new(termNote =>
                        {type => 'administrativeStatus'},
                        $status_map{$status})->
                        paste(last_child => $term_el);
                }
                if(my $pos = $term_group->part_of_speech){
                    XML::Twig::Elt->new(termNote =>
                        {type => 'partOfSpeech'}, $pos)->
                        paste(last_child => $term_el);
                }
                if(my $customer = $term_group->customer){
                    XML::Twig::Elt->new(admin =>
                        {type => 'customerSubset'}, $customer)->
                        paste(last_child => $term_el);
                }
                for my $note_group (@{$term_group->note_groups})
                {
					for my $note_cluster (@{$note_group->notes})
					{
						if((my $note = $note_cluster->noteValue)){ #&& !$note_cluster->noteKey){
							XML::Twig::Elt->new(note => $note)->
								paste(last_child => $term_el);
						}
					}
                }
            }
        }
    }
    return $body->wrap_in('text');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Convert::TBX::Min - Convert TBX-Min to TBX-Basic

=head1 VERSION

version 0.07

=head1 SYNOPSIS

	use Convert::TBX::Min 'min2basic';
	min2basic('/path/to/file'); # XML string pointer okay too

=head1 DESCRIPTION

This module converts TBX-Min XML into TBX-Basic XML.

=head1 FUNCTIONS

=head2 C<min2basic>

Converts TBX-Min data into TBX-Basic data. The input may be either
a TBX::Min object or data to be passed to TBX::Min's
L<TBX::Min/new_from_xml> constructor. The return value is a scalar
ref containing the TBX-Basic XML document as a UTF-8-encoded string.

=head1 SEE ALSO

=over

=item L<min2basic> (the included script)

=item L<TBX::Min>

=item L<Convert::TBX::Basic>

=back

Schema for validating TBX documents, as well as more information
about individual dialects, is available on
L<GitHub|https://github.com/byutrg/TBX-Spec>.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>, James Hayes <james.s.hayes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
