#!/usr/bin/env perl

use CCfn;

use Test::More;
use Test::Exception;

throws_ok {
  package TestArgs {
    use Moose;
    extends 'CCfnX::CommonArgs';
    use CCfnX::Attachments;
    attachment att1 => (
      type          => 'test',
      documentation => 'test-attachment',
      provides      => {
        att1 => 'value',
      }
    );
  }
} qr/already exists/, "Can't create args with two equal parameter names";


package TestAttach {
  use Moose;
  extends 'CCfnX::CommonArgs';
  use CCfnX::Attachments;

  attachment Attachment => (
    type          => 'test',
    documentation => 'test-attachment',
    provides      => {
      Att => 'value',
    }
  );
}

my $params = TestAttach->new_with_options(Att => 'Manual Value', name => 'X', region => 'X', account => 'devel-capside');

cmp_ok($params->Att, 'eq', 'Manual Value', 'Can specify an argument from an attachment without specifying the attachment');

done_testing;
