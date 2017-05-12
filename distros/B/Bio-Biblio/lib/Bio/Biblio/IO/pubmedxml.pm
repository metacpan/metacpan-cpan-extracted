package Bio::Biblio::IO::pubmedxml;
BEGIN {
  $Bio::Biblio::IO::pubmedxml::AUTHORITY = 'cpan:BIOPERLML';
}
{
  $Bio::Biblio::IO::pubmedxml::VERSION = '1.70';
}
use utf8;
use strict;
use warnings;

use parent qw(Bio::Biblio::IO::medlinexml);

# ABSTRACT: a converter of XML files with PUBMED citations
# AUTHOR:   Martin Senger <senger@ebi.ac.uk>
# OWNER:    2002 European Bioinformatics Institute
# LICENSE:  Perl_5


our %PCDATA_NAMES;
our %SIMPLE_TREATMENT;
our %POP_DATA_AND_PEEK_OBJ;
our %POP_AND_ADD_DATA_ELEMENT;


sub _initialize {
    my ($self, @args) = @_;

    # make a hashtable from @args
    my %param = @args;
    @param { map { lc $_ } keys %param } = values %param; # lowercase keys

    # copy all @args into this object (overwriting what may already be
    # there) - changing '-key' into '_key', and making keys lowercase
    my $new_key;
    foreach my $key (keys %param) {
        ($new_key = $key) =~ s/^-/_/;
        $self->{ lc $new_key } = $param { $key };
    }

    # find the format for output - and put it into a global $Convert
    # because it will be used by the event handler who knows nothing
    # about this object
    my $result = $self->{'_result'} || 'pubmed2ref';
    $result = "\L$result";      # normalize capitalization to lower case

    # a special case is 'raw' when no converting module is loaded
    # and citations will be returned as a hashtable (the one which
    # is created during parsing XML file/stream)
    unless ($result eq 'raw') {

        # load module with output converter - as defined in $result
        if (defined &Bio::Biblio::IO::_load_format_module ($result)) {
            $Bio::Biblio::IO::medlinexml::Convert = "Bio::Biblio::IO::$result"->new (@args);
        }
    }

    # create an instance of the XML parser
    # (unless it is already there...)
    $self->{'_xml_parser'} = XML::Parser->new (Handlers => {Init  => \&Bio::Biblio::IO::medlinexml::handle_doc_start,
                                                            Start => \&handle_start,
                                                            End   => \&handle_end,
                                                            Char  => \&Bio::Biblio::IO::medlinexml::handle_char,
                                                            Final => \&Bio::Biblio::IO::medlinexml::handle_doc_end})
        unless $self->{'_xml_parser'};

    # if there is an argument '-callback' then start parsing at once -
    # the registered event handlers will use 'callback' to report
    # back after each citation
    #
    # we need to remember this situation also in a global variable
    # because the event handler subroutines know nothing about this
    # object (unfortunately)
    if ($SUPER::Callback = $self->{'_callback'}) {
        $self->_parse;
    }
}

# ---------------------------------------------------------------------
#
#   Here are the event handlers (they do the real job!)
#
# Note that these methods do not know anything about the object they
# are part of - they are called as subroutines. not as methods.
# It also means that they need to use global variables to store and
# exchnage intermediate results.
#
# ---------------------------------------------------------------------

#
# This is a list of #PCDATA elements.
#
%PCDATA_NAMES =
    (
     'PublicationStatus' => 1,
     'ProviderId' => 1,
     'ArticleId' => 1,
     'URL' => 1,
     );

%SIMPLE_TREATMENT =
    (
     'History' => 1,
     'PubMedArticle' => 1,
     'PubmedArticle' => 1,
     'PubmedData' => 1,
     );

%POP_DATA_AND_PEEK_OBJ =
    (
     'Year' => 1,
     'Month' => 1,
     'Day' => 1,
     'Hour' => 1,
     'Minute' => 1,
     'Second' => 1,
     'ProviderId' => 1,
     'PublicationStatus' => 1,
     );

%POP_AND_ADD_DATA_ELEMENT =
    (
     'PubMedPubDate' => 'pubDates',
     'History' => 'histories',
     );


sub handle_start {
    my ($expat, $e, %attrs) = @_;
#    &Bio::Biblio::IO::medlinexml::_debug_object_stack ("START", $e);

    #
    # The #PCDATA elements which have an attribute list must
    # be first here - because for them I create entries both on
    # the @PCDataStack _and_ on @ObjectStack.
    #
    if ($e eq 'ArticleId') {
        my %p = ();
        $p{'idType'} = (defined $attrs{'IdType'} ? $attrs{'IdType'} : 'pubmed');
        push (@Bio::Biblio::IO::medlinexml::ObjectStack, \%p);
    }

    if ($e eq 'URL') {
        my %p = ();
        $p{'type'} = $attrs{'type'} if $attrs{'type'};
        $p{'lang'} = $attrs{'lang'} if $attrs{'lang'};
        push (@Bio::Biblio::IO::medlinexml::ObjectStack, \%p);
    }

    #
    # Then we have #PCDATA elements without an attribute list.
    # For them I create an entry on @PCDataStack.
    #
    if (exists $PCDATA_NAMES{$e}) {
        push (@Bio::Biblio::IO::medlinexml::PCDataStack, '');

    #
    # And finally, all non-PCDATA elements go to the objectStack
    #
    } elsif (exists $SIMPLE_TREATMENT{$e}) {
        push (@Bio::Biblio::IO::medlinexml::ObjectStack, {});

    } elsif ($e eq 'ArticleIdList') {
        ;

    } elsif ($e eq 'PubMedPubDate') {
        my %p = ();
        $p{'pubStatus'} = $attrs{'PubStatus'} if $attrs{'PubStatus'};
        push (@Bio::Biblio::IO::medlinexml::ObjectStack, \%p);

    } else {
        &Bio::Biblio::IO::medlinexml::handle_start ($expat, $e, %attrs);
    }
}


sub handle_end {
    my ($expat, $e) = @_;

    #
    # First I have to deal with those elements which are both PCDATA
    # (and therefore they are on the pcdataStack) and which have an
    # attribute list (therefore they are also known as a separate
    # p-object on the objectStack.
    #
    if ($e eq 'ArticleId') {
        &Bio::Biblio::IO::medlinexml::_data2obj ('id');
        &Bio::Biblio::IO::medlinexml::_add_element ('pubmedArticleIds', pop @Bio::Biblio::IO::medlinexml::ObjectStack);
#       &Bio::Biblio::IO::medlinexml::_debug_object_stack ("END", $e);
        return;
    }

    if ($e eq 'URL') {
        &Bio::Biblio::IO::medlinexml::_data2obj ('URL');
        &Bio::Biblio::IO::medlinexml::_add_element ('pubmedURLs', pop @Bio::Biblio::IO::medlinexml::ObjectStack);
#       &Bio::Biblio::IO::medlinexml::_debug_object_stack ("END", $e);
        return;
    }


    #
    # both object and pcdata stacks elements mixed here together
    #

    if (exists $POP_DATA_AND_PEEK_OBJ{$e}) {
        &Bio::Biblio::IO::medlinexml::_data2obj ("\l$e");

    } elsif (exists $POP_AND_ADD_DATA_ELEMENT{$e}) {
        &Bio::Biblio::IO::medlinexml::_add_element ($POP_AND_ADD_DATA_ELEMENT{$e}, pop @Bio::Biblio::IO::medlinexml::ObjectStack);

    } elsif ($e eq 'MedlineCitation' ||
             $e eq 'NCBIArticle') {
        &Bio::Biblio::IO::medlinexml::_obj2obj ('Citation');

    } elsif ($e eq 'PubmedData') {
        &Bio::Biblio::IO::medlinexml::_obj2obj ('PubmedData');

    } elsif ($e eq 'PubMedArticle' ||
             $e eq 'PubmedArticle') {

        #
        # Here we finally have the whole citation ready.
        #
        &Bio::Biblio::IO::medlinexml::_process_citation (pop @Bio::Biblio::IO::medlinexml::ObjectStack);

    } else {
        &Bio::Biblio::IO::medlinexml::handle_end ($expat, $e);
    }

#    &Bio::Biblio::IO::medlinexml::_debug_object_stack ("END", $e);

}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::Biblio::IO::pubmedxml - a converter of XML files with PUBMED citations

=head1 VERSION

version 1.70

=head1 SYNOPSIS

Do not use this object directly, it is recommended to access it and use
it through the I<Bio::Biblio::IO> module:

  use Bio::Biblio::IO;
  my $io = Bio::Biblio::IO->new(-format => 'pubmedxml');

=head1 DESCRIPTION

This object reads bibliographic citations in XML/MEDLINE format and
converts them into I<Bio::Biblio::RefI> objects. It is an
implementation of methods defined in I<Bio::Biblio::IO>.

The main documentation details are to be found in
L<Bio::Biblio::IO>.

=head1 FUNCTIONS

=head2 handle_start

=head2 handle_end

=head1 INTERNAL METHODS

=head2 _initialize

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://redmine.open-bio.org/projects/bioperl/

=head1 LEGAL

=head2 Authors

Martin Senger <senger@ebi.ac.uk>

=head2 Copyright and License

This software is Copyright (c) by 2002 European Bioinformatics Institute and released under the license of the same terms as the perl 5 programming language system itself

=cut

