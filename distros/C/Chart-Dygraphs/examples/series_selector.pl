
use Color::Brewer;
use Chart::Dygraphs;
    use Browser::Open qw( open_browser );
    use Path::Tiny;
    use DateTime;
    
    my $data = [map {[$_, rand($_)]} 1..10 ];
    my $html_file = Path::Tiny::tempfile(UNLINK => 0);
    my @color_scheme = Color::Brewer::named_color_scheme(name => 'Set1', number_of_data_classes => 9);
    $html_file->spew_utf8(Chart::Dygraphs::render_full_html(data => $data,
            options => {colors => \@color_scheme,
                        showRangeSelector => 1,
                        highlightSeriesOpts => {
          strokeWidth => 3,
          strokeBorderWidth => 1,
          highlightCircleSize => 5
        } },
        render_html_options => {
            dygraphs_div_inline_style => 'top: 70px;',
            pre_graph_html => '
            <p>
	<input type=checkbox id="0" checked onClick="change(this)">
	<label for="0">Series 1</label>
</p><hr />',
            post_graph_html => '
            <script type="text/javascript">
                  setStatus();

                  function setStatus() {

                    	document.getElementById("visibility").innerHTML =

                    	g.visibility().toString();

                  }


                  function change(el) {

                    	g.setVisibility(parseInt(el.id), el.checked);

                    	setStatus();

                  }

            </script>
            '
        }));
   
    open_browser($html_file->canonpath()); 

    my $start_date = DateTime->now(time_zone => 'UTC')->truncate(to => 'hour');
    my $time_series_data = [map {[$start_date->add(hours => 1)->clone(), rand($_)]} 1..1000];
    
    my $time_series_html_file = Path::Tiny::tempfile(UNLINK => 0);
    $time_series_html_file->spew_utf8(Chart::Dygraphs::render_full_html(data => $time_series_data));

    open_browser($time_series_html_file->canonpath());


