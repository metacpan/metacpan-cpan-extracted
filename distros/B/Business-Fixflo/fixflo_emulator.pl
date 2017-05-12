#!/opt/tools/bin/perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JSON qw/ decode_json encode_json /;
use Readonly;

use FindBin qw/$Bin/;
use lib $Bin;

$ENV{MOJO_LOG_LEVEL} = 'debug';

Readonly my $BASE_URN => '/api/v2';

# 
# emulator for Fixflo
#
app->hook(
	before_dispatch => sub {
		my ( $self ) = @_;

		# must have a "valid" API key
		return 1 if $self->req->headers->header( 'Authorization' );

		$self->render( text => '', status => 401 );
	},
);

# some useful helpers to prevent repetition
app->helper(
	url_detail => sub {
		my ( $self ) = @_;

		my $http = $self->req->url->base->scheme;
		my $host = $self->req->url->base->host_port;
		my $urn  = $self->req->url->path;
		my $url  = "$http://$host";
		my $uri  = "$url$urn";

		return ( $http,$host,$url,$urn,$uri );
	},
);

app->helper(
	pages => sub {
		my ( $self ) = @_;

		my $page = $self->param( 'page' );
		$page = 1 if ( !$page || $page =~ /\D/ || $page < 0 );

		#              next      prev      start         end
		return ( $page,$page + 1,$page - 1,$page * 5 - 4,$page * 5 );
	},
);

my %pager_entities = (
	'Addresses'          => \&_address,
	'Issues'             => \&_issue_url,
	'Agencies'           => \&_agency_url,
	'Search'             => \&_property,
	'LandlordProperties' => \&_landlord_property,
	'Landlords'          => \&_landlord,
);

my %dispatch = (
	'IssueDraftMedia'  => \&_issue_draft_media,
	'IssueDraft'       => \&_issue_draft,
	'Issue'            => \&_issue,
	'Property'         => \&_property,
	'PropertyAddress'  => \&_property_address,
	'Landlord'         => \&_landlord,
	'LandlordProperty' => \&_landlord_property,
	'Agency'           => \&_agency,
);

get "$BASE_URN/:entity"
	=> [
		entity => qr/Landlords|Issues|Agencies/,
	],
	=> sub {

	my ( $self ) = @_;

	my ( $page,$next,$prev,$start,$end ) = $self->pages;
	my ( $http,$host,$url,$urn,$uri )    = $self->url_detail;

	my $entity_item = $pager_entities{ $self->param( 'entity' ) }
		|| return $self->reply->not_found;
	
	my @items = map { $entity_item->( $_,undef,$url ) } $start .. $end;

	$self->render(
		json   => {
			PreviousURL => $prev ? "$uri?page=$prev" : undef,
			NextURL     =>         "$uri?page=$next",
			TotalItems  => scalar( @items ) * $next,
			TotalPages  => $next,
			Items       => [ @items ],
		}
	);
};

get "$BASE_URN/Issue/:id/Report" => sub {
	my ( $self ) = @_;

	my $id = $self->param( 'id' );

	# not returning anything here, just setting the headers for a PDF download
	$self->res->headers->content_type( 'application/pdf' );
	$self->res->headers->content_disposition( "attachment;filename=$id.pdf" );

	$self->render( text => 'some_pdf_data' );
};

get "$BASE_URN/IssueDraftMedia/:id/Download" => sub {
	my ( $self ) = @_;

	my $id = $self->param( 'id' );

	# not returning anything here, just setting the headers for a BIN download
	$self->res->headers->content_type( 'application/octet-stream' );
	$self->res->headers->content_disposition( "attachment;filename=$id.bin" );

	$self->render( text => 'bees' );
};

get "$BASE_URN/:entity/:id/:sub_entity"
	=> { id => undef }
	=> [
		entity     => qr/Landlord|Property|PropertyAddress/,
		sub_entity => qr/Addresses|Issues|Search|LandlordProperties/,
	]
	=> sub {

	my ( $self ) = @_;

	my ( $page,$next,$prev,$start,$end ) = $self->pages;
	my ( $http,$host,$url,$urn,$uri )    = $self->url_detail;

	my $sub_entity_item = $pager_entities{ $self->param( 'sub_entity' ) }
		|| return $self->reply->not_found;

	# avoid infinite calls to $pager->next
	my $do_next_page = rand( 10 ) > 3;

	if (
		$self->param( 'entity' ) eq 'Property'
		&& $self->param( 'sub_entity' ) eq 'Issues'
	) {
		$sub_entity_item = \&_issue_summary;
	}
	
	my @items = map { $sub_entity_item->( $_,undef,$url ) } $start .. $end;
	my $total_pages = $do_next_page ? $next : $prev + 1;

	$self->render(
		json   => {
			PreviousURL => $prev ? "$uri?page=$prev" : undef,
			NextURL     => $do_next_page ? "$uri?page=$next" : undef,
			TotalPages  => $total_pages,
			TotalItems  => scalar( @items ) * $total_pages,
			Items       => [ @items ],
		}
	);
};

get "$BASE_URN/:entity/:id"
	=> { id => undef }
	=> [
		id     => qr/\d+/,
		entity => qr/Property|Issue|IssueDraft|IssueDraftMedia|PropertyAddress|Landlord|LandlordProperty|Agency/,
	],
	=> sub {

	my ( $self ) = @_;

	my $method = $dispatch{ $self->param( 'entity' ) }
		|| return $self->reply->not_found;

	$self->render( json => $method->( $self->param( 'id' ) ) );
};

post "$BASE_URN/:entity/:action"
	=> { action => undef }
	=> [ action => qr/Commit|Delete|Merge|Split|delete|undelete/ ]
	=> sub {

	my ( $self ) = @_;

	my $post_data = $self->req->json
		|| return $self->render( json => {}, status => 400 );

	my $method = $dispatch{ $self->param( 'entity' ) }
		|| return $self->reply->not_found;

	my $action = $self->stash( 'action' );

	$method = $dispatch{ Issue }
		if $action && $action =~ /commit/i;

	$self->render( json => _envelope( $method->( undef,$post_data ) ) );
};

del "$BASE_URN/Agency/:id" => sub {
	my ( $self ) = @_;
	$self->render( json => _envelope( _agency( $self->param( 'id' ) ) ) );
};

get "/api/v2/:qvp/:panel/:id"
	=> [ qvp => qr/qvp/i ],
	=> { panel => undef, id => undef }
	=> sub {

	my ( $self ) =  @_;

	my ( $http,$host,$url,$urn,$uri ) = $self->url_detail;

	if ( $self->param( 'panel' ) ) {
		$self->render( json => [ _qvp( $self->param( 'id' ) ) ] );
	} else {
		$self->render( json => [ map { _qvps( $_,undef,$url ) } 1,37 .. 42 ] );
	}
};

app->start;

sub _issue_draft_media {
	my ( $id ) = @_;

	$id //= time;

	return {
		"Id" => $id,
		"IssueDraftId" => 1,
		"Url" => "",
		"ContentType" => "",
		"ShortDesc" => "",
		"EncodedByteData" => "",
	};
}

sub _issue_url {
	my ( $id,$post_data,$url ) = @_;

 	return "$url/api/v2/Issue/$id";
}

sub _agency_url {
	my ( $id,$post_data,$url ) = @_;

 	return "$url/api/v2/Agency/$id";
}

sub _issue_draft {
	my ( $id ) = @_;

	$id //= time;

	return {
		"Id" => $id,
		"Updated" => "2015-07-01T08:49:43",
		"IssueTitle" => "foo",
		"FaultId" => 0,
		"FaultNotes" => "Rabbit",
		"IssueDraftMedia" => [],
		"FirstName" => "f", # note inconsistent with Issue (Firstname)
		"Surname" => "g",
		"EmailAddress" => "samuel\@givengain.com",
		"ContactNumber" => "i",
		"ContactNumberAlt" => "i",
		"Address" => _property( $id )->{Address},
	};
}

sub _issue {
	my ( $id ) = @_;

	$id //= time;

	return {
		"ContactNumber" => "i",
		"Firstname" => "f", # note inconsistent with IssueDraft (FirstName)
		"Status" => "Reported",
		"Id" => "$id",
		"Salutation" => "e",
		"TenantNotes" => undef,
		"Property" => _property( $id ),
		"StatusChanged" => "2015-07-01T08:49:43",
		"FaultCategory" => "Pests/Vermin > Rodents",
		"FaultNotes" => "Rabbit",
		"CallbackId" => undef,
		"Address" => _property( $id )->{Address},
		"TermsAccepted" => Mojo::JSON->false,
		"EmailAddress" => "samuel\@givengain.com",
		"Title" => "Other (Rodents)",
		"FaultTitle" => undef,
		"FaultTree" => undef,
		"TenantPresenceRequested" => Mojo::JSON->false,
		"PropertyAddressId" => $id,
		"Surname" => "g",
		"Created" => "2015-07-01T08:49:43",
		"DirectMobileNumber" => undef,
		"Media" => [],
		"DirectEmailAddress" => undef,
		"VulnerableOccupiers" => undef,
		"TenantAcceptComplete" => undef,
		"AdditionalDetails" => undef,
		"ContactNumberAlt" => undef,
		"WorksAuthorisationLimit" => undef,
		"ExternalRefTenancyAgreement" => undef,
		"FaultPriority" => 3,
		"TenantId" => "$id",
		"Job" => undef,
	}
}

sub _issue_summary {
	my ( $id ) = @_;

	$id //= time;

	return {
		"Id" => "$id",
		"StatusId" => "$id",
		"Status" => "Reported",
		"StatusChanged" => "2015-07-01T08:49:43",
		"Created" => "2015-07-01T08:49:43",
		"IssueTitle" => "issue title",
		"Address" => _property( $id )->{Address},
	}
}

sub _property {
	my ( $id,$post_data ) = @_;

	$id //= time;

	return {
		"PropertyAddressId" => $id,
		"Id" => $id,
		"KeyReference" => 'foo',
		"ExternalPropertyRef" => "PP60770",
		"Address" => _address(),
		"Created" => "",
		"UpdateDate" => "",
		%{ $post_data // {} },
	};
}

sub _property_address {
	my ( $id ) = @_;

	$id //= time;

	return {
		"PropertyId" => $id,
		"Id" => $id,
		"ExternalPropertyRef" => "PP60770",
		"Address" => _address(),
	};
}

sub _landlord {
	my ( $id ) = @_;

	$id //= time;

	return {
		"Id" => $id,
		"CompanyName" => "Foo",
		"Title" => "Mr",
		"FirstName" => "Lee",
		"Surname" => "Johnson",
		"EmailAddress" => "lee\@g3s.ch",
		"ContactNumber" => "123",
		"ContactNumberAlt" => "456",
		"DisplayName" => "Lee J",
		"WorksAuthorisationLimit" => "0.01",
		"EmailCC" => "lee\@g3s.ch",
		"IsDeleted" => Mojo::JSON->false,
	};
}

sub _landlord_property {
	my ( $id ) = @_;

	$id //= time;

	return {
		"Id" => $id,
		"LandlordId" => $id,
		"PropertyId" => $id,
		"DateFrom" => "2010-07-01T08:49:43",
		"DateTo" => "2020-07-01T08:49:43",
		"Address" => _address(),
	};
}

sub _address {

	return {
		"Country" => "",
		"AddressLine2" => "b",
		"County" => "",
		"AddressLine1" => "a",
		"Town" => "c",
		"PostCode" => "E"
	}
}

sub _agency {
	my ( $id,$post_data ) = @_;

	$id //= time;

	return {
		Id => $id,
		AgencyName => "My Agency",
		CustomDomain => "myagency.fixflo.com",
		EmailAddress => "lee\@g3s.ch",
		Password => "fs03QEFEajda",
		IsDeleted => Mojo::JSON->false,
		Created => "2010-07-01T08:49:43",
		FeatureType => 0,
		IssueTreeRoot => 0,
		SiteBaseUrl => "foo",
		DefaultTimeZoneId => "UTC",
		Locale => "en-GB",
		ApiKey => '',
		TermsAcceptanceDate => '',
		TermsAcceptanceUrl => '',
		UpdateDate => '',
		%{ $post_data // {} },
	}
}

sub _envelope {
	my ( $entity ) = @_;

	return {
		Errors => [],
		Messages => [],
		HttpStatusCode => 200,
		HttpStatusCodeDesc => "OK",
		Entity => $entity,
	}
}

sub _qvps {
	my ( $id,$post_data,$url ) = @_;

	return {
		'DataTypeName' => 'IssueStatusSummary',
		'Explanation'  => 'Summarises all open issues by status',
		'QVPTypeId'    => $id,
		'Title'        => 'Issue status',
		'Url'          => "$url/api/v2/QVP/IssueStatusSummary/$id",
	};
}

sub _qvp {
	my ( $id ) = @_;

	if ( $id == 40 ) {
		return {
			Key   => 'weeee',
			Value => '123',
		}
	}

	if ( $id == 41 ) {

		return ( map {
			{
			  "Id" => "$_",
			  "IssueId" => "$_",
			  "StatusId" => 16,
			  "Status" => "Closed",
			  "StatusChanged" => "2017-01-12T11:01:54",
			  "Created" => "2017-01-11T20:49:35",
			  "IssueTitle" => "Tumble dryer does not work correctly (Tumble dryer)",
			  "Address" => {
				"AddressLine1" => "11 Egerton",
				"AddressLine2" => "Fallowfield",
				"Town" => "Manchester",
				"County" => "",
				"PostCode" => "M14 6YD",
				"Country" => ""
			  }
			}
		} 1 .. 5 );
	}

	return {
		'Count'       => 7,
		'HtmlColor'   => '#6386BA',
		'HtmlColorHi' => '#76A0DF',
		'Label'       => 'Reported',
		'Status'      => 'Reported',
		'StatusId'    => 0
	};
}
