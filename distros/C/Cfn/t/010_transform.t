use Moose::Util::TypeConstraints;

use Cfn;

use Test::More;

{
  my $cfn = Cfn->new(
    Transform => 'AWS::Serverless-2016-10-31'
  );

  ok(defined $cfn->Transform, 'Transform defined');
  cmp_ok($cfn->as_hashref->{ Transform }->[0], 'eq', 'AWS::Serverless-2016-10-31');
}

{
  my $cfn = Cfn->new();

  ok(not(defined $cfn->Transform), 'No Transform defined');
  ok(not(exists $cfn->as_hashref->{ Transform }), 'Transform key not in final result');
}

{
  my $cfn = Cfn->new(
    Transform => ['AWS::Serverless-2016-10-31']
  );

  ok( defined $cfn->Transform, 'Transform defined' );
  cmp_ok( $cfn->as_hashref->{Transform}->[0], 'eq', 'AWS::Serverless-2016-10-31' );
}

{
  my $cfn = Cfn->new();

  ok( not( defined $cfn->Transform ), 'No Transform defined' );
  ok( not( exists $cfn->as_hashref->{Transform} ), 'Transform key not in final result' );
}

done_testing;
