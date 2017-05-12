#!/usr/bin/env perl

use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Business::DK::Postalcode qw(get_city_from_postalcode get_postalcode_from_city);
use Data::Dumper;

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

get '/lookup_zipcode/:zipcode' => sub {
  my $self = shift;

  $self->app->log->debug("zipcode parameter: ", $self->param('zipcode'));

  my $city = get_city_from_postalcode($self->param('zipcode'));

  $self->app->log->debug("city result: ", $city);

  my $response = { city_name => $city };

  $self->respond_to(
      json => { json => $response },
      html => { text => $city },
  );
};

get '/lookup_city/:city' => sub {
  my $self = shift;

  $self->app->log->debug("city parameter: ", $self->param('city'));

  my @postalcodes = get_postalcode_from_city($self->param('city'));

  $self->app->log->debug("postalcodes result: ", Dumper \@postalcodes);

  $self->respond_to(
      json => { json => { postalcodes => \@postalcodes } },
      html => { text => @postalcodes },
  );
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Business::DK::Postalcode web application/ajax demo';

<form action="/" method="post" role="form" class="form-inline">

  <div id="zipcode-group" class="form-group">
  <label for="zipcode" class="control-label" name="zipcodelabel">Zipcode:</label>
  <input class="form-control" id="zipcode" type="text" name="zipcode" placeholder="enter zipcode" onchange="lookup_zipcode()">
  </div>

  <div id="city-group" class="form-group">
  <label class="control-label" name="citylabel" for="city">City:</label>
  <input class="form-control" id="city" type="text" name="city" placeholder="enter city" onchange="lookup_city()">
  </div>

  <button class="btn btn-default" type="reset">
    <span class="glyphicon glyphicon-refresh"></span> Reset
  </button>
</form>


@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta .epp-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= title %></title>

    <!-- Bootstrap -->
    <!-- Latest compiled and minified CSS -->
    <!-- TODO online: <link rel="stylesheet" href="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"> -->
    <!-- Optional theme -->
    <!-- TODO online: <link rel="stylesheet" href="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css"> -->

    <link rel="stylesheet" href="/css/bootstrap.css">
    <link rel="stylesheet" href="/css/bootstrap-theme.css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body role="document">
    <div class="container">

    <p class="lead"><%= $title %></p>
    <p>Enter a danish zipcode (4 digits) and get it validated and get the 
    related city name or you can enter a city name and get the assigned zipcode or assistance to picking the right one, 
    since city names are not necessarily unique.</p>

    <p><%= content %></p>

    </div>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <!-- TODO online <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script> -->
    <script src="/js/jquery.min.js"></script>
    <!-- Latest compiled and minified JavaScript -->
    <!-- TODO online <script src="https://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script> -->
    <script src="/js/bootstrap.js"></script>

    <script language="javascript">

    $(document).ready(function() {
      $(document).on("click", "button[type='reset']", function(e){
        e.preventDefault();
        $("form")[0].reset();

        reset_validation_classes();
        reset_select();
      });
    });

    function reset_select() {
        console.log("resetting select to original form (input)");

        // selection is present so we remove it for input text
        if ($(document).find("select[name='zipcode']").length) {
          $("select[name='zipcode']").remove();

          var new_input = document.createElement('input');
          new_input.type = 'text';
          new_input.name = 'zipcode';
          new_input.setAttribute("id", "zipcode");
          new_input.className = 'form-control';

          $("label[name='zipcodelabel']").after(new_input);
        }
    }

    function reset_validation_classes() {
      console.log("resetting validation classes");

      $('span').remove();

      $('#zipcode-group').removeClass('has-success');
      $('#zipcode-group').removeClass('has-error');
      $('#zipcode-group').removeClass('has-warning');
      $('#zipcode-group').removeClass('has-feedback');

      $('#city-group').removeClass('has-success');
      $('#city-group').removeClass('has-error');
      $('#city-group').removeClass('has-warning');
      $('#city-group').removeClass('has-feedback');
    }

    function add_warning(designated_class) {
      reset_validation_classes();

      $(designated_class).addClass('has-warning');
      $(designated_class).addClass('has-feedback');

      var new_glyph_element = document.createElement('span');
      new_glyph_element.className = 'glyphicon glyphicon-warning-sign form-control-feedback';

      $(designated_class).append(new_glyph_element);
    }


    function add_success(designated_class) {
      reset_validation_classes();

      $(designated_class).addClass('has-success');
      $(designated_class).addClass('has-feedback');

      var new_glyph_element = document.createElement('span');
      new_glyph_element.className = 'glyphicon glyphicon-ok form-control-feedback';

      $(designated_class).append(new_glyph_element);
    }

    function add_error(designated_class) {
      reset_validation_classes();

      $(designated_class).addClass('has-error');
      $(designated_class).addClass('has-feedback');

      var new_glyph_element = document.createElement('span');
      new_glyph_element.className = 'glyphicon glyphicon-remove form-control-feedback';

      $(designated_class).append(new_glyph_element);
    }

    function lookup_city() {

        var city;
        city = $('#city').val();

        if (city.length > 0) {

          $.ajax({
                type: 'GET',
                url: 'lookup_city/' + city,
                dataType: 'json',
                crossDomain: false,
                contentType: "application/json",
                timeout: 1000, // milliseconds
              })
              .done(function(textStatus, data, jqXHR) {
                console.log( "request success: " + jqXHR.status );

                reset_validation_classes();

                if (textStatus.postalcodes.length == 0) {
                  console.log( "No data found");
                  add_error('#city-group');

                  $('#zipcode').val('');

                } else if (textStatus.postalcodes.length == 1) {
                  reset_select();

                  $('#zipcode').val(textStatus.postalcodes[0]);
                  add_success('#zipcode-group');

                } else {
                  console.log( "changing the input type for zipcode" );

                  if ($(document).find("select[name='zipcode']").length) {
                    $("select[name='zipcode']").remove();
                  } else {
                    $("input[name='zipcode']").remove();
                  }

                  var new_select = document.createElement('select');
                  new_select.name = 'zipcode';
                  new_select.className = 'form-control';

                  $("label[name='zipcodelabel']").after(new_select);

                  var zipcode_select = $('select');
                  $(textStatus.postalcodes).each(function() {
                   zipcode_select.append($("<option>").attr('value',this).text(this));
                  });
                }
              })
              .fail(function(jqXHR, textStatus, errorThrown) {
                console.log( "request error: " + jqXHR.status );
                add_error('#city-group');
              })
              .always(function() {
                console.log( "request complete" );
              });
           } else {
            add_warning('#city-group');
           }
          }

    function lookup_zipcode() {

      var zipcode;
      zipcode = $('#zipcode').val();

      if (zipcode.length > 0) {

        $.ajax({
              type: 'GET',
              url: 'lookup_zipcode/' + zipcode,
              dataType: 'json',
              crossDomain: false,
              contentType: "application/json",
              timeout: 1000, // milliseconds
            })
            .done(function(textStatus, data, jqXHR) {
              console.log( "request success: " + jqXHR.status );

              reset_validation_classes();

              if (textStatus.city_name == '') {
                add_error('#zipcode-group');
                $('#city').val('');

              } else {
                $('#city').val(textStatus.city_name);
                add_success('#city-group');
              }
            })
            .fail(function(jqXHR, textStatus, errorThrown) {
              console.log( "request error: " + jqXHR.status );
              add_error('#zipcode-group');
            })
            .always(function() {
              console.log( "request complete" );
            });
          } else {
            add_warning('#zipcode-group');
          }
        }
    </script>

  </body>
</html>