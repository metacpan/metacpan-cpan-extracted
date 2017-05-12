package Amazon::MWS::XML::GenericFeed;

use strict;
use warnings;
use utf8;

use File::Spec;
use Data::Dumper;

use Moo;

=head1 NAME

Amazon::MWS::XML::GenericFeed -- base module to create XML feeds for Amazon MWS

=head1 ACCESSORS

=head2 xml_writer

The L<XML::Compile::Schema> writer object. You can pass this to build
this object manually (usually it's the Uploader who builds the writer).

    my $writer = XML::Compile::Schema->new([glob '*.xsd'])
       ->compile(WRITER => 'AmazonEnvelope');

=head2 merchant_id

Required. The merchant id provided by Amazon.

=head2 debug

Whether to enable debugging or not.

=cut

has xml_writer => (is => 'ro', required => 1);

has debug => (is => 'rw');

has merchant_id => (is => 'ro',
                    required => 1,
                    isa => sub {
                        die "the merchant id must be a string" unless $_[0];
                    });

=head1 METHODS

=head2 create_feed($operation, \@messages, %options)

Create a feed of type $operation, with the messages passed. The
options are not used yet.

=cut

sub create_feed {
    my ($self, $operation, $messages, %options) = @_;
    die "Missign operation" unless $operation;
    return unless $messages && @$messages;

    my $data = {
                Header => {
                           MerchantIdentifier => $self->merchant_id,
                           DocumentVersion => "1.1", # unclear
                          },
                MessageType => $operation,
                # to be handled with options eventually?
                # MarketplaceName => "example",
                # PurgeAndReplace => "false", unclear if "false" works
                Message => $messages,
               };
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $xml = $self->xml_writer->($doc, $data);
    $doc->setDocumentElement($xml);
    return $doc->toString(1);
}

1;
