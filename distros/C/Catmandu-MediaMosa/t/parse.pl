#!/usr/bin/env perl
use Catmandu::Sane;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Data::Dumper;

local($/) = undef;
my $xml = XML::LibXML->load_xml(IO => \*DATA);
my $xpath = XML::LibXML::XPathContext->new($xml);

print Dumper($xpath->find('/response/header//child::*')->get_nodelist());


__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <header>
    <item_count>2</item_count>
    <item_count_total>2</item_count_total>
    <item_offset>0</item_offset>
    <request_class>mediamosa_rest_call_status</request_class>
    <request_matched_method>GET</request_matched_method>
    <request_matched_uri>/status</request_matched_uri>
    <request_result>success</request_result>
    <request_result_description/>
    <request_result_id>601</request_result_id>
    <request_uri>[GET] status</request_uri>
    <version>3.2.x.1858-dev</version>
    <request_process_time>0.0279</request_process_time>
  </header>
  <items>
    <item>
      <components>
        <title>Components</title>
        <mount_set>
          <failure>FALSE</failure>
        </mount_set>
        <mount_exists>
          <failure>FALSE</failure>
        </mount_exists>
        <mount_media_htaccess>
          <failure>FALSE</failure>
        </mount_media_htaccess>
        <mount_structure>
          <failure>FALSE</failure>
        </mount_structure>
        <mount_writeable>
          <failure>FALSE</failure>
        </mount_writeable>
        <mount_rea_write>
          <failure>FALSE</failure>
        </mount_rea_write>
        <mount_disk_free>
          <failure>FALSE</failure>
        </mount_disk_free>
        <du_simpletest>
          <failure>FALSE</failure>
        </du_simpletest>
        <failure>FALSE</failure>
      </components>
      <time>1365145381</time>
    </item>
    <item>
      <configuration>
        <title>Configuration</title>
        <title>Image tool</title>
        <title>jpg2pdf tool</title>
        <title>Image tool</title>
        <php_modules>
          <failure>FALSE</failure>
        </php_modules>
        <php_max_filesize>
          <failure>FALSE</failure>
        </php_max_filesize>
        <php_memory_limit>
          <failure>FALSE</failure>
        </php_memory_limit>
        <php_post_max>
          <failure>FALSE</failure>
        </php_post_max>
        <php_max_execution_time>
          <failure>FALSE</failure>
        </php_max_execution_time>
        <php_max_input_time>
          <failure>FALSE</failure>
        </php_max_input_time>
        <app_ffmpeg>
          <failure>FALSE</failure>
        </app_ffmpeg>
        <app_lua>
          <failure>FALSE</failure>
        </app_lua>
        <app_lua_run>
          <failure>FALSE</failure>
        </app_lua_run>
        <app_lua_xmod1>
          <failure>FALSE</failure>
        </app_lua_xmod1>
        <app_lua_xmod2>
          <failure>FALSE</failure>
        </app_lua_xmod2>
        <app_lua_lpeg>
          <failure>FALSE</failure>
        </app_lua_lpeg>
        <app_yamdi>
          <failure>FALSE</failure>
        </app_yamdi>
        <app_mp4box>
          <failure>FALSE</failure>
        </app_mp4box>
        <app_lav2yuv>
          <failure>FALSE</failure>
        </app_lav2yuv>
        <web_server>
          <failure>FALSE</failure>
        </web_server>
        <server_download_0>
          <failure>TRUE</failure>
        </server_download_0>
        <apache_mod_rewrite>
          <failure>FALSE</failure>
        </apache_mod_rewrite>
        <drupal_clean_url>
          <failure>FALSE</failure>
        </drupal_clean_url>
        <database_innodb>
          <failure>FALSE</failure>
        </database_innodb>
        <database_innodb_buffer_pool_size>
          <failure>FALSE</failure>
        </database_innodb_buffer_pool_size>
        <database_innodb_log_file_size>
          <failure>FALSE</failure>
        </database_innodb_log_file_size>
        <database_privileges_create_table>
          <failure>FALSE</failure>
        </database_privileges_create_table>
        <database_privileges_alter_table>
          <failure>FALSE</failure>
        </database_privileges_alter_table>
        <database_privileges_select>
          <failure>FALSE</failure>
        </database_privileges_select>
        <database_privileges_insert>
          <failure>FALSE</failure>
        </database_privileges_insert>
        <database_privileges_update>
          <failure>FALSE</failure>
        </database_privileges_update>
        <database_privileges_delete>
          <failure>FALSE</failure>
        </database_privileges_delete>
        <database_privileges_drop_table>
          <failure>FALSE</failure>
        </database_privileges_drop_table>
        <app_imagemagic>
          <failure>FALSE</failure>
        </app_imagemagic>
        <app_exiv2>
          <failure>FALSE</failure>
        </app_exiv2>
        <app_imagemagick>
          <failure>FALSE</failure>
        </app_imagemagick>
        <app_pdf2swf>
          <failure>TRUE</failure>
        </app_pdf2swf>
        <app_pdfinfo>
          <failure>FALSE</failure>
        </app_pdfinfo>
        <failure>TRUE</failure>
      </configuration>
      <time>1365145381</time>
    </item>
  </items>
</response>
