Changes in this Release v1.1.1
- Fix multi-version libconfig compatibility (verified against 1.3.2, 1.4.8, 1.4.9, 1.5, 1.8.x)
- Add version guards for all 1.4+ and 1.5+ APIs in XS code
- Fix config_setting_lookup_int type: long* (1.3.x) vs int* (1.4+)
- Fix config_set_hook to use config_setting_set_hook/get_hook
- Add version skips in tests for pre-1.4 and pre-1.8 features

Changes in this Release v1.1.0
- Upgrade to support libconfig 1.8.x API.
- Add config_set_options / config_get_options / config_set_option / config_get_option.
- Add config_set_auto_convert / config_get_auto_convert.
- Add config_set_float_precision / config_get_float_precision.
- Add config_set_tab_width / config_get_tab_width.
- Add config_set_default_format / config_get_default_format.
- Add config_set_hook / config_get_hook.
- Add config_clear.
- Add error_text / error_file / error_line / error_type.
- Add config_setting_lookup and setting-level lookup_* methods.
- Add config_setting_get_*_safe methods.
- Add config_setting_set_format / config_setting_get_format.
- Add config_setting_is_scalar / is_aggregate / is_group / is_array / is_list / is_number.
- Add config_setting_name / parent / is_root / index.
- Add config_setting_source_line / source_file.
- Add CONFIG_FORMAT_* and CONFIG_OPTION_* constants.
- Fix: stray semicolon causing incorrect behavior in get_general_list and get_general_object.
- Optimize: replace fragile log()-based type detection with direct SV flag checks.
- Switch from Module::Install to ExtUtils::MakeMaker for simpler build.
- Suppress all compiler warnings.
- Add new tests: 15-options.t, 16-format.t, 17-setting-adv.t, 18-error.t, 19-safe.t.

Changes in this Release v1.0.3
- Add workflow for github.
- Fix some issues.
- Update general value.