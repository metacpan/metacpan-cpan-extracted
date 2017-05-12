package Amazon::MWS;

=head1 NAME

Amazon::MWS - Perl interface to Amazon Marketplace Web Services

=head1 VERSION

0.141

=cut

our $VERSION = '0.141';

=head1 DESCRIPTION

See L<Amazon::MWS::Client> for the implementation of the low level
Amazon MWS API.

For the high level methods provided by the L<Amazon::MWS::Uploader>
you are going to need to supply database storage.

=head2 Uploading products

Basically you take the products which need to be uploaded to Amazon
and create L<Amazon::MWS::XML::Product> objects from them:

    use Amazon::MWS::XML::Product;
    use Amazon::MWS::Uploader;
    use Try::Tiny;

    my @upload;

    foreach my $product_object (@send_to_amazon) {
        my %prod = ....

        try {
            my $product = Amazon::MWS::XML::Product->new(%prod);
            push @upload, $product;
        } catch {
            warn "Failure with $prod{sku} : $_";
        };
     }

Now you create an L<Amazon::MWS::XML::Uploader> object and do the
actual upload.

    my $uploader = Amazon::MWS::XML::Uploader->new(...);

    try {
        $uploader->products(\@upload);
        $uploader->upload;
    } catch {
        die "Uploader failure with: $_";
    };

A product upload goes through the following steps:

=over 4

=item product

Basic product data.

=item inventory

Product inventory count (required).

=item price

Product price (required).

=item image

Product images (required).

Please note that B<only http:// links> are allowed. If you pass https://
links, they will be rejected by Amazon.

=item variants

Product variants (optional).

=back

You are not by any means finished with the upload, see L</Resume uploads>.

=head2 Delete products

Deleting products is much more straightforward, but you have still to
care of tracking the upload process, see again L</Resume uploads>.

    my $uploader = Amazon::MWS::Uploader->new(...);
    $uploader->delete_skus(@skus);

=head2 Resume uploads

This is necessary to check whether the upload has been
processed by Amazon.

    my $uploader = Amazon::MWS::XML::Uploader->new(...);
    $uploader->resume;

The uploader also goes automatically through the steps for the
product uploads.

=head1 MWS in practice

=head2 Product price

Every product uploaded needs a price of 0.01 or higher, otherwise you
get the following error:

    0.00 price (standard or sales) will not be accepted.
    Please ensure that every SKU in your feed has a price at least equal to or greater than 0.01

=head2 Shipping costs

You need to configure the shipping costs in Amazon Seller Central, you can't pass them
through MWS:

L<https://sellercentral.amazon.com/gp/shipping/dispatch.html>

=head2 Stuck uploads

There is no guarantee that Amazon finishes your uploads at all. We had uploads
stuck for at least a week.

=head2 Multiple marketplaces

You can use this module and the uploader for multiple Amazon marketplaces.
Please make sure that you disable Amazon's synchronisation between marketplaces.

For marketplaces with a different currency you need to convert your price first.

The list of marketplaces can be found at:

L<http://docs.developer.amazonservices.com/en_US/dev_guide/DG_Endpoints.html>

=head2 Throttling and Quota

With Amazon MWS you have to deal with Amazon throttling your uploads and
imposing quotas.

Possible reasons:

=over 4

=item Upload too often

=item Stuck uploads

=item Orders with orderlines

=back

=head3 Throttle Reponse

    <?xml version="1.0"?>
    <ErrorResponse xmlns="http://mws.amazonaws.com/doc/2009-01-01/">
      <Error>
      <Type></Type>
      <Code>RequestThrottled</Code>
      <Message>Request is throttled</Message>
    </Error>
    <RequestID>a7b39ee6-4f76-48ee-92f1-43bc54f693df</RequestID>
    </ErrorResponse>

=head3 Quota Exceeded Error Response

    <?xml version="1.0"?>
    <ErrorResponse xmlns="http://mws.amazonaws.com/doc/2009-01-01/">
      <Error>
        <Type></Type>
        <Code>QuotaExceeded</Code>
        <Message>You exceeded your quota of 80.0 requests per 1 hour for operation Feeds/2009-01-01/GetFeedSubmissionList.  Your quota will reset on Thu Dec 18 07:39:00 UTC 2014</Message>
      </Error>
      <RequestID>5115e00d-35a8-4589-8083-f0ef998f76ef</RequestID>
    </ErrorResponse>

=head2 Upload Errors

=head3 Error 8572: Incorrect UPCs/EANs/...

   error: You are using UPCs, EANs, ISBNs, ASINs, or JAN codes
   that do not match the products you are trying to list. Using incorrect UPCs,
   EANs, ISBNs, ASINs or JAN codes is prohibited and it can result in your ASIN
   creation privileges being suspended or permanently removed.

This happened in our case with products having self assigned EAN codes, but
with a well known manufacturer. Apparently Amazon knows about the EAN ranges
for this manufacturer.

=head3 Error 18181

The format of the tracking number passed to Amazon was invalid, e.g.
wrong number of characters.

=head3 Error 20013: Image file size

   error: Image file size: 13972730 bytes exceeds the the maximum allowed file size: 10485760 bytes.

There is no point in using such big image files for Amazon.

=head1 Uploader Module

L<Amazon::MWS::Uploader> is an upload agent for Amazon::MWS.

=head1 XML Modules

=over 4

=item Generic Feed

L<Amazon::MWS::XML::GenericFeed>

=item Feed

L<Amazon::MWS::XML::Feed>

=item Product

L<Amazon::MWS::XML::Product>

=item Address

L<Amazon::MWS::XML::Address>

=item Order

L<Amazon::MWS::XML::Order>

=item OrderlineItem

L<Amazon::MWS::XML::OrderlineItem>

=back

=head1 AUTHORS

Paul Driver
Phil Smith
Marco Pessotto
Stefan Hornburg (Racke)

=head2 COPYRIGHT

This is free software; you can redistribute it and/or modify it under the same terms
as the Perl 5 programming language system itself.

=cut

1;
