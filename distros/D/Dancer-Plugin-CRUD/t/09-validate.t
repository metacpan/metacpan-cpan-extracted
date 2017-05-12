use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];
use Try::Tiny;

# Dancer::Test had a bug in version previous 1.3059_01 that prevent this test
# from running correctly.
my $dancer_version = eval "\$Dancer::VERSION";
$dancer_version =~ s/_//g;
plan skip_all =>
  "Dancer 1.3059_01 is needed for this test (you have $dancer_version)"
  if $dancer_version < 1.305901;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;
    use Test::More import => ['!pass'];

    set serialzier => 'JSON';

    sub is_def {
        return sub { defined(shift) ? undef : 'Not defined' }
    }

    resource foo => validation => {
        generic => {
            checks => [
                foo_id => is_def,
                foo_id => Validate::Tiny::is_in( [qw[ 123 ]] )
            ]
        },
        create => {
            fields => [qw[ name ]],
            checks => [
                name => Validate::Tiny::is_required,
                name => Validate::Tiny::is_like(qr{^[a-z]{3}$})
            ]
        },
        update => {
            fields => [qw[ name ]],
            checks => [
                name => Validate::Tiny::is_required,
                name => Validate::Tiny::is_like(qr{^[a-z]{3}$})
            ]
        }
      },
      index => sub {
        return var('validate')->data;
      },
      create => sub {
        return var('validate')->data;
      },
      read => sub {
        return var('validate')->data;
      },
      update => sub {
        return var('validate')->data;
      },
      prefix_id => sub {
        resource bar => validation => {
            generic => {
                checks => [
                    bar_id => Validate::Tiny::is_in( [qw[ 456 ]] )
                ]
            },
            update => {
                fields => [qw[ name ]],
                checks => [
                    name => Validate::Tiny::is_required,
                    name => Validate::Tiny::is_like(qr{^[a-z]{5}$})
                ]
            }
          },
          index => sub {
            return var('validate')->data;
          },
          read => sub {
            return var('validate')->data;
          },
          update => sub {
            return var('validate')->data;
          };
      };
}

use Dancer::Test;
use Data::Dumper;

plan tests => 14;

my $r;

$r = dancer_response( GET => '/foo' );
is_deeply $r->{content}, {}, 'index foo ok';

$r = dancer_response( GET => '/foo/456' );
is_deeply $r->{content}, { error => { foo_id => 'Invalid value' } },
  'read foo wrong foo_id';

$r = dancer_response( POST => '/foo', { body => { name => 'xxx' } } );
is_deeply $r->{content}, { name => 'xxx' }, 'create foo ok';

$r = dancer_response( POST => '/foo', { body => { name => 'XXX' } } );
is_deeply $r->{content}, { error => { name => 'Invalid value' } },
  'create foo wrong name';

$r = dancer_response( PUT => '/foo/123', { body => { name => 'xxx' } } );
is_deeply $r->{content}, { foo_id => 123, name => 'xxx' }, 'update foo ok';

$r = dancer_response( PUT => '/foo/123', { body => { name => 'XXX' } } );
is_deeply $r->{content}, { error => { name => 'Invalid value' } },
  'update foo wrong name';

$r = dancer_response( GET => '/foo/123/bar' );
is_deeply $r->{content}, { foo_id => 123 }, 'index foo->bar ok';

$r = dancer_response( GET => '/foo/123/bar/456' );
is_deeply $r->{content}, { foo_id => 123, bar_id => 456 }, 'read foo->bar ok';

$r = dancer_response( GET => '/foo/456/bar/456' );
is_deeply $r->{content}, { error => { foo_id => 'Invalid value' } },
  'read foo->bar wrong foo_id';

$r = dancer_response( GET => '/foo/456/bar/123' );
is_deeply $r->{content},
  { error => { foo_id => 'Invalid value', bar_id => 'Invalid value' } },
  'read foo->bar wrong foo_id,bar_id';

$r =
  dancer_response( PUT => '/foo/123/bar/456', { body => { name => 'xxxxx' } } );
is_deeply $r->{content}, { foo_id => 123, bar_id => 456, name => 'xxxxx' },
  'update foo->bar ok';

$r =
  dancer_response( PUT => '/foo/123/bar/456', { body => { name => 'XXXXX' } } );
is_deeply $r->{content}, { error => { name => 'Invalid value' } },
  'update foo->bar wrong name';

$r = dancer_response( GET => '/foo/123', { body => { garbage => '???' } } );
is_deeply $r->{content}, { foo_id => 123 }, 'read foo ignored garbage params';

$r = dancer_response(
    POST => '/foo.yml',
    { body => { name => 'xxx', format => 'yml' } }
);
is_deeply $r->{content}, { name => 'xxx' }, 'create foo ignored format';

diag sprintf "[%s] %s", $_->{level}, $_->{message} for @{ read_logs() };

done_testing;
