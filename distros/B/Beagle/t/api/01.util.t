use Test::More;
use Beagle::Util;

my @subs = qw/
  enabled_devel enable_devel disable_devel enabled_cache enable_cache disable_cache
  set_current_root current_root root_name set_current_root_by_name check_root
  static_root kennel core_config user_alias
  set_core_config set_user_alias roots set_roots relation
  set_relation default_format split_id root_name name_root root_type
  system_alias create_backend alias aliases resolve_id die_entry_not_found
  die_entry_ambiguous current_handle handles share_root resolve_entry
  is_in_range parse_wiki  parse_markdown parse_pod marks set_marks
  whitelist set_whitelist detect_roots
  detect_roots backends_root cache_root
  share_root marks set_marks
  spread_template_roots web_template_roots
  entry_type_info entry_types
  relation_path marks_path web_options
  tweak_name plugins po_roots
  web_all web_names web_admin
  system_roots current_user
  /;

for (@subs) {
    can_ok( main, $_ );
}

done_testing();
