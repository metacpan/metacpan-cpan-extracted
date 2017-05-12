use Test::More;
eval "use Test::Pod::Coverage";

plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 4;

pod_coverage_ok
  (
   'Data::RuledValidator',
   {
    # It's not private, It has not written.
    also_private => [map qr{^$_$},qw/obj id_method id_obj ok to_obj valid_yet valid_ok create_alias.* add_condition_operator/],
   }
   ,'D:RuledValidator OK'
  );

pod_coverage_ok('Data::RuledValidator::Closure', 'D::R::Closure OK');
pod_coverage_ok('Data::RuledValidator::Plugin::Core', 'D::R::P::Core OK');
pod_coverage_ok('Data::RuledValidator::Filter', 'D::R::Filter OK');

