package Bundle::CPANReporter2;

$VERSION = '0.11';

1;

__END__

=head1 NAME

Bundle::CPANReporter2 - Bundle for CPAN::Reporter::Transport::Metabase

=head1 SYNOPSIS

For all Perl versions:

  $ cpan Bundle::CPANReporter2

Only once:

  $ metabase-profile
  Enter full name: John Doe
  Enter email address: jdoe@example.com
  Enter password/secret: zqxjkh
  Writing profile to 'metabase_id.json'

  $ mkdir ~/.cpanreporter
  $ cp metabase_id.json ~/.cpanreporter/
  $ chmod 400 ~/.cpanreporter/metabase_id.json
  $ vi ~/.cpanreporter/config.ini

  email_from = John Doe <jdoe@example.com>
  transport = Metabase uri https://metabase.cpantesters.org/api/v1/ id_file ~/.cpanreporter/metabase_id.json

=head1 CONTENTS

Params::Util		1.07

HTML::Parser            3.71

Data::UUID		1.219

Data::GUID		0.048

Net::SSLeay		1.58

IO::Socket::SSL		1.981

LWP::Protocol::https	6.04

IPC::Cmd 		0.76

Encode::Locale		1.03

Digest::HMAC_MD5        1.01

Net::IP                 1.26

Net::DNS		0.74

Test::Simple		1.001003

CPAN			2.05

CPAN::Meta		2.132830

CPAN::Version		5.5003

CPAN::Meta::YAML	0.012

Parse::CPAN::Meta	1.4414

Test::Reporter		1.60

Config::Perl::V		0.20

common::sense		3.72

JSON::XS		3.01

JSON			2.90

CPAN::DistnameInfo	0.12

Metabase::Fact		0.024

Metabase::Client::Simple 0.009

CPAN::Reporter		1.2011

CPAN::Testers::Report   1.999001

Test::Reporter::Transport::Metabase 1.999008


=head1 DESCRIPTION

I have a hierarchy of @INC so I mostly have to install only into some
lower versioned perl. Just XS modules need a manual update then. For
this complicated dependency chain I used this bundle, esp. for
Data::UUID, but over time more and more dependencies gone missing.
Latest additions to the club: Params::Util HTML::Parser

=head1 DEVELOPMENT

L<https://github.com/rurban/Bundle-CPANReporter2>

=head1 AUTHOR

Reini Urban
