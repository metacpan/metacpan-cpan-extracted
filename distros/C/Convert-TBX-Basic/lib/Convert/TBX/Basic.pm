#
# This file is part of Convert-TBX-Basic
#
# This software is copyright (c) 2016 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Convert::TBX::Basic;
use strict;
use warnings;
# ABSTRACT: Convert TBX-Basic data into TBX-Min
our $VERSION = '0.03'; # VERSION
use XML::Twig;
use autodie;
use Path::Tiny;
use Carp;
use Log::Any '$log';
use TBX::Min 0.07;
use Try::Tiny;
use Exporter::Easy (
    OK => ['basic2min']
);
use open ':encoding(utf-8)', ':std'; #this ensures output file is UTF-8

my %status_map = (
    'preferredTerm-admn-sts' => 'preferred',
    'admittedTerm-admn-sts' => 'admitted',
    'deprecatedTerm-admn-sts' => 'notRecommended',
    'supersededTerm-admn-st' => 'obsolete'
);

sub basic2min {
    @_ == 3 or croak 'Usage: basic2min(data, source-language, target-language)';
    my ($data, $source, $target) = @_;

    my $fh = _get_handle($data);

    # build a twig out of the input document
    my $twig = XML::Twig->new(
        output_encoding => 'UTF-8',
        do_not_chain_handlers => 1,
        keep_spaces     => 0,

        # these store new entries, langGroups and termGroups
        start_tag_handlers => {
            termEntry => \&_entry_start,
            langSet => \&_langStart,
            tig => \&_termGrpStart,
        },

        TwigHandlers    => {
        	# header attributes
            title => \&_title,
            sourceDesc => \&_source_desc,
            'titleStmt/note' => \&_title_note,

            # decide whether to add a new entry
            termEntry => \&_entry,

            # becomes part of the current TBX::Min::ConceptEntry object
            'termEntry/descrip[@type="subjectField"]' => sub {
                shift->{tbx_min_min_current_entry}->
                    subject_field($_->text)},

            # these become attributes of the current
            # TBX::Min::TIG object
            'tig/termNote[@type="administrativeStatus"]' => \&_status,
            term => sub {shift->{tbx_min_current_term_grp}->
                term($_->text)},
            'tig/termNote[@type="partOfSpeech"]' => sub {
                shift->{tbx_min_current_term_grp}->
                part_of_speech($_->text)},
            'tig/note' => \&_as_note,
            'tig/admin[@type="customerSubset"]' => sub {
                shift->{tbx_min_current_term_grp}->customer($_->text)},

            # the information which cannot be converted faithfully
            # gets added as a note to the current TBX::Min::TIG,
            # with its data category prepended
            'tig/admin' => \&_as_note,
            'tig/descrip' => \&_as_note,
            'tig/termNote' => \&_as_note,
            'tig/transac' => \&_as_note,
            'tig/transacNote' => \&_as_note,
            'tig/transacGrp/date' => \&_as_note,

            # add no-op handlers for twigs not needing conversion
            # so that they aren't logged as being skipped
            'sourceDesc/p' => sub {}, # treated in sourceDesc handler
            titleStmt => sub {},
            fileDesc => sub {},
            martifHeader => sub {},
            text => sub {},
            body => sub {},
            martif => sub {},
            langSet => sub {},
            tig => sub {},
            transacGrp => sub {},

            # log anything that wasn't converted
            _default_ => \&_log_missed,
        }
    );

    # provide language info to the handlers via storage in the twig
    $twig->{tbx_languages} = [lc($source), lc($target)];

    my $min = TBX::Min->new();
    $min->source_lang($source);
    $min->target_lang($target);

    # use handlers to process individual tags and
    # add information to $min
    $twig->{tbx_min} = $min;
    $twig->safe_parse($fh); #using safe_parse here prevents crash when encoded (the open ':encoding(utf-8)) file is passed in

    # warn if the document didn't have tig's of the given source and
    # target language
    if(keys %{ $twig->{tbx_found_languages} } != 2 and
            $log->is_warn){
        # find the difference between the expected languages
        # and those found in the TBX document
        my %missing;
        @missing{ lc $min->source_lang, lc $min->target_lang() } = undef;
        delete @missing{ keys %{$twig->{tbx_found_languages}} };
        $log->warn('could not find langSets for language(s): ' .
            join ', ', sort keys %missing);
    }

    return $min;
}

sub _get_handle {
    my ($data) = @_;
    my $fh;
    if((ref $data) eq 'SCALAR'){
        open $fh, '<', $data; ## no critic(RequireBriefOpen)
    }else{
        $fh = path($data)->filehandle('<');
    }
    return $fh;
}

######################
### XML TWIG HANDLERS
######################
# all of the twig handlers store state on the XML::Twig object. A bit kludgy,
# but it works.

sub _title {
    my ($twig, $node) = @_;
	$twig->{tbx_min}->id($node->text);
	return 0;
}

sub _title_note {
    my ($twig, $node) = @_;
    my $description = $twig->{tbx_min}->description || '';
    $twig->{tbx_min}->description($description . $node->text . "\n");
    return 0;
}

sub _source_desc {
    my ($twig, $node) = @_;
    for my $p ($node->children('p')){
        my $description = $twig->{tbx_min}->description || '';
        $twig->{tbx_min}->description(
            $description . $p->text . "\n");
    }
    return 0;
}

# remove whitespace and convert to TBX-Min picklist value
sub _status {
	my ($twig, $node) = @_;
	my $status = $node->text;
	$status =~ s/[\s\v]//g;
    $twig->{tbx_min_current_term_grp}->status($status_map{$status});
    return 0;
}

# turn the node info into a note labeled with the type;
# the type becomes a noteKey and the info becomes noteValue
sub _as_note {
	my ($twig, $node) = @_;
	my $grp = $twig->{tbx_min_current_term_grp};

 	if (@{$grp->note_groups} > 0)
 	{
 		&_noteStart($twig, $node->text, $node->att('type'));
 	}
	else
	{
		&_noteGrpStart($twig);
		&_noteStart($twig, $node->text, $node->att('type'));
	}

	return 1;
}

# add a new entry to the list of those found in this file
sub _entry_start {
    my ($twig, $node) = @_;
    my $entry = TBX::Min::TermEntry->new();
    if($node->att('id')){
        $entry->id($node->att('id'));
    }else{
        carp 'found entry missing id attribute';
    }
    $twig->{tbx_min_min_current_entry} = $entry;
    return 1;
}

# add the entry to the TBX::Min object if it has any langGroups
sub _entry {
    my ($twig, $node) = @_;
    my $entry = $twig->{tbx_min_min_current_entry};
    if(@{$entry->lang_groups}){
        $twig->{tbx_min}->add_entry($entry);
    }elsif($log->is_info){
        $log->info('element ' . $node->xpath . ' not converted');
    }
    return;
}

#just set the subject_field of the current entry
sub _subjectField {
    my ($twig, $node) = @_;
    $twig->{tbx_min_min_current_entry}->subject_field($node->text);
    return 1;
}

# Create a new LangGroup, add it to the current entry,
# and set it as the current LangGroup.
# This langSet is ignored if its language is different from
# the source and target languages specified to basic2min
sub _langStart {
    my ($twig, $node) = @_;
    my $lang_grp;
    my $lang = $node->att('xml:lang');
    if(!$lang){
        # skip if missing language
        $log->warn('skipping langSet without language: ' .
            $node->xpath) if $log->is_warn;
        $node->ignore;
        return 1;
    }elsif(!grep {$_ eq lc $lang} @{$twig->{tbx_languages}}){
        # skip if non-applicable language
        $node->ignore;
        return 1;
    }

    $lang_grp = TBX::Min::LangSet->new();
    $lang_grp->code($lang);
    $twig->{tbx_found_languages}{lc $lang} = undef;
    $twig->{tbx_min_min_current_entry}->add_lang_group($lang_grp);
    $twig->{tbx_min_current_lang_grp} = $lang_grp;
    return 1;
}

# Create a new termGroup, add it to the current langGroup,
# and set it as the current termGroup.
sub _termGrpStart {
    my ($twig) = @_;
    my $term = TBX::Min::TIG->new();
    $twig->{tbx_min_current_lang_grp}->add_term_group($term);
    $twig->{tbx_min_current_term_grp} = $term;
    return 1;
}

sub _noteGrpStart {
	my ($twig) = @_;
	my $group = TBX::Min::NoteGrp->new;
	$twig->{tbx_min_current_term_grp}->add_note_group($group);
	$twig->{tbx_min_current_note_grp} = $group;
	return 1;
}

sub _noteStart {
	my ($twig, $value, $key) = @_;
	my $note = TBX::Min::Note->new(noteValue => $value, noteKey => $key);
	$twig->{tbx_min_current_note_grp}->add_note($note);
	$twig->{tbx_min_current_note} = $note;
	return 1;
}

# log that an element was not converted
sub _log_missed {
    my (undef, $node) = @_;
    $log->info('element ' . $node->xpath . ' not converted')
        if $log->is_info();
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Convert::TBX::Basic - Convert TBX-Basic data into TBX-Min

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Convert::TBX::Basic 'basic2min';
    # create a TBX-Min document from the TBX-Basic file, using EN
    # as the source language and DE as the target language
    print ${ basic2min('/path/to/file.tbx', 'EN', 'DE')->as_xml };

=head1 DESCRIPTION

TBX-Basic is a subset of TBX-Default which is meant to contain a
smaller number of data categories suitable for most needs. To some
users, however, TBX-Basic can still be too complicated. This module
allows you to convert TBX-Basic into TBX-Min, a minimal, DCT-style
dialect that stresses human-readability and bare-bones simplicity.

=head1 METHODS

=head2 C<basic2min>

    # example usage
    basic2min('path/to/file.tbx', 'EN', 'DE');

Given TBX-Basic input and the source and target languages, this method
returns a L<TBX::Min> object containing a rough equivalent of the
specified data. The source and target languages are necessary because
TBX-Basic can contain many languages, while TBX-Min must contain
exactly 2 languages. The TBX-Basic data may be either a string
containing a file name or a scalar ref containing the actual TBX-Basic
document as a string.

Obviously TBX-Min allows much less structured information than
TBX-Basic, so the conversion must be lossy. C<< <termNote> >>s,
C<< <descrip> >>, and C<< <admins> >>s will be converted if there is a
correspondence with TBX-Min, but those with C<type> attribute values
with no correspondence in TBX-Min will simply be pasted as a note,
prefixed with the name of the category and a colon. This is only
possible for elements at the term level (children of a
C<< <termEntry> >> element) because TBX-Min only allows notes inside of
its C<< <termGrp> >> elements.

As quite a bit of data can be packed into a single C<< <note> >>
element, the result can be quite messy. L<Log::Any> is used to record
the following:

=over

=item 1

(info) the elements which are stuffed into a note

=item 2

(info) the elements that are skipped altogether during the
conversion process

=item 3

(warn) The entries that are skipped because they contained no relevant
language sets, and

=item 4

(warn) The entries that are skipped because they did not have any
language specified.

=back

=head1 TODO

It would be nice to preserve the C<xml:id> attributes in order
to make the conversion process more tranparent to the user.

=head1 SEE ALSO

=over

=item L<basic2min> (the included script)

=item L<TBX::Min>

=item L<Convert::TBX::Min>

=back

=head1 AUTHOR

BYU Translation Research Group <akmtrg@byu.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
