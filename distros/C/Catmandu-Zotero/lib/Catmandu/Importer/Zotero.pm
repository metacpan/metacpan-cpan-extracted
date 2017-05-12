package Catmandu::Importer::Zotero;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use WWW::Zotero;
use Moo;
use feature 'state';

with 'Catmandu::Importer';

has userID       => (is => 'ro');
has groupID      => (is => 'ro');
has collectionID => (is => 'ro');
has apiKey       => (is => 'ro');

# From WWW::Zotero
has sort      => (is => 'ro');
has direction => (is => 'ro');
has itemKey   => (is => 'ro');
has itemType  => (is => 'ro');
has q         => (is => 'ro');
has qmode     => (is => 'ro');
has since     => (is => 'ro');
has tag       => (is => 'ro');

has client  => (is => 'lazy');

sub _build_client {
    my ($self) = @_;
    WWW::Zotero->new(key => $self->apiKey);
}

sub generator {
    my ($self) = @_;

    sub { 
        state $generator;

        unless (defined $generator) {  
            my %options = ();

            $options{user}      = $self->userID if $self->userID;
            $options{group}     = $self->groupID if $self->groupID;
            $options{sort}      = $self->sort if $self->sort;
            $options{direction} = $self->direction if $self->direction;
            $options{itemKey}   = $self->itemKey if $self->itemKey;
            $options{itemType}  = $self->itemType if $self->itemType;
            $options{q}         = $self->q if $self->q();
            $options{qmode}     = $self->qmode if $self->qmode;
            $options{since}     = $self->since if $self->since;
            $options{tag}       = $self->tag if $self->tag;
            $options{include}   = 'data';
            
            $options{itemType} .= " -attachment";

            if ($self->collectionID) {
                $options{collectionKey} = $self->collectionID;
                $generator = $self->client->listCollectionItems(%options, generator => 1);
            } else {
                $generator = $self->client->listItems(%options, generator => 1);
            }
        }

        my $record = $generator->();

        return undef unless $record;
        
        if ($record->{meta}->{numChildren} > 0) {
            # Find children
            $record->{children} = $self->client->getItemChildren(
                                        user    => $self->userID,
                                        group   => $self->groupID,
                                        itemKey => $record->{_id}
                                  );
        }
        else {
            $record->{children} = [];
        }
        
        $record;
    };
}

1;

__END__

=head1 NAME

Catmandu::Importer::Zotero - Import records from Zotero web

=head1 SYNOPSIS

    # From the command line
    # From the command line
    $ catmandu convert Zotero --userID <userID> to JSON
    $ catmandu convert Zotero --groupID <groupID> to JSON
  
    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('Zotero', userID => '...');

    $importer->each(sub {
       my $item = shift;
       print "%s %s\n", $item->{_id} , $item->{title}->[0];
   });

=head1 CONFIGURATION

=over

=item userID 

User identifier (given at L<https://www.zotero.org/settings/keys>). Required
unless C<groupID> is set.

=item groupID

Group identifier (numeric part of the RSS library feed of a group)  

=item collectionID

Collection key (alphanumeric identifier)

=item apiKey

Zotero API key for authenticated access

=item sort      

C<dateAdded>, C<dateModified> (default), C<title>, C<creator>, C<type>,
C<date>, C<publisher>, C<publicationTitle>, C<journalAbbreviation>,
C<language>, C<accessDate>, C<libraryCatalog>, C<callNumber>, C<rights>,
C<addedBy>, or C<numItems>
    
=item direction

C<asc> or C<desc>
    
=item itemKey    

A comma-separated list of item keys. Valid only for item requests. Up to 
50 items can be specified in a single request.
    
=item itemType   

Item type search. See
L<https://www.zotero.org/support/dev/web_api/v3/basics#search_syntax>
for boolean search syntax.

=item q   

Quick search to search titles and individual creator fields, or all fields if
qmode is set to C<everything>.
    
=item qmode    

C<titleCreatorYear> (default) or C<everything>
    
=item since   

Return only objects modified after the specified library version.
    
=item tag 

Tag search. Supports Boolean search like item type search.

=back

=head1 DESCRIPTION

This L<Catmandu::Importer> imports bibliographic data from
L<Zotero|https://www.zotero.org> reference management service.

=head1 SEE ALSO

L<WWW::Zotero>,
L<Catmandu::Importer>,
L<Catmandu::Iterable>

=cut
