#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all =>
 "Test::Pod::Coverage 1.04 required for testing POD coverage"
 if $@;
all_pod_coverage_ok(
  {
    private => [
      qr{^BUILD|DEMOLISH|AUTOMETHOD|START$},
      qr{^_},
      qr{^\(\"\"|as_string|CgiDie|CgiError|charset|CLEAR|\(cmp|compare|Delete|DELETE$},
      qr{^Delete_all|DESTROY|ebcdic|escape|escapeHTML|EXISTS|expires|fetch|FETCH$},
      qr{^FIRSTKEY|HtmlBot|HtmlTop|import|init|loader|make_attributes|MethGet$},
      qr{^MethPost|MyBaseUrl|MyFullUrl|MyURL|new|NEXTKEY|os|parse|PrintHeader$},
      qr{^PrintVariables|query_string|raw_fetch|read_from_cmdline|ReadParse$},
      qr{^rearrange|save_parameters|SplitParam|STORE|TIEHASH|unescape|unescapeHTML$},
      qr{^upload_fieldnames|uploadInfo|utf8_chr$}
    ]
  }
);
