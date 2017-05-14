use Test::More;

    eval "use Test::Pod::Coverage";
    plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

    my $private_funcs = {also_private => [ qw/init_report init_page_header init_body init_graphics init_logos init_fields init_breaks begin_break begin_line begin_field make_field_headers out_field break_fields process_break print_break_header print_break process_field make_fieldtext process_linefield out_textarray print_line sum_totals check_for_break save_breaks process_totals begin_list check_page print_list print_totals end_print make_text make_func print_doc out_text set_papersize mm_to_pt calc_yoffset page_footer header_text print_pagenumber print_pageheader start_body draw_graphics draw_logos new_page text_color set_linecolor draw_topline draw_underline draw_linebox set_font get_pages get_pagedimensions set_size set_font get_add_textpos get_stringwidth draw_line draw_rect shade_rect set_gfxlinewidth add_img_scaled add_img set_textcolor add_paragraph finish_report new/ ]};
    all_pod_coverage_ok($private_funcs);
