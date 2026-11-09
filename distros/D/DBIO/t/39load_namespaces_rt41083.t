use strict;
use warnings;

use lib 't/lib';
use DBIO::Test;
use Test::More tests => 10;

# The text DBIO::Schema::load_namespaces really emits when a ResultSet class
# differs from the one already set on the Result class.
my $rs_complaint = qr/We found ResultSet class '[^']+' matching '[^']+', but it seems that you had already set the '[^']+' resultet to '[^']+' instead/;

sub _chk_warning {
  defined $_[0] ? $_[0] !~ $rs_complaint : 1
}

sub _chk_extra_sources_warning {
  my $p = qr/already has a source, use register_extra_source for additional sources/;
  defined $_[0]? $_[0] !~ /$p/ : 1;
}

sub _verify_sources {
  my @monikers = @_;
  is_deeply (
    [ sort DBIO::Test::Namespace::RtBug41083->sources ],
    \@monikers,
    'List of resultsource registrations',
  );
}

{
  my $warnings;
  eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Namespace::RtBug41083;
    use base 'DBIO::Schema';
    __PACKAGE__->load_namespaces(
      result_namespace => 'Result_A',
      resultset_namespace => 'ResultSet_A',
      default_resultset_class => 'ResultSet'
    );
  };

  ok(!$@) or diag $@;
  ok(_chk_warning($warnings), 'expected no resultset complaint');
  ok(_chk_extra_sources_warning($warnings), 'expected no extra sources complaint') or diag($warnings);

  _verify_sources (qw/A A::Sub/);
}

{
  my $warnings;
  eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Namespace::RtBug41083;
    use base 'DBIO::Schema';
    __PACKAGE__->load_namespaces(
      default_resultset_class => 'ResultSet'
    );
  };
  ok(!$@) or diag $@;
  ok(_chk_warning($warnings), 'expected no resultset complaint') or diag $warnings;
  ok(_chk_extra_sources_warning($warnings), 'expected no extra sources complaint') or diag($warnings);

  _verify_sources (qw/A A::Sub Foo Foo::Sub/);
}

# Positive control: the complaint regex above must match what the code emits,
# otherwise the "expected no resultset complaint" checks cannot fail.
{
  my $rsrc = DBIO::Test::Namespace::RtBug41083::Result_A::A->result_source_instance;
  my $orig = $rsrc->resultset_class;
  $rsrc->resultset_class('DBIO::Test::Namespace::RtBug41083::ResultSet');

  my $warnings;
  eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Namespace::RtBug41083Probe;
    use base 'DBIO::Schema';
    __PACKAGE__->load_namespaces(
      result_namespace => '+DBIO::Test::Namespace::RtBug41083::Result_A',
      resultset_namespace => '+DBIO::Test::Namespace::RtBug41083::ResultSet_A',
    );
  };
  $rsrc->resultset_class($orig);

  ok(!$@) or diag $@;
  ok(defined $warnings && !_chk_warning($warnings), 'a preset/found ResultSet mismatch is complained about, in the text the regex checks')
    or diag($warnings // 'no warning');
}
