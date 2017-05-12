use strict;
use warnings;
package CPAN::Testers::Metabase::AWS;
# ABSTRACT: Metabase backend on Amazon Web Services
our $VERSION = '1.999002'; # VERSION

use Moose;
use Metabase::Archive::S3 1.000;
use Metabase::Index::SimpleDB 1.000;
use Metabase::Librarian 1.000;
use Net::Amazon::Config;
use namespace::autoclean;

with 'Metabase::Gateway';

has 'bucket' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'namespace' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'amazon_config' => (
  is        => 'ro',
  isa       => 'Net::Amazon::Config',
  default   => sub { return Net::Amazon::Config->new },
);

has 'profile_name' => (
  is        => 'ro',
  isa       => 'Str',
  default   => 'cpantesters'
);

has '_profile' => (
  is      => 'ro',
  isa     => 'Net::Amazon::Config::Profile',
  lazy    => 1,
  builder => '_build__profile',
  handles => [ qw/access_key_id secret_access_key/ ],
);

sub _build__profile { 
  my $self = shift;
  return $self->amazon_config->get_profile( $self->profile_name );
}

sub _build_fact_classes { return [qw/CPAN::Testers::Report/] }

sub _build_public_librarian { return $_[0]->__build_librarian("public") }

sub _build_private_librarian { return $_[0]->__build_librarian("private") }

sub __build_librarian {
  my ($self, $subspace) = @_;

  my $bucket      = $self->bucket;
  my $namespace   = $self->namespace;
  my $s3_prefix   = "metabase/${namespace}/${subspace}/";
  my $sdb_domain  = "${bucket}.metabase.${namespace}.${subspace}";

  return Metabase::Librarian->new(
    archive => Metabase::Archive::S3->new(
      access_key_id     => $self->access_key_id,
      secret_access_key => $self->secret_access_key,
      bucket            => $self->bucket,
      prefix            => $s3_prefix,
      compressed        => 1,
      retry             => 1,
    ),
    index => Metabase::Index::SimpleDB->new(
      access_key_id     => $self->access_key_id,
      secret_access_key => $self->secret_access_key,
      domain            => $sdb_domain,
    ),
  );
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

CPAN::Testers::Metabase::AWS - Metabase backend on Amazon Web Services

=head1 VERSION

version 1.999002

=head1 SYNOPSIS

=head2 Direct usage

   use CPAN::Testers::Metabase::AWS;
 
   my $mb = CPAN::Testers::Metabase::AWS->new( 
     bucket    => 'myS3bucket',
     namespace => 'prod' 
   );
 
   $mb->public_librarian->search( %search spec );
   ...

=head2 Metabase::Web config

   ---
   Model::Metabase:
     class: CPAN::Testers::Metabase::AWS
       args:
         bucket: myS3bucket
         namespace: prod

=head1 DESCRIPTION

This class instantiates a Metabase backend on the S3 and SimpleDB Amazon 
Web Services (AWS).  It uses L<Net::Amazon::Config> to provide user credentials
and the L<Metabase::Gateway> Role to provide actual functionality.  As such,
it is mostly glue to get the right credentials to setup AWS clients and provide
them with standard resource names.

For example, given the C<<< bucket >>> "example" and the C<<< namespace >>> "alpha",
the following resource names would be used:

   Public S3: http://example.s3.amazonaws.com/metabase/alpha/public/*
   Public SDB domain: example.metabase.alpha.public
 
   Private S3: http://example.s3.amazonaws.com/metabase/alpha/private/*
   Private SDB domain: example.metabase.alpha.private

=head1 USAGE

=head2 new

   my $mb = CPAN::Testers::Metabase::AWS->new( 
     bucket    => 'myS3bucket',
     namespace     => 'prod', 
     profile_name  => 'cpantesters',
   );

Arguments for C<<< new >>>:

=over

=item *

C<<< bucket >>> -- required -- the Amazon S3 bucket name to hold both public and private
fact content.  Bucket names must be unique across all of AWS.  The bucket
name is also used as part of the SimpleDB namespace for consistency.

=item *

C<<< namespace >>> -- required -- a short phrase that uniquely identifies this
metabase.  E.g. "dev", "test" or "prod".  It is used to specify
specific locations within the S3 bucket and to uniquely identify a SimpleDB 
domain for indexing.

=item *

C<<< amazon_config >>> -- optional -- a L<Net::Amazon::Config> object containing
Amazon Web Service credentials.  If not provided, one will be created using
the default location for the config file.

=item *

C<<< profile_name >>> -- optional -- the name of a profile for use with 
Net::Amazon::Config.  If not provided, it defaults to 'cpantesters'.

=back

=head2 access_key_id

Returns the AWS Access Key ID.

=head2 secret_access_key

Returns the AWS Secret Access Key

=head2 Metabase::Gateway Role

This class does the L<Metabase::Gateway> role, including the following
methods:

=over

=item *

C<<< handle_submission >>>

=item *

C<<< handle_registration >>>

=item *

C<<< enqueue >>>

=back

see L<Metabase::Gateway> for more.

=head1 SEE ALSO

=over

=item *

L<CPAN::Testers::Metabase>

=item *

L<Metabase::Gateway>

=item *

L<Metabase::Web>

=item *

L<Net::Amazon::Config>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Metabase-AWS>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/cpan-testers-metabase-aws>

  git clone https://github.com/dagolden/cpan-testers-metabase-aws.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__

