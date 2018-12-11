package CloudHealth::API;
  use Moo;
  use Types::Standard qw/HasMethods/;

  our $VERSION = '0.01';

  has call_former => (is => 'ro', isa => HasMethods['params2request'], default => sub {
    require CloudHealth::API::CallObjectFormer;
    CloudHealth::API::CallObjectFormer->new;  
  });
  has credentials => (is => 'ro', isa => HasMethods['api_key'], default => sub {
    require CloudHealth::API::Credentials;
    CloudHealth::API::Credentials->new;
  });
  has io => (is => 'ro', isa => HasMethods['call'], default => sub {
    require CloudHealth::API::Caller;
    CloudHealth::API::Caller->new;
  });
  has result_parser => (is => 'ro', isa => HasMethods['result2return'], default => sub {
    require CloudHealth::API::ResultParser;
    CloudHealth::API::ResultParser->new
  });

  sub _invoke {
    my ($self, $method, $params) = @_;
    my $req = $self->call_former->params2request($method, $self->credentials, $params);
    my $result = $self->io->call($req);
    return $self->result_parser->result2return($result);
  }

  sub method_classification {
    {
      aws_accounts => [ qw/EnableAWSAccount AWSAccounts SingleAWSAccount 
                           UpdateExistingAWSAccount DeleteAWSAccount GetExternalID/ ],
      perspectives => [ qw/RetrieveAllPerspectives RetrievePerspectiveSchema CreatePerspectiveSchema
                           UpdatePerspectiveSchema DeletePerspectiveSchema/ ],
      reports      => [ qw/ListQueryableReports ListReportsOfSpecificType DataForStandardReport 
                           DataForCustomReport ReportDimensionsAndMeasures/ ],
      assets       => [ qw/ListOfQueryableAssets AttributesOfSingleAsset SearchForAssets/ ],
      metrics      => [ qw/MetricsForSingleAsset UploadMetricsForSingleAsset/ ],
      tags         => [ qw/UpdateTagsForSingleAsset/ ],
      partner      => [ qw/SpecificCustomerReport AssetsForSpecificCustomer CreatePartnerCustomer 
                           ModifyExistingCustomer DeleteExistingCustomer GetSingleCustomer GetAllCustomers
                           StatementForSingleCustomer StatementsForAllCustomers
                           CreateAWSAccountAssignment ReadAllAWSAccountAssignments 
                           ReadSingleAWSAccountAssignment UpdateAWSAccountAssignment 
                           DeleteAWSAccountAssignment/ ],
      gov_cloud    => [ qw/ConnectGovCloudCommercialAccountToGovCloudAssetAccount
                           ListAllGovCloudLinkagesOwnedByCurrentCustomer
                           DetailsOfSingleGovCloudLinkage UpdateSingleGovCloudLinkage
                           UnderstandFormatOfGovCloudLinkagePayload/ ],
    }
  }

  sub EnableAWSAccount {
    my $self = shift;
    $self->_invoke('EnableAWSAccount', [ @_ ]);
  }
  sub AWSAccounts {
    my $self = shift;
    $self->_invoke('AWSAccounts', [ @_ ]);
  }
  sub SingleAWSAccount {
    my $self = shift;
    $self->_invoke('SingleAWSAccount', [ @_ ]);
  }
  sub UpdateExistingAWSAccount {
    my $self = shift;
    $self->_invoke('UpdateExistingAWSAccount', [ @_ ]);
  }
  sub DeleteAWSAccount {
    my $self = shift;
    $self->_invoke('DeleteAWSAccount', [ @_ ]);
  }
  sub GetExternalID {
    my $self = shift;
    $self->_invoke('GetExternalID', [ @_ ]); 
  }

  sub RetrieveAllPerspectives {
    my $self = shift;
    $self->_invoke('RetrieveAllPerspectives', [ @_ ]);
  }

  sub RetrievePerspectiveSchema {
    my $self = shift;
    $self->_invoke('RetrievePerspectiveSchema', [ @_ ]);
  }
  sub CreatePerspectiveSchema {
    my $self = shift;
    $self->_invoke('CreatePerspectiveSchema', [ @_ ]);  
  }
  sub UpdatePerspectiveSchema {
    my $self = shift;
    $self->_invoke('UpdatePerspectiveSchema', [ @_ ]);   
  }
  sub DeletePerspectiveSchema {
    my $self = shift;
    $self->_invoke('DeletePerspectiveSchema', [ @_ ]);    
  }

  sub ListQueryableReports {
    my $self = shift;
    $self->_invoke('ListQueryableReports', [ @_ ]);
  }

  sub ListReportsOfSpecificType {
    my $self = shift;
    $self->_invoke('ListReportsOfSpecificType', [ @_ ]);
  }

  sub DataForStandardReport { die "TODO" }
  sub DataForCustomReport { die "TODO" }
  sub ReportDimensionsAndMeasures { die "TODO" }

  sub ListOfQueryableAssets {
    my $self = shift;
    $self->_invoke('ListOfQueryableAssets', [ @_ ]);
  }

  sub AttributesOfSingleAsset {
    my $self = shift;
    $self->_invoke('AttributesOfSingleAsset', [ @_ ]);
  }

  sub SearchForAssets {
    my $self = shift;
    $self->_invoke('SearchForAssets', [ @_ ]);
  }

  sub MetricsForSingleAsset {
    my $self = shift;
    $self->_invoke('MetricsForSingleAsset', [ @_ ]);
  }

  sub UploadMetricsForSingleAsset { die "TODO" }

  sub UpdateTagsForSingleAsset {
    my $self = shift;
    $self->_invoke('UpdateTagsForSingleAsset', [ @_ ]);
  }

  sub SpecificCustomerReport {
    my $self = shift;
    $self->_invoke('SpecificCustomerReport', [ @_ ]); 
  }
  sub AssetsForSpecificCustomer {
    my $self = shift;
    $self->_invoke('AssetsForSpecificCustomer', [ @_ ]);
  }
  sub CreatePartnerCustomer {
    my $self = shift;
    $self->_invoke('CreatePartnerCustomer', [ @_ ]);  
  }
  sub ModifyExistingCustomer {
    my $self = shift;
    $self->_invoke('ModifyExistingCustomer', [ @_ ]);  
  }
  sub DeleteExistingCustomer {
    my $self = shift;
    $self->_invoke('DeleteExistingCustomer', [ @_ ]);  
  }
  sub GetSingleCustomer {
    my $self = shift;
    $self->_invoke('GetSingleCustomer', [ @_ ]);
  }
  sub GetAllCustomers {
    my $self = shift;
    $self->_invoke('GetAllCustomers', [ @_ ]); 
  }
  sub StatementForSingleCustomer {
    my $self = shift;
    $self->_invoke('StatementForSingleCustomer', [ @_ ]);
  }
  sub StatementsForAllCustomers {
    my $self = shift;
    $self->_invoke('StatementsForAllCustomers', [ @_ ]);
  }

  sub ConnectGovCloudCommercialAccountToGovCloudAssetAccount { die "TODO" }
  sub ListAllGovCloudLinkagesOwnedByCurrentCustomer { die "TODO" }
  sub DetailsOfSingleGovCloudLinkage { die "TODO" }
  sub UpdateSingleGovCloudLinkage { die "TODO" }
  sub UnderstandFormatOfGovCloudLinkagePayload { die "TODO" }
  
  sub CreateAWSAccountAssignment {
    my $self = shift;
    $self->_invoke('CreateAWSAccountAssignment', [ @_ ]);
  }
  sub ReadAllAWSAccountAssignments {
    my $self = shift;
    $self->_invoke('ReadAllAWSAccountAssignments', [ @_ ]);
  }
  sub ReadSingleAWSAccountAssignment {
    my $self = shift;
    $self->_invoke('ReadSingleAWSAccountAssignment', [ @_ ]); 
  }
  sub UpdateAWSAccountAssignment {
    my $self = shift;
    $self->_invoke('UpdateAWSAccountAssignment', [ @_ ]); 
  }
  sub DeleteAWSAccountAssignment { 
    my $self = shift;
    $self->_invoke('DeleteAWSAccountAssignment', [ @_ ]);  
  }

1;
### main pod documentation begin ###

=encoding UTF-8
 
=head1 NAME
 
CloudHealth::API - A REST API Client for the CloudHealth API

=head1 SYNOPSIS
 
  use CloudHealth::API;
  my $ch = CloudHealth::API->new;
  
  my $res = $ch->MetricsForSingleAsset(
    asset => $asset,
  );
  print Dumper($res);
 
=head1 DESCRIPTION

This module implements the CloudHealth REST API found in L<https://apidocs.cloudhealthtech.com/>

=head1 METHODS

Each method on the client corresponds to an API action. You can find a class in the 
C<CloudHealth::API::Call> namespace that describes the parameters that the method call accepts:

L<CloudHealth::API::Call::EnableAWSAccount>

  $ch->EnableAWSAccount(authentication => { protocol => '..' }, ...);

L<CloudHealth::API::Call::AWSAccounts>

  $ch->AWSAccounts;

L<CloudHealth::API::Call::SingleAWSAccount>

  $ch->SingleAWSAccount(id => $id);

L<CloudHealth::API::Call::UpdateExistingAWSAccount>

  $ch->UpdateExistingAWSAccount(id => $id, authentication => { protocol => '..' }, ...);

L<CloudHealth::API::Call::GetExternalID>

  $ch->GetExternalID(id => $id)

L<CloudHealth::API::Call::MetricsForSingleAsset>

  $ch->MetricsForSingleAsset(asset => $id, from => '...', to => '...');

L<CloudHealth::API::Call::DeleteAWSAccount>

L<CloudHealth::API::Call::RetrieveAllPerspectives>

L<CloudHealth::API::Call::RetrievePerspectiveSchema>

L<CloudHealth::API::Call::CreatePerspectiveSchema>

L<CloudHealth::API::Call::UpdatePerspectiveSchema>

L<CloudHealth::API::Call::DeletePerspectiveSchema>

L<CloudHealth::API::Call::ListQueryableReports>

L<CloudHealth::API::Call::ListReportsOfSpecificType>

L<CloudHealth::API::Call::ListOfQueryableAssets>

L<CloudHealth::API::Call::AttributesOfSingleAsset>

L<CloudHealth::API::Call::SearchForAssets>

L<CloudHealth::API::Call::UpdateTagsForSingleAsset>

L<CloudHealth::API::Call::SpecificCustomerReport>

L<CloudHealth::API::Call::AssetsForSpecificCustomer>

L<CloudHealth::API::Call::CreatePartnerCustomer>

L<CloudHealth::API::Call::ModifyExistingCustomer>

L<CloudHealth::API::Call::DeleteExistingCustomer>

L<CloudHealth::API::Call::GetSingleCustomer>

L<CloudHealth::API::Call::GetAllCustomers>

L<CloudHealth::API::Call::StatementForSingleCustomer>

L<CloudHealth::API::Call::StatementsForAllCustomers>

L<CloudHealth::API::Call::CreateAWSAccountAssignment>

L<CloudHealth::API::Call::ReadAllAWSAccountAssignments>

L<CloudHealth::API::Call::ReadSingleAWSAccountAssignment>

L<CloudHealth::API::Call::UpdateAWSAccountAssignment>

L<CloudHealth::API::Call::DeleteAWSAccountAssignment>

=head1 AUTHENTICATION

As the documentation states, you need an API KEY to query the API. The default authentication
mechanism expects to find that API key in the C<CLOUDHEALTH_APIKEY> environment variable.

You can also pass any object that implements an C<api_key> method to the C<credentials> attribute
of the constructor

=head1 RESULTS

Results are returned as a Perl HashRef representing the JSON returned by the API.

=head1 SEE ALSO

L<https://apidocs.cloudhealthtech.com/>

There is a CLI wrapper available as a CPAN module: L<App::CloudHealth>

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

=head1 BUGS and SOURCE
 
The source code is located here: L<https://github.com/pplu/cloudhealth-api-perl/>
 
Please report bugs to: L<https://github.com/pplu/cloudhealth-api-perl/issues>
 
=head1 COPYRIGHT and LICENSE
 
Copyright (c) 2018 by Jose Luis Martinez Torres
 
This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
