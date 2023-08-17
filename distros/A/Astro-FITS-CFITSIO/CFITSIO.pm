package Astro::FITS::CFITSIO;
$VERSION = '1.18';

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

my @__names_no_short = qw(
			  fits_get_compression_type
			  fits_set_compression_type
                          fits_get_noise_bits
                          fits_set_noise_bits
                          fits_get_tile_dim
                          fits_set_tile_dim
                          fits_translate_keyword
                          fits_translate_keywords
                          fits_copy_cell2image
                          fits_copy_image2cell
                          fits_copy_pixlist2image
                          fits_write_keys_histo
                          fits_rebin_wcs
                          fits_rebin_wcsd
                          fits_make_hist
                          fits_make_histd
                          fits_make_histde
		         );

# perl -nle "next unless /^\s*#define\s+fits_/; (undef,\$l,\$s) = split ' '; print \"\$s => '\$l',\"" /usr/local/cfitsio/longnam.h

my %__names = (
	       ffiurl => 'fits_parse_input_url',
	       ffifile => 'fits_parse_input_filename',
	       ffrtnm => 'fits_parse_rootname',
	       ffrwrg => 'fits_parse_range',
	       ffrwrgll => 'fits_parse_rangell',
	       ffourl => 'fits_parse_output_url',
	       ffexts => 'fits_parse_extspec',
	       ffextn => 'fits_parse_extnum',
	       ffbins => 'fits_parse_binspec',
	       ffbinr => 'fits_parse_binrange',
	       ffdopn => 'fits_open_data',
	       fftopn => 'fits_open_table',
	       ffeopn => 'fits_open_extlist',
	       ffiopn => 'fits_open_image',
	       ffomem => 'fits_open_memfile',
	       ffopen => 'fits_open_file',
	       ffdkopn => 'fits_open_diskfile',
	       ffreopen => 'fits_reopen_file',
	       ffinit => 'fits_create_file',
	       ffdkinit => 'fits_create_diskfile',
	       ffimem => 'fits_create_memfile',
	       fftplt => 'fits_create_template',
	       ffflus => 'fits_flush_file',
	       ffflsh => 'fits_flush_buffer',
	       ffihtps => 'fits_init_https',
	       ffchtps => 'fits_cleanup_https',
	       ffvhtps => 'fits_verbose_https',
	       ffshdwn => 'fits_show_download_progress',
	       ffgtmo => 'fits_get_timeout',
	       ffstmo => 'fits_set_timeout',
	       ffclos => 'fits_close_file',
	       ffdelt => 'fits_delete_file',
	       ffexist => 'fits_file_exists',
	       ffflnm => 'fits_file_name',
	       ffflmd => 'fits_file_mode',
	       ffurlt => 'fits_url_type',
	       ffvers => 'fits_get_version',
	       ffupch => 'fits_uppercase',
	       ffgerr => 'fits_get_errstatus',
	       ffpmsg => 'fits_write_errmsg',
	       ffgmsg => 'fits_read_errmsg',
	       ffcmsg => 'fits_clear_errmsg',
	       ffrprt => 'fits_report_error',
	       ffpmrk => 'fits_write_errmark',
	       ffcmrk => 'fits_clear_errmark',
	       ffcmsg => 'fits_clear_errmsg',
	       ffcmps => 'fits_compare_str',
	       fftkey => 'fits_test_keyword',
	       fftrec => 'fits_test_record',
	       ffnchk => 'fits_null_check',
	       ffkeyn => 'fits_make_keyn',
	       ffnkey => 'fits_make_nkey',
	       ffmkky => 'fits_make_key',
	       ffgkcl => 'fits_get_keyclass',
	       ffdtyp => 'fits_get_keytype',
	       ffpsvc => 'fits_parse_value',
	       ffgknm => 'fits_get_keyname',
	       ffgthd => 'fits_parse_template',
	       ffasfm => 'fits_ascii_tform',
	       ffbnfm => 'fits_binary_tform',
	       ffbnfmll => 'fits_binary_tformll',
	       ffgabc => 'fits_get_tbcol',
	       ffgrsz => 'fits_get_rowsize',
	       ffgcdw => 'fits_get_col_display_width',
	       ffprec => 'fits_write_record',
	       ffpky => 'fits_write_key',
	       ffpunt => 'fits_write_key_unit',
	       ffpcom => 'fits_write_comment',
	       ffphis => 'fits_write_history',
	       ffpdat => 'fits_write_date',
	       ffgstm => 'fits_get_system_time',
	       ffgsdt => 'fits_get_system_date',
	       ffdt2s => 'fits_date2str',
	       fftm2s => 'fits_time2str',
	       ffs2dt => 'fits_str2date',
	       ffs2tm => 'fits_str2time',
	       ffpkls => 'fits_write_key_longstr',
	       ffplsw => 'fits_write_key_longwarn',
	       ffpkyu => 'fits_write_key_null',
	       ffpkys => 'fits_write_key_str',
	       ffpkyl => 'fits_write_key_log',
	       ffpkyj => 'fits_write_key_lng',
	       ffpkyf => 'fits_write_key_fixflt',
	       ffpkye => 'fits_write_key_flt',
	       ffpkyg => 'fits_write_key_fixdbl',
	       ffpkyd => 'fits_write_key_dbl',
	       ffpkfc => 'fits_write_key_fixcmp',
	       ffpkyc => 'fits_write_key_cmp',
	       ffpkfm => 'fits_write_key_fixdblcmp',
	       ffpkym => 'fits_write_key_dblcmp',
	       ffpkyt => 'fits_write_key_triple',
	       ffptdm => 'fits_write_tdim',
	       ffptdmll => 'fits_write_tdimll',
	       ffpkns => 'fits_write_keys_str',
	       ffpknl => 'fits_write_keys_log',
	       ffpknj => 'fits_write_keys_lng',
	       ffpknjj => 'fits_write_keys_lnglng',
	       ffpknf => 'fits_write_keys_fixflt',
	       ffpkne => 'fits_write_keys_flt',
	       ffpkng => 'fits_write_keys_fixdbl',
	       ffpknd => 'fits_write_keys_dbl',
	       ffcpky => 'fits_copy_key',
	       ffphps => 'fits_write_imghdr',
	       ffphpsll => 'fits_write_imghdrll',
	       ffphpr => 'fits_write_grphdr',
	       ffphprll => 'fits_write_grphdrll',
	       ffphtb => 'fits_write_atblhdr',
	       ffphbn => 'fits_write_btblhdr',
	       ffphext => 'fits_write_exthdr',
	       ffpktp => 'fits_write_key_template',
	       ffghsp => 'fits_get_hdrspace',
	       ffghps => 'fits_get_hdrpos',
	       ffmaky => 'fits_movabs_key',
	       ffmrky => 'fits_movrel_key',
	       ffgnxk => 'fits_find_nextkey',
	       ffgrec => 'fits_read_record',
	       ffgcrd => 'fits_read_card',
	       ffgunt => 'fits_read_key_unit',
	       ffgkyn => 'fits_read_keyn',
	       ffgstr => 'fits_read_str',
	       ffgksl => 'fits_read_key_strlen',
	       ffgsky => 'fits_read_string_key',
	       ffdstr => 'fits_delete_str',
	       ffgky => 'fits_read_key',
	       ffgkey => 'fits_read_keyword',
	       ffgkys => 'fits_read_key_str',
	       ffgkyl => 'fits_read_key_log',
	       ffgkyj => 'fits_read_key_lng',
	       ffgkye => 'fits_read_key_flt',
	       ffgkyd => 'fits_read_key_dbl',
	       ffgkyc => 'fits_read_key_cmp',
	       ffgkym => 'fits_read_key_dblcmp',
	       ffgkyt => 'fits_read_key_triple',
	       ffgkcsl => 'fits_get_key_com_strlen',
	       ffgkls => 'fits_read_key_longstr',
	       ffgskyc => 'fits_read_string_key_com',
	       fffree => 'fits_free_memory',
	       ffhdr2str => 'fits_hdr2str',
	       ffcnvthdr2str => 'fits_convert_hdr2str',
	       ffgtdm => 'fits_read_tdim',
	       ffgtdmll => 'fits_read_tdimll',
	       ffdtdm => 'fits_decode_tdim',
	       ffdtdmll => 'fits_decode_tdimll',
	       ffgkns => 'fits_read_keys_str',
	       ffgknl => 'fits_read_keys_log',
	       ffgknj => 'fits_read_keys_lng',
	       ffgknjj => 'fits_read_keys_lnglng',
	       ffgkne => 'fits_read_keys_flt',
	       ffgknd => 'fits_read_keys_dbl',
	       ffghpr => 'fits_read_imghdr',
	       ffghprll => 'fits_read_imghdrll',
	       ffghtb => 'fits_read_atblhdr',
	       ffghtbll => 'fits_read_atblhdrll',
	       ffghbn => 'fits_read_btblhdr',
	       ffghbnll => 'fits_read_btblhdrll',
	       ffh2st => 'fits_header2str',
	       ffucrd => 'fits_update_card',
	       ffuky => 'fits_update_key',
	       ffukyu => 'fits_update_key_null',
	       ffukys => 'fits_update_key_str',
	       ffukls => 'fits_update_key_longstr',
	       ffukyl => 'fits_update_key_log',
	       ffukyj => 'fits_update_key_lng',
	       ffukyf => 'fits_update_key_fixflt',
	       ffukye => 'fits_update_key_flt',
	       ffukyg => 'fits_update_key_fixdbl',
	       ffukyd => 'fits_update_key_dbl',
	       ffukfc => 'fits_update_key_fixcmp',
	       ffukyc => 'fits_update_key_cmp',
	       ffukfm => 'fits_update_key_fixdblcmp',
	       ffukym => 'fits_update_key_dblcmp',
	       ffmrec => 'fits_modify_record',
	       ffmcrd => 'fits_modify_card',
	       ffmnam => 'fits_modify_name',
	       ffmcom => 'fits_modify_comment',
	       ffmkyu => 'fits_modify_key_null',
	       ffmkys => 'fits_modify_key_str',
	       ffmkls => 'fits_modify_key_longstr',
	       ffmkyl => 'fits_modify_key_log',
	       ffmkyj => 'fits_modify_key_lng',
	       ffmkyf => 'fits_modify_key_fixflt',
	       ffmkye => 'fits_modify_key_flt',
	       ffmkyg => 'fits_modify_key_fixdbl',
	       ffmkyd => 'fits_modify_key_dbl',
	       ffmkfc => 'fits_modify_key_fixcmp',
	       ffmkyc => 'fits_modify_key_cmp',
	       ffmkfm => 'fits_modify_key_fixdblcmp',
	       ffmkym => 'fits_modify_key_dblcmp',
	       ffikey => 'fits_insert_card',
	       ffirec => 'fits_insert_record',
	       ffikyu => 'fits_insert_key_null',
	       ffikys => 'fits_insert_key_str',
	       ffikls => 'fits_insert_key_longstr',
	       ffikyl => 'fits_insert_key_log',
	       ffikyj => 'fits_insert_key_lng',
	       ffikyf => 'fits_insert_key_fixflt',
	       ffikye => 'fits_insert_key_flt',
	       ffikyg => 'fits_insert_key_fixdbl',
	       ffikyd => 'fits_insert_key_dbl',
	       ffikfc => 'fits_insert_key_fixcmp',
	       ffikyc => 'fits_insert_key_cmp',
	       ffikfm => 'fits_insert_key_fixdblcmp',
	       ffikym => 'fits_insert_key_dblcmp',
	       ffdkey => 'fits_delete_key',
	       ffdrec => 'fits_delete_record',
	       ffghdn => 'fits_get_hdu_num',
	       ffghdt => 'fits_get_hdu_type',
	       ffghad => 'fits_get_hduaddr',
	       ffghadll => 'fits_get_hduaddrll',
	       ffghof => 'fits_get_hduoff',
	       ffgipr => 'fits_get_img_param',
	       ffgiprll => 'fits_get_img_paramll',
	       ffgidt => 'fits_get_img_type',
	       ffinttyp => 'fits_get_inttype',
	       ffgiet => 'fits_get_img_equivtype',
	       ffgidm => 'fits_get_img_dim',
	       ffgisz => 'fits_get_img_size',
	       ffgiszll => 'fits_get_img_sizell',
	       ffmahd => 'fits_movabs_hdu',
	       ffmrhd => 'fits_movrel_hdu',
	       ffmnhd => 'fits_movnam_hdu',
	       ffthdu => 'fits_get_num_hdus',
	       ffcrim => 'fits_create_img',
	       ffcrimll => 'fits_create_imgll',
	       ffcrtb => 'fits_create_tbl',
	       ffcpht => 'fits_copy_hdutab',
	       ffcrhd => 'fits_create_hdu',
	       ffiimg => 'fits_insert_img',
	       ffiimgll => 'fits_insert_imgll',
	       ffitab => 'fits_insert_atbl',
	       ffibin => 'fits_insert_btbl',
	       ffrsim => 'fits_resize_img',
	       ffrsimll => 'fits_resize_imgll',
	       ffdhdu => 'fits_delete_hdu',
	       ffcpfl => 'fits_copy_file',
	       ffcopy => 'fits_copy_hdu',
	       ffcphd => 'fits_copy_header',
	       ffcpdt => 'fits_copy_data',
	       ffwrhdu => 'fits_write_hdu',
	       ffrdef => 'fits_set_hdustruc',
	       ffhdef => 'fits_set_hdrsize',
	       ffpthp => 'fits_write_theap',
	       ffesum => 'fits_encode_chksum',
	       ffdsum => 'fits_decode_chksum',
	       ffpcks => 'fits_write_chksum',
	       ffupck => 'fits_update_chksum',
	       ffvcks => 'fits_verify_chksum',
	       ffgcks => 'fits_get_chksum',
	       ffpscl => 'fits_set_bscale',
	       fftscl => 'fits_set_tscale',
	       ffpnul => 'fits_set_imgnull',
	       fftnul => 'fits_set_btblnull',
	       ffsnul => 'fits_set_atblnull',
	       ffgcno => 'fits_get_colnum',
	       ffgcnn => 'fits_get_colname',
	       ffgtcl => 'fits_get_coltype',
	       ffgtclll => 'fits_get_coltypell',
	       ffeqty => 'fits_get_eqcoltype',
	       ffeqtyll => 'fits_get_eqcoltypell',
	       ffgnrw => 'fits_get_num_rows',
	       ffgnrwll => 'fits_get_num_rowsll',
	       ffgncl => 'fits_get_num_cols',
	       ffgacl => 'fits_get_acolparms',
	       ffgbcl => 'fits_get_bcolparms',
	       ffgbclll => 'fits_get_bcolparmsll',
	       ffiter => 'fits_iterate_data',
	       ffggpb => 'fits_read_grppar_byt',
	       ffggpb => 'fits_read_grppar_sbyt',
	       ffggpui => 'fits_read_grppar_usht',
	       ffggpuj => 'fits_read_grppar_ulng',
	       ffggpi => 'fits_read_grppar_sht',
	       ffggpj => 'fits_read_grppar_lng',
	       ffggpjj => 'fits_read_grppar_lnglng',
	       ffggpk => 'fits_read_grppar_int',
	       ffggpuk => 'fits_read_grppar_uint',
	       ffggpe => 'fits_read_grppar_flt',
	       ffggpd => 'fits_read_grppar_dbl',
	       ffgpxv => 'fits_read_pix',
	       ffgpxvll => 'fits_read_pixll',
	       ffgpxf => 'fits_read_pixnull',
	       ffgpxfll => 'fits_read_pixnullll',
	       ffgpv => 'fits_read_img',
	       ffgpf => 'fits_read_imgnull',
	       ffgpvb => 'fits_read_img_byt',
	       ffgpvsb => 'fits_read_img_sbyt',
	       ffgpvui => 'fits_read_img_usht',
	       ffgpvuj => 'fits_read_img_ulng',
	       ffgpvi => 'fits_read_img_sht',
	       ffgpvj => 'fits_read_img_lng',
	       ffgpvjj => 'fits_read_img_lnglng',
	       ffgpvuk => 'fits_read_img_uint',
	       ffgpvk => 'fits_read_img_int',
	       ffgpve => 'fits_read_img_flt',
	       ffgpvd => 'fits_read_img_dbl',
	       ffgpfb => 'fits_read_imgnull_byt',
	       ffgpfsb => 'fits_read_imgnull_sbyt',
	       ffgpfui => 'fits_read_imgnull_usht',
	       ffgpfuj => 'fits_read_imgnull_ulng',
	       ffgpfi => 'fits_read_imgnull_sht',
	       ffgpfj => 'fits_read_imgnull_lng',
	       ffgpfjj => 'fits_read_imgnull_lnglng',
	       ffgpfuk => 'fits_read_imgnull_uint',
	       ffgpfk => 'fits_read_imgnull_int',
	       ffgpfe => 'fits_read_imgnull_flt',
	       ffgpfd => 'fits_read_imgnull_dbl',
	       ffg2db => 'fits_read_2d_byt',
	       ffg2dsb => 'fits_read_2d_sbyt',
	       ffg2dui => 'fits_read_2d_usht',
	       ffg2duj => 'fits_read_2d_ulng',
	       ffg2di => 'fits_read_2d_sht',
	       ffg2dj => 'fits_read_2d_lng',
	       ffg2djj => 'fits_read_2d_lnglng',
	       ffg2duk => 'fits_read_2d_uint',
	       ffg2dk => 'fits_read_2d_int',
	       ffg2de => 'fits_read_2d_flt',
	       ffg2dd => 'fits_read_2d_dbl',
	       ffg3db => 'fits_read_3d_byt',
	       ffg3dsb => 'fits_read_3d_sbyt',
	       ffg3dui => 'fits_read_3d_usht',
	       ffg3duj => 'fits_read_3d_ulng',
	       ffg3di => 'fits_read_3d_sht',
	       ffg3dj => 'fits_read_3d_lng',
	       ffg3dj => 'fits_read_3d_lnglng',
	       ffg3duk => 'fits_read_3d_uint',
	       ffg3dk => 'fits_read_3d_int',
	       ffg3de => 'fits_read_3d_flt',
	       ffg3dd => 'fits_read_3d_dbl',
	       ffgsv => 'fits_read_subset',
	       ffgsvb => 'fits_read_subset_byt',
	       ffgsvsb => 'fits_read_subset_sbyt',
	       ffgsvui => 'fits_read_subset_usht',
	       ffgsvuj => 'fits_read_subset_ulng',
	       ffgsvi => 'fits_read_subset_sht',
	       ffgsvj => 'fits_read_subset_lng',
	       ffgsvjj => 'fits_read_subset_lnglng',
	       ffgsvuk => 'fits_read_subset_uint',
	       ffgsvk => 'fits_read_subset_int',
	       ffgsve => 'fits_read_subset_flt',
	       ffgsvd => 'fits_read_subset_dbl',
	       ffgsfb => 'fits_read_subsetnull_byt',
	       ffgsfsb => 'fits_read_subsetnull_sbyt',
	       ffgsfui => 'fits_read_subsetnull_usht',
	       ffgsfuj => 'fits_read_subsetnull_ulng',
	       ffgsfi => 'fits_read_subsetnull_sht',
	       ffgsfj => 'fits_read_subsetnull_lng',
	       ffgsfjj => 'fits_read_subsetnull_lnglng',
	       ffgsfuk => 'fits_read_subsetnull_uint',
	       ffgsfk => 'fits_read_subsetnull_int',
	       ffgsfe => 'fits_read_subsetnull_flt',
	       ffgsfd => 'fits_read_subsetnull_dbl',
	       fits_decomp_img => 'fits_decompress_img',
	       ffgcv => 'fits_read_col',
	       ffgcf => 'fits_read_colnull',
	       ffgcvs => 'fits_read_col_str',
	       ffgcvl => 'fits_read_col_log',
	       ffgcvb => 'fits_read_col_byt',
	       ffgcvsb => 'fits_read_col_sbyt',
	       ffgcvui => 'fits_read_col_usht',
	       ffgcvuj => 'fits_read_col_ulng',
	       ffgcvi => 'fits_read_col_sht',
	       ffgcvj => 'fits_read_col_lng',
	       ffgcvjj => 'fits_read_col_lnglng',
	       ffgcvuk => 'fits_read_col_uint',
	       ffgcvk => 'fits_read_col_int',
	       ffgcve => 'fits_read_col_flt',
	       ffgcvd => 'fits_read_col_dbl',
	       ffgcvc => 'fits_read_col_cmp',
	       ffgcvm => 'fits_read_col_dblcmp',
	       ffgcx => 'fits_read_col_bit',
	       ffgcxui => 'fits_read_col_bit_usht',
	       ffgcxuk => 'fits_read_col_bit_uint',
	       ffgcfs => 'fits_read_colnull_str',
	       ffgcfl => 'fits_read_colnull_log',
	       ffgcfb => 'fits_read_colnull_byt',
	       ffgcfsb => 'fits_read_colnull_sbyt',
	       ffgcfui => 'fits_read_colnull_usht',
	       ffgcfuj => 'fits_read_colnull_ulng',
	       ffgcfi => 'fits_read_colnull_sht',
	       ffgcfj => 'fits_read_colnull_lng',
	       ffgcfjj => 'fits_read_colnull_lnglng',
	       ffgcfuk => 'fits_read_colnull_uint',
	       ffgcfk => 'fits_read_colnull_int',
	       ffgcfe => 'fits_read_colnull_flt',
	       ffgcfd => 'fits_read_colnull_dbl',
	       ffgcfc => 'fits_read_colnull_cmp',
	       ffgcfm => 'fits_read_colnull_dblcmp',
	       ffgdes => 'fits_read_descript',
	       ffgdesll => 'fits_read_descriptll',
	       ffgdess => 'fits_read_descripts',
	       ffgdessll => 'fits_read_descriptsll',
	       ffgtbb => 'fits_read_tblbytes',
	       ffpgpb => 'fits_write_grppar_byt',
	       ffpgpsb => 'fits_write_grppar_sbyt',
	       ffpgpui => 'fits_write_grppar_usht',
	       ffpgpuj => 'fits_write_grppar_ulng',
	       ffpgpi => 'fits_write_grppar_sht',
	       ffpgpj => 'fits_write_grppar_lng',
	       ffpgpjj => 'fits_write_grppar_lngj',
	       ffpgpuk => 'fits_write_grppar_uint',
	       ffpgpk => 'fits_write_grppar_int',
	       ffpgpe => 'fits_write_grppar_flt',
	       ffpgpd => 'fits_write_grppar_dbl',
	       ffppx => 'fits_write_pix',
	       ffppxll => 'fits_write_pixll',
	       ffppxn => 'fits_write_pixnull',
	       ffppxnll => 'fits_write_pixnullll',
	       ffppr => 'fits_write_img',
	       ffpprb => 'fits_write_img_byt',
	       ffpprsb => 'fits_write_img_sbyt',
	       ffpprui => 'fits_write_img_usht',
	       ffppruj => 'fits_write_img_ulng',
	       ffppri => 'fits_write_img_sht',
	       ffpprj => 'fits_write_img_lng',
	       ffpprjj => 'fits_write_img_lnglng',
	       ffppruk => 'fits_write_img_uint',
	       ffpprk => 'fits_write_img_int',
	       ffppre => 'fits_write_img_flt',
	       ffpprd => 'fits_write_img_dbl',
	       ffppn => 'fits_write_imgnull',
	       ffppnb => 'fits_write_imgnull_byt',
	       ffppnsb => 'fits_write_imgnull_sbyt',
	       ffppnui => 'fits_write_imgnull_usht',
	       ffppnuj => 'fits_write_imgnull_ulng',
	       ffppni => 'fits_write_imgnull_sht',
	       ffppnj => 'fits_write_imgnull_lng',
	       ffppnjj => 'fits_write_imgnull_lnglng',
	       ffppnuk => 'fits_write_imgnull_uint',
	       ffppnk => 'fits_write_imgnull_int',
	       ffppne => 'fits_write_imgnull_flt',
	       ffppnd => 'fits_write_imgnull_dbl',
	       ffppru => 'fits_write_img_null',
	       ffpprn => 'fits_write_null_img',
	       ffp2db => 'fits_write_2d_byt',
	       ffp2dsb => 'fits_write_2d_sbyt',
	       ffp2dui => 'fits_write_2d_usht',
	       ffp2duj => 'fits_write_2d_ulng',
	       ffp2di => 'fits_write_2d_sht',
	       ffp2dj => 'fits_write_2d_lng',
	       ffp2djj => 'fits_write_2d_lnglng',
	       ffp2duk => 'fits_write_2d_uint',
	       ffp2dk => 'fits_write_2d_int',
	       ffp2de => 'fits_write_2d_flt',
	       ffp2dd => 'fits_write_2d_dbl',
	       ffp3db => 'fits_write_3d_byt',
	       ffp3dsb => 'fits_write_3d_sbyt',
	       ffp3dui => 'fits_write_3d_usht',
	       ffp3duj => 'fits_write_3d_ulng',
	       ffp3di => 'fits_write_3d_sht',
	       ffp3dj => 'fits_write_3d_lng',
	       ffp3djj => 'fits_write_3d_lnglng',
	       ffp3duk => 'fits_write_3d_uint',
	       ffp3dk => 'fits_write_3d_int',
	       ffp3de => 'fits_write_3d_flt',
	       ffp3dd => 'fits_write_3d_dbl',
	       ffpss => 'fits_write_subset',
	       ffpssb => 'fits_write_subset_byt',
	       ffpsssb => 'fits_write_subset_sbyt',
	       ffpssui => 'fits_write_subset_usht',
	       ffpssuj => 'fits_write_subset_ulng',
	       ffpssi => 'fits_write_subset_sht',
	       ffpssj => 'fits_write_subset_lng',
	       ffpssjj => 'fits_write_subset_lnglng',
	       ffpssuk => 'fits_write_subset_uint',
	       ffpssk => 'fits_write_subset_int',
	       ffpsse => 'fits_write_subset_flt',
	       ffpssd => 'fits_write_subset_dbl',
	       ffprwu => 'fits_write_nullrows',
	       ffpcl => 'fits_write_col',
	       ffpcls => 'fits_write_col_str',
	       ffpcll => 'fits_write_col_log',
	       ffpclb => 'fits_write_col_byt',
	       ffpclsb => 'fits_write_col_sbyt',
	       ffpclui => 'fits_write_col_usht',
	       ffpcluj => 'fits_write_col_ulng',
	       ffpcli => 'fits_write_col_sht',
	       ffpclj => 'fits_write_col_lng',
	       ffpcljj => 'fits_write_col_lnglng',
	       ffpcluk => 'fits_write_col_uint',
	       ffpclk => 'fits_write_col_int',
	       ffpcle => 'fits_write_col_flt',
	       ffpcld => 'fits_write_col_dbl',
	       ffpclc => 'fits_write_col_cmp',
	       ffpclm => 'fits_write_col_dblcmp',
	       ffpclu => 'fits_write_col_null',
	       ffpclx => 'fits_write_col_bit',
	       ffpcn => 'fits_write_colnull',
	       ffpcns => 'fits_write_colnull_str',
	       ffpcnl => 'fits_write_colnull_log',
	       ffpcnb => 'fits_write_colnull_byt',
	       ffpcnsb => 'fits_write_colnull_sbyt',
	       ffpcnui => 'fits_write_colnull_usht',
	       ffpcnuj => 'fits_write_colnull_ulng',
	       ffpcni => 'fits_write_colnull_sht',
	       ffpcnj => 'fits_write_colnull_lng',
	       ffpcnjj => 'fits_write_colnull_lnglng',
	       ffpcnuk => 'fits_write_colnull_uint',
	       ffpcnk => 'fits_write_colnull_int',
	       ffpcne => 'fits_write_colnull_flt',
	       ffpcnd => 'fits_write_colnull_dbl',
	       ffpdes => 'fits_write_descript',
	       ffcmph => 'fits_compress_heap',
	       fftheap => 'fits_test_heap',
	       ffptbb => 'fits_write_tblbytes',
	       ffirow => 'fits_insert_rows',
	       ffdrrg => 'fits_delete_rowrange',
	       ffdrow => 'fits_delete_rows',
	       ffdrws => 'fits_delete_rowlist',
	       ffdrwsll => 'fits_delete_rowlistll',
	       fficol => 'fits_insert_col',
	       fficls => 'fits_insert_cols',
	       ffdcol => 'fits_delete_col',
	       ffcpcl => 'fits_copy_col',
	       ffccls => 'fits_copy_cols',
	       ffcprw => 'fits_copy_rows',
	       ffcpsr => 'fits_copy_selrows',
	       ffmvec => 'fits_modify_vector_len',
	       ffgics => 'fits_read_img_coord',
	       ffgtcs => 'fits_read_tbl_coord',
	       ffgicsa => 'fits_read_img_coord_version',
	       ffwldp => 'fits_pix_to_world',
	       ffxypx => 'fits_world_to_pix',
	       ffgiwcs => 'fits_get_image_wcs_keys',
	       ffgtwcs => 'fits_get_table_wcs_keys',
	       fffrow => 'fits_find_rows',
	       ffffrw => 'fits_find_first_row',
	       fffrwc => 'fits_find_rows_cmp',
	       ffsrow => 'fits_select_rows',
	       ffcrow => 'fits_calc_rows',
	       ffcalc => 'fits_calculator',
	       ffcalc_rng => 'fits_calculator_rng',
	       fftexp => 'fits_test_expr',
	       ffgtcr => 'fits_create_group',
	       ffgtis => 'fits_insert_group',
	       ffgtch => 'fits_change_group',
	       ffgtrm => 'fits_remove_group',
	       ffgtcp => 'fits_copy_group',
	       ffgtmg => 'fits_merge_groups',
	       ffmbyt => 'fits_seek',
	       ffgtcm => 'fits_compact_group',
	       ffgtvf => 'fits_verify_group',
	       ffgtop => 'fits_open_group',
	       ffgtam => 'fits_add_group_member',
	       ffgtnm => 'fits_get_num_members',
	       ffgmng => 'fits_get_num_groups',
	       ffgmop => 'fits_open_member',
	       ffgmcp => 'fits_copy_member',
	       ffgmtf => 'fits_transfer_member',
	       ffgmrm => 'fits_remove_member',
	       );

my @__shortnames = keys %__names;
my @__longnames = (values(%__names), @__names_no_short);
my @__constants = qw(
		     ANGLE_TOO_BIG
		     ANY_HDU
		     ARRAY_TOO_BIG
		     ASCII_TBL
		     BAD_ATABLE_FORMAT
		     BAD_BITPIX
		     BAD_BTABLE_FORMAT
		     BAD_C2D
		     BAD_C2F
		     BAD_C2I
		     BAD_COL_NUM
		     BAD_DATATYPE
		     BAD_DATA_FILL
		     BAD_DATE
		     BAD_DECIM
		     BAD_DIMEN
		     BAD_DOUBLEKEY
		     BAD_ELEM_NUM
		     BAD_F2C
		     BAD_FILEPTR
		     BAD_FLOATKEY
		     BAD_GCOUNT
		     BAD_GROUP_ID
		     BAD_HDU_NUM
		     BAD_HEADER_FILL
		     BAD_I2C
		     BAD_INTKEY
		     BAD_KEYCHAR
		     BAD_LOGICALKEY
		     BAD_NAXES
		     BAD_NAXIS
		     BAD_OPTION
		     BAD_ORDER
		     BAD_PCOUNT
		     BAD_PIX_NUM
		     BAD_ROW_NUM
		     BAD_ROW_WIDTH
		     BAD_SIMPLE
		     BAD_TBCOL
		     BAD_TDIM
		     BAD_TFIELDS
		     BAD_TFORM
		     BAD_TFORM_DTYPE
		     BAD_URL_PREFIX
		     BAD_WCS_PROJ
		     BAD_WCS_VAL
		     BINARY_TBL
		     BYTE_IMG
		     CASEINSEN
		     CASESEN
		     CFITSIO_MAJOR
		     CFITSIO_MINOR
		     COL_NOT_FOUND
		     COL_NOT_UNIQUE
		     COL_TOO_WIDE
		     DOUBLENULLVALUE
		     DOUBLE_IMG
		     DRIVER_INIT_FAILED
		     END_JUNK
		     END_OF_FILE
		     FALSE
		     FILE_NOT_CLOSED
		     FILE_NOT_CREATED
		     FILE_NOT_OPENED
		     FLEN_CARD
		     FLEN_COMMENT
		     FLEN_ERRMSG
		     FLEN_FILENAME
		     FLEN_KEYWORD
		     FLEN_STATUS
		     FLEN_VALUE
		     FLOATNULLVALUE
		     FLOAT_IMG
		     GROUP_NOT_FOUND
		     GT_ID_ALL
		     GT_ID_ALL_URI
		     GT_ID_POS
		     GT_ID_POS_URI
		     GT_ID_REF
		     GT_ID_REF_URI
		     GZIP_1
		     HDU_ALREADY_MEMBER
		     HDU_ALREADY_TRACKED
		     HEADER_NOT_EMPTY
		     IDENTICAL_POINTERS
		     IMAGE_HDU
		     InputCol
		     InputOutputCol
		     KEY_NO_EXIST
		     KEY_OUT_BOUNDS
		     LONG_IMG
		     LONGLONG_IMG
		     MAXHDU
		     MEMBER_NOT_FOUND
		     MEMORY_ALLOCATION
		     NEG_AXIS
		     NEG_BYTES
		     NEG_FILE_POS
		     NEG_ROWS
		     NEG_WIDTH
		     NOT_ASCII_COL
		     NOT_ATABLE
		     NOT_BTABLE
		     NOT_GROUP_TABLE
		     NOT_IMAGE
		     NOT_LOGICAL_COL
		     NOT_POS_INT
		     NOT_TABLE
		     NOT_VARI_LEN
		     NO_BITPIX
		     NO_END
		     NO_GCOUNT
		     NO_MATCHING_DRIVER
		     NO_NAXES
		     NO_NAXIS
		     NO_NULL
		     NO_PCOUNT
		     NO_QUOTE
		     NO_SIMPLE
		     NO_TBCOL
		     NO_TFIELDS
		     NO_TFORM
		     NO_WCS_KEY
		     NO_XTENSION
		     NULL_INPUT_PTR
		     NUM_OVERFLOW
		     OPT_CMT_MBR
		     OPT_CMT_MBR_DEL
		     OPT_GCP_ALL
		     OPT_GCP_GPT
		     OPT_GCP_MBR
		     OPT_MCP_ADD
		     OPT_MCP_MOV
		     OPT_MCP_NADD
		     OPT_MCP_REPL
		     OPT_MRG_COPY
		     OPT_MRG_MOV
		     OPT_RM_ALL
		     OPT_RM_ENTRY
		     OPT_RM_GPT
		     OPT_RM_MBR
		     OVERFLOW_ERR
		     OutputCol
		     PARSE_BAD_COL
		     PARSE_BAD_OUTPUT
		     PARSE_BAD_TYPE
		     PARSE_LRG_VECTOR
		     PARSE_NO_OUTPUT
		     PARSE_SYNTAX_ERR
		     PLIO_1
		     READONLY
		     READONLY_FILE
		     READWRITE
		     READ_ERROR
		     RICE_1
		     SAME_FILE
		     SEEK_ERROR
		     SHORT_IMG
		     TBIT
		     TBYTE
		     TSBYTE
		     TCOMPLEX
		     TDBLCOMPLEX
		     TDOUBLE
		     TFLOAT
		     TINT
		     TLOGICAL
		     TLONG
		     TLONGLONG
		     TOO_MANY_DRIVERS
		     TOO_MANY_FILES
		     TOO_MANY_HDUS_TRACKED
		     TRUE
		     TSHORT
		     TSTRING
		     TUINT
		     TULONG
		     TUSHORT
		     ULONG_IMG
		     UNKNOWN_EXT
		     UNKNOWN_REC
		     URL_PARSE_ERROR
		     USE_MEM_BUFF
		     USHORT_IMG
		     VALIDSTRUC
		     VALUE_UNDEFINED
		     WCS_ERROR
		     WRITE_ERROR
		     ZERO_SCALE
		     TYP_STRUC_KEY
		     TYP_CMPRS_KEY
		     TYP_SCAL_KEY
		     TYP_NULL_KEY
		     TYP_DIM_KEY
		     TYP_RANG_KEY
		     TYP_UNIT_KEY
		     TYP_DISP_KEY
		     TYP_HDUID_KEY
		     TYP_CKSUM_KEY
		     TYP_WCS_KEY
		     TYP_REFSYS_KEY
		     TYP_COMM_KEY
		     TYP_CONT_KEY
		     TYP_USER_KEY
		     ); ### @__constants

@EXPORT = qw( );

%EXPORT_TAGS = ( 
		 'shortnames' => \@__shortnames,
		 'longnames' => \@__longnames,
		 'constants' => \@__constants,
		 );

@EXPORT_OK = (
	      'PerlyUnpacking',
	      @__shortnames,
	      @__longnames,
	      @__constants,
	      );

sub AUTOLOAD {
    no strict;

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Astro::FITS::CFITSIO macro $constname";
	}
    }
    *$AUTOLOAD = sub { $val };
	#eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Astro::FITS::CFITSIO $VERSION;

# Preloaded methods go here.

# Compound routines -- useful routines that combine lower level
# Astro::FITS::CFITSIO commands
# This routine takes an argument (either a fitsfilePtr object
# or a string containing a FITS file name) and returns the header
# into a hash along with the exit status of the routine.
# If it is called in a scalar context then only the hash reference
# is returned

#  $hashref = fits_read_header("test.fits");
#  ($hashref, $status) = $fitsfile->read_header;

# The comments are stored in a hash in $hashref->{COMMENTS}.

sub fits_read_header {

  croak 'Usage: fits_read_header(file|fitsfilePtr)'
    unless @_;

  my ($fitsfile, $status);
  my ($n, $left, %header, $key, $value, $comment);

  # Read the argument
  my $file = shift;

  my $obj_passed = 0; # were we passed a fitsfilePtr?

  $status = 0;
  if (UNIVERSAL::isa($file,'fitsfilePtr')) {
    $fitsfile = $file;
    $obj_passed = 1;
  } else {
    # Open the file.
    fits_open_file($fitsfile, $file, READONLY(), $status);
  }

  # Now we have an open file -- check that status is good before
  # proceeding
  unless ($status) {

    # Get the number of fits keywords in primary header
    $fitsfile->get_hdrspace($n, $left, $status);

    # Loop over the keys
    for my $i (1..$n) {
      last unless $status == 0;

      $fitsfile->read_keyn($i, $key, $value, $comment, $status);

      # Store the key/value in a hash
      $header{$key} = $value;

      # Store the comments.
      if (! exists $header{COMMENTS}{$key}) {
	  $header{COMMENTS}{$key} = $comment;
      }
      # HISTORY keywords, for instance, can be numerous
      else {
	  if (! ref $header{COMMENTS}{$key}) {
	      $header{COMMENTS}{$key} = [ $header{COMMENTS}{$key} ];
	  }
	  push @{$header{COMMENTS}{$key}}, $comment;
      }

    }

    # Close the file if we opened it
    $fitsfile->close_file($status) unless $obj_passed;
  }

  # Report an error - may not always want to write to STDERR...
  fits_report_error(*STDERR, $status);


  return (\%header, $status) if wantarray;
  return \%header;

}

# This section provides perl aliases for the OO interface
# This is a bit of a kluge since the actual command is in the
# Astro::FITS::CFITSIO namespace. Did not open a new namespace with the package
# command since AUTOSPLIT gets confused

sub fitsfilePtr::read_header {
  my $self = shift;
  my ($href, $status) = Astro::FITS::CFITSIO::fits_read_header($self);
  return ($href, $status) if wantarray;
  return $href;
}


  
# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

Astro::FITS::CFITSIO - Perl extension for using the cfitsio library

=head1 SYNOPSIS

  use Astro::FITS::CFITSIO;
  use Astro::FITS::CFITSIO qw( :longnames );
  use Astro::FITS::CFITSIO qw( :shortnames );
  use Astro::FITS::CFITSIO qw( :constants );

=head1 DESCRIPTION

Perl interface to William Pence's cfitsio subroutine library. For more
information on cfitsio, see
http://heasarc.gsfc.nasa.gov/fitsio.

This module attempts to provide a wrapper for nearly every cfitsio routine,
while retaining as much cfitsio behavior as possible. As such, one should
be aware that it is still somewhat low-level, in the sense that handing an
array which is not the correct size to a routine like C<fits_write_img()>
may cause SIGSEGVs.

My goal is to eventually use these routines to build a more Perl-like
interface to many common tasks such as reading and writing of images and
ASCII and binary tables.

=head1 cfitsio API MAPPING

Astro::FITS::CFITSIO allows one to use either the long or short name forms of the
cfitsio routines. These work by using the exact same form of arguments
as one would find in an equivalent C program.

There is also an object-oriented API which uses the same function names
as the long-name API, but with the leading "fits_" stripped. To get
a Astro::FITS::CFITSIO "object" one would call C<open_file()>, C<create_file()> or
C<create_template()>:

    my $status = 0;
    my $fptr = Astro::FITS::CFITSIO::open_file($filename,
                        Astro::FITS::CFITSIO::READONLY(),$status);

    $fptr->read_key_str('NAXIS1',$naxis1,undef,$status);

Note that the object-oriented forms of function names are only available for
those cfitsio routines which accept a C<fitsfile*> data-type as the first
argument.

As an added benefit, whenever a filehandle goes out of scope, B<ffclos()>
is automatically closed:

    {
      my $fptr = Astro::FITS::CFITSIO::open_file($filename,
                        Astro::FITS::CFITSIO::READWRITE(),$status);
      [manipulate $fptr]

      # neither of the following are needed
      # ffclos($fptr,$status);
      # $fptr->close_file($status);
    }

It there is an error, it will B<croak()>.


=head1 NAME SPACE

All cfitsio routines, with the exception of C<fits_iterate_data()> and
C<fits_open_memfile()>, are available in both long and short name
forms (e.g., C<fits_read_key> E<lt>=E<gt> C<ffgky>), as well as all
constants defined in the F<fitsio.h> header file. This raises the
possibility of your name space being invaded by nearly 1000 function
and constant names.

To deal with this situation, Astro::FITS::CFITSIO makes use of the Exporter
package support for C<%EXPORT_TAGS>. You can import the long-named functions
with

    use Astro::FITS::CFITSIO qw( :longnames );

and the short-named routines with

    use Astro::FITS::CFITSIO qw( :shortnames );

Constants are actually implemented as AUTOLOADed functions, so C<TSTRING>, for
instance, would be accessed via C<Astro::FITS::CFITSIO::TSTRING()>. Alternatively
you can

    use Astro::FITS::CFITSIO qw( :constants );

which would allow you to simply say C<TSTRING>.

=head1 DATA STORAGE DETAILS

=head2 Input Variables

If a routine expects an N-dimensional array as input, and you hand it a
reference to a scalar, then Astro::FITS::CFITSIO simply uses the data in the scalar
which the argument is referencing.
Otherwise it expects the argument to be a Perl array reference whose total
number of elements satisfies the input demands of the corresponding
C routine. Astro::FITS::CFITSIO then unpacks the array reference into a format that
the C routine can understand. If your input array does not hold enough
data for the C routine then a segfault is likely to occur.

cfitsio functions which take an optional NULL pointer - indicating no output
in that place is desired - can instead be given an C<undef>. In other words,
the following C and Perl statements which read a keyword but ignore the
comment would be roughly equivalent:

    fits_read_key_lng(fptr,key,&value,NULL,&status);

    fits_read_key_lng($fptr,$key,$value,undef,$status);

=head2 Output Variables

Calling cfitsio routines which read data from FITS files causes the
output variable to be transformed into a Perl array of the appropriate
dimensions.  The exception to this is if one wants the output to be in
the machine-native format (e.g., for use with PDL).
Then all output variables will become scalars containing the
appropriate data. The exception here is with routines which read
arrays of strings (e.g., C<fits_read_col_str()>).  In this case the
output is again a Perl array reference.

There are two ways to specify how data are retrieved.  The behavior
can be specified either globally or on a per filehandle basis.  The
global selection is done by calling the B<PerlyUnpacking> function.
This sets the behavior for I<all> file handles which do not
I<explicitly> choose not to follow it.

  # turn ON unpacking into Perl arrays.  This is the default
  PerlyUnpacking(1);

  # turn OFF unpacking into Perl arrays, i.e. put in machine-native
  # format
  PerlyUnpacking(0);

  # retrieve the current state:
  $state = PerlyUnpacking();

To change the behavior for a particular file handle, use the
B<perlyunpacking> method.  The default behavior for a file handle
is to track what is done with B<PerlyUnpacking()>

  # track PerlyUnpacking().  This is the default
  $fptr->perlyunpacking(-1);

  # turn ON unpacking into Perl arrays
  $fptr->perlyunpacking(1);

  # turn OFF unpacking into Perl arrays
  $fptr->perlyunpacking(0);

  # retrieve the current state:
  $state = $fptr->perlyunpacking;


=head1 EXAMPLES

Take a look at F<testprog/testprog.pl> under the distribution directory. It
should
produce output identical to F<testprog.c> which comes with the cfitsio
library. Additionally, the
versions named F<testprog_longnames.pl>, F<testprog_OO.pl>  and
F<testprog_pdl.pl> test the long-name and object-oriented APIs,
and machine-native unpacking with PDL.

There is also an F<examples/> directory with scripts which do
the following:

=over 4

=item F<image_read.pl>

reads a FITS primary image and displays it using PGPLOT

=item F<image_read_pdl.pl>

same as above, but uses machine-native unpacking with PDL

=item F<bintable_read_pdl.pl>

reads binary table column into PDL object, makes histogram and plots it

=back

=head1 CONSIDERATIONS

=over 4

=item Ensure your input arrays contain enough data

The caller is responsible for ensuring that the input arrays given
to Astro::FITS::CFITSIO routines are large enough to satisfy the access demands
of said routines. For example, if you tell C<fits_write_col()> to write
a data column containing 100 elements, your Perl array should contain
at least 100 elements. Segfaults abound, so beware!

=item maxdim semantics

Some cfitsio routines take a parameter named something like 'C<maxdim>',
indicating that no more than that many elements should be placed into
the output data area. An example of this would be C<fits_read_tdim()>.
In these cases Astro::FITS::CFITSIO will automatically determine how much storage
space is needed for the full amount of output possible. As a result,
the arguments expected in Astro::FITS::CFITSIO are slightly different than
one would use in a C program, in that the 'C<maxdim>' argument
is unnecessary.

Currently the routines
for which this is the case are C<fits_read_atblhdr()>, C<fits_read_btblhdr()>,
C<fits_read_imghdr()>, C<fits_decode_tdim()>, C<fits_read_tdim()>
C<fits_test_expr()>, C<fits_get_img_parm()> and C<fits_get_img_size()>.

=item Output arrays remain as undisturbed as possible

For routines like C<fits_read_col()>, Astro::FITS::CFITSIO unpacks the output into
a Perl array reference (unless C<PerlyUnpacking(0)> has been called, of
course). Prior to doing this, it ensures the scalar passed is a reference
to an array large enough to hold the data. If the argument is an
array reference which is too small, it expands the array pointed to
appropriately. B<But>, if the array is large enough already, the data
are just unpacked into the array. The upshot: If you call
C<fits_read_col()>, telling it to read 100 data elements, and the array
you are placing the data into already has 200 elements, then after
C<fits_read_col()> returns your array will still have 200 elements, only
the first 100 of which actually correspond to the data read by the routine.

In more succinct language:

    @output = (0..199);
    fits_read_col_lng($fptr,2,1,1,100,0,\@output,$anynul,$status);

    # @output still has 200 elements, only first 100 are from FITS
    # file

=back

=head1 EXTRA COMMANDS

Some extra commands that use sets of cfitsio routines are supplied to
simplify some standard tasks:

=over 4

=item fits_read_header(filename)

This command reads in a primary fits header (unless one is using the extended
filename sytax to move to a different HDU on open) from the specified filename
and returns the header as a hash reference and a status (when called
in an array context) or simply a hash reference (when called in a scalar
context):

  ($hash_ref, $status) = fits_read_header ($file);
  $hash_ref = fits_read_header($file);

An object-oriented interface is also provided for reading headers from
FITS files that have already been opened. In this case, the header
read is from the current HDU.

  $fitsfile = Astro::FITS::CFITSIO::open_file($file);
  $hash_ref = $fitsfile->read_header;
  ($hash_ref, $status) = $fitsfile->read_header;

=item sizeof_datatype(datatype)

Returns the size of the given Astro::FITS::CFITSIO datatype constant (e.g., C<Astro::FITS::CFITSIO::TSHORT()>).

=back

=head1 BUGS

FIXME

=head1 AUTHOR

Pete Ratzlaff E<lt>pratzlaff@cfa.harvard.eduE<gt>, with a great deal
of code taken from Karl Glazebrook's PGPLOT module.

Contributors include:

=over 4

=item Diab Jerius, E<lt>djerius@cpan.orgE<gt>

general improvements

=item Tim Jenness, E<lt>t.jenness@jach.hawaii.eduE<gt>

convenience routines

=item Tim Conrow, E<lt>tim@ipac.caltech.eduE<gt>

function implementations, bug fixes

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002,2004,2006,2011,2023 by the Smithsonian Astrophysical
Observatory.

This software is released under the same terms as Perl. A copy of the
Perl license may be obtained at http://dev.perl.org/licenses/

=cut
