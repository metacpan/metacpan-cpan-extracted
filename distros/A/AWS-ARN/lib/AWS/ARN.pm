package AWS::ARN;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str/;
use Type::Utils;

our $VERSION = '0.005';

use overload '""' => sub {
	shift->arn;
};

my $partitionRe = my $serviceRe = qr{[\w-]+};
my $regionRe = qr{[\w-]*};
my $account_idRe = qr{\d*};
my $resource_idRe = qr{.+};
my $arnRe = qr{arn:$partitionRe:$serviceRe:$regionRe:$account_idRe:$resource_idRe};
my $Arn = declare(
	as Str, 
	where { m{^$arnRe$} }, 
	message { "$_ is not a valid ARN" }
);
my $ArnRegion = declare(
	as Str, 
	where { m{^$regionRe$} }, 
	message { "$_ is not a valid AWS Region" }
);
my $ArnPartition = declare(
	as Str, 
	where { m{^$partitionRe$} }, 
	message { "$_ is not a valid AWS Partitition" }
);
my $ArnService = declare(
	as Str,
	where { m{^$serviceRe$} },
	message { "$_ is not a valid AWS Service" }
);
my $ArnAccountID = declare(
	as Str,
	where { m{^$account_idRe$} }, 
	message { "$_ is not a valid AWS Account ID" }
);
my $ArnResourceID = declare(
	as Str,
	where { m{^$resource_idRe$} },
	message { "$_ is not a valid AWS Resource" },
);

sub _split_arn {
	my $self = shift;
	my ($index) = @_;
	return "" unless $self->_has_arn;
	my @parts = split( /:/, $self->arn, 6 );
	return $parts[$index||0]||"";
}

has arn => (
	is => 'rw',
	isa => $Arn,
	lazy => 1,
	builder => '_build_arn',
	clearer => '_clear_arn',
	predicate => '_has_arn',
	trigger => 1,
);

has partition => (
	is => 'rw',
	isa => $ArnPartition,
	lazy => 1,
	builder => '_build_partition',
	clearer => '_clear_partition',
	default => 'aws',
	trigger => sub { shift->_clear_arn },
);

has service => (
	is => 'rw',
	isa => $ArnService,
	lazy => 1,
	required => 1,
	builder => '_build_service',
	clearer => '_clear_service',
	trigger => sub { shift->_clear_arn },
);

has region => (
	is => 'rw',
	isa => $ArnRegion,
	lazy => 1,
	builder => '_build_region',
	clearer => '_clear_region',
	trigger => sub { shift->_clear_arn },
);

has account_id => (
	is => 'rw',
	isa => $ArnAccountID,
	lazy => 1,
	builder => '_build_account_id',
	clearer => '_clear_account_id',
	trigger => sub { shift->_clear_arn },
);

has resource_id => (
	is => 'rw',
	isa => $ArnResourceID,
	lazy => 1,
	builder => '_build_resource_id',
	clearer => '_clear_resource_id',
	trigger => sub { shift->_clear_arn },
);

sub _build_arn {
	my $self = shift;
	my $arn = join( ':',
		'arn',
		$self->partition,
		$self->service,
		$self->region,
		$self->account_id,
		$self->resource_id,
	);
}

sub _build_partition {
	shift->_split_arn( 1 )
}
sub _build_service {
	shift->_split_arn( 2 )
}
sub _build_region {
	shift->_split_arn( 3 )
}
sub _build_account_id {
	shift->_split_arn( 4 )
}
sub _build_resource_id {
	shift->_split_arn( 5 )
}
sub _trigger_arn {
	my $self = shift;
	$self->_clear_partition;
	$self->_clear_service;
	$self->_clear_region;
	$self->_clear_account_id;
	$self->_clear_resource_id;
}

around BUILDARGS => sub {
	my ( $orig, $class, @args ) = @_;

	return { arn => $args[0] }
		if @args == 1 && !ref $args[0];

	return $class->$orig( @args );
};

no Try::Tiny;
no Type::Utils;
no Types::Standard;
no Moo;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AWS::ARN -  module to parse and generate ARNs

=head1 VERSION

0.005

=head1 DESCRIPTION

Parse, modify and generate AWS ARNs (Amazon Resource Names)

=head1 CONSTRUCTOR

=head2 new( C<$arn> );

Return a new L<AWS::ARN> object

=head2 new( partition => $part, service => $svc, region => $rgn, account_id => $acct, resource_id => $res );

Returns a new L<AWS::ARN> object, build from the provided attributes

=head1 ATTRIBUTES

=head2 partition 

The partition in which the resource is located. A partition is a group of AWS Regions. Each AWS account is scoped to one partition.

The following are the supported partitions:

=over

=item * aws - AWS Regions

=item * aws-cn - China Regions

=item * aws-us-gov - AWS GovCloud (US) Regions

=back

Defaults to "aws"

=head2 service

The service namespace that identifies the AWS product. For example, s3 for Amazon S3 resources.

=head2 region

The Region. For example, us-east-2 for US East (Ohio).

=head2 account_id

The ID of the AWS account that owns the resource, without the hyphens. For example, 123456789012.

=head2 resource_id

The resource identifier. This part of the ARN can be the name or ID of the resource or a resource path. 
For example, user/Bob for an IAM user or instance/i-1234567890abcdef0 for an EC2 instance. Some resource 
identifiers include a parent resource (sub-resource-type/parent-resource/sub-resource) or a qualifier such 
as a version (resource-type:resource-name:qualifier).

=head1 NOTES

=over 

=item * Needs tests

=item * Needs more validation

=back

=head1 AUTHOR

James Wright <jwright@cpan.org>

=head1 SEE ALSO

=over

=item * L<< AWS Resource Names | https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html >>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by James Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


